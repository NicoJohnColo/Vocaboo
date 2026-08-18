package com.vocaboo.service;

import com.vocaboo.dto.response.DifficultyProgressResponse;
import com.vocaboo.dto.response.WordMasterySummaryResponse;
import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;
import java.util.List;
import java.util.Map;
import java.util.ArrayList;
import java.util.stream.Collectors;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
@RequiredArgsConstructor
public class DifficultyAdjustmentService {

    private final DifficultyProgressRepository progressRepository;
    private final DifficultyAuditLogRepository auditLogRepository;
    private final LearnerRepository learnerRepository;
    private final VocabularyWordRepository wordRepository;
    private final PointTransactionRepository pointTransactionRepository;
    private final LearnerMasteryRepository masteryRepository;
    private final WordPerformanceRepository wordPerformanceRepository;

    @Transactional(readOnly = true)
    public DifficultyLevel getCurrentLevel(UUID learnerId, UUID wordId, Integer moduleNumber) {
        return progressRepository.findByLearnerLearnerIdAndWordWordIdAndModuleNumber(learnerId, wordId, moduleNumber != null ? moduleNumber : 2)
                .map(DifficultyProgress::getCurrentLevel)
                .orElse(DifficultyLevel.LEARNING);
    }

    public boolean shouldOfferHints(int consecutiveIncorrect, DifficultyLevel level) {
        return level == DifficultyLevel.LEARNING && consecutiveIncorrect >= 3;
    }

    @Transactional(readOnly = true)
    public boolean shouldOfferHints(UUID learnerId, UUID wordId, Integer moduleNumber) {
        DifficultyProgress progress = getOrCreateProgress(learnerId, wordId, moduleNumber);
        return shouldOfferHints(progress.getConsecutiveIncorrect(), progress.getCurrentLevel());
    }

    @Transactional(readOnly = true)
    public DifficultyProgressResponse getProgress(UUID learnerId, UUID wordId, Integer moduleNumber) {
        DifficultyProgress progress = getOrCreateProgress(learnerId, wordId, moduleNumber);
        return toProgressResponse(progress);
    }

    @Transactional(readOnly = true)
    public Map<UUID, String> getDifficultiesForLesson(UUID learnerId, UUID lessonId, Integer moduleNumber) {
        int modNum = moduleNumber != null ? moduleNumber : 2;
        return progressRepository.findByLearnerLearnerIdAndWordLessonLessonIdAndModuleNumber(learnerId, lessonId, modNum)
            .stream()
            .collect(Collectors.toMap(
                dp -> dp.getWord().getWordId(),
                dp -> dp.getCurrentLevel().name()
            ));
    }

    @Transactional(readOnly = true)
    public List<WordMasterySummaryResponse> getWordMasterySummary(UUID learnerId, UUID lessonId) {
        List<VocabularyWord> words = wordRepository.findByLessonLessonIdOrderByWordOrderAsc(lessonId);
        List<WordMasterySummaryResponse> responses = new ArrayList<>();
        
        for (VocabularyWord word : words) {
            DifficultyProgress progress = progressRepository.findByLearnerLearnerIdAndWordWordIdAndModuleNumber(learnerId, word.getWordId(), 2).orElse(null);
            WordPerformance perf = wordPerformanceRepository.findByLearnerLearnerIdAndWordWordId(learnerId, word.getWordId()).orElse(null);
            
            String tierState = progress != null ? progress.getCurrentLevel().name() : DifficultyLevel.LEARNING.name();
            
            String rating = null;
            if ("MASTERED".equals(tierState) && perf != null && perf.getAccuracy() != null) {
                double acc = perf.getAccuracy().doubleValue();
                if (acc >= 90.0) {
                    rating = "GOLD";
                } else if (acc >= 70.0) {
                    rating = "SILVER";
                } else {
                    rating = "BRONZE";
                }
            }
            
            responses.add(WordMasterySummaryResponse.builder()
                .wordId(word.getWordId())
                .englishWord(word.getEnglishWord())
                .cebuanoMeaning(word.getCebuanoMeaning())
                .partOfSpeech(word.getPartOfSpeech())
                .tierState(tierState)
                .wordRating(rating)
                .totalAttempts(perf != null ? perf.getTotalAttempts() : 0)
                .correctAttempts(perf != null ? perf.getCorrectCount() : 0)
                .accuracy(perf != null && perf.getAccuracy() != null ? perf.getAccuracy() : BigDecimal.ZERO)
                .tierDropCount(0) // Default as it's not tracked directly
                .build());
        }
        return responses;
    }

