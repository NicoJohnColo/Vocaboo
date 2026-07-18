package com.vocaboo.service;

import com.vocaboo.dto.response.DifficultyProgressResponse;
import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.OffsetDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class DifficultyAdjustmentService {

    public static final int UPGRADE_THRESHOLD = 3;
    public static final int DOWNGRADE_THRESHOLD = 2;
    public static final int RESET_THRESHOLD = 3;

    private final DifficultyProgressRepository progressRepository;
    private final DifficultyAuditLogRepository auditLogRepository;
    private final LearnerRepository learnerRepository;
    private final VocabularyWordRepository wordRepository;
    private final PointTransactionRepository pointTransactionRepository;
    private final LearnerMasteryRepository masteryRepository;

    @Transactional(readOnly = true)
    public DifficultyLevel getCurrentLevel(UUID learnerId, UUID wordId) {
        return progressRepository.findByLearnerLearnerIdAndWordWordId(learnerId, wordId)
                .map(DifficultyProgress::getCurrentLevel)
                .orElse(DifficultyLevel.LEARNING);
    }

    @Transactional
    public DifficultyProgressResponse getProgress(UUID learnerId, UUID wordId) {
        DifficultyProgress progress = getOrCreateProgress(learnerId, wordId);
        return toProgressResponse(progress);
    }

    @Transactional
    public DifficultyProgressResponse calculateNext(UUID learnerId, UUID wordId, boolean isCorrect) {
        DifficultyProgress progress = getOrCreateProgress(learnerId, wordId);
        DifficultyLevel oldLevel = progress.getCurrentLevel();
        DifficultyLevel newLevel = oldLevel;

        if (isCorrect) {
            progress.setConsecutiveIncorrect(0);
            progress.setConsecutiveCorrect(progress.getConsecutiveCorrect() + 1);

            if (progress.getConsecutiveCorrect() >= UPGRADE_THRESHOLD) {
                // Word mastered! Record transaction
                PointTransaction transaction = PointTransaction.builder()
                        .learner(progress.getLearner())
                        .actionType(PointActionType.WORD_MASTERED)
                        .pointsAwarded(50)
                        .relatedWord(progress.getWord())
                        .createdAt(OffsetDateTime.now())
                        .build();
                pointTransactionRepository.save(transaction);

                final Learner targetLearner = progress.getLearner();
                // Update cached totalPoints in LearnerMastery
                LearnerMastery mastery = masteryRepository.findByLearnerLearnerId(targetLearner.getLearnerId())
                        .orElseGet(() -> LearnerMastery.builder()
                                .learner(targetLearner)
                                .totalSessionsPlayed(0)
                                .totalCorrectAnswers(0)
                                .totalQuestionsAnswered(0)
                                .overallAccuracy(BigDecimal.ZERO)
                                .wordsMasteredCount(0)
                                .totalPoints(0)
                                .createdAt(OffsetDateTime.now())
                                .build());
                mastery.setTotalPoints(mastery.getTotalPoints() + 50);
                masteryRepository.save(mastery);

                newLevel = getNextHigher(oldLevel);
                if (newLevel != oldLevel) {
                    progress.setCurrentLevel(newLevel);
                    logTransition(progress.getLearner(), progress.getWord(), oldLevel, newLevel, "CONSECUTIVE_CORRECT");
                }
                progress.setConsecutiveCorrect(0);
            }
        } else {
            progress.setConsecutiveCorrect(0);
            int newIncorrect = progress.getConsecutiveIncorrect() + 1;
            progress.setConsecutiveIncorrect(newIncorrect);

            if (newIncorrect >= RESET_THRESHOLD) {
                newLevel = DifficultyLevel.LEARNING;
                if (newLevel != oldLevel) {
                    progress.setCurrentLevel(newLevel);
                    logTransition(progress.getLearner(), progress.getWord(), oldLevel, newLevel, "SEVERE_STRUGGLING_RESET");
                }
                progress.setConsecutiveIncorrect(0);
            } else if (newIncorrect >= DOWNGRADE_THRESHOLD) {
                newLevel = getNextLower(oldLevel);
                if (newLevel != oldLevel) {
                    progress.setCurrentLevel(newLevel);
                    logTransition(progress.getLearner(), progress.getWord(), oldLevel, newLevel, "CONSECUTIVE_INCORRECT");
                }
                progress.setConsecutiveIncorrect(0);
            }
        }

        progress.setLastAdjustedAt(OffsetDateTime.now());
        progress.setUpdatedAt(OffsetDateTime.now());
        progress = progressRepository.save(progress);

        return toProgressResponse(progress);
    }

    @Transactional
    public DifficultyProgressResponse increment(UUID learnerId, UUID wordId) {
        DifficultyProgress progress = getOrCreateProgress(learnerId, wordId);
        DifficultyLevel oldLevel = progress.getCurrentLevel();
        DifficultyLevel newLevel = getNextHigher(oldLevel);

        if (newLevel != oldLevel) {
            progress.setCurrentLevel(newLevel);
            progress.setConsecutiveCorrect(0);
            progress.setConsecutiveIncorrect(0);
            logTransition(progress.getLearner(), progress.getWord(), oldLevel, newLevel, "MANUAL_INCREMENT");
        }

        progress.setLastAdjustedAt(OffsetDateTime.now());
        progress.setUpdatedAt(OffsetDateTime.now());
        progress = progressRepository.save(progress);

        return toProgressResponse(progress);
    }

    @Transactional
    public DifficultyProgressResponse decrement(UUID learnerId, UUID wordId) {
        DifficultyProgress progress = getOrCreateProgress(learnerId, wordId);
        DifficultyLevel oldLevel = progress.getCurrentLevel();
        DifficultyLevel newLevel = getNextLower(oldLevel);

        if (newLevel != oldLevel) {
            progress.setCurrentLevel(newLevel);
            progress.setConsecutiveCorrect(0);
            progress.setConsecutiveIncorrect(0);
            logTransition(progress.getLearner(), progress.getWord(), oldLevel, newLevel, "MANUAL_DECREMENT");
        }

        progress.setLastAdjustedAt(OffsetDateTime.now());
        progress.setUpdatedAt(OffsetDateTime.now());
        progress = progressRepository.save(progress);

        return toProgressResponse(progress);
    }

    private DifficultyProgress getOrCreateProgress(UUID learnerId, UUID wordId) {
        return progressRepository.findByLearnerLearnerIdAndWordWordId(learnerId, wordId)
                .orElseGet(() -> {
                    Learner learner = learnerRepository.findById(learnerId)
                            .orElseThrow(() -> new IllegalArgumentException("Learner not found"));
                    VocabularyWord word = wordRepository.findById(wordId)
                            .orElseThrow(() -> new IllegalArgumentException("Word not found"));

                    DifficultyProgress defaultProgress = DifficultyProgress.builder()
                            .learner(learner)
                            .word(word)
                            .currentLevel(DifficultyLevel.LEARNING)
                            .consecutiveCorrect(0)
                            .consecutiveIncorrect(0)
                            .createdAt(OffsetDateTime.now())
                            .updatedAt(OffsetDateTime.now())
                            .build();

                    return progressRepository.save(defaultProgress);
                });
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
        return DifficultyProgressResponse.builder()
                .progressId(progress.getProgressId())
                .learnerId(progress.getLearner().getLearnerId())
                .wordId(progress.getWord().getWordId())
                .currentLevel(progress.getCurrentLevel().name())
                .consecutiveCorrect(progress.getConsecutiveCorrect())
                .consecutiveIncorrect(progress.getConsecutiveIncorrect())
                .lastAdjustedAt(progress.getLastAdjustedAt())
                .build();
    }
}
