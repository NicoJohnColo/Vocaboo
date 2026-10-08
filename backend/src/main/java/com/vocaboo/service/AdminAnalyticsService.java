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
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

@Service
@Transactional(readOnly = true)
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
    private final com.vocaboo.repository.ClassEnrollmentRepository classEnrollmentRepository;
    private final com.vocaboo.repository.ClassPerformanceRepository classPerformanceRepository;
    private final com.vocaboo.repository.ClassroomRepository classroomRepository;

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
            CumulativeReviewSessionRepository cumulativeReviewSessionRepository,
            com.vocaboo.repository.ClassEnrollmentRepository classEnrollmentRepository,
            com.vocaboo.repository.ClassPerformanceRepository classPerformanceRepository,
            com.vocaboo.repository.ClassroomRepository classroomRepository) {
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
        this.classEnrollmentRepository = classEnrollmentRepository;
        this.classPerformanceRepository = classPerformanceRepository;
        this.classroomRepository = classroomRepository;
    }

    public AdminAnalyticsDashboardResponse getDashboardAnalytics(UUID sectionId, GradeLevel gradeLevel, String timeRange) {
        return getDashboardAnalytics(sectionId, gradeLevel, timeRange, null, null);
    }

    public AdminAnalyticsDashboardResponse getDashboardAnalytics(UUID sectionId, GradeLevel gradeLevel, String timeRange, String cohortType) {
        return getDashboardAnalytics(sectionId, gradeLevel, timeRange, cohortType, null);
    }

    public AdminAnalyticsDashboardResponse getDashboardAnalytics(UUID sectionId, GradeLevel gradeLevel, String timeRange, String cohortType, UUID teacherId) {
        // 1. Get filtered active learners
        List<Learner> learners;
        if (sectionId != null) {
            List<UUID> classEnrolledIds = classEnrollmentRepository.findEnrolledLearnerIdsByClassId(sectionId);
            if (!classEnrolledIds.isEmpty()) {
                learners = learnerRepository.findAllById(classEnrolledIds).stream()
                        .filter(Learner::getIsActive)
                        .collect(Collectors.toList());
            } else {
                learners = learnerRepository.findBySectionSectionIdAndIsActiveTrue(sectionId);
            }
        } else if ("INDEPENDENT".equalsIgnoreCase(cohortType) && teacherId == null) {
            learners = learnerRepository.findBySectionIsNullAndIsActiveTrue();
        } else if ("ENROLLED".equalsIgnoreCase(cohortType) && teacherId == null) {
            learners = learnerRepository.findBySectionIsNotNullAndIsActiveTrue();
        } else {
            learners = learnerRepository.findByIsActiveTrue();
        }

        if (teacherId != null) {
            List<UUID> teacherEnrolledIds = classEnrollmentRepository.findEnrolledLearnerIdsByTeacherId(teacherId);
            learners = learners.stream()
                    .filter(l -> teacherEnrolledIds.contains(l.getLearnerId()))
                    .collect(Collectors.toList());
        }

        if (gradeLevel != null) {
            learners = learners.stream()
                    .filter(l -> l.getGradeLevel() == gradeLevel)
                    .collect(Collectors.toList());
        }

        // 2. Resolve scoped classrooms and lessons
        Set<UUID> resolvedTeacherClassIds;
        if (teacherId != null) {
            List<Classroom> teacherClasses = classroomRepository.findByTeacherTeacherId(teacherId);
            Set<UUID> ownedClassIds = teacherClasses.stream().map(Classroom::getClassId).collect(Collectors.toSet());
            if (sectionId != null) {
                if (!ownedClassIds.contains(sectionId)) {
                    learners = Collections.emptyList();
                    resolvedTeacherClassIds = Collections.emptySet();
                } else {
                    resolvedTeacherClassIds = Set.of(sectionId);
                }
            } else {
                resolvedTeacherClassIds = ownedClassIds;
            }
        } else if (sectionId != null) {
            resolvedTeacherClassIds = Set.of(sectionId);
        } else {
            resolvedTeacherClassIds = Set.of();
        }
        final Set<UUID> teacherClassIds = resolvedTeacherClassIds;

        final boolean isScoped = (teacherId != null || sectionId != null);
        Set<UUID> scopedLessonIds = Set.of();
        if (isScoped) {
            scopedLessonIds = lessonRepository.findByIsDeletedFalseOrderByLessonOrderAsc().stream()
                    .filter(l -> l.getClassroom() != null && teacherClassIds.contains(l.getClassroom().getClassId()))
                    .map(Lesson::getLessonId)
                    .collect(Collectors.toSet());
        }
        final Set<UUID> finalScopedLessonIds = scopedLessonIds;

        // 3. Fetch masteries, statuses, and word performances (strictly filtered in teacher POV)
        List<LearnerMastery> masteries = learners.stream()
                .map(l -> masteryRepository.findByLearnerLearnerId(l.getLearnerId()).orElse(null))
                .filter(Objects::nonNull)
                .collect(Collectors.toList());

        List<LearnerLessonStatus> allStatuses = learners.stream()
                .flatMap(l -> lessonStatusRepository.findByLearnerLearnerId(l.getLearnerId()).stream())
                .filter(st -> {
                    if (isScoped) {
                        return st.getLesson() != null && finalScopedLessonIds.contains(st.getLesson().getLessonId());
                    }
                    return true;
                })
                .collect(Collectors.toList());

        List<WordPerformance> allWordPerformances = learners.stream()
                .flatMap(l -> wordPerformanceRepository.findByLearnerLearnerId(l.getLearnerId()).stream())
                .filter(wp -> {
                    if (isScoped) {
                        return wp.getWord() != null && wp.getWord().getLesson() != null
                                && finalScopedLessonIds.contains(wp.getWord().getLesson().getLessonId());
                    }
                    return true;
                })
                .collect(Collectors.toList());

        // Fetch class performance
        Map<UUID, com.vocaboo.entity.ClassPerformance> classPerfMap = new HashMap<>();
        if (sectionId != null) {
            List<com.vocaboo.entity.ClassPerformance> cpList = classPerformanceRepository.findByClassroomClassId(sectionId);
            for (com.vocaboo.entity.ClassPerformance cp : cpList) {
                if (cp.getLearner() != null) {
                    classPerfMap.put(cp.getLearner().getLearnerId(), cp);
                }
            }
        } else if (teacherId != null) {
            for (UUID cId : teacherClassIds) {
                List<com.vocaboo.entity.ClassPerformance> cpList = classPerformanceRepository.findByClassroomClassId(cId);
                for (com.vocaboo.entity.ClassPerformance cp : cpList) {
                    if (cp.getLearner() != null) {
                        classPerfMap.merge(cp.getLearner().getLearnerId(), cp, (existing, incoming) -> {
                            int pts = (existing.getClassPoints() != null ? existing.getClassPoints() : 0) + (incoming.getClassPoints() != null ? incoming.getClassPoints() : 0);
                            int q = (existing.getClassTotalQuestions() != null ? existing.getClassTotalQuestions() : 0) + (incoming.getClassTotalQuestions() != null ? incoming.getClassTotalQuestions() : 0);
                            int c = (existing.getClassCorrectAnswers() != null ? existing.getClassCorrectAnswers() : 0) + (incoming.getClassCorrectAnswers() != null ? incoming.getClassCorrectAnswers() : 0);
                            int s = (existing.getClassSessionsPlayed() != null ? existing.getClassSessionsPlayed() : 0) + (incoming.getClassSessionsPlayed() != null ? incoming.getClassSessionsPlayed() : 0);
                            BigDecimal acc = q > 0 ? BigDecimal.valueOf(c * 100.0 / q).setScale(2, RoundingMode.HALF_UP) : BigDecimal.ZERO;
                            com.vocaboo.entity.ClassPerformance merged = new com.vocaboo.entity.ClassPerformance();
                            merged.setLearner(existing.getLearner());
                            merged.setClassPoints(pts);
                            merged.setClassTotalQuestions(q);
                            merged.setClassCorrectAnswers(c);
                            merged.setClassSessionsPlayed(s);
                            merged.setClassAccuracy(acc);
                            return merged;
                        });
                    }
                }
            }
        }

        // 4. Resolve Time Window Cutoff
        int days;
        OffsetDateTime cutoffDate;
        if ("30d".equalsIgnoreCase(timeRange)) {
            days = 30;
            cutoffDate = OffsetDateTime.now().minusDays(30);
        } else if ("all".equalsIgnoreCase(timeRange) || "all_time".equalsIgnoreCase(timeRange)) {
            days = 90;
            cutoffDate = null;
        } else {
            days = 7;
            cutoffDate = OffsetDateTime.now().minusDays(7);
        }

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

        // 5. Compute class-context PracticeSessions & SessionSummaries (strictly scoped)
        List<PracticeSession> pSessions = new ArrayList<>();
        List<SessionSummary> allSummaries = new ArrayList<>();

        for (Learner l : learners) {
            List<PracticeSession> pList = practiceSessionRepository.findByLearnerLearnerId(l.getLearnerId());
            if (pList != null) {
                for (PracticeSession ps : pList) {
                    if (isScoped) {
                        if (ps.getClassroomContextId() == null || !teacherClassIds.contains(ps.getClassroomContextId())) {
                            continue;
                        }
                    }
                    if (ps.getCreatedAt() != null && ps.getCompletedAt() != null) {
                        if (cutoffDate == null || ps.getCreatedAt().isAfter(cutoffDate)) {
                            pSessions.add(ps);
                        }
                    }
                }
            }

            List<SessionSummary> sList = sessionSummaryRepository.findByLearnerLearnerId(l.getLearnerId());
            if (sList != null) {
                for (SessionSummary sm : sList) {
                    if (isScoped) {
                        if (sm.getClassroom() == null || !teacherClassIds.contains(sm.getClassroom().getClassId())) {
                            continue;
                        }
                    }
                    if (cutoffDate == null || (sm.getCompletedAt() != null && sm.getCompletedAt().isAfter(cutoffDate))) {
                        allSummaries.add(sm);
                    }
                }
            }
        }

        long activeLearnersCount = cutoffDate == null
                ? learners.size()
                : learnerLastActive.values().stream()
                        .filter(dt -> dt != null && dt.isAfter(cutoffDate))
                        .count();

        long lessonsCompleted;
        if (isScoped) {
            long summaryCompletions = allSummaries.size();
            long statusCompletions = allStatuses.stream()
                    .filter(s -> s.getStatus() == LessonStatus.COMPLETED)
                    .filter(s -> {
                        if (cutoffDate == null) return true;
                        OffsetDateTime dt = s.getCompletedAt() != null ? s.getCompletedAt() : s.getUpdatedAt();
                        return dt != null && dt.isAfter(cutoffDate);
                    })
                    .count();
            lessonsCompleted = Math.max(summaryCompletions, statusCompletions);
        } else {
            lessonsCompleted = allStatuses.stream()
                    .filter(s -> s.getStatus() == LessonStatus.COMPLETED)
                    .filter(s -> {
                        if (cutoffDate == null) return true;
                        OffsetDateTime dt = s.getCompletedAt() != null ? s.getCompletedAt() : s.getUpdatedAt();
                        return dt != null && dt.isAfter(cutoffDate);
                    })
                    .count();
        }

        // Calculate average session length in seconds from completed PracticeSessions within the time window
        long avgSessionDurationSeconds = 180;
        if (!pSessions.isEmpty()) {
            avgSessionDurationSeconds = (long) pSessions.stream()
                    .mapToLong(ps -> Math.max(10, java.time.Duration.between(ps.getCreatedAt(), ps.getCompletedAt()).getSeconds()))
                    .average()
                    .orElse(180.0);
        }

        // Period-filtered word performances and statuses for accuracy and curriculum analytics
        List<WordPerformance> periodWordPerformances = allWordPerformances.stream()
                .filter(wp -> {
                    if (cutoffDate == null) return true;
                    OffsetDateTime dt = wp.getLastPracticedAt() != null ? wp.getLastPracticedAt() : wp.getUpdatedAt();
                    return dt != null && dt.isAfter(cutoffDate);
                })
                .collect(Collectors.toList());

        List<LearnerLessonStatus> periodStatuses = allStatuses.stream()
                .filter(st -> {
                    if (cutoffDate == null) return true;
                    OffsetDateTime dt = st.getCompletedAt() != null ? st.getCompletedAt() : st.getUpdatedAt();
                    return dt != null && dt.isAfter(cutoffDate);
                })
                .collect(Collectors.toList());

        // Determine average accuracy in the selected period / class context
        double avgAccDouble;
        if (!classPerfMap.isEmpty()) {
            avgAccDouble = classPerfMap.values().stream()
                    .map(com.vocaboo.entity.ClassPerformance::getClassAccuracy)
                    .filter(Objects::nonNull)
                    .mapToDouble(BigDecimal::doubleValue)
                    .average()
                    .orElse(0.0);
        } else if (!allSummaries.isEmpty()) {
            avgAccDouble = allSummaries.stream()
                    .map(SessionSummary::getAccuracyRate)
                    .filter(Objects::nonNull)
                    .mapToDouble(BigDecimal::doubleValue)
                    .average()
                    .orElse(0.0);
        } else if (teacherId != null) {
            avgAccDouble = 0.0;
        } else {
            avgAccDouble = periodWordPerformances.stream()
                    .map(WordPerformance::getAccuracy)
                    .filter(Objects::nonNull)
                    .mapToDouble(BigDecimal::doubleValue)
                    .average()
                    .orElseGet(() -> masteries.stream()
                            .map(LearnerMastery::getOverallAccuracy)
                            .filter(Objects::nonNull)
                            .mapToDouble(BigDecimal::doubleValue)
                            .average()
                            .orElse(0.0));
        }
        BigDecimal avgAccuracy = BigDecimal.valueOf(avgAccDouble).setScale(2, RoundingMode.HALF_UP);

        long totalWordsMastered;
        if (!classPerfMap.isEmpty()) {
            totalWordsMastered = classPerfMap.values().stream()
                    .mapToInt(cp -> cp.getClassCorrectAnswers() != null ? cp.getClassCorrectAnswers() : 0)
                    .sum();
        } else if (teacherId != null) {
            totalWordsMastered = 0;
        } else {
            totalWordsMastered = masteries.stream()
                    .mapToInt(m -> m.getWordsMasteredCount() != null ? m.getWordsMasteredCount() : 0)
                    .sum();
        }

        DashboardKpis kpis = DashboardKpis.builder()
                .totalLearners(learners.size())
                .weeklyActiveLearners(activeLearnersCount)
                .avgAccuracy(avgAccuracy)
                .lessonsCompleted(lessonsCompleted)
                .avgSessionLengthSeconds(avgSessionDurationSeconds)
                .totalWordsMastered(totalWordsMastered)
                .build();

        // 6. Compute Trends
        DashboardTrends trends = computeTrends(learners, periodStatuses.isEmpty() ? allStatuses : periodStatuses,
                periodWordPerformances.isEmpty() ? allWordPerformances : periodWordPerformances,
                allSummaries, pSessions, days, avgAccDouble, isScoped);

        // 7. Struggling Learners (Multi-signal, factoring in class performance)
        List<StrugglingLearnerSummary> strugglingList = computeStrugglingLearners(learners, masteries, allWordPerformances, classPerfMap, sectionId, teacherId);

        // 8. Top Performers (Top 10 by class points or global points)
        List<TopPerformerSummary> topPerformers = computeTopPerformers(learners, masteries, classPerfMap, sectionId, teacherId);

        // 9. Curriculum Analytics (with per-POS breakdown)
        CurriculumAnalytics curriculum = computeCurriculumAnalytics(
                learners.size(),
                periodWordPerformances.isEmpty() ? allWordPerformances : periodWordPerformances,
                periodStatuses.isEmpty() ? allStatuses : periodStatuses,
                allSummaries,
                sectionId,
                teacherId,
                gradeLevel,
                cohortType,
                learners);

        return AdminAnalyticsDashboardResponse.builder()
                .kpis(kpis)
                .trends(trends)
                .strugglingLearners(strugglingList)
                .topPerformers(topPerformers)
                .curriculumAnalytics(curriculum)
                .build();
    }

    public AdminDemographicsResponse getGlobalDemographics() {
        return getGlobalDemographics(null);
    }

    public AdminDemographicsResponse getGlobalDemographics(UUID teacherId) {
        List<Learner> allActive = learnerRepository.findByIsActiveTrue();
        if (teacherId != null) {
            List<UUID> enrolledIds = classEnrollmentRepository.findEnrolledLearnerIdsByTeacherId(teacherId);
            allActive = allActive.stream()
                    .filter(l -> enrolledIds.contains(l.getLearnerId()))
                    .collect(Collectors.toList());
        }

        long total = allActive.size();
        long independent;
        long enrolled;
        double independentPct;
        double enrolledPct;

        if (teacherId != null) {
            // Teachers only manage enrolled classroom students
            independent = 0;
            enrolled = total;
            independentPct = 0.0;
            enrolledPct = total > 0 ? 100.0 : 0.0;
        } else {
            independent = allActive.stream().filter(l -> l.getSection() == null).count();
            enrolled = allActive.stream().filter(l -> l.getSection() != null).count();
            independentPct = total > 0 ? Math.round((independent * 100.0 / total) * 10.0) / 10.0 : 0.0;
            enrolledPct = total > 0 ? Math.round((enrolled * 100.0 / total) * 10.0) / 10.0 : 0.0;
        }

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

        Set<UUID> activeLearnerIds = allActive.stream().map(Learner::getLearnerId).collect(Collectors.toSet());
        List<LearnerMastery> masteries = masteryRepository.findAll().stream()
                .filter(m -> m.getLearner() != null && activeLearnerIds.contains(m.getLearner().getLearnerId()))
                .collect(Collectors.toList());

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
        return getLeaderboardStats(range, cohortType, sectionId, null);
    }

    public AdminLeaderboardStatsResponse getLeaderboardStats(String range, String cohortType, UUID sectionId, UUID teacherId) {
        String effectiveRange = (range != null && "weekly".equalsIgnoreCase(range)) ? "weekly" : "all_time";

        // 1. Get filtered cohort of learners
        List<Learner> cohort;
        if (sectionId != null) {
            List<UUID> classEnrolledIds = classEnrollmentRepository.findEnrolledLearnerIdsByClassId(sectionId);
            Set<UUID> allSectionLearnerIds = new HashSet<>(classEnrolledIds);
            learnerRepository.findBySectionSectionIdAndIsActiveTrue(sectionId)
                    .forEach(l -> allSectionLearnerIds.add(l.getLearnerId()));
            cohort = allSectionLearnerIds.isEmpty() ? List.of() : learnerRepository.findAllById(allSectionLearnerIds).stream()
                    .filter(Learner::getIsActive)
                    .collect(Collectors.toList());
        } else if ("INDEPENDENT".equalsIgnoreCase(cohortType) && teacherId == null) {
            List<UUID> activeEnrolledIds = classEnrollmentRepository.findAll().stream()
                    .filter(e -> "ACTIVE".equalsIgnoreCase(e.getStatus()) && e.getLearner() != null)
                    .map(e -> e.getLearner().getLearnerId())
                    .collect(Collectors.toList());
            cohort = learnerRepository.findByIsActiveTrue().stream()
                    .filter(l -> l.getSection() == null && !activeEnrolledIds.contains(l.getLearnerId()))
                    .collect(Collectors.toList());
        } else if ("ENROLLED".equalsIgnoreCase(cohortType) && teacherId == null) {
            List<UUID> activeEnrolledIds = classEnrollmentRepository.findAll().stream()
                    .filter(e -> "ACTIVE".equalsIgnoreCase(e.getStatus()) && e.getLearner() != null)
                    .map(e -> e.getLearner().getLearnerId())
                    .collect(Collectors.toList());
            cohort = learnerRepository.findByIsActiveTrue().stream()
                    .filter(l -> l.getSection() != null || activeEnrolledIds.contains(l.getLearnerId()))
                    .collect(Collectors.toList());
        } else {
            cohort = learnerRepository.findByIsActiveTrue();
        }

        if (teacherId != null && sectionId == null) {
            List<UUID> teacherEnrolledIds = classEnrollmentRepository.findEnrolledLearnerIdsByTeacherId(teacherId);
            cohort = cohort.stream()
                    .filter(l -> teacherEnrolledIds.contains(l.getLearnerId()))
                    .collect(Collectors.toList());
        }

        Set<UUID> cohortIds = cohort.stream().map(Learner::getLearnerId).collect(Collectors.toSet());

        Map<UUID, LearnerMastery> masteryMap = masteryRepository.findAll().stream()
                .filter(m -> m.getLearner() != null && cohortIds.contains(m.getLearner().getLearnerId()))
                .collect(Collectors.toMap(m -> m.getLearner().getLearnerId(), m -> m, (m1, m2) -> m1));

        Map<UUID, List<RewardData>> rewardMap = rewardDataRepository.findAll().stream()
                .filter(r -> r.getLearner() != null && cohortIds.contains(r.getLearner().getLearnerId()))
                .collect(Collectors.groupingBy(r -> r.getLearner().getLearnerId()));

        Map<UUID, com.vocaboo.entity.ClassPerformance> classPerfMap = new HashMap<>();
        if (sectionId != null) {
            List<com.vocaboo.entity.ClassPerformance> cpList = classPerformanceRepository.findByClassroomClassId(sectionId);
            for (com.vocaboo.entity.ClassPerformance cp : cpList) {
                if (cp.getLearner() != null) {
                    classPerfMap.put(cp.getLearner().getLearnerId(), cp);
                }
            }
        } else if (teacherId != null) {
            List<Classroom> tClasses = classroomRepository.findByTeacherTeacherId(teacherId);
            for (Classroom cls : tClasses) {
                List<com.vocaboo.entity.ClassPerformance> cpList = classPerformanceRepository.findByClassroomClassId(cls.getClassId());
                for (com.vocaboo.entity.ClassPerformance cp : cpList) {
                    if (cp.getLearner() != null) {
                        classPerfMap.merge(cp.getLearner().getLearnerId(), cp, (existing, incoming) -> {
                            int pts = (existing.getClassPoints() != null ? existing.getClassPoints() : 0) + (incoming.getClassPoints() != null ? incoming.getClassPoints() : 0);
                            int q = (existing.getClassTotalQuestions() != null ? existing.getClassTotalQuestions() : 0) + (incoming.getClassTotalQuestions() != null ? incoming.getClassTotalQuestions() : 0);
                            int c = (existing.getClassCorrectAnswers() != null ? existing.getClassCorrectAnswers() : 0) + (incoming.getClassCorrectAnswers() != null ? incoming.getClassCorrectAnswers() : 0);
                            int s = (existing.getClassSessionsPlayed() != null ? existing.getClassSessionsPlayed() : 0) + (incoming.getClassSessionsPlayed() != null ? incoming.getClassSessionsPlayed() : 0);
                            BigDecimal acc = q > 0 ? BigDecimal.valueOf(c * 100.0 / q).setScale(2, RoundingMode.HALF_UP) : BigDecimal.ZERO;
                            com.vocaboo.entity.ClassPerformance merged = new com.vocaboo.entity.ClassPerformance();
                            merged.setLearner(existing.getLearner());
                            merged.setClassPoints(pts);
                            merged.setClassTotalQuestions(q);
                            merged.setClassCorrectAnswers(c);
                            merged.setClassSessionsPlayed(s);
                            merged.setClassAccuracy(acc);
                            return merged;
                        });
                    }
                }
            }
        }

        final boolean isScoped = (sectionId != null || teacherId != null);

        // 2. Build Leaderboard Entries
        List<AdminLeaderboardEntryResponse> allEntries = new ArrayList<>();
        OffsetDateTime oneWeekAgo = OffsetDateTime.now().minusDays(7);

        for (Learner learner : cohort) {
            LearnerMastery mastery = masteryMap.get(learner.getLearnerId());
            com.vocaboo.entity.ClassPerformance cp = classPerfMap.get(learner.getLearnerId());
            List<RewardData> rewards = rewardMap.getOrDefault(learner.getLearnerId(), List.of());

            int points;
            double acc;
            String entrySecName;
            boolean isIndep;

            if (isScoped) {
                if ("weekly".equalsIgnoreCase(effectiveRange)) {
                    if (sectionId != null) {
                        points = pointTransactionRepository.sumClassPointsByLearnerAndClassAndDateAfter(learner.getLearnerId(), sectionId, oneWeekAgo);
                    } else if (teacherId != null) {
                        List<Classroom> tClasses = classroomRepository.findByTeacherTeacherId(teacherId);
                        int weeklyClassPts = 0;
                        for (Classroom c : tClasses) {
                            weeklyClassPts += pointTransactionRepository.sumClassPointsByLearnerAndClassAndDateAfter(learner.getLearnerId(), c.getClassId(), oneWeekAgo);
                        }
                        points = weeklyClassPts;
                    } else {
                        points = cp != null && cp.getClassPoints() != null ? cp.getClassPoints() : 0;
                    }
                } else {
                    points = cp != null && cp.getClassPoints() != null ? cp.getClassPoints() : 0;
                }
                acc = cp != null && cp.getClassAccuracy() != null ? cp.getClassAccuracy().doubleValue() : 0.0;
                entrySecName = sectionId != null ? resolveClassroomName(sectionId) : resolveLearnerFirstClassName(learner.getLearnerId());
                if (entrySecName == null) entrySecName = learner.getSection() != null ? learner.getSection().getSectionName() : "Classroom";
                isIndep = false;
            } else {
                if ("weekly".equalsIgnoreCase(effectiveRange)) {
                    points = pointTransactionRepository.sumPointsByLearnerAndDateAfter(learner.getLearnerId(), oneWeekAgo);
                } else {
                    points = mastery != null && mastery.getTotalPoints() != null ? mastery.getTotalPoints() : 0;
                }
                acc = mastery != null && mastery.getOverallAccuracy() != null
                        ? mastery.getOverallAccuracy().doubleValue()
                        : 0.0;
                entrySecName = learner.getSection() != null ? learner.getSection().getSectionName() : resolveLearnerFirstClassName(learner.getLearnerId());
                isIndep = (entrySecName == null || entrySecName.isBlank() || "Independent".equalsIgnoreCase(entrySecName));
            }

            String tier = resolveLeagueTier(points, (isScoped && cp != null && cp.getClassMasteryLevel() != null)
                    ? cp.getClassMasteryLevel()
                    : (mastery != null ? mastery.getMasteryLevel() : null));

            allEntries.add(AdminLeaderboardEntryResponse.builder()
                    .learnerId(learner.getLearnerId())
                    .displayName(learner.getDisplayName())
                    .avatar(learner.getAvatar())
                    .sectionName(entrySecName)
                    .independent(isIndep)
                    .gradeLevel(learner.getGradeLevel() != null ? learner.getGradeLevel().name() : "")
                    .tier(tier)
                    .points(points)
                    .badgesCount(rewards.size())
                    .overallAccuracy(Math.round(acc * 10.0) / 10.0)
                    .build());
        }

        // Sort descending by points, then accuracy
        allEntries.sort((a, b) -> {
            int cmp = Integer.compare(b.getPoints(), a.getPoints());
            if (cmp != 0) return cmp;
            return Double.compare(b.getOverallAccuracy(), a.getOverallAccuracy());
        });

        int rank = 1;
        for (AdminLeaderboardEntryResponse entry : allEntries) {
            entry.setRank(rank++);
        }

        // 3. Compute Gamification KPIs
        long totalPoints = allEntries.stream().mapToLong(AdminLeaderboardEntryResponse::getPoints).sum();
        long totalSessions;
        if (isScoped && !classPerfMap.isEmpty()) {
            totalSessions = classPerfMap.values().stream()
                    .mapToLong(cp -> cp.getClassSessionsPlayed() != null ? cp.getClassSessionsPlayed() : 0)
                    .sum();
        } else if (isScoped) {
            totalSessions = 0;
        } else {
            totalSessions = masteryMap.values().stream()
                    .mapToLong(m -> m.getTotalSessionsPlayed() != null ? m.getTotalSessionsPlayed() : 0)
                    .sum();
        }

        double avgPoints = cohort.isEmpty() ? 0.0 : (double) totalPoints / Math.max(1, cohort.size());

        List<RewardData> cohortRewards = rewardDataRepository.findAll().stream()
                .filter(r -> r.getLearner() != null && cohortIds.contains(r.getLearner().getLearnerId()))
                .collect(Collectors.toList());
        long totalBadges = cohortRewards.size();
        Map<String, Long> badgeTiers = cohortRewards.stream()
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

        List<AdminLeaderboardEntryResponse> displayedEntries = allEntries.size() > 50
                ? allEntries.subList(0, 50)
                : allEntries;

        return AdminLeaderboardStatsResponse.builder()
                .range(effectiveRange)
                .cohortType(cohortType != null ? cohortType.toUpperCase() : "ALL")
                .gamificationSummary(gamificationSummary)
                .leaderboard(displayedEntries)
                .build();
    }

    private DashboardTrends computeTrends(
            List<Learner> learners,
            List<LearnerLessonStatus> statuses,
            List<WordPerformance> wordPerformances,
            List<SessionSummary> summaries,
            List<PracticeSession> pSessions,
            int days,
            double baselineAccuracy,
            boolean isClassScoped) {

        DateTimeFormatter dtf = DateTimeFormatter.ofPattern("yyyy-MM-dd");
        LocalDate today = LocalDate.now();

        List<DateValuePoint> accuracyTrends = new ArrayList<>();
        List<DateValuePoint> completionTrends = new ArrayList<>();
        List<DateValuePoint> activityTrends = new ArrayList<>();

        double lastKnownAccuracy = baselineAccuracy;

        for (int i = days - 1; i >= 0; i--) {
            LocalDate date = today.minusDays(i);
            String dateStr = date.format(dtf);

            // Completions on this date
            long completions;
            if (isClassScoped) {
                long summaryCompletions = summaries.stream()
                        .filter(sm -> sm.getCompletedAt() != null && sm.getCompletedAt().toLocalDate().equals(date))
                        .count();
                long pSessionCompletions = pSessions != null
                        ? pSessions.stream().filter(ps -> ps.getCompletedAt() != null && ps.getCompletedAt().toLocalDate().equals(date)).count()
                        : 0;
                completions = Math.max(summaryCompletions, pSessionCompletions);
            } else {
                long statusCompletions = statuses.stream()
                        .filter(s -> (s.getStatus() == LessonStatus.COMPLETED || s.getMasteryScore() != null))
                        .filter(s -> {
                            OffsetDateTime dt = s.getCompletedAt() != null ? s.getCompletedAt() : s.getUpdatedAt();
                            return dt != null && dt.toLocalDate().equals(date);
                        })
                        .count();
                long summaryCompletions = summaries.stream()
                        .filter(sm -> sm.getCompletedAt() != null && sm.getCompletedAt().toLocalDate().equals(date))
                        .count();
                completions = Math.max(statusCompletions, summaryCompletions);
            }
            completionTrends.add(new DateValuePoint(dateStr, (double) completions));

            // Accuracy on this date from SessionSummaries and WordPerformances
            List<Double> dayAccuracies = new ArrayList<>();
            for (SessionSummary sm : summaries) {
                if (sm.getCompletedAt() != null && sm.getCompletedAt().toLocalDate().equals(date) && sm.getAccuracyRate() != null) {
                    dayAccuracies.add(sm.getAccuracyRate().doubleValue());
                }
            }
            if (!isClassScoped) {
                for (WordPerformance wp : wordPerformances) {
                    if (wp.getLastPracticedAt() != null && wp.getLastPracticedAt().toLocalDate().equals(date) && wp.getAccuracy() != null) {
                        dayAccuracies.add(wp.getAccuracy().doubleValue());
                    }
                }
            }

            double dayAcc;
            if (!dayAccuracies.isEmpty()) {
                dayAcc = dayAccuracies.stream().mapToDouble(Double::doubleValue).average().orElse(0.0);
                lastKnownAccuracy = dayAcc;
            } else {
                dayAcc = lastKnownAccuracy > 0 ? lastKnownAccuracy : baselineAccuracy;
            }
            accuracyTrends.add(new DateValuePoint(dateStr, Math.round(dayAcc * 100.0) / 100.0));

            // Unique active learners on this date
            Set<UUID> activeLearnerIds = new HashSet<>();
            for (SessionSummary sm : summaries) {
                if (sm.getCompletedAt() != null && sm.getCompletedAt().toLocalDate().equals(date) && sm.getLearner() != null) {
                    activeLearnerIds.add(sm.getLearner().getLearnerId());
                }
            }
            if (pSessions != null) {
                for (PracticeSession ps : pSessions) {
                    if (ps.getCreatedAt() != null && ps.getCreatedAt().toLocalDate().equals(date) && ps.getLearner() != null) {
                        activeLearnerIds.add(ps.getLearner().getLearnerId());
                    }
                }
            }
            if (!isClassScoped) {
                for (WordPerformance wp : wordPerformances) {
                    if (wp.getLastPracticedAt() != null && wp.getLastPracticedAt().toLocalDate().equals(date) && wp.getLearner() != null) {
                        activeLearnerIds.add(wp.getLearner().getLearnerId());
                    }
                }
            }
            activityTrends.add(new DateValuePoint(dateStr, (double) activeLearnerIds.size()));
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
            List<WordPerformance> wordPerformances,
            Map<UUID, com.vocaboo.entity.ClassPerformance> classPerfMap,
            UUID sectionId,
            UUID teacherId) {

        Map<UUID, LearnerMastery> masteryMap = masteries.stream()
                .collect(Collectors.toMap(m -> m.getLearner().getLearnerId(), m -> m, (m1, m2) -> m1));

        Map<UUID, List<WordPerformance>> wpMap = wordPerformances.stream()
                .collect(Collectors.groupingBy(wp -> wp.getLearner().getLearnerId()));

        List<StrugglingLearnerSummary> result = new ArrayList<>();
        final boolean isScoped = (sectionId != null || teacherId != null);

        for (Learner learner : learners) {
            LearnerMastery mastery = masteryMap.get(learner.getLearnerId());
            com.vocaboo.entity.ClassPerformance classPerf = classPerfMap != null ? classPerfMap.get(learner.getLearnerId()) : null;
            List<WordPerformance> wps = wpMap.getOrDefault(learner.getLearnerId(), List.of());

            int totalDemerits = wps.stream().mapToInt(wp -> wp.getDemeritPoints() != null ? wp.getDemeritPoints() : 0).sum();
            int totalTierDrops = wps.stream().mapToInt(wp -> wp.getTierDropCount() != null ? wp.getTierDropCount() : 0).sum();

            BigDecimal accuracy;
            int totalAttempts;
            if (isScoped) {
                accuracy = classPerf != null && classPerf.getClassAccuracy() != null ? classPerf.getClassAccuracy() : BigDecimal.ZERO;
                totalAttempts = classPerf != null && classPerf.getClassTotalQuestions() != null ? classPerf.getClassTotalQuestions() : 0;
            } else {
                accuracy = mastery != null && mastery.getOverallAccuracy() != null ? mastery.getOverallAccuracy() : BigDecimal.ZERO;
                totalAttempts = mastery != null && mastery.getTotalQuestionsAnswered() != null ? mastery.getTotalQuestionsAnswered() : 0;
            }

            List<String> reasons = new ArrayList<>();
            if (totalAttempts >= 5 && accuracy.compareTo(BigDecimal.valueOf(70.0)) < 0) {
                reasons.add("Low accuracy (" + accuracy.setScale(1, RoundingMode.HALF_UP) + "%)");
            }
            if (totalDemerits >= 50) {
                reasons.add("High errors (" + totalDemerits + " demerit points)");
            }
            if (totalTierDrops >= 3) {
                reasons.add("Tier regressions (" + totalTierDrops + " drops)");
            }

            String sName = sectionId != null ? resolveClassroomName(sectionId) : null;
            if (sName == null) sName = learner.getSection() != null ? learner.getSection().getSectionName() : resolveLearnerFirstClassName(learner.getLearnerId());
            if (sName == null) sName = "Self-Paced";

            if (!reasons.isEmpty()) {
                result.add(StrugglingLearnerSummary.builder()
                        .learnerId(learner.getLearnerId())
                        .displayName(learner.getDisplayName())
                        .gradeLevel(learner.getGradeLevel() != null ? learner.getGradeLevel().name() : null)
                        .sectionName(sName)
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
            List<LearnerMastery> masteries,
            Map<UUID, com.vocaboo.entity.ClassPerformance> classPerfMap,
            UUID sectionId,
            UUID teacherId) {

        Map<UUID, LearnerMastery> masteryMap = masteries.stream()
                .collect(Collectors.toMap(m -> m.getLearner().getLearnerId(), m -> m, (m1, m2) -> m1));

        List<TopPerformerSummary> topList = new ArrayList<>();
        final boolean isScoped = (sectionId != null || teacherId != null);

        for (Learner l : learners) {
            LearnerMastery m = masteryMap.get(l.getLearnerId());
            com.vocaboo.entity.ClassPerformance classPerf = classPerfMap != null ? classPerfMap.get(l.getLearnerId()) : null;

            int points;
            BigDecimal accuracy;
            int masteredCount;
            if (isScoped) {
                points = classPerf != null && classPerf.getClassPoints() != null ? classPerf.getClassPoints() : 0;
                accuracy = classPerf != null && classPerf.getClassAccuracy() != null ? classPerf.getClassAccuracy() : BigDecimal.ZERO;
                masteredCount = classPerf != null && classPerf.getClassCorrectAnswers() != null ? classPerf.getClassCorrectAnswers() : 0;
            } else {
                points = m != null && m.getTotalPoints() != null ? m.getTotalPoints() : 0;
                accuracy = m != null && m.getOverallAccuracy() != null ? m.getOverallAccuracy() : BigDecimal.ZERO;
                masteredCount = m != null && m.getWordsMasteredCount() != null ? m.getWordsMasteredCount() : 0;
            }

            String sName = sectionId != null ? resolveClassroomName(sectionId) : null;
            if (sName == null) sName = l.getSection() != null ? l.getSection().getSectionName() : resolveLearnerFirstClassName(l.getLearnerId());
            if (sName == null) sName = "Self-Paced";

            topList.add(TopPerformerSummary.builder()
                    .learnerId(l.getLearnerId())
                    .displayName(l.getDisplayName())
                    .gradeLevel(l.getGradeLevel() != null ? l.getGradeLevel().name() : null)
                    .sectionName(sName)
                    .totalPoints(points)
                    .overallAccuracy(accuracy)
                    .wordsMasteredCount(masteredCount)
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
        return computeCurriculumAnalytics(
                totalLearnersCount,
                wordPerformances,
                statuses,
                List.of(),
                null,
                null,
                null,
                null,
                List.of());
    }

    private CurriculumAnalytics computeCurriculumAnalytics(
            int totalLearnersCount,
            List<WordPerformance> wordPerformances,
            List<LearnerLessonStatus> statuses,
            List<SessionSummary> allSummaries,
            UUID sectionId,
            UUID teacherId,
            GradeLevel gradeLevel,
            String cohortType,
            List<Learner> learners) {

        // 1. Resolve visible lessons strictly scoped to this class / teacher / cohort
        List<Lesson> visibleLessons;
        if (sectionId != null) {
            List<Lesson> classLessons = lessonRepository.findByClassroomClassIdAndIsDeletedFalseOrderByLessonOrderAsc(sectionId);
            Set<UUID> practicedLessonIds = (allSummaries != null ? allSummaries : List.<SessionSummary>of()).stream()
                    .filter(s -> s.getLesson() != null)
                    .map(s -> s.getLesson().getLessonId())
                    .collect(Collectors.toSet());

            if (!classLessons.isEmpty()) {
                final List<Lesson> classLessonList = new ArrayList<>(classLessons);
                for (UUID plId : practicedLessonIds) {
                    if (classLessonList.stream().noneMatch(l -> l.getLessonId().equals(plId))) {
                        lessonRepository.findById(plId).ifPresent(l -> {
                            if (!l.getIsDeleted() && (l.getClassroom() != null && sectionId.equals(l.getClassroom().getClassId()))) {
                                classLessonList.add(l);
                            }
                        });
                    }
                }
                visibleLessons = classLessonList;
            } else if (teacherId != null) {
                // In teacher's POV, do not fallback to global lessons!
                visibleLessons = new ArrayList<>();
            } else {
                GradeLevel targetGrade = gradeLevel;
                if (targetGrade == null && learners != null && !learners.isEmpty()) {
                    targetGrade = learners.get(0).getGradeLevel();
                }
                if (targetGrade == null) {
                    Classroom cls = classroomRepository.findById(sectionId).orElse(null);
                    if (cls != null && cls.getName() != null) {
                        String n = cls.getName().toUpperCase();
                        if (n.contains("GRADE 4") || n.contains("GRADE4")) targetGrade = GradeLevel.GRADE_4;
                        else if (n.contains("GRADE 5") || n.contains("GRADE5")) targetGrade = GradeLevel.GRADE_5;
                        else if (n.contains("GRADE 6") || n.contains("GRADE6")) targetGrade = GradeLevel.GRADE_6;
                    }
                }

                final GradeLevel effectiveGrade = targetGrade;
                List<Lesson> allActive = lessonRepository.findByIsDeletedFalseOrderByLessonOrderAsc();
                visibleLessons = allActive.stream()
                        .filter(l -> {
                            if (l.getClassroom() != null && sectionId.equals(l.getClassroom().getClassId())) return true;
                            if (practicedLessonIds.contains(l.getLessonId())) return true;
                            if (l.getClassroom() == null && effectiveGrade != null && l.getGradeLevel() == effectiveGrade) return true;
                            return false;
                        })
                        .collect(Collectors.toList());
            }
        } else if (teacherId != null) {
            List<Classroom> tClasses = classroomRepository.findByTeacherTeacherId(teacherId);
            Set<UUID> tClassIds = tClasses.stream().map(Classroom::getClassId).collect(Collectors.toSet());
            List<Lesson> allActive = lessonRepository.findByIsDeletedFalseOrderByLessonOrderAsc();
            visibleLessons = allActive.stream()
                    .filter(l -> l.getClassroom() != null && tClassIds.contains(l.getClassroom().getClassId()))
                    .collect(Collectors.toList());
            // In teacher's POV, strictly only teacher's class lessons are visible. No global fallback!
        } else if ("GLOBAL".equalsIgnoreCase(cohortType) || "INDEPENDENT".equalsIgnoreCase(cohortType)) {
            visibleLessons = lessonRepository.findByIsDeletedFalseAndClassroomIsNullOrderByLessonOrderAsc().stream()
                    .filter(l -> gradeLevel == null || l.getGradeLevel() == gradeLevel)
                    .collect(Collectors.toList());
        } else {
            visibleLessons = lessonRepository.findByIsDeletedFalseOrderByLessonOrderAsc().stream()
                    .filter(l -> gradeLevel == null || l.getGradeLevel() == gradeLevel)
                    .collect(Collectors.toList());
        }

        // Fallback for tests or empty mock environments - only for global admin view
        if (visibleLessons.isEmpty() && teacherId == null && sectionId == null && !"GLOBAL".equalsIgnoreCase(cohortType) && !"INDEPENDENT".equalsIgnoreCase(cohortType)) {
            visibleLessons = lessonRepository.findAll();
        }

        // 2. Resolve target words strictly belonging to visible lessons
        Set<UUID> visibleLessonIds = visibleLessons.stream()
                .map(Lesson::getLessonId)
                .collect(Collectors.toSet());

        List<VocabularyWord> allWords = vocabularyWordRepository.findAllWithLesson();
        List<VocabularyWord> targetWords;
        if (!visibleLessonIds.isEmpty()) {
            targetWords = allWords.stream()
                    .filter(w -> w.getLesson() != null && visibleLessonIds.contains(w.getLesson().getLessonId()))
                    .collect(Collectors.toList());
        } else if (teacherId != null || sectionId != null || "GLOBAL".equalsIgnoreCase(cohortType) || "INDEPENDENT".equalsIgnoreCase(cohortType)) {
            targetWords = Collections.emptyList();
        } else {
            targetWords = allWords;
        }
        Set<UUID> targetWordIds = targetWords.stream().map(VocabularyWord::getWordId).collect(Collectors.toSet());

        // 3. Filter word performances to target words
        List<WordPerformance> targetWordPerformances = wordPerformances.stream()
                .filter(wp -> wp.getWord() != null && targetWordIds.contains(wp.getWord().getWordId()))
                .collect(Collectors.toList());
        Map<UUID, List<WordPerformance>> byWord = targetWordPerformances.stream()
                .collect(Collectors.groupingBy(wp -> wp.getWord().getWordId()));

        // Words Needing Curriculum Attention (Hardest Words)
        List<HardestWordSummary> hardest = new ArrayList<>();
        for (VocabularyWord word : targetWords) {
            List<WordPerformance> list = byWord.getOrDefault(word.getWordId(), List.of());
            if (list.isEmpty()) continue;

            int totalAttempts = list.stream().mapToInt(wp -> wp.getTotalAttempts() != null ? wp.getTotalAttempts() : 0).sum();
            int incorrectCount = list.stream().mapToInt(wp -> wp.getIncorrectCount() != null ? wp.getIncorrectCount() : 0).sum();
            int totalDemerits = list.stream().mapToInt(wp -> wp.getDemeritPoints() != null ? wp.getDemeritPoints() : 0).sum();
            int totalFallback = list.stream().mapToInt(wp -> wp.getFallbackCount() != null ? wp.getFallbackCount() : 0).sum();
            double avgDemerits = list.isEmpty() ? 0.0 : (double) totalDemerits / list.size();

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

            String recommendation;
            if (avgAcc >= 85.0) {
                recommendation = "Content Verified (Normal)";
            } else if (avgAcc < 70.0 || (avgAcc < 75.0 && totalDemerits >= 20)) {
                recommendation = "Review Example Sentence & Context";
            } else if (totalFallback > 2) {
                recommendation = "Verify Image & Audio Assets";
            } else if (avgAcc < 85.0 && strugglePercentage >= 30.0) {
                recommendation = "Review Distractor Choices";
            } else {
                recommendation = "Content Verified (Normal)";
            }

            if (totalAttempts > 0) {
                hardest.add(HardestWordSummary.builder()
                        .wordId(word.getWordId())
                        .englishWord(word.getEnglishWord())
                        .cebuanoMeaning(word.getCebuanoMeaning())
                        .partOfSpeech(word.getPartOfSpeech() != null ? word.getPartOfSpeech() : "NOUN")
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

        hardest.sort(Comparator.comparing(HardestWordSummary::getTotalDemerits).reversed()
                .thenComparing(HardestWordSummary::getStrugglingLearnerCount, Comparator.reverseOrder())
                .thenComparing(HardestWordSummary::getAvgAccuracy)
                .thenComparing(HardestWordSummary::getStrugglePercentage, Comparator.reverseOrder()));

        List<HardestWordSummary> topHardest = hardest.stream().limit(10).collect(Collectors.toList());

        // Fallback Words
        List<FallbackWordSummary> fallbacks = new ArrayList<>();
        for (VocabularyWord word : targetWords) {
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

        // 4. Lesson Pass Rates & Specific Lesson Average Accuracy
        Map<UUID, List<SessionSummary>> summariesByLesson = (allSummaries != null ? allSummaries : List.<SessionSummary>of()).stream()
                .filter(s -> s.getLesson() != null)
                .collect(Collectors.groupingBy(s -> s.getLesson().getLessonId()));

        Map<UUID, List<WordPerformance>> wordPerfsByLesson = targetWordPerformances.stream()
                .filter(wp -> wp.getWord() != null && wp.getWord().getLesson() != null)
                .collect(Collectors.groupingBy(wp -> wp.getWord().getLesson().getLessonId()));

        Map<UUID, List<LearnerLessonStatus>> statusesByLesson = statuses.stream()
                .filter(s -> s.getLesson() != null)
                .collect(Collectors.groupingBy(s -> s.getLesson().getLessonId()));

        List<LessonPassRateSummary> lessonPassRates = new ArrayList<>();
        for (Lesson lesson : visibleLessons) {
            UUID lid = lesson.getLessonId();
            List<SessionSummary> sList = summariesByLesson.getOrDefault(lid, List.of());
            List<WordPerformance> wpList = wordPerfsByLesson.getOrDefault(lid, List.of());
            List<LearnerLessonStatus> stList = statusesByLesson.getOrDefault(lid, List.of());

            Set<UUID> completedLearnerIds = new HashSet<>();
            for (LearnerLessonStatus st : stList) {
                if (st.getStatus() == LessonStatus.COMPLETED && st.getLearner() != null) {
                    completedLearnerIds.add(st.getLearner().getLearnerId());
                }
            }
            for (SessionSummary ss : sList) {
                if (ss.getLearner() != null) {
                    completedLearnerIds.add(ss.getLearner().getLearnerId());
                }
            }
            long completedCount = completedLearnerIds.size();
            BigDecimal completionRate = totalLearnersCount > 0
                    ? BigDecimal.valueOf(completedCount * 100.0 / totalLearnersCount).setScale(2, RoundingMode.HALF_UP)
                    : BigDecimal.ZERO;

            double lessonAvgAcc;
            int sessionAttempts = sList.stream().mapToInt(s -> s.getTotalAttempts() != null ? s.getTotalAttempts() : 0).sum();
            int sessionCorrect = sList.stream().mapToInt(s -> s.getCorrectPronunciations() != null ? s.getCorrectPronunciations() : 0).sum();

            if (sessionAttempts > 0) {
                lessonAvgAcc = (sessionCorrect * 100.0) / sessionAttempts;
            } else if (!sList.isEmpty()) {
                lessonAvgAcc = sList.stream()
                        .map(SessionSummary::getAccuracyRate)
                        .filter(Objects::nonNull)
                        .mapToDouble(BigDecimal::doubleValue)
                        .average()
                        .orElse(0.0);
            } else {
                int wpAttempts = wpList.stream().mapToInt(wp -> wp.getTotalAttempts() != null ? wp.getTotalAttempts() : 0).sum();
                int wpCorrect = wpList.stream().mapToInt(wp -> wp.getCorrectCount() != null ? wp.getCorrectCount() : 0).sum();
                if (wpAttempts > 0) {
                    lessonAvgAcc = (wpCorrect * 100.0) / wpAttempts;
                } else if (teacherId != null || sectionId != null) {
                    lessonAvgAcc = 0.0;
                } else {
                    lessonAvgAcc = stList.stream()
                            .map(LearnerLessonStatus::getMasteryScore)
                            .filter(Objects::nonNull)
                            .mapToDouble(BigDecimal::doubleValue)
                            .average()
                            .orElse(0.0);
                }
            }

            BigDecimal avgScore = BigDecimal.valueOf(lessonAvgAcc).setScale(2, RoundingMode.HALF_UP);

            lessonPassRates.add(LessonPassRateSummary.builder()
                    .lessonId(lesson.getLessonId())
                    .lessonTitle(lesson.getLessonTitle())
                    .gradeLevel(lesson.getGradeLevel() != null ? lesson.getGradeLevel().name() : "")
                    .completionRate(completionRate)
                    .avgScore(avgScore)
                    .totalCompletions(completedCount)
                    .classId(lesson.getClassroom() != null ? lesson.getClassroom().getClassId() : null)
                    .className(lesson.getClassroom() != null ? lesson.getClassroom().getName() : null)
                    .isClassLesson(lesson.getClassroom() != null)
                    .build());
        }

        lessonPassRates.sort(Comparator.comparing(LessonPassRateSummary::getCompletionRate).reversed()
                .thenComparing(LessonPassRateSummary::getAvgScore, Comparator.reverseOrder()));

        // Cumulative Review Summary (strictly filtered for teacher POV)
        CumulativeAnalyticsSummary cumSummary;
        if (teacherId != null) {
            cumSummary = CumulativeAnalyticsSummary.builder()
                    .totalSessionsCompleted(0L)
                    .avgRetentionScore(null)
                    .perfectGoldCount(0L)
                    .goldCount(0L)
                    .silverCount(0L)
                    .bronzeCount(0L)
                    .build();
        } else {
            List<CumulativeReviewSession> allCum = cumulativeReviewSessionRepository.findAll();
            Set<UUID> learnerIds = statuses.stream()
                    .filter(s -> s.getLearner() != null)
                    .map(s -> s.getLearner().getLearnerId())
                    .collect(Collectors.toSet());

            List<CumulativeReviewSession> filteredCum = learnerIds.isEmpty() ? allCum : allCum.stream()
                    .filter(cs -> cs.getLearner() != null && learnerIds.contains(cs.getLearner().getLearnerId()))
                    .collect(Collectors.toList());

            List<CumulativeReviewSession> completedCum = filteredCum.stream()
                    .filter(cs -> "COMPLETED".equalsIgnoreCase(cs.getSessionStatus()))
                    .collect(Collectors.toList());

            BigDecimal avgRetentionScore = null;
            if (!completedCum.isEmpty()) {
                double avgCumScore = completedCum.stream()
                        .filter(cs -> cs.getAccuracyPercent() != null)
                        .mapToDouble(cs -> cs.getAccuracyPercent().doubleValue())
                        .average()
                        .orElse(0.0);
                avgRetentionScore = BigDecimal.valueOf(avgCumScore).setScale(2, RoundingMode.HALF_UP);
            }

            long perfectGold = completedCum.stream().filter(cs -> "PERFECT_GOLD".equalsIgnoreCase(cs.getBadgeAwarded())).count();
            long gold = completedCum.stream().filter(cs -> "GOLD".equalsIgnoreCase(cs.getBadgeAwarded())).count();
            long silver = completedCum.stream().filter(cs -> "SILVER".equalsIgnoreCase(cs.getBadgeAwarded())).count();
            long bronze = completedCum.stream().filter(cs -> "BRONZE".equalsIgnoreCase(cs.getBadgeAwarded())).count();

            cumSummary = CumulativeAnalyticsSummary.builder()
                    .totalSessionsCompleted((long) completedCum.size())
                    .avgRetentionScore(avgRetentionScore)
                    .perfectGoldCount(perfectGold)
                    .goldCount(gold)
                    .silverCount(silver)
                    .bronzeCount(bronze)
                    .build();
        }

        // 5. Part of Speech (POS) Accuracy Breakdown
        Map<String, List<VocabularyWord>> wordsByPos = targetWords.stream()
                .filter(w -> w.getPartOfSpeech() != null && !w.getPartOfSpeech().isBlank())
                .collect(Collectors.groupingBy(w -> w.getPartOfSpeech().trim().toUpperCase()));

        List<AdminAnalyticsDashboardResponse.PosAccuracySummary> posSummaries = new ArrayList<>();
        for (Map.Entry<String, List<VocabularyWord>> entry : wordsByPos.entrySet()) {
            String pos = entry.getKey();
            List<VocabularyWord> posWords = entry.getValue();
            Set<UUID> posWordIds = posWords.stream().map(VocabularyWord::getWordId).collect(Collectors.toSet());

            List<WordPerformance> posPerfs = targetWordPerformances.stream()
                    .filter(wp -> wp.getWord() != null && posWordIds.contains(wp.getWord().getWordId()))
                    .collect(Collectors.toList());

            int totalAttempts = posPerfs.stream().mapToInt(wp -> wp.getTotalAttempts() != null ? wp.getTotalAttempts() : 0).sum();
            int correctCount = posPerfs.stream().mapToInt(wp -> wp.getCorrectCount() != null ? wp.getCorrectCount() : 0).sum();
            BigDecimal posAcc = totalAttempts > 0
                    ? BigDecimal.valueOf(correctCount * 100.0 / totalAttempts).setScale(2, RoundingMode.HALF_UP)
                    : BigDecimal.ZERO;

            posSummaries.add(AdminAnalyticsDashboardResponse.PosAccuracySummary.builder()
                    .partOfSpeech(pos)
                    .totalWords(posWords.size())
                    .totalAttempts(totalAttempts)
                    .correctCount(correctCount)
                    .accuracy(posAcc)
                    .build());
        }

        posSummaries.sort(Comparator.comparing(AdminAnalyticsDashboardResponse.PosAccuracySummary::getAccuracy).reversed());

        return CurriculumAnalytics.builder()
                .hardestWords(topHardest)
                .fallbackFrequency(topFallbacks)
                .lessonPassRates(lessonPassRates)
                .cumulativeSummary(cumSummary)
                .posAccuracyBreakdown(posSummaries)
                .build();
    }

    private String resolveLeagueTier(int points, String masteryLevel) {
        if (points >= 3500 || "MASTERED".equalsIgnoreCase(masteryLevel)) {
            return "DIAMOND";
        } else if (points >= 2500 || "PROFICIENT".equalsIgnoreCase(masteryLevel)) {
            return "GOLD";
        } else if (points >= 1000 || "FAMILIAR".equalsIgnoreCase(masteryLevel)) {
            return "SILVER";
        } else {
            return "BRONZE";
        }
    }

    private String resolveClassroomName(UUID classId) {
        if (classId == null) return null;
        try {
            return classroomRepository.findById(classId).map(com.vocaboo.entity.Classroom::getName).orElse(null);
        } catch (Exception e) {
            return null;
        }
    }

    private String resolveLearnerFirstClassName(UUID learnerId) {
        if (learnerId == null) return null;
        try {
            List<com.vocaboo.entity.ClassEnrollment> enrollments = classEnrollmentRepository.findByLearnerLearnerIdAndStatus(learnerId, "ACTIVE");
            if (!enrollments.isEmpty() && enrollments.get(0).getClassroom() != null) {
                return enrollments.get(0).getClassroom().getName();
            }
        } catch (Exception ignored) {}
        return null;
    }
}