    @Transactional
    public DifficultyProgressResponse calculateNext(UUID learnerId, UUID wordId, boolean isCorrect, Integer moduleNumber, String activityType) {
        DifficultyProgress progress = getOrCreateProgress(learnerId, wordId, moduleNumber);
        DifficultyLevel oldLevel = progress.getCurrentLevel();
        DifficultyLevel newLevel = oldLevel;

        if ("PRONUNCIATION_FEEDBACK".equalsIgnoreCase(activityType)) {
            return toProgressResponse(progress);
        }

        // True/False is a flat-rate exception: scores fixed points, but NEVER touches streak or tier either way
        if ("TRUE_OR_FALSE".equalsIgnoreCase(activityType)) {
            progress.setAttemptCountAtCurrentTier(progress.getAttemptCountAtCurrentTier() + 1);
            progress.setLastAdjustedAt(OffsetDateTime.now());
            progress.setUpdatedAt(OffsetDateTime.now());
            progress = progressRepository.save(progress);
            return toProgressResponse(progress);
        }

        boolean isRecallType = isRecallActivity(activityType);
        log.info("CALCULATE_NEXT_ENTRY: word={} activity={} correct={} module={} oldLevel={} streakCorrect={} streakIncorrect={} recallFlag={}",
                wordId, activityType, isCorrect, moduleNumber, oldLevel,
                progress.getConsecutiveCorrect(), progress.getConsecutiveIncorrect(),
                progress.getRecallInCurrentStreak());

        boolean isModule3 = (moduleNumber != null && moduleNumber == 3);

        if (isCorrect) {
            // Reset consecutive wrong streak; preserve and increment correct streak
            progress.setConsecutiveIncorrect(0);
            progress.setConsecutiveCorrect(progress.getConsecutiveCorrect() + 1);

            if (isRecallType) {
                progress.setRecallInCurrentStreak(true);
            }

            if (isModule3) {
                if ("SENTENCE_ARRANGEMENT".equalsIgnoreCase(activityType)) {
                    progress.setSentenceRearrangementClearedAtCurrentTier(true);
                } else if ("FILL_IN_BLANK".equalsIgnoreCase(activityType) || "SENTENCE_COMPLETION".equalsIgnoreCase(activityType)) {
                    progress.setSentenceCompletionClearedAtCurrentTier(true);
                }
            }

            boolean readyToAdvance = false;
            int requiredStreak = getRequiredUpgradeStreak(oldLevel);
            boolean satisfiesRecallGate = (oldLevel != DifficultyLevel.PROFICIENT) || Boolean.TRUE.equals(progress.getRecallInCurrentStreak());

            if (isModule3) {
                readyToAdvance = Boolean.TRUE.equals(progress.getSentenceCompletionClearedAtCurrentTier()) && 
                                 Boolean.TRUE.equals(progress.getSentenceRearrangementClearedAtCurrentTier());
                log.info("CALCULATE_NEXT_CORRECT_M3: word={} activity={} oldLevel={} compCleared={} arrCleared={} ready={}",
                        wordId, activityType, oldLevel, progress.getSentenceCompletionClearedAtCurrentTier(),
                        progress.getSentenceRearrangementClearedAtCurrentTier(), readyToAdvance);
            } else {
                readyToAdvance = (progress.getConsecutiveCorrect() >= requiredStreak && satisfiesRecallGate);
                log.info("CALCULATE_NEXT_CORRECT: word={} activity={} oldLevel={} streak={}/{} recallGate={}",
                        wordId, activityType, oldLevel, progress.getConsecutiveCorrect(), requiredStreak, satisfiesRecallGate);
            }

            if (readyToAdvance && oldLevel != DifficultyLevel.MASTERED) {
                newLevel = getNextHigher(oldLevel);
                progress.setCurrentLevel(newLevel);
                progress.setConsecutiveCorrect(0);
                progress.setRecallInCurrentStreak(false);
                progress.setSentenceCompletionClearedAtCurrentTier(false);
                progress.setSentenceRearrangementClearedAtCurrentTier(false);
                progress.setAttemptCountAtCurrentTier(1);
                log.info("LEVEL_UP: word={} {} -> {}", wordId, oldLevel, newLevel);
                logTransition(progress.getLearner(), progress.getWord(), oldLevel, newLevel, "CONSECUTIVE_CORRECT");

                if (newLevel == DifficultyLevel.MASTERED && !Boolean.TRUE.equals(progress.getMasteryBonusAwarded())) {
                    progress.setMasteryBonusAwarded(true);
                    PointTransaction transaction = PointTransaction.builder()
                            .learner(progress.getLearner())
                            .actionType(PointActionType.WORD_MASTERED)
                            .pointsAwarded(50)
                            .relatedWord(progress.getWord())
                            .createdAt(OffsetDateTime.now())
                            .build();
                    pointTransactionRepository.save(transaction);

                    final Learner targetLearner = progress.getLearner();
                    LearnerMastery mastery = masteryRepository.findByLearnerLearnerId(targetLearner.getLearnerId())
                            .orElseGet(() -> LearnerMastery.builder()
                                    .learner(targetLearner)
                                    .totalSessionsPlayed(0)
                                    .totalCorrectAnswers(0)
                                    .totalQuestionsAnswered(0)
                                    .overallAccuracy(BigDecimal.ZERO)
                                    .wordsMasteredCount(0)
                                    .totalPoints(0)
                                    .masteryLevel("LEARNING")
                                    .createdAt(OffsetDateTime.now())
                                    .build());
                    mastery.setTotalPoints(mastery.getTotalPoints() + 50);
                    masteryRepository.save(mastery);
                }
            } else {
                // Not yet at required streak — stay at current level, no demotion
                progress.setAttemptCountAtCurrentTier(progress.getAttemptCountAtCurrentTier() + 1);
                log.info("CALCULATE_NEXT_HOLD: word={} stays at {} (streak {}/{}, recallGate={})",
                        wordId, oldLevel, progress.getConsecutiveCorrect(), requiredStreak, satisfiesRecallGate);
            }
        } else {
            // Wrong answer: reset correct streak
            progress.setConsecutiveCorrect(0);
            progress.setRecallInCurrentStreak(false);
            int newIncorrect = progress.getConsecutiveIncorrect() + 1;
            progress.setConsecutiveIncorrect(newIncorrect);
            progress.setAttemptCountAtCurrentTier(progress.getAttemptCountAtCurrentTier() + 1);

            if (isModule3) {
                progress.setSentenceCompletionClearedAtCurrentTier(false);
                progress.setSentenceRearrangementClearedAtCurrentTier(false);
                progress.setConsecutiveIncorrect(0);
                newLevel = getNextLower(oldLevel);
                if (newLevel != oldLevel) {
                    progress.setCurrentLevel(newLevel);
                    progress.setAttemptCountAtCurrentTier(1);
                    logTransition(progress.getLearner(), progress.getWord(), oldLevel, newLevel, "MODULE_3_INCORRECT_DEMOTION");
                }
            } else {
                // Demotion gate: require 2 consecutive wrong answers before easing down
                // (1 wrong answer just resets the correct streak — no tier change)
                final int demotionThreshold = 2;

                log.info("CALCULATE_NEXT_WRONG: word={} oldLevel={} consecutiveWrong={}/{}",
                        wordId, oldLevel, newIncorrect, demotionThreshold);

                if (oldLevel != DifficultyLevel.LEARNING && newIncorrect >= demotionThreshold) {
                    // After 2 consecutive wrong answers, ease down one level
                    newLevel = getNextLower(oldLevel);
                    progress.setCurrentLevel(newLevel);
                    progress.setConsecutiveIncorrect(0);
                    progress.setAttemptCountAtCurrentTier(1);
                    log.info("LEVEL_DOWN: word={} {} -> {} after {} wrong answers", wordId, oldLevel, newLevel, demotionThreshold);
                    logTransition(progress.getLearner(), progress.getWord(), oldLevel, newLevel, "CONSECUTIVE_INCORRECT_EASE_DOWN");
                } else if (oldLevel == DifficultyLevel.LEARNING) {
                    // At LEARNING floor: if 4 consecutive incorrect, trigger short reintroduction
                    if (newIncorrect >= 4) {
                        progress.setNeedsReintroduction(true);
                        progress.setReintroductionCount(progress.getReintroductionCount() + 1);
                        progress.setLastReintroducedAt(OffsetDateTime.now());
                        progress.setConsecutiveIncorrect(0);
                        logTransition(progress.getLearner(), progress.getWord(), oldLevel, oldLevel, "SHORT_REINTRODUCTION_TRIGGERED");
                    }
                }
            }
        }

        progress.setLastAdjustedAt(OffsetDateTime.now());
        progress.setUpdatedAt(OffsetDateTime.now());
        progress = progressRepository.save(progress);
        log.info("CALCULATE_NEXT_RESULT: word={} savedLevel={} savedStreak={}", wordId, progress.getCurrentLevel(), progress.getConsecutiveCorrect());

        return toProgressResponse(progress);
    }

