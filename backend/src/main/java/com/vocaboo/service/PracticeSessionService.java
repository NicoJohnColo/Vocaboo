package com.vocaboo.service;

import com.vocaboo.dto.response.*;
import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.OffsetDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PracticeSessionService {

    private final PracticeSessionRepository sessionRepository;
    private final PracticeResultRepository resultRepository;
    private final LearnerMasteryRepository masteryRepository;
    private final WordPerformanceRepository performanceRepository;
    private final LearnerRepository learnerRepository;
    private final LessonRepository lessonRepository;
    private final VocabularyWordRepository wordRepository;
    private final PointTransactionRepository pointTransactionRepository;
    private final VocabularyCategoryRepository categoryRepository;
    private final SessionSummaryRepository summaryRepository;
    private final DifficultyProgressRepository difficultyProgressRepository;
    private final ReviewItemRepository reviewItemRepository;
    private final LearnerLessonStatusRepository lessonStatusRepository;
    private final LessonModuleScoreRepository lessonModuleScoreRepository;

    // Activities excluded from all scoring (no pts, no accuracy count)
    private static final java.util.Set<String> SCORING_EXCLUDED = java.util.Set.of(
        "CONFUSABLE_DISTINCTION", "PRONUNCIATION_FEEDBACK"
    );
    // TRUE_FALSE uses flat rate, excluded from streak/tier but counted in accuracy
    private static final java.util.Set<String> TRUE_FALSE_TYPES = java.util.Set.of(
        "TRUE_OR_FALSE", "TRUE_FALSE"
    );

    @Transactional
    public PracticeSessionResponse start(UUID learnerId, UUID lessonId, int moduleNumber) {
        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner not found"));
        Lesson lesson = lessonRepository.findById(lessonId)
                .orElseThrow(() -> new IllegalArgumentException("Lesson not found"));

        PracticeSession session = PracticeSession.builder()
                .sessionId(UUID.randomUUID())
                .learner(learner)
                .lesson(lesson)
                .moduleNumber(moduleNumber)
                .createdAt(OffsetDateTime.now())
                .updatedAt(OffsetDateTime.now())
                .build();

        session = sessionRepository.save(session);

        // Lazily initialize LearnerMastery record if not exists
        if (masteryRepository.findByLearnerLearnerId(learnerId).isEmpty()) {
            LearnerMastery mastery = LearnerMastery.builder()
                    .learner(learner)
                    .totalSessionsPlayed(0)
                    .totalCorrectAnswers(0)
                    .totalQuestionsAnswered(0)
                    .overallAccuracy(BigDecimal.ZERO)
                    .wordsMasteredCount(0)
                    .totalPoints(0)
                    .masteryLevel("LEARNING")
                    .createdAt(OffsetDateTime.now())
                    .updatedAt(OffsetDateTime.now())
                    .build();
            masteryRepository.save(mastery);
        }

        return toSessionResponse(session);
    }

    @Transactional
    public PracticeResultResponse record(UUID sessionId, UUID wordId, boolean isCorrect) {
        return record(sessionId, wordId, isCorrect, null, null);
    }

    @Transactional
    public PracticeResultResponse record(UUID sessionId, UUID wordId, boolean isCorrect, String activityType, Integer explicitAttemptNumber) {
        PracticeSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new IllegalArgumentException("Session not found"));
        VocabularyWord word = wordRepository.findById(wordId)
                .orElseThrow(() -> new IllegalArgumentException("Word not found"));

        String resolvedActivityType = activityType != null && !activityType.isBlank()
                ? activityType.toUpperCase()
                : "MULTIPLE_CHOICE";

        // Activities excluded from percentage accuracy scoring
        if (SCORING_EXCLUDED.contains(resolvedActivityType)) {
            int excludedPoints = ("PRONUNCIATION_FEEDBACK".equals(resolvedActivityType) && isCorrect) ? 15 : 0;
            // Still record the result row for audit; awards 15 pts for correct pronunciation without accuracy impact
            PracticeResult result = PracticeResult.builder()
                    .session(session)
                    .word(word)
                    .isCorrect(isCorrect)
                    .attemptNumber(1)
                    .activityType(resolvedActivityType)
                    .points(excludedPoints)
                    .recordedAt(OffsetDateTime.now())
                    .build();
            return toResultResponse(resultRepository.save(result));
        }

        // TRUE_FALSE: flat 5 pts correct, 0 wrong — no tier/streak effect
        boolean isTrueFalse = TRUE_FALSE_TYPES.contains(resolvedActivityType);

        // Determine points:
        // TRUE_FALSE: flat 5/0
        // All others: use attemptCountAtCurrentTier from DifficultyProgress (resets on tier change)
        int pointsEarned = 0;
        if (isCorrect) {
            if (isTrueFalse) {
                pointsEarned = 5;
            } else {
                int mod = session.getModuleNumber() != null ? session.getModuleNumber() : 2;
                // Look up the attempt count at current tier from DifficultyProgress
                int attemptCount = difficultyProgressRepository
                        .findByLearnerLearnerIdAndWordWordIdAndModuleNumber(session.getLearner().getLearnerId(), wordId, mod)
                        .map(dp -> dp.getAttemptCountAtCurrentTier() != null ? dp.getAttemptCountAtCurrentTier() : 1)
                        .orElse(1);
                if (attemptCount == 1) pointsEarned = 10;
                else if (attemptCount == 2) pointsEarned = 7;
                else pointsEarned = 5; // 3rd+ attempt, floor at 5
            }
        }

        // Determine attempt number for audit record
        int attemptNumber;
        if (explicitAttemptNumber != null && explicitAttemptNumber > 0) {
            attemptNumber = explicitAttemptNumber;
        } else {
            List<PracticeResult> existingResults = resultRepository.findBySessionSessionId(sessionId);
            long attemptsOnThisWord = existingResults.stream()
                    .filter(r -> r.getWord().getWordId().equals(wordId))
                    .count();
            attemptNumber = (int) attemptsOnThisWord + 1;
        }

        PracticeResult result = PracticeResult.builder()
                .session(session)
                .word(word)
                .isCorrect(isCorrect)
                .attemptNumber(attemptNumber)
                .activityType(resolvedActivityType)
                .points(pointsEarned)
                .recordedAt(OffsetDateTime.now())
                .build();

        result = resultRepository.save(result);

        if (isCorrect && pointsEarned > 0) {
            PointTransaction transaction = PointTransaction.builder()
                    .learner(session.getLearner())
                    .actionType(PointActionType.CORRECT_ANSWER)
                    .pointsAwarded(pointsEarned)
                    .relatedSessionId(sessionId)
                    .relatedWord(word)
                    .createdAt(OffsetDateTime.now())
                    .build();
            pointTransactionRepository.save(transaction);
        }

        // Only advance tier state via API call since DifficultyAdjustmentService handles the gate rules.
        // We do NOT modify difficulty state here anymore, but we can query it if needed.
        difficultyProgressRepository
                .findByLearnerLearnerIdAndWordWordIdAndModuleNumber(session.getLearner().getLearnerId(), wordId, session.getModuleNumber() != null ? session.getModuleNumber() : 2)
                .ifPresent(dp -> {
                    // Just touching it so it's fresh if needed for metrics elsewhere
                });

        // Update WordPerformance (track accuracy for word rating)
        WordPerformance performance = performanceRepository
                .findByLearnerLearnerIdAndWordWordId(session.getLearner().getLearnerId(), wordId)
                .orElseGet(() -> WordPerformance.builder()
                        .learner(session.getLearner())
                        .word(word)
                        .correctCount(0)
                        .incorrectCount(0)
                        .totalAttempts(0)
                        .tierDropCount(0)
                        .accuracy(BigDecimal.ZERO)
                        .createdAt(OffsetDateTime.now())
                        .build());

        performance.setTotalAttempts(performance.getTotalAttempts() + 1);
        if (isCorrect) {
            performance.setCorrectCount(performance.getCorrectCount() + 1);
        } else {
            performance.setIncorrectCount(performance.getIncorrectCount() + 1);
        }

        BigDecimal accuracy = BigDecimal.valueOf(performance.getCorrectCount() * 100.0 / performance.getTotalAttempts())
                .setScale(2, RoundingMode.HALF_UP);
        performance.setAccuracy(accuracy);
        performance.setDemeritPoints(performance.getIncorrectCount() * 2);
        performance.setLastPracticedAt(OffsetDateTime.now());
        performance.setUpdatedAt(OffsetDateTime.now());

        performanceRepository.save(performance);

        // Update LearnerMastery incrementally
        LearnerMastery mastery = masteryRepository.findByLearnerLearnerId(session.getLearner().getLearnerId())
                .orElseGet(() -> LearnerMastery.builder()
                        .learner(session.getLearner())
                        .totalSessionsPlayed(0)
                        .totalCorrectAnswers(0)
                        .totalQuestionsAnswered(0)
                        .overallAccuracy(BigDecimal.ZERO)
                        .wordsMasteredCount(0)
                        .totalPoints(0)
                        .masteryLevel("LEARNING")
                        .createdAt(OffsetDateTime.now())
                        .build());

        mastery.setTotalQuestionsAnswered(mastery.getTotalQuestionsAnswered() + 1);
        if (isCorrect) {
            mastery.setTotalCorrectAnswers(mastery.getTotalCorrectAnswers() + 1);
            mastery.setTotalPoints(mastery.getTotalPoints() + pointsEarned);
        }

        BigDecimal overallAccuracy = BigDecimal.valueOf(mastery.getTotalCorrectAnswers() * 100.0 / mastery.getTotalQuestionsAnswered())
                .setScale(2, RoundingMode.HALF_UP);
        mastery.setOverallAccuracy(overallAccuracy);
        mastery.setMasteryLevel(calculateMasteryLevel(overallAccuracy));
        mastery.setUpdatedAt(OffsetDateTime.now());

        masteryRepository.save(mastery);

        return toResultResponse(result);
    }

    @Transactional
    public PracticeSessionResponse end(UUID sessionId) {
        PracticeSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new IllegalArgumentException("Session not found"));

        if (session.getCompletedAt() != null) {
            return toSessionResponse(session);
        }

        final Learner learner = session.getLearner();

        BigDecimal score = calculateScore(sessionId);
        session.setScore(score);
        session.setStarsEarned(calculateStars(score));
        session.setCompletedAt(OffsetDateTime.now());
        session.setUpdatedAt(OffsetDateTime.now());
        session = sessionRepository.save(session);

        // Update LearnerMastery sessions played and mastered count
        LearnerMastery mastery = masteryRepository.findByLearnerLearnerId(learner.getLearnerId())
                .orElseGet(() -> LearnerMastery.builder()
                        .learner(learner)
                        .totalSessionsPlayed(0)
                        .totalCorrectAnswers(0)
                        .totalQuestionsAnswered(0)
                        .overallAccuracy(BigDecimal.ZERO)
                        .wordsMasteredCount(0)
                        .masteryLevel("LEARNING")
                        .createdAt(OffsetDateTime.now())
                        .build());

        mastery.setTotalSessionsPlayed(mastery.getTotalSessionsPlayed() + 1);

        // Recalculate mastered words (difficulty level MASTERED or accuracy >= 80%)
        List<WordPerformance> performances = performanceRepository.findByLearnerLearnerId(learner.getLearnerId());
        final int modNum = session.getModuleNumber() != null ? session.getModuleNumber() : 2;
        long masteredCount = performances.stream().filter(p -> {
            if (p.getWord() == null) {
                return false;
            }
            var dpOpt = difficultyProgressRepository.findByLearnerLearnerIdAndWordWordIdAndModuleNumber(learner.getLearnerId(), p.getWord().getWordId(), modNum);
            DifficultyLevel currentLevel = dpOpt.map(DifficultyProgress::getCurrentLevel).orElse(DifficultyLevel.LEARNING);
            return currentLevel == DifficultyLevel.MASTERED;
        }).count();

        mastery.setWordsMasteredCount((int) masteredCount);
        mastery.setMasteryLevel(calculateMasteryLevel(mastery.getOverallAccuracy()));
        mastery.setUpdatedAt(OffsetDateTime.now());
        masteryRepository.save(mastery);

        return toSessionResponse(session);
    }

    /**
     * Lesson accuracy score: correct / total for all SCORED activities in the session.
     * Confusable Distinction and Pronunciation Feedback are excluded from both numerator
     * and denominator per scoring plan §5.
     */
    @Transactional(readOnly = true)
    public BigDecimal calculateScore(UUID sessionId) {
        List<PracticeResult> results = resultRepository.findBySessionSessionId(sessionId);
        if (results.isEmpty()) {
            return BigDecimal.ZERO;
        }

        // Filter out excluded activity types
        List<PracticeResult> scoredResults = results.stream()
                .filter(r -> {
                    String t = r.getActivityType();
                    if (t == null) return true; // default include
                    String upper = t.toUpperCase();
                    return !upper.equals("CONFUSABLE_DISTINCTION") && !upper.equals("PRONUNCIATION_FEEDBACK");
                })
                .collect(java.util.stream.Collectors.toList());

        if (scoredResults.isEmpty()) return BigDecimal.ZERO;

        long totalCount = scoredResults.size();
        long correctCount = scoredResults.stream().filter(PracticeResult::getIsCorrect).count();

        return BigDecimal.valueOf(correctCount * 100.0 / totalCount).setScale(2, RoundingMode.HALF_UP);
    }

    private void syncWordPerformanceFromActivities(UUID learnerId) {
        if (reviewItemRepository == null) return;
        Learner learner = learnerRepository.findById(learnerId).orElse(null);
        if (learner == null) return;

        List<ReviewItem> reviewItems = reviewItemRepository.findAllByLearnerIdOrderByCreatedAtAsc(learnerId);
        if (reviewItems != null && !reviewItems.isEmpty()) {
            Map<UUID, List<ReviewItem>> wordGroup = reviewItems.stream()
                    .filter(ri -> ri.getWord() != null)
                    .collect(Collectors.groupingBy(ri -> ri.getWord().getWordId()));

            for (Map.Entry<UUID, List<ReviewItem>> entry : wordGroup.entrySet()) {
                UUID wordId = entry.getKey();
                List<ReviewItem> items = entry.getValue();
                VocabularyWord word = items.get(0).getWord();

                WordPerformance perf = performanceRepository.findByLearnerLearnerIdAndWordWordId(learnerId, wordId)
                        .orElseGet(() -> WordPerformance.builder()
                                .learner(learner)
                                .word(word)
                                .build());

                long correctCount = items.stream().filter(i -> Boolean.TRUE.equals(i.getIsCorrect())).count();
                long totalCount = items.size();

                if (perf.getCorrectCount() < (int) correctCount) {
                    int maxTotal = Math.max(perf.getTotalAttempts(), (int) totalCount);
                    int maxCorrect = Math.max(perf.getCorrectCount(), (int) correctCount);
                    perf.setTotalAttempts(maxTotal);
                    perf.setCorrectCount(maxCorrect);
                    perf.setIncorrectCount(Math.max(0, maxTotal - maxCorrect));
                    double wordAcc = (double) maxCorrect / maxTotal * 100.0;
                    perf.setAccuracy(BigDecimal.valueOf(wordAcc).setScale(2, RoundingMode.HALF_UP));
                    perf.setLastPracticedAt(OffsetDateTime.now());
                    performanceRepository.save(perf);
                }
            }
        }
    }

    @Transactional
    public void updateMastery(UUID learnerId) {
        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner not found"));

        syncWordPerformanceFromActivities(learnerId);

        List<WordPerformance> performances = performanceRepository.findByLearnerLearnerId(learnerId);
        int totalQuestions = performances.stream().mapToInt(WordPerformance::getTotalAttempts).sum();
        int totalCorrect = performances.stream().mapToInt(WordPerformance::getCorrectCount).sum();

        BigDecimal overallAccuracy = totalQuestions > 0
                ? BigDecimal.valueOf(totalCorrect * 100.0 / totalQuestions).setScale(2, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        long masteredCount = performances.stream().filter(p -> {
            if (p.getWord() == null) {
                return p.getAccuracy() != null && p.getAccuracy().compareTo(BigDecimal.valueOf(80.0)) >= 0;
            }
            int modNum = 2; // Default for non-session context
            var dpOpt = difficultyProgressRepository.findByLearnerLearnerIdAndWordWordIdAndModuleNumber(learnerId, p.getWord().getWordId(), modNum);
            DifficultyLevel currentLevel = dpOpt.map(DifficultyProgress::getCurrentLevel).orElse(DifficultyLevel.LEARNING);
            return currentLevel == DifficultyLevel.MASTERED;
        }).count();

        List<PracticeSession> sessions = sessionRepository.findByLearnerLearnerId(learnerId);
        long completedSessions = sessions.stream().filter(s -> s.getCompletedAt() != null).count();

        LearnerMastery mastery = masteryRepository.findByLearnerLearnerId(learnerId)
                .orElseGet(() -> LearnerMastery.builder()
                        .learner(learner)
                        .build());

        mastery.setTotalQuestionsAnswered(totalQuestions);
        mastery.setTotalCorrectAnswers(totalCorrect);
        mastery.setOverallAccuracy(overallAccuracy);
        mastery.setWordsMasteredCount((int) masteredCount);
        mastery.setTotalSessionsPlayed((int) completedSessions);
        mastery.setMasteryLevel(calculateMasteryLevel(overallAccuracy));
        mastery.setUpdatedAt(OffsetDateTime.now());

        masteryRepository.save(mastery);
    }

    @Transactional
    public LearnerProgressResponse getProgress(UUID learnerId) {
        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner not found"));

        syncWordPerformanceFromActivities(learnerId);

        LearnerMastery mastery = masteryRepository.findByLearnerLearnerId(learnerId)
                .orElseGet(() -> LearnerMastery.builder()
                        .learner(learner)
                        .totalSessionsPlayed(0)
                        .totalCorrectAnswers(0)
                        .totalQuestionsAnswered(0)
                        .overallAccuracy(BigDecimal.ZERO)
                        .wordsMasteredCount(0)
                        .totalPoints(0)
                        .masteryLevel("LEARNING")
                        .build());

        // Dynamically compute overallAccuracy and wordsMasteredCount from word_performance and difficulty_progress at read-time
        List<WordPerformance> performances = performanceRepository.findByLearnerLearnerId(learnerId);
        int totalQuestions = performances.stream().mapToInt(WordPerformance::getTotalAttempts).sum();
        int totalCorrect = performances.stream().mapToInt(WordPerformance::getCorrectCount).sum();

        BigDecimal overallAccuracy = totalQuestions > 0
                ? BigDecimal.valueOf(totalCorrect * 100.0 / totalQuestions).setScale(2, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        long masteredCount = difficultyProgressRepository.countTotalMasteredWordsByLearner(learnerId);

        mastery.setTotalQuestionsAnswered(totalQuestions);
        mastery.setTotalCorrectAnswers(totalCorrect);
        mastery.setOverallAccuracy(overallAccuracy);
        mastery.setWordsMasteredCount((int) masteredCount);
        mastery.setMasteryLevel(calculateMasteryLevel(overallAccuracy));
        masteryRepository.save(mastery);

        return toProgressResponse(mastery);
    }

    /**
     * Non-overlapping star bands per scoring plan §6:
     *   90%+    → 3 ★ Gold
     *   80–89%  → 2 ★ Silver
     *   70–79%  → 1 ★ Bronze
     *   < 70%   → 0 ★
     */
    public static int calculateStars(BigDecimal accuracy) {
        if (accuracy == null) return 0;
        double val = accuracy.doubleValue();
        if (val >= 90.0) return 3;
        if (val >= 80.0) return 2;
        if (val >= 70.0) return 1;
        return 0;
    }

    public static String calculateMasteryLevel(BigDecimal accuracy) {
        if (accuracy == null) return "LEARNING";
        double val = accuracy.doubleValue();
        if (val >= 90.0) return "MASTERED";
        if (val >= 80.0) return "PROFICIENT";
        if (val >= 70.0) return "FAMILIAR";
        return "LEARNING";
    }

    private PracticeSessionResponse toSessionResponse(PracticeSession session) {
        return PracticeSessionResponse.builder()
                .sessionId(session.getSessionId())
                .learnerId(session.getLearner().getLearnerId())
                .lessonId(session.getLesson().getLessonId())
                .moduleNumber(session.getModuleNumber())
                .score(session.getScore())
                .starsEarned(session.getStarsEarned())
                .completedAt(session.getCompletedAt())
                .createdAt(session.getCreatedAt())
                .build();
    }

    private PracticeResultResponse toResultResponse(PracticeResult result) {
        return PracticeResultResponse.builder()
                .resultId(result.getResultId())
                .sessionId(result.getSession().getSessionId())
                .wordId(result.getWord().getWordId())
                .isCorrect(result.getIsCorrect())
                .attemptNumber(result.getAttemptNumber())
                .activityType(result.getActivityType())
                .points(result.getPoints())
                .recordedAt(result.getRecordedAt())
                .build();
    }

    @Transactional(readOnly = true)
    public List<LearnerLessonProgressResponse> getLessonProgress(UUID learnerId) {
        List<Lesson> lessons = lessonRepository.findAll();
        List<SessionSummary> summaries = summaryRepository.findByLearnerLearnerId(learnerId);
        List<LearnerLessonStatus> lessonStatuses = lessonStatusRepository.findByLearnerLearnerId(learnerId);
        List<LessonModuleScore> moduleScores = lessonModuleScoreRepository.findByLearnerLearnerId(learnerId);

        Map<UUID, SessionSummary> latestSummaryMap = new HashMap<>();
        for (SessionSummary summary : summaries) {
            UUID lessonId = summary.getLesson().getLessonId();
            SessionSummary existing = latestSummaryMap.get(lessonId);
            if (existing == null || (summary.getCompletedAt() != null && (existing.getCompletedAt() == null || summary.getCompletedAt().isAfter(existing.getCompletedAt())))) {
                latestSummaryMap.put(lessonId, summary);
            }
        }

        Map<UUID, LearnerLessonStatus> statusMap = lessonStatuses.stream()
                .collect(Collectors.toMap(s -> s.getLesson().getLessonId(), s -> s, (s1, s2) -> s1));

        Map<UUID, List<LessonModuleScore>> moduleScoreMap = moduleScores.stream()
                .collect(Collectors.groupingBy(m -> m.getLesson().getLessonId()));

        List<LearnerLessonProgressResponse> list = new ArrayList<>();
        for (Lesson lesson : lessons) {
            SessionSummary summary = latestSummaryMap.get(lesson.getLessonId());
            LearnerLessonStatus lls = statusMap.get(lesson.getLessonId());
            List<LessonModuleScore> lmsList = moduleScoreMap.getOrDefault(lesson.getLessonId(), Collections.emptyList());

            List<VocabularyWord> lessonWords = wordRepository.findByLessonLessonIdOrderByWordOrderAsc(lesson.getLessonId());
            int totalLessonAttempts = 0;
            int totalLessonCorrect = 0;
            for (VocabularyWord lw : lessonWords) {
                WordPerformance wp = performanceRepository.findByLearnerLearnerIdAndWordWordId(learnerId, lw.getWordId()).orElse(null);
                if (wp != null && wp.getTotalAttempts() > 0) {
                    totalLessonAttempts += wp.getTotalAttempts();
                    totalLessonCorrect += wp.getCorrectCount();
                }
            }

            BigDecimal accuracy = null;
            if (totalLessonAttempts > 0) {
                accuracy = BigDecimal.valueOf(totalLessonCorrect * 100.0 / totalLessonAttempts).setScale(2, RoundingMode.HALF_UP);
            } else if (lls != null && lls.getMasteryScore() != null) {
                accuracy = lls.getMasteryScore();
            } else if (summary != null && summary.getAccuracyRate() != null) {
                accuracy = summary.getAccuracyRate();
            }

            if (accuracy == null) {
                if (!lmsList.isEmpty()) {
                    double avg = lmsList.stream()
                            .filter(m -> m.getScore() != null)
                            .mapToDouble(m -> m.getScore().doubleValue())
                            .average()
                            .orElse(0.0);
                    if (avg > 0.0) {
                        accuracy = BigDecimal.valueOf(avg).setScale(2, RoundingMode.HALF_UP);
                    }
                }
            }
            if (accuracy == null) {
                accuracy = BigDecimal.ZERO;
            }

            int stars = calculateStars(accuracy);
            int totalAttempts = summary != null ? summary.getTotalAttempts() : (lls != null && lls.getAttempts() != null ? lls.getAttempts() : totalLessonAttempts);
            OffsetDateTime completedAt = summary != null ? summary.getCompletedAt() : (lls != null ? lls.getUpdatedAt() : null);
            
            long masteredInLesson = difficultyProgressRepository.countMasteredWordsByLearnerAndLesson(learnerId, lesson.getLessonId());
            boolean hasCompletedMod3 = lmsList.stream()
                    .anyMatch(m -> m.getModuleNumber() != null && m.getModuleNumber() == 3 && m.getTotalCount() != null && m.getTotalCount() > 0);

            boolean isCompleted = (lls != null && lls.getStatus() == LessonStatus.COMPLETED) ||
                    (summary != null && summary.getCompletedAt() != null) ||
                    (hasCompletedMod3 && (
                        (lesson.getTotalWordCount() != null && lesson.getTotalWordCount() > 0 && masteredInLesson >= lesson.getTotalWordCount()) ||
                        (accuracy.compareTo(BigDecimal.valueOf(70.0)) >= 0 && totalLessonAttempts > 0)
                    ));

            String status = isCompleted ? "COMPLETED" : (lls != null && lls.getStatus() != null ? lls.getStatus().name() : "UNLOCKED");

            list.add(LearnerLessonProgressResponse.builder()
                    .lessonId(lesson.getLessonId())
                    .lessonTitle(lesson.getLessonTitle())
                    .categoryId(lesson.getCategory().getCategoryId())
                    .categoryName(lesson.getCategory().getCategoryName())
                    .accuracyRate(accuracy)
                    .starsEarned(stars)
                    .totalAttempts(totalAttempts)
                    .completedAt(completedAt)
                    .status(status)
                    .build());
        }

        list.sort(Comparator.comparing(LearnerLessonProgressResponse::getLessonTitle));
        return list;
    }

    @Transactional(readOnly = true)
    public List<LearnerCategoryProgressResponse> getCategoryProgress(UUID learnerId) {
        List<VocabularyCategory> categories = categoryRepository.findAll();
        List<LearnerLessonProgressResponse> lessonProgress = getLessonProgress(learnerId);

        Map<UUID, List<LearnerLessonProgressResponse>> lessonsByCategory = lessonProgress.stream()
                .collect(Collectors.groupingBy(LearnerLessonProgressResponse::getCategoryId));

        List<LearnerCategoryProgressResponse> list = new ArrayList<>();
        for (VocabularyCategory category : categories) {
            List<LearnerLessonProgressResponse> cLessons = lessonsByCategory.getOrDefault(category.getCategoryId(), Collections.emptyList());
            int total = cLessons.size();
            int completed = (int) cLessons.stream().filter(l -> "COMPLETED".equals(l.getStatus())).count();

            double avgAcc = cLessons.stream()
                    .mapToDouble(l -> l.getAccuracyRate() != null ? l.getAccuracyRate().doubleValue() : 0.0)
                    .average()
                    .orElse(0.0);

            list.add(LearnerCategoryProgressResponse.builder()
                    .categoryId(category.getCategoryId())
                    .categoryName(category.getCategoryName())
                    .totalLessons(total)
                    .completedLessons(completed)
                    .categoryAccuracy(BigDecimal.valueOf(avgAcc).setScale(2, RoundingMode.HALF_UP))
                    .build());
        }

        list.sort(Comparator.comparing(LearnerCategoryProgressResponse::getCategoryName));
        return list;
    }

    @Transactional(readOnly = true)
    public List<RecentWordProgressResponse> getRecentWords(UUID learnerId, int limit) {
        Pageable pageable = PageRequest.of(0, limit);
        List<WordPerformance> performances = performanceRepository.findByLearnerLearnerIdOrderByLastPracticedAtDesc(learnerId, pageable);

        List<RecentWordProgressResponse> list = new ArrayList<>();
        for (WordPerformance wp : performances) {
            int modNum = 2; // Default for learner word stats
            Optional<DifficultyProgress> dpOpt = difficultyProgressRepository.findByLearnerLearnerIdAndWordWordIdAndModuleNumber(learnerId, wp.getWord().getWordId(), modNum);
            DifficultyLevel currentLevel = dpOpt.map(DifficultyProgress::getCurrentLevel)
                    .orElse(DifficultyLevel.LEARNING);
            String level = dpOpt.isPresent() ? dpOpt.get().getCurrentLevel().name() : calculateMasteryLevel(wp.getAccuracy());

            list.add(RecentWordProgressResponse.builder()
                    .wordId(wp.getWord().getWordId())
                    .englishWord(wp.getWord().getEnglishWord())
                    .cebuanoMeaning(wp.getWord().getCebuanoMeaning())
                    .accuracy(wp.getAccuracy())
                    .currentLevel(level)
                    .partOfSpeech(wp.getWord().getPartOfSpeech())
                    .lastPracticedAt(wp.getLastPracticedAt())
                    .build());
        }
        return list;
    }

    private LearnerProgressResponse toProgressResponse(LearnerMastery mastery) {
        int pointsThisWeek = pointTransactionRepository.sumPointsByLearnerAndDateAfter(
                mastery.getLearner().getLearnerId(),
                OffsetDateTime.now().minusDays(7)
        );

        String masteryLevel = mastery.getMasteryLevel() != null
                ? mastery.getMasteryLevel()
                : calculateMasteryLevel(mastery.getOverallAccuracy());

        return LearnerProgressResponse.builder()
                .learnerId(mastery.getLearner().getLearnerId())
                .totalSessionsPlayed(mastery.getTotalSessionsPlayed())
                .totalCorrectAnswers(mastery.getTotalCorrectAnswers())
                .totalQuestionsAnswered(mastery.getTotalQuestionsAnswered())
                .overallAccuracy(mastery.getOverallAccuracy())
                .wordsMasteredCount(mastery.getWordsMasteredCount())
                .totalPoints(mastery.getTotalPoints())
                .pointsThisWeek(pointsThisWeek)
                .masteryLevel(masteryLevel)
                .build();
    }
}
