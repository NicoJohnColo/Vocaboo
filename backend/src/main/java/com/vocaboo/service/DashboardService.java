package com.vocaboo.service;

import com.vocaboo.dto.response.DashboardResponse;
import com.vocaboo.dto.response.DashboardStatsResponse;
import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.math.BigDecimal;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DashboardService {

    private final LearnerLessonStatusRepository lessonStatusRepository;
    private final LessonRepository lessonRepository;
    private final PronunciationAttemptRepository pronunciationAttemptRepository;
    private final SandboxSessionRepository sandboxSessionRepository;
    private final SandboxWordRepository sandboxWordRepository;
    private final LearnerRepository learnerRepository;
    private final AdminRepository adminRepository;
    private final ReviewSessionRepository reviewSessionRepository;
    private final CumulativeReviewSessionRepository cumulativeReviewSessionRepository;
    private final LessonModuleScoreRepository lessonModuleScoreRepository;
    private final DifficultyProgressRepository difficultyProgressRepository;
    private final VocabularyWordRepository wordRepository;
    private final WordPerformanceRepository performanceRepository;

    public DashboardResponse getDashboardData(UUID learnerId) {
        // ── Core lesson stats ──────────────────────────────────────────────────
        List<Lesson> allLessons = lessonRepository.findAll();
        List<LearnerLessonStatus> statuses = lessonStatusRepository.findByLearnerLearnerId(learnerId);
        List<LessonModuleScore> moduleScores = lessonModuleScoreRepository.findByLearnerLearnerId(learnerId);

        Map<UUID, LearnerLessonStatus> statusMap = statuses.stream()
                .collect(Collectors.toMap(s -> s.getLesson().getLessonId(), s -> s, (s1, s2) -> s1));

        Map<UUID, List<LessonModuleScore>> moduleScoreMap = moduleScores.stream()
                .collect(Collectors.groupingBy(m -> m.getLesson().getLessonId()));

        int completedCount = 0;
        double scoreSum = 0.0;
        int scoredLessonCount = 0;
        Map<UUID, Double> computedLessonScores = new HashMap<>();

        for (Lesson lesson : allLessons) {
            LearnerLessonStatus s = statusMap.get(lesson.getLessonId());
            long masteredInLesson = difficultyProgressRepository.countMasteredWordsByLearnerAndLesson(learnerId, lesson.getLessonId());

            List<VocabularyWord> lessonWords = wordRepository.findByLessonLessonIdOrderByWordOrderAsc(lesson.getLessonId());
            int totalLessonAttempts = 0;
            int totalLessonCorrect = 0;
            double wordAccSum = 0.0;
            int wordsWithAcc = 0;
            for (VocabularyWord lw : lessonWords) {
                WordPerformance wp = performanceRepository.findByLearnerLearnerIdAndWordWordId(learnerId, lw.getWordId()).orElse(null);
                if (wp != null && wp.getTotalAttempts() > 0) {
                    totalLessonAttempts += wp.getTotalAttempts();
                    totalLessonCorrect += wp.getCorrectCount();
                    if (wp.getAccuracy() != null) {
                        wordAccSum += wp.getAccuracy().doubleValue();
                        wordsWithAcc++;
                    }
                }
            }

            BigDecimal score = null;
            if (wordsWithAcc > 0) {
                double wholeLessonAvg = wordAccSum / wordsWithAcc;
                score = BigDecimal.valueOf(wholeLessonAvg).setScale(2, java.math.RoundingMode.HALF_UP);
            } else if (s != null && s.getMasteryScore() != null) {
                score = s.getMasteryScore();
            } else if (wordsWithAcc > 0) {
                score = BigDecimal.valueOf(wordAccSum / wordsWithAcc).setScale(2, java.math.RoundingMode.HALF_UP);
            } else if (totalLessonAttempts > 0) {
                score = BigDecimal.valueOf(totalLessonCorrect * 100.0 / totalLessonAttempts).setScale(2, java.math.RoundingMode.HALF_UP);
            } else {
                List<LessonModuleScore> lmsList = moduleScoreMap.getOrDefault(lesson.getLessonId(), List.of());
                if (!lmsList.isEmpty()) {
                    Optional<LessonModuleScore> mod4Opt = lmsList.stream()
                            .filter(m -> m.getModuleNumber() != null && m.getModuleNumber() == 4 && m.getScore() != null)
                            .findFirst();
                    if (mod4Opt.isPresent()) {
                        score = mod4Opt.get().getScore();
                    } else {
                        double avg = lmsList.stream()
                                .filter(m -> m.getTotalCount() != null && m.getTotalCount() > 0 && m.getScore() != null)
                                .mapToDouble(m -> m.getScore().doubleValue())
                                .average()
                                .orElse(0.0);
                        if (avg > 0.0) {
                            score = BigDecimal.valueOf(avg).setScale(2, java.math.RoundingMode.HALF_UP);
                        }
                    }
                }
            }

            List<LessonModuleScore> lmsListForMod3 = moduleScoreMap.getOrDefault(lesson.getLessonId(), List.of());
            boolean hasCompletedMod3 = lmsListForMod3.stream()
                    .anyMatch(m -> m.getModuleNumber() != null && m.getModuleNumber() == 3 && m.getTotalCount() != null && m.getTotalCount() > 0);

            boolean isCompleted = (s != null && s.getStatus() == LessonStatus.COMPLETED) ||
                    (hasCompletedMod3 && (
                        (lesson.getTotalWordCount() != null && lesson.getTotalWordCount() > 0 && masteredInLesson >= lesson.getTotalWordCount()) ||
                        (score != null && score.compareTo(BigDecimal.valueOf(70.0)) >= 0 && totalLessonAttempts > 0)
                    ));

            if (isCompleted) {
                completedCount++;
            }

            if (score != null && score.compareTo(BigDecimal.ZERO) > 0) {
                scoreSum += score.doubleValue();
                scoredLessonCount++;
                computedLessonScores.put(lesson.getLessonId(), score.doubleValue());
            }
        }

        long totalLessons = allLessons.size();
        List<WordPerformance> allPerformances = performanceRepository.findByLearnerLearnerId(learnerId);
        int totalLifetimeQuestions = allPerformances.stream().mapToInt(WordPerformance::getTotalAttempts).sum();
        int totalLifetimeCorrect = allPerformances.stream().mapToInt(WordPerformance::getCorrectCount).sum();
        double averageScore = totalLifetimeQuestions > 0
                ? (totalLifetimeCorrect * 100.0 / totalLifetimeQuestions)
                : (scoredLessonCount > 0 ? (scoreSum / scoredLessonCount) : 0.0);

        // ── Pronunciation stats ────────────────────────────────────────────────
        int totalPronunciations = (int) pronunciationAttemptRepository.countByLearnerLearnerId(learnerId);
        int correctPronunciations = (int) pronunciationAttemptRepository.countByLearnerLearnerIdAndIsCorrect(learnerId, true);

        // ── Cumulative review stats & history ──────────────────────────────────
        List<CumulativeReviewSession> cumulativeSessions = cumulativeReviewSessionRepository.findByLearnerLearnerIdOrderByStartTimeDesc(learnerId);
        long cumulativeCompletedCount = cumulativeSessions.stream().filter(s -> "COMPLETED".equals(s.getSessionStatus())).count();

        String bestBadge = null;
        if (cumulativeSessions.stream().anyMatch(s -> "GOLD".equals(s.getBadgeAwarded()))) {
            bestBadge = "GOLD";
        } else if (cumulativeSessions.stream().anyMatch(s -> "SILVER".equals(s.getBadgeAwarded()))) {
            bestBadge = "SILVER";
        } else if (cumulativeSessions.stream().anyMatch(s -> "BRONZE".equals(s.getBadgeAwarded()))) {
            bestBadge = "BRONZE";
        }

        List<DashboardResponse.CumulativeSessionDetails> cumulativeHistory = cumulativeSessions.stream()
                .map(s -> DashboardResponse.CumulativeSessionDetails.builder()
                        .sessionId(s.getId())
                        .lessonPairId(s.getLessonPairId())
                        .sessionStatus(s.getSessionStatus())
                        .accuracyPercent(s.getAccuracyPercent() != null ? s.getAccuracyPercent().doubleValue() : null)
                        .badgeAwarded(s.getBadgeAwarded())
                        .pointsEarned(s.getPointsEarned())
                        .pointsBreakdown(s.getPointsBreakdown())
                        .startTime(s.getStartTime())
                        .endTime(s.getEndTime())
                        .build())
                .collect(Collectors.toList());

        // ── Sandbox history ────────────────────────────────────────────────────
        List<SandboxSession> sandboxSessions = sandboxSessionRepository.findByLearnerLearnerIdOrderByCreatedAtDesc(learnerId);
        List<DashboardResponse.SandboxSessionDetails> sandboxHistory = new ArrayList<>();

        for (SandboxSession session : sandboxSessions) {
            List<SandboxWord> words = sandboxWordRepository.findBySessionSessionIdOrderByWordOrderAsc(session.getSessionId());
            List<String> englishWords = words.stream()
                    .map(SandboxWord::getEnglishWord)
                    .collect(Collectors.toList());

            sandboxHistory.add(DashboardResponse.SandboxSessionDetails.builder()
                    .sessionId(session.getSessionId())
                    .topic(session.getTopic())
                    .customWord(session.getCustomWord())
                    .masteryScore(session.getMasteryScore())
                    .completedAt(session.getCompletedAt())
                    .words(englishWords)
                    .build());
        }

        // ── Category breakdowns ────────────────────────────────────────────────
        List<DashboardResponse.CategoryBreakdown> categoryBreakdowns =
                buildCategoryBreakdowns(learnerId, allLessons, computedLessonScores, cumulativeSessions);

        return DashboardResponse.builder()
                .completedLessons((int) completedCount)
                .totalLessons((int) totalLessons)
                .averageMasteryScore(averageScore)
                .totalPronunciationAttempts(totalPronunciations)
                .correctPronunciationAttempts(correctPronunciations)
                .sandboxHistory(sandboxHistory)
                .cumulativeReviewsCompleted((int) cumulativeCompletedCount)
                .bestCumulativeBadge(bestBadge)
                .cumulativeReviewHistory(cumulativeHistory)
                .categoryBreakdowns(categoryBreakdowns)
                .build();
    }

    /**
     * Builds a breakdown per category from the learner's completed cumulative
     * review sessions.
     *
     * For each unique lessonPairId that has at least one COMPLETED session:
     *  - Splits the lessonPairId on "_" to find the covered lesson UUIDs.
     *  - Looks up each lesson's Module 2 + 3 accuracy from lesson_module_scores.
     *  - Picks the latest COMPLETED cumulative session's accuracyPercent as the
     *    independent cumulative score (shown separately on the card).
     *  - Computes overallAccuracy = (avg lesson accuracy * 0.60) + (cumulativeAccuracy * 0.40).
     *    Same 60/40 weighting used by the Mastery Result Screen.
     */
    private List<DashboardResponse.CategoryBreakdown> buildCategoryBreakdowns(
            UUID learnerId,
            List<Lesson> allLessons,
            Map<UUID, Double> computedLessonScores,
            List<CumulativeReviewSession> cumulativeSessions) {

        // Index lessons by id for fast lookup
        Map<UUID, Lesson> lessonById = allLessons.stream()
                .collect(Collectors.toMap(Lesson::getLessonId, l -> l, (a, b) -> a));

        // Keep only COMPLETED cumulative sessions, ordered newest-first (already ordered)
        List<CumulativeReviewSession> completedSessions = cumulativeSessions.stream()
                .filter(s -> "COMPLETED".equals(s.getSessionStatus()))
                .collect(Collectors.toList());

        if (completedSessions.isEmpty()) {
            return List.of();
        }

        // Group by lessonPairId, pick the latest (first after desc ordering)
        Map<String, CumulativeReviewSession> latestByPair = new LinkedHashMap<>();
        for (CumulativeReviewSession session : completedSessions) {
            latestByPair.putIfAbsent(session.getLessonPairId(), session);
        }

        List<DashboardResponse.CategoryBreakdown> result = new ArrayList<>();

        for (Map.Entry<String, CumulativeReviewSession> entry : latestByPair.entrySet()) {
            String lessonPairId = entry.getKey();
            CumulativeReviewSession latestSession = entry.getValue();

            // Split the lessonPairId to get individual lesson UUID strings
            String[] lessonIdParts = lessonPairId.split("_");

            // Collect lessons in order
            List<DashboardResponse.LessonScoreDetail> lessonDetails = new ArrayList<>();
            String categoryId = null;
            String categoryName = "Lessons";
            // Separate list just for lesson accuracies (for the 60% side of the formula)
            List<Double> lessonAccuracyValues = new ArrayList<>();

            // Sort lesson parts by lesson order for consistent display
            List<Lesson> coveredLessons = new ArrayList<>();
            for (String idStr : lessonIdParts) {
                try {
                    UUID lessonUuid = UUID.fromString(idStr.trim());
                    Lesson l = lessonById.get(lessonUuid);
                    if (l != null) coveredLessons.add(l);
                } catch (IllegalArgumentException ignored) {
                    // Skip malformed UUIDs
                }
            }
            coveredLessons.sort(Comparator.comparingInt(l -> l.getLessonOrder() != null ? l.getLessonOrder() : 0));

            for (Lesson lesson : coveredLessons) {
                // Category from first resolved lesson
                if (categoryId == null && lesson.getCategory() != null) {
                    categoryId = lesson.getCategory().getCategoryId().toString();
                    categoryName = lesson.getCategory().getCategoryName() != null
                            ? lesson.getCategory().getCategoryName() : "Lessons";
                }

                // Overall accuracy for this lesson
                Double lessonAcc = computedLessonScores.get(lesson.getLessonId());

                if (lessonAcc != null) {
                    lessonAccuracyValues.add(lessonAcc);
                }

                lessonDetails.add(DashboardResponse.LessonScoreDetail.builder()
                        .lessonId(lesson.getLessonId().toString())
                        .lessonTitle(lesson.getLessonTitle() != null ? lesson.getLessonTitle() : "Lesson")
                        .lessonOrder(lesson.getLessonOrder() != null ? lesson.getLessonOrder() : 0)
                        .lessonAccuracy(lessonAcc)
                        .build());
            }

            // Independent cumulative accuracy (shown as its own row on the dashboard)
            Double cumulativeAccuracy = latestSession.getAccuracyPercent() != null
                    ? latestSession.getAccuracyPercent().doubleValue() : null;

            // Overall = (avg lesson accuracy * 0.60) + (cumulative accuracy * 0.40)
            // Mirrors the same 60/40 weighting used on the Mastery Result Screen.
            // Only computed when both sides are available.
            Double overallAccuracy = null;
            if (!lessonAccuracyValues.isEmpty() && cumulativeAccuracy != null) {
                double lessonAvg = lessonAccuracyValues.stream().mapToDouble(d -> d).average().orElse(0.0);
                overallAccuracy = (lessonAvg * 0.60) + (cumulativeAccuracy * 0.40);
            } else if (!lessonAccuracyValues.isEmpty()) {
                // Cumulative not yet done — show lesson avg only
                overallAccuracy = lessonAccuracyValues.stream().mapToDouble(d -> d).average().orElse(0.0);
            } else if (cumulativeAccuracy != null) {
                // No lesson scores yet — show cumulative only
                overallAccuracy = cumulativeAccuracy;
            }

            // Best badge across ALL completed sessions for this pair
            String pairBestBadge = null;
            List<CumulativeReviewSession> allForPair = completedSessions.stream()
                    .filter(s -> lessonPairId.equals(s.getLessonPairId()))
                    .collect(Collectors.toList());
            if (allForPair.stream().anyMatch(s -> "GOLD".equals(s.getBadgeAwarded()))) {
                pairBestBadge = "GOLD";
            } else if (allForPair.stream().anyMatch(s -> "SILVER".equals(s.getBadgeAwarded()))) {
                pairBestBadge = "SILVER";
            } else if (allForPair.stream().anyMatch(s -> "BRONZE".equals(s.getBadgeAwarded()))) {
                pairBestBadge = "BRONZE";
            }

            result.add(DashboardResponse.CategoryBreakdown.builder()
                    .categoryId(categoryId != null ? categoryId : lessonPairId)
                    .categoryName(categoryName)
                    .lessons(lessonDetails)
                    .cumulativeAccuracy(cumulativeAccuracy)
                    .overallAccuracy(overallAccuracy != null
                            ? Math.round(overallAccuracy * 100.0) / 100.0 : null)
                    .bestCumulativeBadge(pairBestBadge)
                    .build());
        }

        return result;
    }

    public DashboardStatsResponse getDashboardStats() {
        long totalLearners = learnerRepository.count();
        long totalLessons = lessonRepository.count();
        long activeSessions = reviewSessionRepository.countByCompletedAtIsNull();
        long totalAdmins = adminRepository.count();

        return DashboardStatsResponse.builder()
                .totalLearners(totalLearners)
                .totalLessons(totalLessons)
                .activeSessions(activeSessions)
                .totalAdmins(totalAdmins)
                .build();
    }
}