    private boolean isRecallActivity(String activityType) {
        if (activityType == null) return false;
        String type = activityType.toUpperCase();
        return type.equals("FILL_IN_BLANK") || 
               type.equals("WORD_SCRAMBLE") || 
               type.equals("TRANSLATION_RECALL") || 
               type.equals("TYPE_WHAT_YOU_HEAR") || 
               type.equals("SENTENCE_ARRANGEMENT") || 
               type.equals("SENTENCE_COMPLETION");
    }

    @Transactional
    public DifficultyProgressResponse completeReintroduction(UUID learnerId, UUID wordId, Integer moduleNumber) {
        DifficultyProgress progress = getOrCreateProgress(learnerId, wordId, moduleNumber);
        DifficultyLevel oldLevel = progress.getCurrentLevel();

        progress.setCurrentLevel(DifficultyLevel.LEARNING);
        progress.setNeedsReintroduction(false);
        progress.setConsecutiveCorrect(0);
        progress.setConsecutiveIncorrect(0);
        progress.setRecallInCurrentStreak(false);
        progress.setAttemptCountAtCurrentTier(1);
        progress.setLastAdjustedAt(OffsetDateTime.now());
        progress.setUpdatedAt(OffsetDateTime.now());

        logTransition(progress.getLearner(), progress.getWord(), oldLevel, DifficultyLevel.LEARNING, "REINTRODUCTION_COMPLETED");
        progress = progressRepository.save(progress);

        return toProgressResponse(progress);
    }

