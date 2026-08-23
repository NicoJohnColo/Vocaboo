package com.vocaboo.service;

import com.vocaboo.dto.response.AdminAnalyticsDashboardResponse;
import com.vocaboo.dto.response.AdminAnalyticsDashboardResponse.*;
import com.vocaboo.dto.response.AdminDemographicsResponse;
import com.vocaboo.dto.response.AdminGamificationStatsResponse;
import com.vocaboo.dto.response.AdminLeaderboardEntryResponse;
import com.vocaboo.dto.response.AdminLeaderboardStatsResponse;
import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class AdminAnalyticsService {

    private final LearnerRepository learnerRepository;
    private final SectionRepository sectionRepository;
    private final LearnerMasteryRepository masteryRepository;
    private final LearnerLessonStatusRepository lessonStatusRepository;
    private final LessonRepository lessonRepository;
    private final WordPerformanceRepository wordPerformanceRepository;
    private final VocabularyWordRepository vocabularyWordRepository;
    private final PracticeSessionRepository practiceSessionRepository;
    private final SessionSummaryRepository sessionSummaryRepository;
    private final PointTransactionRepository pointTransactionRepository;
    private final RewardDataRepository rewardDataRepository;
    private final CumulativeReviewSessionRepository cumulativeReviewSessionRepository;

    public AdminAnalyticsService(
            LearnerRepository learnerRepository,
            SectionRepository sectionRepository,
            LearnerMasteryRepository masteryRepository,
            LearnerLessonStatusRepository lessonStatusRepository,
            LessonRepository lessonRepository,
            WordPerformanceRepository wordPerformanceRepository,
            VocabularyWordRepository vocabularyWordRepository,
            PracticeSessionRepository practiceSessionRepository,
            SessionSummaryRepository sessionSummaryRepository,
            PointTransactionRepository pointTransactionRepository,
            RewardDataRepository rewardDataRepository,
            CumulativeReviewSessionRepository cumulativeReviewSessionRepository) {
        this.learnerRepository = learnerRepository;
        this.sectionRepository = sectionRepository;
        this.masteryRepository = masteryRepository;
        this.lessonStatusRepository = lessonStatusRepository;
        this.lessonRepository = lessonRepository;
        this.wordPerformanceRepository = wordPerformanceRepository;
        this.vocabularyWordRepository = vocabularyWordRepository;
        this.practiceSessionRepository = practiceSessionRepository;
        this.sessionSummaryRepository = sessionSummaryRepository;
        this.pointTransactionRepository = pointTransactionRepository;
        this.rewardDataRepository = rewardDataRepository;
        this.cumulativeReviewSessionRepository = cumulativeReviewSessionRepository;
    }

    public AdminAnalyticsDashboardResponse getDashboardAnalytics(UUID sectionId, GradeLevel gradeLevel, String timeRange) {
        return getDashboardAnalytics(sectionId, gradeLevel, timeRange, null);
    }

    public AdminAnalyticsDashboardResponse getDashboardAnalytics(UUID sectionId, GradeLevel gradeLevel, String timeRange, String cohortType) {
        // 1. Get filtered active learners
        List<Learner> learners;
        if (sectionId != null) {
            learners = learnerRepository.findBySectionSectionIdAndIsActiveTrue(sectionId);
        } else if ("INDEPENDENT".equalsIgnoreCase(cohortType)) {
            learners = learnerRepository.findBySectionIsNullAndIsActiveTrue();
        } else if ("ENROLLED".equalsIgnoreCase(cohortType)) {
            learners = learnerRepository.findBySectionIsNotNullAndIsActiveTrue();
        } else if (gradeLevel != null) {
            learners = learnerRepository.findByGradeLevelAndIsActiveTrue(gradeLevel);
        } else {
            learners = learnerRepository.findByIsActiveTrue();
        }

        // 2. Fetch masteries and lesson statuses for these learners
        List<LearnerMastery> masteries = learners.stream()
                .map(l -> masteryRepository.findByLearnerLearnerId(l.getLearnerId()).orElse(null))
                .filter(Objects::nonNull)
                .collect(Collectors.toList());

        List<LearnerLessonStatus> allStatuses = learners.stream()
                .flatMap(l -> lessonStatusRepository.findByLearnerLearnerId(l.getLearnerId()).stream())
                .collect(Collectors.toList());

        List<WordPerformance> allWordPerformances = learners.stream()
                .flatMap(l -> wordPerformanceRepository.findByLearnerLearnerId(l.getLearnerId()).stream())
                .collect(Collectors.toList());

        // 3. Compute KPIs
        OffsetDateTime sevenDaysAgo = OffsetDateTime.now().minusDays(7);

        // Map latest activity for each learner
        Map<UUID, OffsetDateTime> learnerLastActive = new HashMap<>();
        for (Learner l : learners) {
            learnerLastActive.put(l.getLearnerId(), l.getUpdatedAt());
        }
        for (WordPerformance wp : allWordPerformances) {
            UUID lid = wp.getLearner().getLearnerId();
            if (wp.getLastPracticedAt() != null) {
                OffsetDateTime prev = learnerLastActive.get(lid);
                if (prev == null || wp.getLastPracticedAt().isAfter(prev)) {
                    learnerLastActive.put(lid, wp.getLastPracticedAt());
                }
            }
        }
        for (LearnerLessonStatus st : allStatuses) {
            UUID lid = st.getLearner().getLearnerId();
            if (st.getUpdatedAt() != null) {
                OffsetDateTime prev = learnerLastActive.get(lid);
                if (prev == null || st.getUpdatedAt().isAfter(prev)) {
                    learnerLastActive.put(lid, st.getUpdatedAt());
                }
            }
        }

        long weeklyActiveCount = learnerLastActive.values().stream()
                .filter(dt -> dt != null && dt.isAfter(sevenDaysAgo))
                .count();

        long lessonsCompleted = allStatuses.stream()
                .filter(s -> s.getStatus() == LessonStatus.COMPLETED)
                .count();

        double avgAccDouble = masteries.stream()
                .map(LearnerMastery::getOverallAccuracy)
                .filter(Objects::nonNull)
                .mapToDouble(BigDecimal::doubleValue)
                .average()
                .orElse(0.0);
        BigDecimal avgAccuracy = BigDecimal.valueOf(avgAccDouble).setScale(2, RoundingMode.HALF_UP);

        long totalWordsMastered = masteries.stream()
                .mapToInt(m -> m.getWordsMasteredCount() != null ? m.getWordsMasteredCount() : 0)
                .sum();

        // Calculate average session length in seconds from completed PracticeSessions
        long avgSessionDurationSeconds = 180; // default benchmark 3 minutes if no sessions logged yet
        List<PracticeSession> pSessions = new ArrayList<>();
        for (Learner l : learners) {
            List<PracticeSession> pList = practiceSessionRepository.findByLearnerLearnerId(l.getLearnerId());
            if (pList != null) {
                for (PracticeSession ps : pList) {
                    if (ps.getCreatedAt() != null && ps.getCompletedAt() != null) {
                        pSessions.add(ps);
                    }
                }
            }
        }

        if (!pSessions.isEmpty()) {
            avgSessionDurationSeconds = (long) pSessions.stream()
                    .mapToLong(ps -> Math.max(10, java.time.Duration.between(ps.getCreatedAt(), ps.getCompletedAt()).getSeconds()))
                    .average()
                    .orElse(180.0);
        }

        DashboardKpis kpis = DashboardKpis.builder()
                .totalLearners(learners.size())
                .weeklyActiveLearners(weeklyActiveCount)
                .avgAccuracy(avgAccuracy)
                .lessonsCompleted(lessonsCompleted)
                .avgSessionLengthSeconds(avgSessionDurationSeconds)
                .totalWordsMastered(totalWordsMastered)
                .build();

        // 4. Compute Trends (Last 7 days)
        DashboardTrends trends = computeTrends(learners, allStatuses, allWordPerformances, 7);

        // 5. Struggling Learners (Multi-signal)
        List<StrugglingLearnerSummary> strugglingList = computeStrugglingLearners(learners, masteries, allWordPerformances);

        // 6. Top Performers (Top 10 by points/accuracy)
        List<TopPerformerSummary> topPerformers = computeTopPerformers(learners, masteries);

        // 7. Curriculum Analytics
        CurriculumAnalytics curriculum = computeCurriculumAnalytics(learners.size(), allWordPerformances, allStatuses);

        return AdminAnalyticsDashboardResponse.builder()
                .kpis(kpis)
                .trends(trends)
                .strugglingLearners(strugglingList)
                .topPerformers(topPerformers)
                .curriculumAnalytics(curriculum)
                .build();
    }

    public AdminDemographicsResponse getGlobalDemographics() {
        long total = learnerRepository.countByIsActiveTrue();
        long independent = learnerRepository.countBySectionIsNullAndIsActiveTrue();
        long enrolled = learnerRepository.countBySectionIsNotNullAndIsActiveTrue();

        double independentPct = total > 0 ? Math.round((independent * 100.0 / total) * 10.0) / 10.0 : 0.0;
        double enrolledPct = total > 0 ? Math.round((enrolled * 100.0 / total) * 10.0) / 10.0 : 0.0;

        List<Learner> allActive = learnerRepository.findByIsActiveTrue();
        Map<String, Long> langMap = allActive.stream()
                .collect(Collectors.groupingBy(
                        l -> l.getLanguagePreference() != null ? l.getLanguagePreference().name() : "CEBUANO",
                        Collectors.counting()
                ));

        Map<String, Long> gradeMap = allActive.stream()
                .collect(Collectors.groupingBy(
                        l -> l.getGradeLevel() != null ? l.getGradeLevel().name() : "UNASSIGNED",
                        Collectors.counting()
                ));

        List<LearnerMastery> masteries = masteryRepository.findAll();
        Map<String, Long> tierMap = masteries.stream()
                .collect(Collectors.groupingBy(
                        m -> m.getMasteryLevel() != null ? m.getMasteryLevel() : "LEARNING",
                        Collectors.counting()
                ));

        return AdminDemographicsResponse.builder()
                .totalLearners(total)
                .independentLearnersCount(independent)
                .enrolledLearnersCount(enrolled)
                .independentPercentage(independentPct)
                .enrolledPercentage(enrolledPct)
                .languagePreferenceDistribution(langMap)
                .gradeLevelDistribution(gradeMap)
                .masteryTierDistribution(tierMap)
                .build();
    }

    public AdminLeaderboardStatsResponse getLeaderboardStats(String range, String cohortType, UUID sectionId) {
        String effectiveRange = (range != null && "weekly".equalsIgnoreCase(range)) ? "weekly" : "all_time";

        // 1. Get filtered cohort of learners
        List<Learner> cohort;
        if (sectionId != null) {
            cohort = learnerRepository.findBySectionSectionIdAndIsActiveTrue(sectionId);
        } else if ("INDEPENDENT".equalsIgnoreCase(cohortType)) {
            cohort = learnerRepository.findBySectionIsNullAndIsActiveTrue();
        } else if ("ENROLLED".equalsIgnoreCase(cohortType)) {
            cohort = learnerRepository.findBySectionIsNotNullAndIsActiveTrue();
        } else {
            cohort = learnerRepository.findByIsActiveTrue();
        }

        Map<UUID, LearnerMastery> masteryMap = masteryRepository.findAll().stream()
                .filter(m -> m.getLearner() != null)
                .collect(Collectors.toMap(m -> m.getLearner().getLearnerId(), m -> m, (m1, m2) -> m1));

        Map<UUID, List<RewardData>> rewardMap = rewardDataRepository.findAll().stream()
                .filter(r -> r.getLearner() != null)
                .collect(Collectors.groupingBy(r -> r.getLearner().getLearnerId()));

        // 2. Compute Gamification KPIs (Platform-wide or Cohort)
        long totalPoints = masteryMap.values().stream()
                .mapToLong(m -> m.getTotalPoints() != null ? m.getTotalPoints() : 0)
                .sum();

        long totalSessions = masteryMap.values().stream()
                .mapToLong(m -> m.getTotalSessionsPlayed() != null ? m.getTotalSessionsPlayed() : 0)
                .sum();

        double avgPoints = cohort.isEmpty() ? 0.0 : (double) totalPoints / Math.max(1, cohort.size());

        List<RewardData> allRewards = rewardDataRepository.findAll();
        long totalBadges = allRewards.size();
        Map<String, Long> badgeTiers = allRewards.stream()
                .collect(Collectors.groupingBy(
                        r -> r.getBadgeType() != null ? r.getBadgeType() : "BRONZE",
                        Collectors.counting()
                ));

        AdminGamificationStatsResponse gamificationSummary = AdminGamificationStatsResponse.builder()
                .totalPointsAwarded(totalPoints)
                .averagePointsPerActiveLearner(Math.round(avgPoints * 10.0) / 10.0)
                .totalSessionsPlayed(totalSessions)
                .totalBadgesUnlocked(totalBadges)
                .badgeTierCounts(badgeTiers)
                .build();

        // 3. Build Leaderboard Entries
        List<AdminLeaderboardEntryResponse> entries = new ArrayList<>();
        OffsetDateTime oneWeekAgo = OffsetDateTime.now().minusDays(7);

        for (Learner learner : cohort) {
            LearnerMastery mastery = masteryMap.get(learner.getLearnerId());
            List<RewardData> rewards = rewardMap.getOrDefault(learner.getLearnerId(), List.of());

            int points;
            if ("weekly".equalsIgnoreCase(effectiveRange)) {
                points = pointTransactionRepository.sumPointsByLearnerAndDateAfter(learner.getLearnerId(), oneWeekAgo);
            } else {
                points = mastery != null && mastery.getTotalPoints() != null ? mastery.getTotalPoints() : 0;
            }

            double acc = mastery != null && mastery.getOverallAccuracy() != null
                    ? mastery.getOverallAccuracy().doubleValue()
                    : 0.0;

            String tier = mastery != null && mastery.getMasteryLevel() != null
                    ? mastery.getMasteryLevel()
                    : "LEARNING";

            entries.add(AdminLeaderboardEntryResponse.builder()
                    .learnerId(learner.getLearnerId())
                    .displayName(learner.getDisplayName())
                    .sectionName(learner.getSection() != null ? learner.getSection().getSectionName() : null)
                    .independent(learner.getSection() == null)
                    .gradeLevel(learner.getGradeLevel() != null ? learner.getGradeLevel().name() : "")
                    .tier(tier)
                    .points(points)
                    .badgesCount(rewards.size())
                    .overallAccuracy(Math.round(acc * 10.0) / 10.0)
                    .build());
        }

        // Sort descending by points, then accuracy
        entries.sort((a, b) -> {
            int cmp = Integer.compare(b.getPoints(), a.getPoints());
            if (cmp != 0) return cmp;
            return Double.compare(b.getOverallAccuracy(), a.getOverallAccuracy());
        });

        int rank = 1;
        for (AdminLeaderboardEntryResponse entry : entries) {
            entry.setRank(rank++);
        }

        if (entries.size() > 50) {
            entries = entries.subList(0, 50);
        }

        return AdminLeaderboardStatsResponse.builder()
                .range(effectiveRange)
                .cohortType(cohortType != null ? cohortType.toUpperCase() : "ALL")
                .gamificationSummary(gamificationSummary)
                .leaderboard(entries)
                .build();
    }

    private DashboardTrends computeTrends(
            List<Learner> learners,
            List<LearnerLessonStatus> statuses,
            List<WordPerformance> wordPerformances,
            int days) {

        DateTimeFormatter dtf = DateTimeFormatter.ofPattern("yyyy-MM-dd");
        LocalDate today = LocalDate.now();

        List<DateValuePoint> accuracyTrends = new ArrayList<>();
        List<DateValuePoint> completionTrends = new ArrayList<>();
        List<DateValuePoint> activityTrends = new ArrayList<>();

        for (int i = days - 1; i >= 0; i--) {
            LocalDate date = today.minusDays(i);
            String dateStr = date.format(dtf);

            // Completions on this date
            long completions = statuses.stream()
                    .filter(s -> s.getStatus() == LessonStatus.COMPLETED && s.getCompletedAt() != null)
                    .filter(s -> s.getCompletedAt().toLocalDate().equals(date))
                    .count();
            completionTrends.add(new DateValuePoint(dateStr, (double) completions));

            // Word practices on this date
            List<WordPerformance> dayPractices = wordPerformances.stream()
                    .filter(wp -> wp.getLastPracticedAt() != null && wp.getLastPracticedAt().toLocalDate().equals(date))
                    .collect(Collectors.toList());

            double dayAcc = dayPractices.stream()
                    .map(WordPerformance::getAccuracy)
                    .filter(Objects::nonNull)
                    .mapToDouble(BigDecimal::doubleValue)
                    .average()
                    .orElse(0.0);
            accuracyTrends.add(new DateValuePoint(dateStr, Math.round(dayAcc * 100.0) / 100.0));

            // Unique active learners on this date
            long activeOnDay = dayPractices.stream()
                    .map(wp -> wp.getLearner().getLearnerId())
                    .distinct()
                    .count();
            activityTrends.add(new DateValuePoint(dateStr, (double) activeOnDay));
        }

        return DashboardTrends.builder()
                .accuracyTrends(accuracyTrends)
                .completionTrends(completionTrends)
                .activityTrends(activityTrends)
                .build();
    }

    private List<StrugglingLearnerSummary> computeStrugglingLearners(
            List<Learner> learners,
            List<LearnerMastery> masteries,
            List<WordPerformance> wordPerformances) {

        Map<UUID, LearnerMastery> masteryMap = masteries.stream()
                .collect(Collectors.toMap(m -> m.getLearner().getLearnerId(), m -> m, (m1, m2) -> m1));

        Map<UUID, List<WordPerformance>> wpMap = wordPerformances.stream()
                .collect(Collectors.groupingBy(wp -> wp.getLearner().getLearnerId()));

        List<StrugglingLearnerSummary> result = new ArrayList<>();

        for (Learner learner : learners) {
            LearnerMastery mastery = masteryMap.get(learner.getLearnerId());
            List<WordPerformance> wps = wpMap.getOrDefault(learner.getLearnerId(), List.of());

            int totalDemerits = wps.stream().mapToInt(wp -> wp.getDemeritPoints() != null ? wp.getDemeritPoints() : 0).sum();
            int totalTierDrops = wps.stream().mapToInt(wp -> wp.getTierDropCount() != null ? wp.getTierDropCount() : 0).sum();
            BigDecimal accuracy = mastery != null && mastery.getOverallAccuracy() != null ? mastery.getOverallAccuracy() : BigDecimal.ZERO;
            int totalAttempts = mastery != null && mastery.getTotalQuestionsAnswered() != null ? mastery.getTotalQuestionsAnswered() : 0;

            List<String> reasons = new ArrayList<>();
            if (totalAttempts >= 10 && accuracy.compareTo(BigDecimal.valueOf(70.0)) < 0) {
                reasons.add("Low accuracy (" + accuracy.setScale(1, RoundingMode.HALF_UP) + "%)");
            }
            if (totalDemerits >= 5) {
                reasons.add("High errors (" + totalDemerits + " demerit points)");
            }
            if (totalTierDrops >= 3) {
                reasons.add("Tier regressions (" + totalTierDrops + " drops)");
            }

            if (!reasons.isEmpty()) {
                result.add(StrugglingLearnerSummary.builder()
                        .learnerId(learner.getLearnerId())
                        .displayName(learner.getDisplayName())
                        .gradeLevel(learner.getGradeLevel() != null ? learner.getGradeLevel().name() : null)
                        .sectionName(learner.getSection() != null ? learner.getSection().getSectionName() : "Unassigned")
                        .overallAccuracy(accuracy)
                        .demeritPoints(totalDemerits)
                        .tierDropCount(totalTierDrops)
                        .reasons(reasons)
                        .build());
            }
        }

        // Sort by demerits desc then accuracy asc
        result.sort(Comparator.comparing(StrugglingLearnerSummary::getDemeritPoints).reversed()
                .thenComparing(StrugglingLearnerSummary::getOverallAccuracy));

        return result.stream().limit(10).collect(Collectors.toList());
    }

    private List<TopPerformerSummary> computeTopPerformers(
            List<Learner> learners,
            List<LearnerMastery> masteries) {

        Map<UUID, LearnerMastery> masteryMap = masteries.stream()
                .collect(Collectors.toMap(m -> m.getLearner().getLearnerId(), m -> m, (m1, m2) -> m1));

        List<TopPerformerSummary> topList = new ArrayList<>();
        for (Learner l : learners) {
            LearnerMastery m = masteryMap.get(l.getLearnerId());
            topList.add(TopPerformerSummary.builder()
                    .learnerId(l.getLearnerId())
                    .displayName(l.getDisplayName())
                    .gradeLevel(l.getGradeLevel() != null ? l.getGradeLevel().name() : null)
                    .sectionName(l.getSection() != null ? l.getSection().getSectionName() : "Unassigned")
                    .totalPoints(m != null && m.getTotalPoints() != null ? m.getTotalPoints() : 0)
                    .overallAccuracy(m != null && m.getOverallAccuracy() != null ? m.getOverallAccuracy() : BigDecimal.ZERO)
                    .wordsMasteredCount(m != null && m.getWordsMasteredCount() != null ? m.getWordsMasteredCount() : 0)
                    .build());
        }

        topList.sort(Comparator.comparing(TopPerformerSummary::getTotalPoints).reversed()
                .thenComparing(TopPerformerSummary::getOverallAccuracy).reversed());

        return topList.stream().limit(10).collect(Collectors.toList());
    }

    private CurriculumAnalytics computeCurriculumAnalytics(
            int totalLearnersCount,
            List<WordPerformance> wordPerformances,
            List<LearnerLessonStatus> statuses) {

        // Group word performance by wordId
        Map<UUID, List<WordPerformance>> byWord = wordPerformances.stream()
                .collect(Collectors.groupingBy(wp -> wp.getWord().getWordId()));

        List<VocabularyWord> allWords = vocabularyWordRepository.findAll();

        // 1. Words Needing Curriculum Attention (Hardest Words & Class-Wide Difficulty)
        List<HardestWordSummary> hardest = new ArrayList<>();
        for (VocabularyWord word : allWords) {
            List<WordPerformance> list = byWord.getOrDefault(word.getWordId(), List.of());
            if (list.isEmpty()) continue;

            int totalAttempts = list.stream().mapToInt(wp -> wp.getTotalAttempts() != null ? wp.getTotalAttempts() : 0).sum();
            int incorrectCount = list.stream().mapToInt(wp -> wp.getIncorrectCount() != null ? wp.getIncorrectCount() : 0).sum();
            int totalDemerits = list.stream().mapToInt(wp -> wp.getDemeritPoints() != null ? wp.getDemeritPoints() : 0).sum();
            int totalFallback = list.stream().mapToInt(wp -> wp.getFallbackCount() != null ? wp.getFallbackCount() : 0).sum();
            double avgDemerits = list.isEmpty() ? 0.0 : (double) totalDemerits / list.size();

            // Distinct learners who have struggled on this word (incorrect > 0 or demerit > 0)
            int strugglingLearners = (int) list.stream()
                    .filter(wp -> (wp.getIncorrectCount() != null && wp.getIncorrectCount() > 0) || (wp.getDemeritPoints() != null && wp.getDemeritPoints() > 0))
                    .count();
            int totalPracticedLearners = list.size();
            double strugglePercentage = totalPracticedLearners > 0
                    ? Math.round((strugglingLearners * 100.0 / totalPracticedLearners) * 10.0) / 10.0
                    : 0.0;

            double avgAcc = totalAttempts > 0
                    ? ((totalAttempts - incorrectCount) * 100.0 / totalAttempts)
                    : 0.0;

            // Automated curriculum recommendation
            String recommendation;
            if (avgAcc >= 85.0 && totalDemerits < 15) {
                recommendation = "Content Verified (Normal)";
            } else if (avgAcc < 70.0 || totalDemerits >= 30) {
                recommendation = "Review Example Sentence & Context";
            } else if (totalFallback > 2) {
                recommendation = "Verify Image & Audio Assets";
            } else if (avgAcc < 80.0 && strugglePercentage >= 30.0) {
                recommendation = "Review Distractor Choices";
            } else {
                recommendation = "Content Verified (Normal)";
            }

            if (totalAttempts > 0) {
                hardest.add(HardestWordSummary.builder()
                        .wordId(word.getWordId())
                        .englishWord(word.getEnglishWord())
                        .cebuanoMeaning(word.getCebuanoMeaning())
                        .lessonTitle(word.getLesson() != null ? word.getLesson().getLessonTitle() : "")
                        .avgDemerits(Math.round(avgDemerits * 100.0) / 100.0)
                        .totalDemerits(totalDemerits)
                        .strugglingLearnerCount(strugglingLearners)
                        .strugglePercentage(strugglePercentage)
                        .curriculumRecommendation(recommendation)
                        .avgAccuracy(BigDecimal.valueOf(avgAcc).setScale(2, RoundingMode.HALF_UP))
                        .totalAttempts(totalAttempts)
                        .incorrectCount(incorrectCount)
                        .build());
            }
        }

        // Sort by widespread struggle rate (% of learners), then total demerits (severity)
        hardest.sort(Comparator.comparing(HardestWordSummary::getStrugglePercentage).reversed()
                .thenComparing(Comparator.comparing(HardestWordSummary::getTotalDemerits).reversed())
                .thenComparing(HardestWordSummary::getAvgAccuracy));

        List<HardestWordSummary> topHardest = hardest.stream().limit(10).collect(Collectors.toList());

        // 2. Fallback Words
        List<FallbackWordSummary> fallbacks = new ArrayList<>();
        for (VocabularyWord word : allWords) {
            List<WordPerformance> list = byWord.getOrDefault(word.getWordId(), List.of());
            int totalFallback = list.stream().mapToInt(wp -> wp.getFallbackCount() != null ? wp.getFallbackCount() : 0).sum();
            if (totalFallback > 0) {
                fallbacks.add(FallbackWordSummary.builder()
                        .wordId(word.getWordId())
                        .englishWord(word.getEnglishWord())
                        .cebuanoMeaning(word.getCebuanoMeaning())
                        .lessonTitle(word.getLesson() != null ? word.getLesson().getLessonTitle() : "")
                        .fallbackCount(totalFallback)
                        .build());
            }
        }
        fallbacks.sort(Comparator.comparing(FallbackWordSummary::getFallbackCount).reversed());
        List<FallbackWordSummary> topFallbacks = fallbacks.stream().limit(10).collect(Collectors.toList());

        // 3. Lesson Pass Rates
        List<Lesson> allLessons = lessonRepository.findAll();
        Map<UUID, List<LearnerLessonStatus>> byLesson = statuses.stream()
                .collect(Collectors.groupingBy(s -> s.getLesson().getLessonId()));

        List<LessonPassRateSummary> lessonPassRates = allLessons.stream().map(lesson -> {
            List<LearnerLessonStatus> list = byLesson.getOrDefault(lesson.getLessonId(), List.of());
            long completedCount = list.stream().filter(s -> s.getStatus() == LessonStatus.COMPLETED).count();

            BigDecimal completionRate = totalLearnersCount > 0
                    ? BigDecimal.valueOf(completedCount * 100.0 / totalLearnersCount).setScale(2, RoundingMode.HALF_UP)
                    : BigDecimal.ZERO;

            double avgScoreDouble = list.stream()
                    .map(LearnerLessonStatus::getMasteryScore)
                    .filter(Objects::nonNull)
                    .mapToDouble(BigDecimal::doubleValue)
                    .average()
                    .orElse(0.0);

            return LessonPassRateSummary.builder()
                    .lessonId(lesson.getLessonId())
                    .lessonTitle(lesson.getLessonTitle())
                    .gradeLevel(lesson.getGradeLevel() != null ? lesson.getGradeLevel().name() : "")
                    .completionRate(completionRate)
                    .avgScore(BigDecimal.valueOf(avgScoreDouble).setScale(2, RoundingMode.HALF_UP))
                    .totalCompletions(completedCount)
                    .build();
        }).sorted(Comparator.comparing(LessonPassRateSummary::getCompletionRate).reversed())
                .collect(Collectors.toList());

        // 4. Cumulative Review Summary
        List<CumulativeReviewSession> allCum = cumulativeReviewSessionRepository.findAll();
        Set<UUID> learnerIds = statuses.stream()
                .filter(s -> s.getLearner() != null)
                .map(s -> s.getLearner().getLearnerId())
                .collect(Collectors.toSet());

        List<CumulativeReviewSession> filteredCum = learnerIds.isEmpty() ? allCum : allCum.stream()
                .filter(cs -> cs.getLearner() != null && learnerIds.contains(cs.getLearner().getLearnerId()))
                .collect(Collectors.toList());

        List<CumulativeReviewSession> completedCum = new ArrayList<>(filteredCum.stream()
                .filter(cs -> "COMPLETED".equalsIgnoreCase(cs.getSessionStatus()))
                .collect(Collectors.toList()));

        // Fallback: If no explicit CumulativeReviewSession recorded yet, synthesize from completed lessons in statuses
        if (completedCum.isEmpty()) {
            Map<UUID, List<LearnerLessonStatus>> byLearner = statuses.stream()
                    .filter(st -> st.getLearner() != null && (st.getStatus() == LessonStatus.COMPLETED || st.getMasteryScore() != null))
                    .collect(Collectors.groupingBy(st -> st.getLearner().getLearnerId()));

            for (Map.Entry<UUID, List<LearnerLessonStatus>> entry : byLearner.entrySet()) {
                List<LearnerLessonStatus> learnerStatuses = entry.getValue();
                double avgScore = learnerStatuses.stream()
                        .filter(st -> st.getMasteryScore() != null)
                        .mapToDouble(st -> st.getMasteryScore().doubleValue())
                        .average()
                        .orElse(0.0);

                if (avgScore > 0) {
                    String badge = "BRONZE";
                    if (avgScore >= 100.0) badge = "PERFECT_GOLD";
                    else if (avgScore >= 90.0) badge = "GOLD";
                    else if (avgScore >= 80.0) badge = "SILVER";

                    CumulativeReviewSession synthetic = CumulativeReviewSession.builder()
                            .id(UUID.randomUUID())
                            .learner(learnerStatuses.get(0).getLearner())
                            .lessonPairId("Category Review")
                            .sessionStatus("COMPLETED")
                            .accuracyPercent(BigDecimal.valueOf(avgScore).setScale(2, RoundingMode.HALF_UP))
                            .badgeAwarded(badge)
                            .pointsEarned((int) Math.round(avgScore * 1.5))
                            .startTime(OffsetDateTime.now().minusMinutes(5))
                            .endTime(OffsetDateTime.now())
                            .build();
                    completedCum.add(synthetic);
                }
            }
        }

        double avgCumScore = completedCum.isEmpty() ? 0.0 :
                completedCum.stream()
                        .filter(cs -> cs.getAccuracyPercent() != null)
                        .mapToDouble(cs -> cs.getAccuracyPercent().doubleValue())
                        .average()
                        .orElse(0.0);

        long perfectGold = completedCum.stream().filter(cs -> "PERFECT_GOLD".equalsIgnoreCase(cs.getBadgeAwarded())).count();
        long gold = completedCum.stream().filter(cs -> "GOLD".equalsIgnoreCase(cs.getBadgeAwarded())).count();
        long silver = completedCum.stream().filter(cs -> "SILVER".equalsIgnoreCase(cs.getBadgeAwarded())).count();
        long bronze = completedCum.stream().filter(cs -> "BRONZE".equalsIgnoreCase(cs.getBadgeAwarded())).count();

        CumulativeAnalyticsSummary cumSummary = CumulativeAnalyticsSummary.builder()
                .totalSessionsCompleted((long) completedCum.size())
                .avgRetentionScore(BigDecimal.valueOf(avgCumScore).setScale(2, RoundingMode.HALF_UP))
                .perfectGoldCount(perfectGold)
                .goldCount(gold)
                .silverCount(silver)
                .bronzeCount(bronze)
                .build();

        return CurriculumAnalytics.builder()
                .hardestWords(topHardest)
                .fallbackFrequency(topFallbacks)
                .lessonPassRates(lessonPassRates)
                .cumulativeSummary(cumSummary)
                .build();
    }
}
