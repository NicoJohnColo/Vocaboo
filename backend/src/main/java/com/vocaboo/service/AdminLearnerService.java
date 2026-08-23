package com.vocaboo.service;

import com.vocaboo.dto.request.BulkLearnerActionRequest;
import com.vocaboo.dto.request.UpdateLearnerAdminRequest;
import com.vocaboo.dto.response.AdminLearnerDetailResponse;
import com.vocaboo.dto.response.AdminLearnerDetailResponse.LearnerLessonProgressDetail;
import com.vocaboo.dto.response.AdminLearnerDetailResponse.LearnerWordPerformanceDetail;
import com.vocaboo.dto.response.AdminLearnerDetailResponse.ModuleScoreDetail;
import com.vocaboo.dto.response.AdminLearnerDetailResponse.CumulativeReviewPerformanceDetail;
import com.vocaboo.dto.response.AdminLearnerSummaryResponse;
import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import jakarta.persistence.criteria.Predicate;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.OffsetDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminLearnerService {

    private final LearnerRepository learnerRepository;
    private final SectionRepository sectionRepository;
    private final LearnerMasteryRepository masteryRepository;
    private final LearnerLessonStatusRepository lessonStatusRepository;
    private final LessonRepository lessonRepository;
    private final LessonModuleScoreRepository lessonModuleScoreRepository;
    private final DifficultyProgressRepository difficultyProgressRepository;
    private final WordPerformanceRepository wordPerformanceRepository;
    private final SandboxSessionRepository sandboxSessionRepository;
    private final SandboxWordRepository sandboxWordRepository;
    private final SandboxWordProgressRepository sandboxWordProgressRepository;
    private final SandboxModuleScoreRepository sandboxModuleScoreRepository;
    private final ReviewSessionRepository reviewSessionRepository;
    private final ReviewItemRepository reviewItemRepository;
    private final PracticeSessionRepository practiceSessionRepository;
    private final PracticeResultRepository practiceResultRepository;
    private final SessionSummaryRepository summaryRepository;
    private final PointTransactionRepository pointTransactionRepository;
    private final RewardDataRepository rewardDataRepository;
    private final PronunciationAttemptRepository pronunciationAttemptRepository;
    private final WordProgressRepository wordProgressRepository;
    private final DiagnosticResultRepository diagnosticResultRepository;
    private final IntroductionSessionRepository introductionSessionRepository;
    private final CumulativeReviewSessionRepository cumulativeReviewSessionRepository;
    private final AdminAuditLogRepository auditLogRepository;

    public Page<AdminLearnerSummaryResponse> searchLearners(
            String search,
            UUID sectionId,
            GradeLevel gradeLevel,
            Boolean isActive,
            String cohortType,
            Pageable pageable) {

        Specification<Learner> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (search != null && !search.trim().isEmpty()) {
                predicates.add(cb.like(cb.lower(root.get("displayName")), "%" + search.trim().toLowerCase() + "%"));
            }

            if (sectionId != null) {
                predicates.add(cb.equal(root.get("section").get("sectionId"), sectionId));
            } else if ("INDEPENDENT".equalsIgnoreCase(cohortType)) {
                predicates.add(cb.isNull(root.get("section")));
            } else if ("ENROLLED".equalsIgnoreCase(cohortType)) {
                predicates.add(cb.isNotNull(root.get("section")));
            }

            if (gradeLevel != null) {
                predicates.add(cb.equal(root.get("gradeLevel"), gradeLevel));
            }

            if (isActive != null) {
                predicates.add(cb.equal(root.get("isActive"), isActive));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        Page<Learner> learners = learnerRepository.findAll(spec, pageable);
        return learners.map(this::toSummaryResponse);
    }

    public List<AdminLearnerSummaryResponse> getAllLearnersSummary(UUID sectionId, GradeLevel gradeLevel) {
        List<Learner> learners;
        if (sectionId != null) {
            learners = learnerRepository.findBySectionSectionId(sectionId);
        } else if (gradeLevel != null) {
            learners = learnerRepository.findByGradeLevelAndIsActiveTrue(gradeLevel);
        } else {
            learners = learnerRepository.findAll();
        }
        return learners.stream().map(this::toSummaryResponse).collect(Collectors.toList());
    }

    public AdminLearnerDetailResponse getLearnerDetail(UUID learnerId) {
        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner not found: " + learnerId));

        LearnerMastery mastery = masteryRepository.findByLearnerLearnerId(learnerId).orElse(null);
        List<LearnerLessonStatus> statuses = lessonStatusRepository.findByLearnerLearnerId(learnerId);
        List<LessonModuleScore> moduleScores = lessonModuleScoreRepository.findByLearnerLearnerId(learnerId);
        List<Lesson> allLessons = lessonRepository.findAll();
        List<WordPerformance> wordPerformances = wordPerformanceRepository.findByLearnerLearnerId(learnerId);

        // Compute struggling reasons
        List<String> strugglingReasons = new ArrayList<>();
        int totalDemerits = wordPerformances.stream().mapToInt(wp -> wp.getDemeritPoints() != null ? wp.getDemeritPoints() : 0).sum();
        int totalTierDrops = wordPerformances.stream().mapToInt(wp -> wp.getTierDropCount() != null ? wp.getTierDropCount() : 0).sum();
        BigDecimal accuracy = mastery != null && mastery.getOverallAccuracy() != null ? mastery.getOverallAccuracy() : BigDecimal.ZERO;
        int totalAttempts = mastery != null && mastery.getTotalQuestionsAnswered() != null ? mastery.getTotalQuestionsAnswered() : 0;

        if (totalAttempts >= 10 && accuracy.compareTo(BigDecimal.valueOf(70.0)) < 0) {
            strugglingReasons.add("Low overall accuracy (" + accuracy.setScale(1, RoundingMode.HALF_UP) + "% < 70%)");
        }
        if (totalDemerits >= 5) {
            strugglingReasons.add("High error accumulation (" + totalDemerits + " total demerit points)");
        }
        if (totalTierDrops >= 3) {
            strugglingReasons.add("Difficulty regression (" + totalTierDrops + " tier drops)");
        }
        boolean isStruggling = !strugglingReasons.isEmpty();

        // Build Lesson breakdown
        Map<UUID, LearnerLessonStatus> statusMap = statuses.stream()
                .collect(Collectors.toMap(s -> s.getLesson().getLessonId(), s -> s, (s1, s2) -> s1));
        Map<UUID, List<LessonModuleScore>> scoreMap = moduleScores.stream()
                .collect(Collectors.groupingBy(m -> m.getLesson().getLessonId()));
        Map<UUID, List<WordPerformance>> lessonPerfMap = wordPerformances.stream()
                .filter(wp -> wp.getWord() != null && wp.getWord().getLesson() != null)
                .collect(Collectors.groupingBy(wp -> wp.getWord().getLesson().getLessonId()));

        List<LearnerLessonProgressDetail> lessonDetails = allLessons.stream().map(lesson -> {
            LearnerLessonStatus st = statusMap.get(lesson.getLessonId());
            List<LessonModuleScore> lms = scoreMap.getOrDefault(lesson.getLessonId(), List.of());

            List<ModuleScoreDetail> modDetails = lms.stream()
                    .map(m -> ModuleScoreDetail.builder()
                            .moduleNumber(m.getModuleNumber())
                            .score(m.getScore())
                            .correctCount(m.getCorrectCount())
                            .totalCount(m.getTotalCount())
                            .build())
                    .sorted(Comparator.comparingInt(m -> m.getModuleNumber() != null ? m.getModuleNumber() : 0))
                    .collect(Collectors.toList());

            BigDecimal m1 = null, m2 = null, m3 = null, m4 = null;
            for (ModuleScoreDetail md : modDetails) {
                if (md.getModuleNumber() != null) {
                    if (md.getModuleNumber() == 1) m1 = md.getScore();
                    else if (md.getModuleNumber() == 2) m2 = md.getScore();
                    else if (md.getModuleNumber() == 3) m3 = md.getScore();
                    else if (md.getModuleNumber() == 4) m4 = md.getScore();
                }
            }

            List<WordPerformance> lPerfs = lessonPerfMap.getOrDefault(lesson.getLessonId(), List.of());
            int totAtt = lPerfs.stream().mapToInt(wp -> wp.getTotalAttempts() != null ? wp.getTotalAttempts() : 0).sum();
            int totCorr = lPerfs.stream().mapToInt(wp -> wp.getCorrectCount() != null ? wp.getCorrectCount() : 0).sum();

            BigDecimal displayScore = null;
            if (totAtt > 0) {
                displayScore = BigDecimal.valueOf(totCorr * 100.0 / totAtt).setScale(2, RoundingMode.HALF_UP);
            } else if (st != null && st.getMasteryScore() != null) {
                displayScore = st.getMasteryScore();
            }

            OffsetDateTime lastPracticed = st != null ? (st.getCompletedAt() != null ? st.getCompletedAt() : st.getUpdatedAt()) : null;
            boolean bonusAwarded = st != null && (Boolean.TRUE.equals(st.getLessonCompletionBonusAwarded()) || Boolean.TRUE.equals(st.getPerfectScoreBonusAwarded()));

            return LearnerLessonProgressDetail.builder()
                    .lessonId(lesson.getLessonId())
                    .lessonTitle(lesson.getLessonTitle())
                    .gradeLevel(lesson.getGradeLevel() != null ? lesson.getGradeLevel().name() : "")
                    .status(st != null && st.getStatus() != null ? st.getStatus().name() : "NOT_STARTED")
                    .masteryScore(displayScore)
                    .module1Score(m1)
                    .module2Score(m2)
                    .module3Score(m3)
                    .module4Score(m4)
                    .starsEarned(st != null && st.getBestLessonPoints() != null ? Math.min(3, st.getBestLessonPoints() / 100) : 0)
                    .masteryBonusAwarded(bonusAwarded)
                    .moduleScores(modDetails)
                    .completedAt(st != null ? st.getCompletedAt() : null)
                    .lastPracticedAt(lastPracticed)
                    .build();
        }).collect(Collectors.toList());

        // Build Weak words (accuracy < 70% or demeritPoints > 0)
        List<LearnerWordPerformanceDetail> weakWords = wordPerformances.stream()
                .filter(wp -> (wp.getDemeritPoints() != null && wp.getDemeritPoints() > 0) ||
                              (wp.getTotalAttempts() != null && wp.getTotalAttempts() > 0 && wp.getAccuracy() != null && wp.getAccuracy().compareTo(BigDecimal.valueOf(70.0)) < 0))
                .sorted(Comparator.comparing((WordPerformance wp) -> wp.getDemeritPoints() != null ? wp.getDemeritPoints() : 0).reversed()
                        .thenComparing(wp -> wp.getAccuracy() != null ? wp.getAccuracy() : BigDecimal.ZERO))
                .map(wp -> LearnerWordPerformanceDetail.builder()
                        .wordId(wp.getWord().getWordId())
                        .englishWord(wp.getWord().getEnglishWord())
                        .cebuanoMeaning(wp.getWord().getCebuanoMeaning())
                        .lessonTitle(wp.getWord().getLesson() != null ? wp.getWord().getLesson().getLessonTitle() : "")
                        .accuracy(wp.getAccuracy())
                        .totalAttempts(wp.getTotalAttempts() != null ? wp.getTotalAttempts() : 0)
                        .correctCount(wp.getCorrectCount())
                        .incorrectCount(wp.getIncorrectCount())
                        .demeritPoints(wp.getDemeritPoints())
                        .tierDropCount(wp.getTierDropCount())
                        .fallbackCount(wp.getFallbackCount())
                        .lastPracticedAt(wp.getLastPracticedAt())
                        .build())
                .collect(Collectors.toList());

        // Cumulative reviews for this learner
        List<CumulativeReviewSession> cumSessions = new ArrayList<>(
                cumulativeReviewSessionRepository.findByLearnerLearnerIdOrderByStartTimeDesc(learnerId)
        );

        // Fallback: If no explicit CumulativeReviewSession recorded yet, synthesize from completed category lessons / statuses
        if (cumSessions.isEmpty()) {
            Map<UUID, List<Lesson>> lessonsByCategory = allLessons.stream()
                    .filter(l -> l.getCategory() != null)
                    .collect(Collectors.groupingBy(l -> l.getCategory().getCategoryId()));

            for (Map.Entry<UUID, List<Lesson>> entry : lessonsByCategory.entrySet()) {
                List<Lesson> catLessons = entry.getValue();
                List<LearnerLessonStatus> completedStatuses = catLessons.stream()
                        .map(l -> statusMap.get(l.getLessonId()))
                        .filter(st -> st != null && (st.getStatus() == LessonStatus.COMPLETED || st.getMasteryScore() != null))
                        .collect(Collectors.toList());

                if (!completedStatuses.isEmpty()) {
                    double avgScore = completedStatuses.stream()
                            .filter(st -> st.getMasteryScore() != null)
                            .mapToDouble(st -> st.getMasteryScore().doubleValue())
                            .average()
                            .orElse(0.0);

                    if (avgScore > 0) {
                        String catName = (catLessons.get(0).getCategory() != null && catLessons.get(0).getCategory().getCategoryName() != null)
                                ? catLessons.get(0).getCategory().getCategoryName()
                                : "Lessons Review";

                        String badge = "BRONZE";
                        if (avgScore >= 100.0) badge = "PERFECT_GOLD";
                        else if (avgScore >= 90.0) badge = "GOLD";
                        else if (avgScore >= 80.0) badge = "SILVER";

                        OffsetDateTime completedTime = completedStatuses.stream()
                                .map(st -> st.getCompletedAt() != null ? st.getCompletedAt() : st.getUpdatedAt())
                                .filter(Objects::nonNull)
                                .max(OffsetDateTime::compareTo)
                                .orElse(OffsetDateTime.now());

                        CumulativeReviewSession synthetic = CumulativeReviewSession.builder()
                                .id(UUID.randomUUID())
                                .learner(learner)
                                .lessonPairId(catName)
                                .sessionStatus("COMPLETED")
                                .accuracyPercent(BigDecimal.valueOf(avgScore).setScale(2, RoundingMode.HALF_UP))
                                .badgeAwarded(badge)
                                .pointsEarned((int) Math.round(avgScore * 1.5))
                                .startTime(completedTime.minusMinutes(5))
                                .endTime(completedTime)
                                .build();
                        cumSessions.add(synthetic);
                    }
                }
            }
        }

        List<CumulativeReviewSession> completedCum = cumSessions.stream()
                .filter(cs -> "COMPLETED".equalsIgnoreCase(cs.getSessionStatus()))
                .collect(Collectors.toList());

        double avgCumScore = completedCum.isEmpty() ? 0.0 :
                completedCum.stream()
                        .filter(cs -> cs.getAccuracyPercent() != null)
                        .mapToDouble(cs -> cs.getAccuracyPercent().doubleValue())
                        .average()
                        .orElse(0.0);

        String bestCumBadge = null;
        if (completedCum.stream().anyMatch(cs -> "PERFECT_GOLD".equalsIgnoreCase(cs.getBadgeAwarded()))) {
            bestCumBadge = "PERFECT_GOLD";
        } else if (completedCum.stream().anyMatch(cs -> "GOLD".equalsIgnoreCase(cs.getBadgeAwarded()))) {
            bestCumBadge = "GOLD";
        } else if (completedCum.stream().anyMatch(cs -> "SILVER".equalsIgnoreCase(cs.getBadgeAwarded()))) {
            bestCumBadge = "SILVER";
        } else if (completedCum.stream().anyMatch(cs -> "BRONZE".equalsIgnoreCase(cs.getBadgeAwarded()))) {
            bestCumBadge = "BRONZE";
        }

        List<CumulativeReviewPerformanceDetail> cumDetails = cumSessions.stream().map(cs -> {
            return CumulativeReviewPerformanceDetail.builder()
                    .sessionId(cs.getId())
                    .lessonPairId(cs.getLessonPairId())
                    .categoryName(cs.getLessonPairId())
                    .accuracyPercent(cs.getAccuracyPercent())
                    .badgeAwarded(cs.getBadgeAwarded())
                    .pointsEarned(cs.getPointsEarned())
                    .correctCount(cs.getCorrectCount())
                    .totalAttempts(cs.getTotalAttempts())
                    .sessionStatus(cs.getSessionStatus())
                    .completedAt(cs.getEndTime() != null ? cs.getEndTime() : cs.getStartTime())
                    .build();
        }).collect(Collectors.toList());

        OffsetDateTime lastActiveAt = resolveLastActiveAt(learnerId, learner.getUpdatedAt(), wordPerformances, statuses);

        return AdminLearnerDetailResponse.builder()
                .learnerId(learner.getLearnerId())
                .displayName(learner.getDisplayName())
                .age(learner.getAge())
                .gradeLevel(learner.getGradeLevel() != null ? learner.getGradeLevel().name() : null)
                .sectionId(learner.getSection() != null ? learner.getSection().getSectionId() : null)
                .sectionName(learner.getSection() != null ? learner.getSection().getSectionName() : null)
                .languagePreference(learner.getLanguagePreference() != null ? learner.getLanguagePreference().name() : null)
                .posFocus(learner.getPosFocus())
                .isActive(learner.getIsActive())
                .createdAt(learner.getCreatedAt())
                .updatedAt(learner.getUpdatedAt())
                .lastActiveAt(lastActiveAt)
                .masteryLevel(mastery != null ? mastery.getMasteryLevel() : "LEARNING")
                .totalPoints(mastery != null && mastery.getTotalPoints() != null ? mastery.getTotalPoints() : 0)
                .overallAccuracy(mastery != null ? mastery.getOverallAccuracy() : BigDecimal.ZERO)
                .wordsMasteredCount(mastery != null && mastery.getWordsMasteredCount() != null ? mastery.getWordsMasteredCount() : 0)
                .totalSessionsPlayed(mastery != null && mastery.getTotalSessionsPlayed() != null ? mastery.getTotalSessionsPlayed() : 0)
                .totalQuestionsAnswered(mastery != null && mastery.getTotalQuestionsAnswered() != null ? mastery.getTotalQuestionsAnswered() : 0)
                .totalCorrectAnswers(mastery != null && mastery.getTotalCorrectAnswers() != null ? mastery.getTotalCorrectAnswers() : 0)
                .cumulativeReviewsCompleted(completedCum.size())
                .avgCumulativeScore(BigDecimal.valueOf(avgCumScore).setScale(2, RoundingMode.HALF_UP))
                .bestCumulativeBadge(bestCumBadge)
                .cumulativeReviews(cumDetails)
                .isStruggling(isStruggling)
                .strugglingReasons(strugglingReasons)
                .lessons(lessonDetails)
                .weakWords(weakWords)
                .build();
    }

    @Transactional
    public AdminLearnerSummaryResponse updateLearner(UUID learnerId, UpdateLearnerAdminRequest req, UUID adminId) {
        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner not found: " + learnerId));

        if (req.getDisplayName() != null && !req.getDisplayName().trim().isEmpty()) {
            String newName = req.getDisplayName().trim();
            if (learnerRepository.existsByDisplayNameIgnoreCaseAndLearnerIdNot(newName, learnerId)) {
                throw new IllegalArgumentException("A learner with display name '" + newName + "' already exists.");
            }
            learner.setDisplayName(newName);
        }

        if (req.getAge() != null) {
            learner.setAge(req.getAge());
        }

        if (req.getGradeLevel() != null) {
            learner.setGradeLevel(req.getGradeLevel());
        }

        if (req.getSectionId() != null) {
            Section section = sectionRepository.findById(req.getSectionId())
                    .orElseThrow(() -> new IllegalArgumentException("Section not found: " + req.getSectionId()));
            learner.setSection(section);
        }

        if (req.getLanguagePreference() != null) {
            learner.setLanguagePreference(req.getLanguagePreference());
        }

        if (req.getPosFocus() != null && !req.getPosFocus().trim().isEmpty()) {
            learner.setPosFocus(req.getPosFocus().trim().toUpperCase());
        }

        if (req.getIsActive() != null) {
            learner.setIsActive(req.getIsActive());
        }

        learner = learnerRepository.save(learner);

        if (adminId != null) {
            auditLogRepository.save(AdminAuditLog.builder()
                    .adminId(adminId)
                    .action("UPDATE_LEARNER")
                    .targetId(learnerId)
                    .details("Updated profile for learner: " + learner.getDisplayName())
                    .build());
        }

        return toSummaryResponse(learner);
    }

    @Transactional
    public void deactivateLearner(UUID learnerId, UUID adminId) {
        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner not found: " + learnerId));
        learner.setIsActive(false);
        learnerRepository.save(learner);

        if (adminId != null) {
            auditLogRepository.save(AdminAuditLog.builder()
                    .adminId(adminId)
                    .action("DEACTIVATE_LEARNER")
                    .targetId(learnerId)
                    .details("Deactivated learner: " + learner.getDisplayName())
                    .build());
        }
    }

    @Transactional
    public void reactivateLearner(UUID learnerId, UUID adminId) {
        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner not found: " + learnerId));
        learner.setIsActive(true);
        learnerRepository.save(learner);

        if (adminId != null) {
            auditLogRepository.save(AdminAuditLog.builder()
                    .adminId(adminId)
                    .action("REACTIVATE_LEARNER")
                    .targetId(learnerId)
                    .details("Reactivated learner: " + learner.getDisplayName())
                    .build());
        }
    }

    @Transactional
    public void resetLearnerProgress(UUID learnerId, UUID lessonId, UUID adminId) {
        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner not found: " + learnerId));

        if (lessonId == null) {
            // Full Reset
            List<SandboxSession> sSessions = sandboxSessionRepository.findByLearnerLearnerIdOrderByCreatedAtDesc(learnerId);
            for (SandboxSession sSession : sSessions) {
                sandboxModuleScoreRepository.deleteBySessionSessionId(sSession.getSessionId());
                sandboxWordProgressRepository.deleteBySessionSessionId(sSession.getSessionId());
                sandboxWordRepository.deleteBySessionSessionId(sSession.getSessionId());
            }
            sandboxSessionRepository.deleteByLearnerLearnerId(learnerId);

            List<ReviewSession> rSessions = reviewSessionRepository.findByLearnerLearnerId(learnerId);
            for (ReviewSession rSession : rSessions) {
                reviewItemRepository.deleteBySessionSessionId(rSession.getSessionId());
            }
            reviewSessionRepository.deleteByLearnerLearnerId(learnerId);

            List<PracticeSession> pSessions = practiceSessionRepository.findByLearnerLearnerId(learnerId);
            for (PracticeSession pSession : pSessions) {
                practiceResultRepository.deleteBySessionSessionId(pSession.getSessionId());
            }
            practiceSessionRepository.deleteByLearnerLearnerId(learnerId);

            summaryRepository.deleteByLearnerLearnerId(learnerId);
            wordPerformanceRepository.deleteByLearnerLearnerId(learnerId);
            masteryRepository.deleteByLearnerLearnerId(learnerId);
            difficultyProgressRepository.deleteByLearnerLearnerId(learnerId);
            pointTransactionRepository.deleteByLearnerLearnerId(learnerId);
            rewardDataRepository.deleteByLearnerLearnerId(learnerId);
            pronunciationAttemptRepository.deleteByLearnerLearnerId(learnerId);
            wordProgressRepository.deleteByLearnerLearnerId(learnerId);
            diagnosticResultRepository.deleteByLearnerLearnerId(learnerId);
            introductionSessionRepository.deleteByLearnerLearnerId(learnerId);
            lessonStatusRepository.deleteByLearnerLearnerId(learnerId);
            lessonModuleScoreRepository.deleteByLearnerLearnerId(learnerId);

            // Recreate baseline LearnerMastery
            LearnerMastery freshMastery = LearnerMastery.builder()
                    .learner(learner)
                    .totalSessionsPlayed(0)
                    .totalCorrectAnswers(0)
                    .totalQuestionsAnswered(0)
                    .overallAccuracy(BigDecimal.ZERO)
                    .wordsMasteredCount(0)
                    .totalPoints(0)
                    .masteryLevel("LEARNING")
                    .createdAt(OffsetDateTime.now())
                    .build();
            masteryRepository.save(freshMastery);

            if (adminId != null) {
                auditLogRepository.save(AdminAuditLog.builder()
                        .adminId(adminId)
                        .action("RESET_ALL_PROGRESS")
                        .targetId(learnerId)
                        .details("Reset all learning progress and mastery baseline for learner: " + learner.getDisplayName())
                        .build());
            }
        } else {
            // Lesson-Specific Reset
            Lesson lesson = lessonRepository.findById(lessonId)
                    .orElseThrow(() -> new IllegalArgumentException("Lesson not found: " + lessonId));

            lessonStatusRepository.deleteByLearnerLearnerIdAndLessonLessonId(learnerId, lessonId);
            lessonModuleScoreRepository.deleteByLearnerLearnerIdAndLessonLessonId(learnerId, lessonId);
            difficultyProgressRepository.deleteByLearnerLearnerIdAndWordLessonLessonId(learnerId, lessonId);
            wordPerformanceRepository.deleteByLearnerLearnerIdAndWordLessonLessonId(learnerId, lessonId);

            // Recompute LearnerMastery metrics from remaining word performances
            List<WordPerformance> remaining = wordPerformanceRepository.findByLearnerLearnerId(learnerId);
            int totalAttempts = remaining.stream().mapToInt(wp -> wp.getTotalAttempts() != null ? wp.getTotalAttempts() : 0).sum();
            int totalCorrect = remaining.stream().mapToInt(wp -> wp.getCorrectCount() != null ? wp.getCorrectCount() : 0).sum();
            BigDecimal overallAcc = totalAttempts > 0
                    ? BigDecimal.valueOf(totalCorrect * 100.0 / totalAttempts).setScale(2, RoundingMode.HALF_UP)
                    : BigDecimal.ZERO;
            long masteredCount = difficultyProgressRepository.countTotalMasteredWordsByLearner(learnerId);

            LearnerMastery mastery = masteryRepository.findByLearnerLearnerId(learnerId).orElse(null);
            if (mastery != null) {
                mastery.setTotalQuestionsAnswered(totalAttempts);
                mastery.setTotalCorrectAnswers(totalCorrect);
                mastery.setOverallAccuracy(overallAcc);
                mastery.setWordsMasteredCount((int) masteredCount);
                masteryRepository.save(mastery);
            }

            if (adminId != null) {
                auditLogRepository.save(AdminAuditLog.builder()
                        .adminId(adminId)
                        .action("RESET_LESSON_PROGRESS")
                        .targetId(learnerId)
                        .details("Reset progress for lesson '" + lesson.getLessonTitle() + "' for learner: " + learner.getDisplayName())
                        .build());
            }
        }
    }

    @Transactional
    public Map<String, Object> executeBulkAction(BulkLearnerActionRequest req, UUID adminId) {
        int successCount = 0;
        List<String> errors = new ArrayList<>();

        for (UUID lid : req.getLearnerIds()) {
            try {
                switch (req.getAction()) {
                    case ASSIGN_SECTION -> {
                        Learner learner = learnerRepository.findById(lid).orElse(null);
                        if (learner != null) {
                            Section section = req.getSectionId() != null
                                    ? sectionRepository.findById(req.getSectionId()).orElse(null)
                                    : null;
                            learner.setSection(section);
                            learnerRepository.save(learner);
                            successCount++;
                        }
                    }
                    case DEACTIVATE -> {
                        Learner learner = learnerRepository.findById(lid).orElse(null);
                        if (learner != null) {
                            learner.setIsActive(false);
                            learnerRepository.save(learner);
                            successCount++;
                        }
                    }
                    case REACTIVATE -> {
                        Learner learner = learnerRepository.findById(lid).orElse(null);
                        if (learner != null) {
                            learner.setIsActive(true);
                            learnerRepository.save(learner);
                            successCount++;
                        }
                    }
                    case RESET_PROGRESS -> {
                        resetLearnerProgress(lid, req.getLessonId(), adminId);
                        successCount++;
                    }
                }
            } catch (Exception e) {
                errors.add("Error processing learner " + lid + ": " + e.getMessage());
            }
        }

        if (adminId != null) {
            auditLogRepository.save(AdminAuditLog.builder()
                    .adminId(adminId)
                    .action("BULK_" + req.getAction().name())
                    .details("Executed bulk " + req.getAction().name() + " on " + req.getLearnerIds().size() + " learners. Successful: " + successCount)
                    .build());
        }

        return Map.of(
                "action", req.getAction().name(),
                "requested_count", req.getLearnerIds().size(),
                "success_count", successCount,
                "errors", errors
        );
    }

    public AdminLearnerSummaryResponse toSummaryResponse(Learner learner) {
        LearnerMastery mastery = masteryRepository.findByLearnerLearnerId(learner.getLearnerId()).orElse(null);
        List<LearnerLessonStatus> statuses = lessonStatusRepository.findByLearnerLearnerId(learner.getLearnerId());
        List<WordPerformance> wordPerformances = wordPerformanceRepository.findByLearnerLearnerId(learner.getLearnerId());

        int completedLessons = (int) statuses.stream()
                .filter(s -> s.getStatus() == LessonStatus.COMPLETED)
                .count();

        int totalDemerits = wordPerformances.stream().mapToInt(wp -> wp.getDemeritPoints() != null ? wp.getDemeritPoints() : 0).sum();
        int totalTierDrops = wordPerformances.stream().mapToInt(wp -> wp.getTierDropCount() != null ? wp.getTierDropCount() : 0).sum();
        BigDecimal accuracy = mastery != null && mastery.getOverallAccuracy() != null ? mastery.getOverallAccuracy() : BigDecimal.ZERO;
        int totalAttempts = mastery != null && mastery.getTotalQuestionsAnswered() != null ? mastery.getTotalQuestionsAnswered() : 0;

        boolean isStruggling = (totalAttempts >= 10 && accuracy.compareTo(BigDecimal.valueOf(70.0)) < 0) ||
                               totalDemerits >= 5 ||
                               totalTierDrops >= 3;

        OffsetDateTime lastActiveAt = resolveLastActiveAt(learner.getLearnerId(), learner.getUpdatedAt(), wordPerformances, statuses);

        List<CumulativeReviewSession> cumSessions = new ArrayList<>(
                cumulativeReviewSessionRepository.findByLearnerLearnerIdOrderByStartTimeDesc(learner.getLearnerId())
        );

        if (cumSessions.isEmpty() && completedLessons > 0) {
            double avgScore = statuses.stream()
                    .filter(st -> (st.getStatus() == LessonStatus.COMPLETED || st.getMasteryScore() != null) && st.getMasteryScore() != null)
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
                        .learner(learner)
                        .lessonPairId("Category Review")
                        .sessionStatus("COMPLETED")
                        .accuracyPercent(BigDecimal.valueOf(avgScore).setScale(2, RoundingMode.HALF_UP))
                        .badgeAwarded(badge)
                        .pointsEarned((int) Math.round(avgScore * 1.5))
                        .startTime(OffsetDateTime.now().minusMinutes(5))
                        .endTime(OffsetDateTime.now())
                        .build();
                cumSessions.add(synthetic);
            }
        }

        List<CumulativeReviewSession> completedCum = cumSessions.stream()
                .filter(cs -> "COMPLETED".equalsIgnoreCase(cs.getSessionStatus()))
                .collect(Collectors.toList());

        double avgCum = completedCum.isEmpty() ? 0.0 :
                completedCum.stream()
                        .filter(cs -> cs.getAccuracyPercent() != null)
                        .mapToDouble(cs -> cs.getAccuracyPercent().doubleValue())
                        .average()
                        .orElse(0.0);

        String bestBadge = null;
        if (completedCum.stream().anyMatch(cs -> "PERFECT_GOLD".equalsIgnoreCase(cs.getBadgeAwarded()))) {
            bestBadge = "PERFECT_GOLD";
        } else if (completedCum.stream().anyMatch(cs -> "GOLD".equalsIgnoreCase(cs.getBadgeAwarded()))) {
            bestBadge = "GOLD";
        } else if (completedCum.stream().anyMatch(cs -> "SILVER".equalsIgnoreCase(cs.getBadgeAwarded()))) {
            bestBadge = "SILVER";
        } else if (completedCum.stream().anyMatch(cs -> "BRONZE".equalsIgnoreCase(cs.getBadgeAwarded()))) {
            bestBadge = "BRONZE";
        }

        return AdminLearnerSummaryResponse.builder()
                .learnerId(learner.getLearnerId())
                .displayName(learner.getDisplayName())
                .age(learner.getAge())
                .gradeLevel(learner.getGradeLevel() != null ? learner.getGradeLevel().name() : null)
                .sectionId(learner.getSection() != null ? learner.getSection().getSectionId() : null)
                .sectionName(learner.getSection() != null ? learner.getSection().getSectionName() : null)
                .languagePreference(learner.getLanguagePreference() != null ? learner.getLanguagePreference().name() : null)
                .isActive(learner.getIsActive())
                .masteryLevel(mastery != null ? mastery.getMasteryLevel() : "LEARNING")
                .totalPoints(mastery != null && mastery.getTotalPoints() != null ? mastery.getTotalPoints() : 0)
                .overallAccuracy(mastery != null ? mastery.getOverallAccuracy() : BigDecimal.ZERO)
                .completedLessonsCount(completedLessons)
                .wordsMasteredCount(mastery != null && mastery.getWordsMasteredCount() != null ? mastery.getWordsMasteredCount() : 0)
                .cumulativeReviewsCompleted(completedCum.size())
                .avgCumulativeScore(BigDecimal.valueOf(avgCum).setScale(2, RoundingMode.HALF_UP))
                .bestCumulativeBadge(bestBadge)
                .isStruggling(isStruggling)
                .lastActiveAt(lastActiveAt)
                .createdAt(learner.getCreatedAt())
                .build();
    }

    private OffsetDateTime resolveLastActiveAt(
            UUID learnerId,
            OffsetDateTime learnerUpdatedAt,
            List<WordPerformance> wordPerformances,
            List<LearnerLessonStatus> statuses) {

        OffsetDateTime latest = learnerUpdatedAt;

        for (WordPerformance wp : wordPerformances) {
            if (wp.getLastPracticedAt() != null && (latest == null || wp.getLastPracticedAt().isAfter(latest))) {
                latest = wp.getLastPracticedAt();
            }
        }

        for (LearnerLessonStatus st : statuses) {
            if (st.getUpdatedAt() != null && (latest == null || st.getUpdatedAt().isAfter(latest))) {
                latest = st.getUpdatedAt();
            }
        }

        return latest;
    }
}