    @Transactional
    public DifficultyProgressResponse increment(UUID learnerId, UUID wordId, Integer moduleNumber) {
        DifficultyProgress progress = getOrCreateProgress(learnerId, wordId, moduleNumber);
        DifficultyLevel oldLevel = progress.getCurrentLevel();
        DifficultyLevel newLevel = getNextHigher(oldLevel);

        if (newLevel != oldLevel) {
            progress.setCurrentLevel(newLevel);
            progress.setConsecutiveCorrect(0);
            progress.setConsecutiveIncorrect(0);
            progress.setRecallInCurrentStreak(false);
            progress.setAttemptCountAtCurrentTier(1);
            logTransition(progress.getLearner(), progress.getWord(), oldLevel, newLevel, "MANUAL_INCREMENT");
        }

        progress.setLastAdjustedAt(OffsetDateTime.now());
        progress.setUpdatedAt(OffsetDateTime.now());
        progress = progressRepository.save(progress);

        return toProgressResponse(progress);
    }

    @Transactional
    public DifficultyProgressResponse decrement(UUID learnerId, UUID wordId, Integer moduleNumber) {
        DifficultyProgress progress = getOrCreateProgress(learnerId, wordId, moduleNumber);
        DifficultyLevel oldLevel = progress.getCurrentLevel();
        DifficultyLevel newLevel = getNextLower(oldLevel);

        if (newLevel != oldLevel) {
            progress.setCurrentLevel(newLevel);
            progress.setConsecutiveCorrect(0);
            progress.setConsecutiveIncorrect(0);
            progress.setRecallInCurrentStreak(false);
            progress.setAttemptCountAtCurrentTier(1);
            logTransition(progress.getLearner(), progress.getWord(), oldLevel, newLevel, "MANUAL_DECREMENT");
        }

        progress.setLastAdjustedAt(OffsetDateTime.now());
        progress.setUpdatedAt(OffsetDateTime.now());
        progress = progressRepository.save(progress);

        return toProgressResponse(progress);
    }

    private DifficultyProgress getOrCreateProgress(UUID learnerId, UUID wordId, Integer moduleNumber) {
        int modNum = moduleNumber != null ? moduleNumber : 2;
        return progressRepository.findByLearnerLearnerIdAndWordWordIdAndModuleNumber(learnerId, wordId, modNum)
                .orElseGet(() -> {
                    log.warn("PROGRESS_ROW_MISSING: No DifficultyProgress row for learner={} word={} module={} — creating default",
                            learnerId, wordId, modNum);
                    Learner learner = learnerRepository.findById(learnerId)
                            .orElseThrow(() -> new IllegalArgumentException("Learner not found"));
                    VocabularyWord word = wordRepository.findById(wordId)
                            .orElseThrow(() -> new IllegalArgumentException("Word not found"));

                    DifficultyLevel initialLevel = DifficultyLevel.LEARNING;

                    // If creating for module 2, inherit from Diagnostic (module 1) if it exists
                    if (modNum == 2) {
                        DifficultyLevel diagLevel = progressRepository.findByLearnerLearnerIdAndWordWordIdAndModuleNumber(learnerId, wordId, 1)
                                .map(DifficultyProgress::getCurrentLevel)
                                .orElse(DifficultyLevel.LEARNING);
                        
                        if (diagLevel == DifficultyLevel.FAMILIAR || diagLevel == DifficultyLevel.PROFICIENT || diagLevel == DifficultyLevel.MASTERED) {
                            initialLevel = DifficultyLevel.FAMILIAR;
                            log.info("INHERIT_DIAGNOSTIC: Learner={} Word={} starting Module 2 at FAMILIAR", learnerId, wordId);
                        }
                    }

                    DifficultyProgress defaultProgress = DifficultyProgress.builder()
                            .learner(learner)
                            .word(word)
                            .moduleNumber(modNum)
                            .currentLevel(initialLevel)
                            .consecutiveCorrect(0)
                            .consecutiveIncorrect(0)
                            .needsReintroduction(false)
                            .reintroductionCount(0)
                            .createdAt(OffsetDateTime.now())
                            .updatedAt(OffsetDateTime.now())
                            .build();

                    return progressRepository.save(defaultProgress);
                });
    }

    private int getRequiredUpgradeStreak(DifficultyLevel level) {
        switch (level) {
            case LEARNING:
                return 2;
            case FAMILIAR:
                return 2;
            case PROFICIENT:
                return 3;
            default:
                return Integer.MAX_VALUE;
        }
    }

    private DifficultyLevel getNextHigher(DifficultyLevel current) {
        switch (current) {
            case LEARNING:
                return DifficultyLevel.FAMILIAR;
            case FAMILIAR:
                return DifficultyLevel.PROFICIENT;
            case PROFICIENT:
            case MASTERED:
                return DifficultyLevel.MASTERED;
            default:
                return current;
        }
    }

    private DifficultyLevel getNextLower(DifficultyLevel current) {
        switch (current) {
            case MASTERED:
                return DifficultyLevel.PROFICIENT;
            case PROFICIENT:
                return DifficultyLevel.FAMILIAR;
            case FAMILIAR:
            case LEARNING:
                return DifficultyLevel.LEARNING;
            default:
                return current;
        }
    }

    @Transactional
    public DifficultyProgressResponse diagnosticBoost(UUID learnerId, UUID wordId, String activityType, Integer moduleNumber) {
        DifficultyProgress progress = getOrCreateProgress(learnerId, wordId, moduleNumber);
        DifficultyLevel oldLevel = progress.getCurrentLevel();
        // Known words start at FAMILIAR: FAMILIAR (2 correct) -> PROFICIENT (3 correct + recall) -> MASTERED
        progress.setCurrentLevel(DifficultyLevel.FAMILIAR);
        progress.setConsecutiveCorrect(0);
        progress.setConsecutiveIncorrect(0);
        progress.setRecallInCurrentStreak(false);
        progress.setAttemptCountAtCurrentTier(1);
        progress.setDiagnosticAdministered(true);
        progress.setDiagnosticResult("correct");
        if (activityType != null && !activityType.isBlank()) {
            progress.setDiagnosticActivityType(activityType);
        }
        logTransition(progress.getLearner(), progress.getWord(), oldLevel, DifficultyLevel.FAMILIAR, "DIAGNOSTIC_BOOST");
        progress.setLastAdjustedAt(OffsetDateTime.now());
        progress.setUpdatedAt(OffsetDateTime.now());
        progress = progressRepository.save(progress);
        return toProgressResponse(progress);
    }

    @Transactional
    public DifficultyProgressResponse recordDiagnosticFail(UUID learnerId, UUID wordId, String activityType, Integer moduleNumber) {
        DifficultyProgress progress = getOrCreateProgress(learnerId, wordId, moduleNumber);
        DifficultyLevel oldLevel = progress.getCurrentLevel();
        progress.setCurrentLevel(DifficultyLevel.LEARNING);
        progress.setConsecutiveCorrect(0);
        progress.setConsecutiveIncorrect(0);
        progress.setRecallInCurrentStreak(false);
        progress.setAttemptCountAtCurrentTier(1);
        progress.setDiagnosticAdministered(true);
        progress.setDiagnosticResult("incorrect");
        if (activityType != null && !activityType.isBlank()) {
            progress.setDiagnosticActivityType(activityType);
        }
        logTransition(progress.getLearner(), progress.getWord(), oldLevel, DifficultyLevel.LEARNING, "DIAGNOSTIC_FAIL");
        progress.setLastAdjustedAt(OffsetDateTime.now());
        progress.setUpdatedAt(OffsetDateTime.now());
        progress = progressRepository.save(progress);
        return toProgressResponse(progress);
    }

    private void logTransition(Learner learner, VocabularyWord word, DifficultyLevel oldL, DifficultyLevel newL, String reason) {
        DifficultyAuditLog auditLog = DifficultyAuditLog.builder()
                .learner(learner)
                .word(word)
                .oldLevel(oldL)
                .newLevel(newL)
                .reason(reason)
                .changedAt(OffsetDateTime.now())
                .build();
        auditLogRepository.save(auditLog);
    }

    private DifficultyProgressResponse toProgressResponse(DifficultyProgress progress) {
        boolean showHints = shouldOfferHints(progress.getConsecutiveIncorrect(), progress.getCurrentLevel());
        return DifficultyProgressResponse.builder()
                .progressId(progress.getProgressId())
                .learnerId(progress.getLearner().getLearnerId())
                .wordId(progress.getWord().getWordId())
                .currentLevel(progress.getCurrentLevel().name())
                .consecutiveCorrect(progress.getConsecutiveCorrect())
                .consecutiveIncorrect(progress.getConsecutiveIncorrect())
                .recallInCurrentStreak(progress.getRecallInCurrentStreak())
                .attemptCountAtCurrentTier(progress.getAttemptCountAtCurrentTier())
                .needsReintroduction(progress.getNeedsReintroduction())
                .reintroductionCount(progress.getReintroductionCount())
                .lastReintroducedAt(progress.getLastReintroducedAt())
                .needsTeacherReview(progress.getNeedsTeacherReview())
                .diagnosticAdministered(progress.getDiagnosticAdministered())
                .diagnosticResult(progress.getDiagnosticResult())
                .diagnosticActivityType(progress.getDiagnosticActivityType())
                .showHints(showHints)
                .lastAdjustedAt(progress.getLastAdjustedAt())
                .build();
    }
}
