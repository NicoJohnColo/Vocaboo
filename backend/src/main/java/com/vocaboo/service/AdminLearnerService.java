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
import org.springframework.data.domain.PageImpl;
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
    private final LessonWordAccuracyRepository lessonWordAccuracyRepository;
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
    private final com.vocaboo.repository.ClassEnrollmentRepository classEnrollmentRepository;
    private final com.vocaboo.repository.ClassPerformanceRepository classPerformanceRepository;
    private final com.vocaboo.repository.ClassroomRepository classroomRepository;
    private final LearnerService learnerService;

    public Page<AdminLearnerSummaryResponse> searchLearners(
            String search,
            UUID sectionId,
            GradeLevel gradeLevel,
            Boolean isActive,
            String cohortType,
            Pageable pageable) {
        return searchLearners(search, sectionId, gradeLevel, isActive, cohortType, null, pageable);
    }

    public Page<AdminLearnerSummaryResponse> searchLearners(
            String search,
            UUID sectionId,
            GradeLevel gradeLevel,
            Boolean isActive,
            String cohortType,
            UUID teacherId,
            Pageable pageable) {

        List<UUID> enrolledIds = null;
        if (teacherId != null) {
            enrolledIds = new ArrayList<>(classEnrollmentRepository.findEnrolledLearnerIdsByTeacherId(teacherId));
            if (sectionId != null) {
                List<UUID> classEnrolledIds = classEnrollmentRepository.findEnrolledLearnerIdsByClassId(sectionId);
                enrolledIds.retainAll(classEnrolledIds);
            }
            if (enrolledIds.isEmpty()) {
                return new PageImpl<>(Collections.emptyList(), pageable, 0);
            }
        } else if (sectionId != null) {
            List<UUID> classEnrolledIds = classEnrollmentRepository.findEnrolledLearnerIdsByClassId(sectionId);
            if (!classEnrolledIds.isEmpty()) {
                enrolledIds = new ArrayList<>(classEnrolledIds);
            }
        }

        final List<UUID> finalEnrolledIds = enrolledIds;

        Specification<Learner> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (finalEnrolledIds != null) {
                predicates.add(root.get("learnerId").in(finalEnrolledIds));
            } else if (sectionId != null) {
                predicates.add(cb.equal(root.get("section").get("sectionId"), sectionId));
            }

            if (search != null && !search.trim().isEmpty()) {
                String searchPattern = "%" + search.trim().toLowerCase() + "%";
                predicates.add(cb.or(
                        cb.like(cb.lower(root.get("displayName")), searchPattern),
                        cb.like(cb.lower(root.get("userId")), searchPattern)
                ));
            }

            if ("INDEPENDENT".equalsIgnoreCase(cohortType)) {
                predicates.add(cb.isNull(root.get("section")));
            } else if ("ENROLLED".equalsIgnoreCase(cohortType) && finalEnrolledIds == null) {
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
        return learners.map(l -> toSummaryResponse(l, sectionId, teacherId));
    }

    public List<AdminLearnerSummaryResponse> getAllLearnersSummary(UUID sectionId, GradeLevel gradeLevel) {
        return getAllLearnersSummary(sectionId, gradeLevel, null);
    }

    public List<AdminLearnerSummaryResponse> getAllLearnersSummary(UUID sectionId, GradeLevel gradeLevel, UUID teacherId) {
        List<Learner> learners;
        if (sectionId != null) {
            List<UUID> classEnrolledIds = classEnrollmentRepository.findEnrolledLearnerIdsByClassId(sectionId);
            if (!classEnrolledIds.isEmpty()) {
                learners = learnerRepository.findAllById(classEnrolledIds).stream()
                        .filter(Learner::getIsActive)
                        .collect(Collectors.toList());
            } else {
                learners = learnerRepository.findBySectionSectionId(sectionId);
            }
        } else if (gradeLevel != null && teacherId == null) {
            learners = learnerRepository.findByGradeLevelAndIsActiveTrue(gradeLevel);
        } else {
            learners = learnerRepository.findAll();
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

        return learners.stream().map(l -> toSummaryResponse(l, sectionId, teacherId)).collect(Collectors.toList());
    }

    public AdminLearnerDetailResponse getLearnerDetail(UUID learnerId) {
        return getLearnerDetail(learnerId, null, null);
    }

    public AdminLearnerDetailResponse getLearnerDetail(UUID learnerId, UUID teacherId) {
        return getLearnerDetail(learnerId, teacherId, null);
    }

    @Transactional(readOnly = true)
    public AdminLearnerDetailResponse getLearnerDetail(UUID learnerId, UUID teacherId, UUID classId) {
        if (teacherId != null) {
            List<UUID> enrolledIds = classEnrollmentRepository.findEnrolledLearnerIdsByTeacherId(teacherId);
            if (!enrolledIds.contains(learnerId)) {
                throw new org.springframework.security.access.AccessDeniedException("You can only access students enrolled in your classes.");
            }
            if (classId != null) {
                boolean ownsClass = classroomRepository.findById(classId)
                        .map(c -> c.getTeacher() != null && teacherId.equals(c.getTeacher().getTeacherId()))
                        .orElse(false);
                if (!ownsClass) {
                    throw new org.springframework.security.access.AccessDeniedException("You do not have access to this classroom.");
                }
            }
        }

        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner not found: " + learnerId));

        LearnerMastery mastery = masteryRepository.findByLearnerLearnerId(learnerId).orElse(null);
        List<LearnerLessonStatus> statuses = lessonStatusRepository.findByLearnerLearnerId(learnerId);
        List<LessonModuleScore> moduleScores = lessonModuleScoreRepository.findByLearnerLearnerId(learnerId);

        // ── Enrolled Classes Breakdown ──
        List<com.vocaboo.entity.ClassEnrollment> activeEnrollments = classEnrollmentRepository.findByLearnerLearnerIdAndStatus(learnerId, "ACTIVE");
        List<AdminLearnerDetailResponse.EnrolledClassDetail> enrolledClassDetails = new ArrayList<>();

        for (com.vocaboo.entity.ClassEnrollment ce : activeEnrollments) {
            com.vocaboo.entity.Classroom cr = ce.getClassroom();
            if (cr == null) continue;
            // If viewing as teacher, only include classes belonging to this teacher
            if (teacherId != null && (cr.getTeacher() == null || !teacherId.equals(cr.getTeacher().getTeacherId()))) {
                continue;
            }

            UUID cId = cr.getClassId();
            Optional<com.vocaboo.entity.ClassPerformance> cpOpt = classPerformanceRepository.findByLearnerLearnerIdAndClassroomClassId(learnerId, cId);

            Integer cPts = 0;
            BigDecimal cAcc = BigDecimal.ZERO;
            String cMst = "LEARNING";
            Integer cSess = 0;
            if (cpOpt.isPresent()) {
                com.vocaboo.entity.ClassPerformance cp = cpOpt.get();
                cPts = cp.getClassPoints() != null ? cp.getClassPoints() : 0;
                cAcc = cp.getClassAccuracy() != null ? cp.getClassAccuracy() : BigDecimal.ZERO;
                cMst = cp.getClassMasteryLevel() != null ? cp.getClassMasteryLevel() : "LEARNING";
                cSess = cp.getClassSessionsPlayed() != null ? cp.getClassSessionsPlayed() : 0;
            }

            String teacherName = null;
            if (cr.getTeacher() != null) {
                String fn = cr.getTeacher().getFirstname();
                String ln = cr.getTeacher().getLastname();
                if (fn != null && !fn.isBlank()) {
                    teacherName = (fn + (ln != null ? " " + ln : "")).trim();
                } else if (cr.getTeacher().getEmail() != null) {
                    teacherName = cr.getTeacher().getEmail();
                } else {
                    teacherName = cr.getTeacher().getUsername();
                }
            }

            enrolledClassDetails.add(AdminLearnerDetailResponse.EnrolledClassDetail.builder()
                    .classId(cId)
                    .className(cr.getName())
                    .classCode(cr.getClassCode())
                    .teacherName(teacherName)
                    .classPoints(cPts)
                    .classAccuracy(cAcc)
                    .classMasteryLevel(cMst)
                    .classSessionsPlayed(cSess)
                    .build());
        }

        // Resolve Classroom Context
        UUID resolvedClassId = classId;
        String resolvedClassName = null;
        String resolvedClassCode = null;
        Integer classPoints = null;
        BigDecimal classAccuracy = null;
        String classMasteryLevel = null;
        Integer classSessionsPlayed = null;

        if (resolvedClassId != null) {
            Optional<com.vocaboo.entity.Classroom> crOpt = classroomRepository.findById(resolvedClassId);
            if (crOpt.isPresent()) {
                com.vocaboo.entity.Classroom cr = crOpt.get();
                resolvedClassName = cr.getName();
                resolvedClassCode = cr.getClassCode();
                Optional<com.vocaboo.entity.ClassPerformance> cpOpt = classPerformanceRepository
                        .findByLearnerLearnerIdAndClassroomClassId(learnerId, resolvedClassId);
                if (cpOpt.isPresent()) {
                    com.vocaboo.entity.ClassPerformance cp = cpOpt.get();
                    classPoints = cp.getClassPoints() != null ? cp.getClassPoints() : 0;
                    classAccuracy = cp.getClassAccuracy() != null ? cp.getClassAccuracy() : BigDecimal.ZERO;
                    classMasteryLevel = cp.getClassMasteryLevel() != null ? cp.getClassMasteryLevel() : "LEARNING";
                    classSessionsPlayed = cp.getClassSessionsPlayed() != null ? cp.getClassSessionsPlayed() : 0;
                } else {
                    classPoints = 0;
                    classAccuracy = BigDecimal.ZERO;
                    classMasteryLevel = "LEARNING";
                    classSessionsPlayed = 0;
                }
            }
        } else if (teacherId != null) {
            if (enrolledClassDetails.size() == 1) {
                AdminLearnerDetailResponse.EnrolledClassDetail singleCls = enrolledClassDetails.get(0);
                resolvedClassId = singleCls.getClassId();
                resolvedClassName = singleCls.getClassName();
                resolvedClassCode = singleCls.getClassCode();
                classPoints = singleCls.getClassPoints();
                classAccuracy = singleCls.getClassAccuracy();
                classMasteryLevel = singleCls.getClassMasteryLevel();
                classSessionsPlayed = singleCls.getClassSessionsPlayed();
            } else if (enrolledClassDetails.size() > 1) {
                // Combined across teacher's classes
                resolvedClassId = null;
                resolvedClassName = null;
                resolvedClassCode = null;
                classPoints = enrolledClassDetails.stream().mapToInt(c -> c.getClassPoints() != null ? c.getClassPoints() : 0).sum();
                classSessionsPlayed = enrolledClassDetails.stream().mapToInt(c -> c.getClassSessionsPlayed() != null ? c.getClassSessionsPlayed() : 0).sum();
                double avgAcc = enrolledClassDetails.stream()
                        .map(AdminLearnerDetailResponse.EnrolledClassDetail::getClassAccuracy)
                        .filter(Objects::nonNull)
                        .mapToDouble(BigDecimal::doubleValue)
                        .average()
                        .orElse(0.0);
                classAccuracy = BigDecimal.valueOf(avgAcc).setScale(2, RoundingMode.HALF_UP);
                classMasteryLevel = "COMBINED";
            }
        } else {
            // Global scope for admin: strictly global, no class context pollution
            resolvedClassId = null;
            resolvedClassName = null;
            resolvedClassCode = null;
            classPoints = null;
            classAccuracy = null;
            classMasteryLevel = null;
            classSessionsPlayed = null;
        }

        final boolean isClassScope = (classId != null || teacherId != null);

        // Lessons: strictly separated between class and global
        List<Lesson> allLessons;
        if (classId != null) {
            allLessons = lessonRepository.findByClassroomClassIdAndIsDeletedFalseOrderByLessonOrderAsc(classId);
        } else if (teacherId != null) {
            allLessons = lessonRepository.findByClassroomTeacherTeacherIdAndIsDeletedFalseOrderByLessonOrderAsc(teacherId);
        } else {
            allLessons = lessonRepository.findByIsDeletedFalseAndClassroomIsNullOrderByLessonOrderAsc();
            if (allLessons.isEmpty()) {
                allLessons = lessonRepository.findByIsDeletedFalseOrderByLessonOrderAsc();
            }
        }

        Set<UUID> visibleLessonIds = allLessons.stream().map(Lesson::getLessonId).collect(Collectors.toSet());

        List<WordPerformance> wordPerformances = wordPerformanceRepository.findByLearnerLearnerId(learnerId);
        wordPerformances = wordPerformances.stream()
                .filter(wp -> wp.getWord() != null && wp.getWord().getLesson() != null && visibleLessonIds.contains(wp.getWord().getLesson().getLessonId()))
                .collect(Collectors.toList());

        // Mastered words count in this scope
        long masteredCount;
        if (isClassScope) {
            masteredCount = wordPerformances.stream().filter(wp -> {
                if (wp.getWord() == null) return false;
                var dpOpt = difficultyProgressRepository.findByLearnerLearnerIdAndWordWordIdAndModuleNumber(learnerId, wp.getWord().getWordId(), 2);
                DifficultyLevel currentLevel = dpOpt.map(DifficultyProgress::getCurrentLevel).orElse(DifficultyLevel.LEARNING);
                return currentLevel == DifficultyLevel.MASTERED;
            }).count();
        } else {
            masteredCount = mastery != null && mastery.getWordsMasteredCount() != null ? mastery.getWordsMasteredCount() : 0;
        }

        // Compute struggling reasons
        List<String> strugglingReasons = new ArrayList<>();
        int totalDemerits = wordPerformances.stream().mapToInt(wp -> wp.getDemeritPoints() != null ? wp.getDemeritPoints() : 0).sum();
        int totalTierDrops = wordPerformances.stream().mapToInt(wp -> wp.getTierDropCount() != null ? wp.getTierDropCount() : 0).sum();
        BigDecimal accuracy;
        int totalAttempts;
        if (isClassScope) {
            int totAtt = wordPerformances.stream().mapToInt(wp -> wp.getTotalAttempts() != null ? wp.getTotalAttempts() : 0).sum();
            int totCorr = wordPerformances.stream().mapToInt(wp -> wp.getCorrectCount() != null ? wp.getCorrectCount() : 0).sum();
            accuracy = totAtt > 0 ? BigDecimal.valueOf(totCorr * 100.0 / totAtt).setScale(2, RoundingMode.HALF_UP) : (classAccuracy != null ? classAccuracy : BigDecimal.ZERO);
            totalAttempts = totAtt;
        } else {
            accuracy = mastery != null && mastery.getOverallAccuracy() != null ? mastery.getOverallAccuracy() : BigDecimal.ZERO;
            totalAttempts = mastery != null && mastery.getTotalQuestionsAnswered() != null ? mastery.getTotalQuestionsAnswered() : 0;
            if ((accuracy == null || accuracy.compareTo(BigDecimal.ZERO) == 0) && !wordPerformances.isEmpty()) {
                int totAtt = wordPerformances.stream().mapToInt(wp -> wp.getTotalAttempts() != null ? wp.getTotalAttempts() : 0).sum();
                int totCorr = wordPerformances.stream().mapToInt(wp -> wp.getCorrectCount() != null ? wp.getCorrectCount() : 0).sum();
                if (totAtt > 0) {
                    accuracy = BigDecimal.valueOf(totCorr * 100.0 / totAtt).setScale(2, RoundingMode.HALF_UP);
                    totalAttempts = totAtt;
                }
            }
        }

        if (totalAttempts >= 10 && accuracy.compareTo(BigDecimal.valueOf(70.0)) < 0) {
            strugglingReasons.add("Low overall accuracy (" + accuracy.setScale(1, RoundingMode.HALF_UP) + "% < 70%)");
        }
        if (totalDemerits >= 50) {
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

            List<AdminLearnerDetailResponse.ModuleScoreDetail> modDetails = lms.stream()
                    .map(m -> {
                        BigDecimal score = m.getScore();
                        if (score != null) {
                            score = score.min(BigDecimal.valueOf(100.00)).max(BigDecimal.ZERO);
                        }
                        Integer corr = m.getCorrectCount();
                        Integer tot = m.getTotalCount();
                        if (tot != null && tot > 0 && corr != null && corr > tot) {
                            corr = tot;
                        }
                        return AdminLearnerDetailResponse.ModuleScoreDetail.builder()
                                .moduleNumber(m.getModuleNumber())
                                .score(score)
                                .correctCount(corr)
                                .totalCount(tot)
                                .build();
                    })
                    .sorted(Comparator.comparingInt(m -> m.getModuleNumber() != null ? m.getModuleNumber() : 0))
                    .collect(Collectors.toList());

            BigDecimal m1 = null, m2 = null, m3 = null, m4 = null;
            for (AdminLearnerDetailResponse.ModuleScoreDetail md : modDetails) {
                if (md.getModuleNumber() != null) {
                    BigDecimal s = md.getScore();
                    if (s != null) {
                        s = s.min(BigDecimal.valueOf(100.00)).max(BigDecimal.ZERO);
                    }
                    if (md.getModuleNumber() == 1) m1 = s;
                    else if (md.getModuleNumber() == 2) m2 = s;
                    else if (md.getModuleNumber() == 3) m3 = s;
                    else if (md.getModuleNumber() == 4) m4 = s;
                }
            }

            List<WordPerformance> lPerfs = lessonPerfMap.getOrDefault(lesson.getLessonId(), List.of());
            int totAtt = lPerfs.stream().mapToInt(wp -> wp.getTotalAttempts() != null ? wp.getTotalAttempts() : 0).sum();
            int totCorr = lPerfs.stream().mapToInt(wp -> wp.getCorrectCount() != null ? wp.getCorrectCount() : 0).sum();

            double wordAccSum = 0.0;
            int wordsWithAcc = 0;
            for (WordPerformance wp : lPerfs) {
                if (wp.getAccuracy() != null && (wp.getTotalAttempts() == null || wp.getTotalAttempts() > 0)) {
                    wordAccSum += wp.getAccuracy().doubleValue();
                    wordsWithAcc++;
                }
            }

            BigDecimal displayScore = null;
            if (st != null && st.getStatus() == LessonStatus.COMPLETED && st.getMasteryScore() != null && st.getMasteryScore().compareTo(BigDecimal.ZERO) > 0) {
                displayScore = st.getMasteryScore();
            } else if (totAtt > 0) {
                displayScore = BigDecimal.valueOf(totCorr * 100.0 / totAtt).setScale(2, RoundingMode.HALF_UP);
            } else if (wordsWithAcc > 0) {
                displayScore = BigDecimal.valueOf(wordAccSum / wordsWithAcc).setScale(2, RoundingMode.HALF_UP);
            } else if (!lms.isEmpty()) {
                Optional<LessonModuleScore> mod4Opt = lms.stream()
                        .filter(m -> m.getModuleNumber() != null && m.getModuleNumber() == 4 && m.getScore() != null)
                        .findFirst();
                if (mod4Opt.isPresent()) {
                    displayScore = mod4Opt.get().getScore();
                } else {
                    double avg = lms.stream()
                            .filter(m -> m.getModuleNumber() != null && m.getModuleNumber() > 1 && m.getTotalCount() != null && m.getTotalCount() > 0 && m.getScore() != null)
                            .mapToDouble(m -> m.getScore().doubleValue())
                            .average()
                            .orElse(0.0);
                    if (avg > 0.0) {
                        displayScore = BigDecimal.valueOf(avg).setScale(2, RoundingMode.HALF_UP);
                    }
                }
            }
            if (displayScore != null) {
                displayScore = displayScore.min(BigDecimal.valueOf(100.00)).max(BigDecimal.ZERO);
            }

            OffsetDateTime lastPracticed = st != null ? (st.getCompletedAt() != null ? st.getCompletedAt() : st.getUpdatedAt()) : null;
            boolean bonusAwarded = st != null && (Boolean.TRUE.equals(st.getLessonCompletionBonusAwarded()) || Boolean.TRUE.equals(st.getPerfectScoreBonusAwarded()));

            return AdminLearnerDetailResponse.LearnerLessonProgressDetail.builder()
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

        // Pre-fetch all practice results for this learner to calculate authentic per-word lesson accuracy
        List<PracticeResult> allPracticeResults = practiceResultRepository.findBySessionLearnerLearnerId(learnerId);
        Map<UUID, List<PracticeResult>> resultsByWord = allPracticeResults.stream()
                .filter(pr -> pr.getWord() != null)
                .collect(Collectors.groupingBy(pr -> pr.getWord().getWordId()));

        java.util.function.Function<WordPerformance, AdminLearnerDetailResponse.LearnerWordPerformanceDetail> mapWordDetail = wp -> {
            UUID wordId = wp.getWord().getWordId();
            int totAtt = wp.getTotalAttempts() != null ? wp.getTotalAttempts() : 0;
            int totCorr = wp.getCorrectCount() != null ? wp.getCorrectCount() : 0;
            BigDecimal lifetimeAcc = totAtt > 0
                    ? BigDecimal.valueOf(totCorr * 100.0 / totAtt).setScale(2, RoundingMode.HALF_UP)
                    : BigDecimal.ZERO;

            // Self-heal corrupted WordPerformance.accuracy in DB if it was locked to 100% while errors were made
            if (totAtt > 0 && (wp.getAccuracy() == null || (totCorr < totAtt && wp.getAccuracy().compareTo(BigDecimal.valueOf(100.0)) == 0))) {
                wp.setAccuracy(lifetimeAcc);
                wordPerformanceRepository.save(wp);
            }

            // Determine authentic lesson accuracy from actual practice results
            UUID lessonId = wp.getWord().getLesson() != null ? wp.getWord().getLesson().getLessonId() : null;
            List<PracticeResult> wordResults = resultsByWord.getOrDefault(wordId, List.of());
            List<PracticeResult> lessonResults = (lessonId != null)
                    ? wordResults.stream().filter(pr -> pr.getSession() != null && pr.getSession().getLesson() != null && lessonId.equals(pr.getSession().getLesson().getLessonId())).collect(Collectors.toList())
                    : wordResults;

            BigDecimal lessonAcc;
            if (!lessonResults.isEmpty()) {
                Map<UUID, List<PracticeResult>> sessionMap = lessonResults.stream()
                        .filter(pr -> pr.getSession() != null)
                        .collect(Collectors.groupingBy(pr -> pr.getSession().getSessionId()));
                double maxSessionAcc = 0.0;
                for (List<PracticeResult> sResults : sessionMap.values()) {
                    long sCorr = sResults.stream().filter(pr -> Boolean.TRUE.equals(pr.getIsCorrect())).count();
                    double acc = (double) sCorr / sResults.size() * 100.0;
                    if (acc > maxSessionAcc) {
                        maxSessionAcc = acc;
                    }
                }
                lessonAcc = BigDecimal.valueOf(maxSessionAcc).setScale(2, RoundingMode.HALF_UP);
            } else {
                // Check lesson_word_accuracy if available
                BigDecimal lwaBest = null;
                if (lessonId != null) {
                    var lwaOpt = lessonWordAccuracyRepository.findByLearnerLearnerIdAndLessonLessonIdAndWordWordId(learnerId, lessonId, wordId);
                    if (lwaOpt.isPresent() && lwaOpt.get().getBestAccuracy() != null) {
                        BigDecimal candidate = lwaOpt.get().getBestAccuracy();
                        if (candidate.compareTo(BigDecimal.valueOf(100.0)) < 0 || totCorr == totAtt) {
                            lwaBest = candidate;
                        }
                    }
                }
                lessonAcc = lwaBest != null ? lwaBest : lifetimeAcc;
            }

            return AdminLearnerDetailResponse.LearnerWordPerformanceDetail.builder()
                    .wordId(wordId)
                    .englishWord(wp.getWord().getEnglishWord())
                    .cebuanoMeaning(wp.getWord().getCebuanoMeaning())
                    .partOfSpeech(wp.getWord().getPartOfSpeech() != null ? wp.getWord().getPartOfSpeech() : "NOUN")
                    .lessonTitle(wp.getWord().getLesson() != null ? wp.getWord().getLesson().getLessonTitle() : "")
                    .accuracy(lessonAcc)
                    .lessonAccuracy(lessonAcc)
                    .lifetimeAccuracy(lifetimeAcc)
                    .totalAttempts(totAtt)
                    .correctCount(wp.getCorrectCount())
                    .incorrectCount(wp.getIncorrectCount())
                    .demeritPoints(wp.getDemeritPoints())
                    .tierDropCount(wp.getTierDropCount())
                    .fallbackCount(wp.getFallbackCount())
                    .lastPracticedAt(wp.getLastPracticedAt())
                    .build();
        };

        // Build Weak words (accuracy < 70% or demeritPoints > 0)
        List<AdminLearnerDetailResponse.LearnerWordPerformanceDetail> weakWords = wordPerformances.stream()
                .filter(wp -> (wp.getDemeritPoints() != null && wp.getDemeritPoints() > 0) ||
                              (wp.getTotalAttempts() != null && wp.getTotalAttempts() > 0 && 
                               (wp.getCorrectCount() * 100.0 / wp.getTotalAttempts()) < 70.0))
                .sorted(Comparator.comparing((WordPerformance wp) -> wp.getDemeritPoints() != null ? wp.getDemeritPoints() : 0).reversed()
                        .thenComparing(wp -> wp.getAccuracy() != null ? wp.getAccuracy() : BigDecimal.ZERO))
                .map(mapWordDetail)
                .collect(Collectors.toList());

        // Full Word-by-Word diagnostic list for teacher & admin
        List<AdminLearnerDetailResponse.LearnerWordPerformanceDetail> allWords = wordPerformances.stream()
                .filter(wp -> wp.getWord() != null)
                .sorted(Comparator.comparing((WordPerformance wp) -> {
                    int att = wp.getTotalAttempts() != null ? wp.getTotalAttempts() : 0;
                    int corr = wp.getCorrectCount() != null ? wp.getCorrectCount() : 0;
                    return att > 0 ? (double) corr / att : 0.0;
                }))
                .map(mapWordDetail)
                .collect(Collectors.toList());

        // Part of Speech (POS) accuracy breakdown for this student
        Map<String, List<WordPerformance>> byPos = wordPerformances.stream()
                .filter(wp -> wp.getWord() != null && wp.getWord().getPartOfSpeech() != null && !wp.getWord().getPartOfSpeech().isBlank())
                .collect(Collectors.groupingBy(wp -> wp.getWord().getPartOfSpeech().trim().toUpperCase()));

        List<AdminLearnerDetailResponse.PosAccuracyDetail> posBreakdown = new ArrayList<>();
        for (Map.Entry<String, List<WordPerformance>> entry : byPos.entrySet()) {
            String pos = entry.getKey();
            List<WordPerformance> wList = entry.getValue();
            int totAtt = wList.stream().mapToInt(wp -> wp.getTotalAttempts() != null ? wp.getTotalAttempts() : 0).sum();
            int totCorr = wList.stream().mapToInt(wp -> wp.getCorrectCount() != null ? wp.getCorrectCount() : 0).sum();
            double posWordAccSum = 0.0;
            int posWordsWithAcc = 0;
            for (WordPerformance wp : wList) {
                if (wp.getAccuracy() != null && (wp.getTotalAttempts() == null || wp.getTotalAttempts() > 0)) {
                    posWordAccSum += wp.getAccuracy().doubleValue();
                    posWordsWithAcc++;
                }
            }
            BigDecimal posAcc = totAtt > 0
                    ? BigDecimal.valueOf(totCorr * 100.0 / totAtt).setScale(2, RoundingMode.HALF_UP)
                    : (posWordsWithAcc > 0 ? BigDecimal.valueOf(posWordAccSum / posWordsWithAcc).setScale(2, RoundingMode.HALF_UP) : BigDecimal.ZERO);

            posBreakdown.add(AdminLearnerDetailResponse.PosAccuracyDetail.builder()
                    .partOfSpeech(pos)
                    .totalWords(wList.size())
                    .totalAttempts(totAtt)
                    .correctCount(totCorr)
                    .accuracy(posAcc)
                    .build());
        }
        posBreakdown.sort(Comparator.comparing(AdminLearnerDetailResponse.PosAccuracyDetail::getAccuracy).reversed());

        // Cumulative reviews for this learner - only real completed mobile sessions (excluded for class/teacher POV)
        List<CumulativeReviewSession> cumSessions = isClassScope
                ? Collections.emptyList()
                : cumulativeReviewSessionRepository.findByLearnerLearnerIdOrderByStartTimeDesc(learnerId);

        List<CumulativeReviewSession> completedCum = cumSessions.stream()
                .filter(cs -> "COMPLETED".equalsIgnoreCase(cs.getSessionStatus()))
                .collect(Collectors.toList());

        BigDecimal avgCumScore = null;
        if (!completedCum.isEmpty()) {
            double avgScore = completedCum.stream()
                    .filter(cs -> cs.getAccuracyPercent() != null)
                    .mapToDouble(cs -> cs.getAccuracyPercent().doubleValue())
                    .average()
                    .orElse(0.0);
            avgCumScore = BigDecimal.valueOf(avgScore).setScale(2, RoundingMode.HALF_UP);
        }

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

        List<AdminLearnerDetailResponse.CumulativeReviewPerformanceDetail> cumDetails = cumSessions.stream().map(cs -> {
            return AdminLearnerDetailResponse.CumulativeReviewPerformanceDetail.builder()
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
                .userId(learner.getUserId())
                .displayName(learner.getDisplayName())
                .age(learner.getAge())
                .gradeLevel(learner.getGradeLevel() != null ? learner.getGradeLevel().name() : null)
                .sectionId(learner.getSection() != null ? learner.getSection().getSectionId() : null)
                .sectionName(learner.getSection() != null ? learner.getSection().getSectionName() : null)
                .languagePreference(learner.getLanguagePreference() != null ? learner.getLanguagePreference().name() : null)
                .posFocus(learner.getPosFocus())
                .avatar(learner.getAvatar())
                .isActive(learner.getIsActive())
                .createdAt(learner.getCreatedAt())
                .updatedAt(learner.getUpdatedAt())
                .lastActiveAt(lastActiveAt)
                .masteryLevel(isClassScope ? (classMasteryLevel != null ? classMasteryLevel : "LEARNING") : (mastery != null ? mastery.getMasteryLevel() : "LEARNING"))
                .totalPoints(isClassScope ? (classPoints != null ? classPoints : 0) : (mastery != null && mastery.getTotalPoints() != null ? mastery.getTotalPoints() : 0))
                .overallAccuracy(isClassScope ? (classAccuracy != null ? classAccuracy : BigDecimal.ZERO) : (mastery != null && mastery.getOverallAccuracy() != null && mastery.getOverallAccuracy().compareTo(BigDecimal.ZERO) > 0 ? mastery.getOverallAccuracy() : accuracy))
                .wordsMasteredCount((int) masteredCount)
                .totalSessionsPlayed(isClassScope ? (classSessionsPlayed != null ? classSessionsPlayed : 0) : (mastery != null && mastery.getTotalSessionsPlayed() != null ? mastery.getTotalSessionsPlayed() : 0))
                .totalQuestionsAnswered(isClassScope ? wordPerformances.stream().mapToInt(wp -> wp.getTotalAttempts() != null ? wp.getTotalAttempts() : 0).sum() : (mastery != null && mastery.getTotalQuestionsAnswered() != null ? mastery.getTotalQuestionsAnswered() : 0))
                .totalCorrectAnswers(isClassScope ? wordPerformances.stream().mapToInt(wp -> wp.getCorrectCount() != null ? wp.getCorrectCount() : 0).sum() : (mastery != null && mastery.getTotalCorrectAnswers() != null ? mastery.getTotalCorrectAnswers() : 0))
                .isStruggling(isStruggling)
                .strugglingReasons(strugglingReasons)
                .lessons(lessonDetails)
                .weakWords(weakWords)
                .allWords(allWords)
                .posBreakdown(posBreakdown)
                .classId(resolvedClassId)
                .className(resolvedClassName)
                .classCode(resolvedClassCode)
                .classPoints(classPoints)
                .classAccuracy(classAccuracy)
                .classMasteryLevel(classMasteryLevel)
                .classSessionsPlayed(classSessionsPlayed)
                .enrolledClasses(enrolledClassDetails)
                .cumulativeReviewsCompleted(completedCum.size())
                .avgCumulativeScore(avgCumScore)
                .bestCumulativeBadge(bestCumBadge)
                .cumulativeReviews(cumDetails)
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
    public void deleteLearner(UUID learnerId, UUID adminId) {
        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner not found: " + learnerId));
        String displayName = learner.getDisplayName();
        learnerRepository.delete(learner);

        if (adminId != null) {
            auditLogRepository.save(AdminAuditLog.builder()
                    .adminId(adminId)
                    .action("DELETE_LEARNER")
                    .targetId(learnerId)
                    .details("Permanently deleted student account: " + displayName)
                    .build());
        }
    }

    @Transactional
    public void resetLearnerProgress(UUID learnerId, UUID lessonId, UUID adminId) {
        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner not found: " + learnerId));

        if (lessonId == null) {
            // Full Reset - wipes all progress, class performance, cumulative reviews, queues, and mastery
            learnerService.resetProgress(learnerId);

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
            lessonWordAccuracyRepository.deleteByLearnerLearnerIdAndLessonLessonId(learnerId, lessonId);

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
                            if (req.getSectionId() != null) {
                                Section section = sectionRepository.findById(req.getSectionId()).orElse(null);
                                if (section != null) {
                                    learner.setSection(section);
                                } else {
                                    com.vocaboo.entity.Classroom classroom = classroomRepository.findById(req.getSectionId()).orElse(null);
                                    if (classroom != null) {
                                        java.util.Optional<com.vocaboo.entity.ClassEnrollment> existingOpt =
                                                classEnrollmentRepository.findByClassroomClassIdAndLearnerLearnerId(classroom.getClassId(), learner.getLearnerId());
                                        if (existingOpt.isPresent()) {
                                            com.vocaboo.entity.ClassEnrollment enrollment = existingOpt.get();
                                            enrollment.setStatus("ACTIVE");
                                            classEnrollmentRepository.save(enrollment);
                                        } else {
                                            com.vocaboo.entity.ClassEnrollment enrollment = com.vocaboo.entity.ClassEnrollment.builder()
                                                    .classroom(classroom)
                                                    .learner(learner)
                                                    .status("ACTIVE")
                                                    .invitedByTeacher(classroom.getTeacher())
                                                    .build();
                                            classEnrollmentRepository.save(enrollment);
                                        }
                                        String cName = classroom.getName();
                                        if (cName != null) {
                                            if (cName.contains("Grade 4") || cName.contains("Grade_4")) {
                                                learner.setGradeLevel(com.vocaboo.entity.GradeLevel.GRADE_4);
                                            } else if (cName.contains("Grade 5") || cName.contains("Grade_5")) {
                                                learner.setGradeLevel(com.vocaboo.entity.GradeLevel.GRADE_5);
                                            } else if (cName.contains("Grade 6") || cName.contains("Grade_6")) {
                                                learner.setGradeLevel(com.vocaboo.entity.GradeLevel.GRADE_6);
                                            }
                                        }
                                    }
                                }
                            } else {
                                learner.setSection(null);
                            }
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
        return toSummaryResponse(learner, null, null);
    }

    public AdminLearnerSummaryResponse toSummaryResponse(Learner learner, UUID sectionId) {
        return toSummaryResponse(learner, sectionId, null);
    }

    public AdminLearnerSummaryResponse toSummaryResponse(Learner learner, UUID sectionId, UUID teacherId) {
        LearnerMastery mastery = masteryRepository.findByLearnerLearnerId(learner.getLearnerId()).orElse(null);
        List<LearnerLessonStatus> statuses = lessonStatusRepository.findByLearnerLearnerId(learner.getLearnerId());
        List<WordPerformance> wordPerformances = wordPerformanceRepository.findByLearnerLearnerId(learner.getLearnerId());

        com.vocaboo.entity.ClassPerformance classPerf = null;
        if (sectionId != null) {
            classPerf = classPerformanceRepository.findByLearnerLearnerIdAndClassroomClassId(learner.getLearnerId(), sectionId).orElse(null);
        } else if (teacherId != null) {
            List<com.vocaboo.entity.Classroom> teacherClasses = classroomRepository.findByTeacherTeacherId(teacherId);
            Set<UUID> teacherClassIds = teacherClasses.stream().map(com.vocaboo.entity.Classroom::getClassId).collect(Collectors.toSet());
            List<com.vocaboo.entity.ClassPerformance> cpList = classPerformanceRepository.findByLearnerLearnerId(learner.getLearnerId()).stream()
                    .filter(cp -> cp.getClassroom() != null && teacherClassIds.contains(cp.getClassroom().getClassId()))
                    .collect(Collectors.toList());
            if (!cpList.isEmpty()) {
                int totalPts = cpList.stream().mapToInt(cp -> cp.getClassPoints() != null ? cp.getClassPoints() : 0).sum();
                int totalQ = cpList.stream().mapToInt(cp -> cp.getClassTotalQuestions() != null ? cp.getClassTotalQuestions() : 0).sum();
                int totalC = cpList.stream().mapToInt(cp -> cp.getClassCorrectAnswers() != null ? cp.getClassCorrectAnswers() : 0).sum();
                int totalS = cpList.stream().mapToInt(cp -> cp.getClassSessionsPlayed() != null ? cp.getClassSessionsPlayed() : 0).sum();
                BigDecimal acc = totalQ > 0 ? BigDecimal.valueOf(totalC * 100.0 / totalQ).setScale(2, RoundingMode.HALF_UP) : BigDecimal.ZERO;
                com.vocaboo.entity.ClassPerformance merged = new com.vocaboo.entity.ClassPerformance();
                merged.setClassPoints(totalPts);
                merged.setClassTotalQuestions(totalQ);
                merged.setClassCorrectAnswers(totalC);
                merged.setClassSessionsPlayed(totalS);
                merged.setClassAccuracy(acc);
                merged.setClassMasteryLevel(cpList.get(0).getClassMasteryLevel());
                classPerf = merged;
            }
        }

        final boolean isScoped = (sectionId != null || teacherId != null);

        int completedLessons = (int) statuses.stream()
                .filter(s -> s.getStatus() == LessonStatus.COMPLETED)
                .count();

        int totalDemerits = wordPerformances.stream().mapToInt(wp -> wp.getDemeritPoints() != null ? wp.getDemeritPoints() : 0).sum();
        int totalTierDrops = wordPerformances.stream().mapToInt(wp -> wp.getTierDropCount() != null ? wp.getTierDropCount() : 0).sum();

        BigDecimal accuracy;
        int totalAttempts;
        if (isScoped) {
            accuracy = classPerf != null && classPerf.getClassAccuracy() != null ? classPerf.getClassAccuracy() : BigDecimal.ZERO;
            totalAttempts = classPerf != null && classPerf.getClassTotalQuestions() != null ? classPerf.getClassTotalQuestions() : 0;
        } else {
            accuracy = mastery != null && mastery.getOverallAccuracy() != null ? mastery.getOverallAccuracy() : BigDecimal.ZERO;
            totalAttempts = mastery != null && mastery.getTotalQuestionsAnswered() != null ? mastery.getTotalQuestionsAnswered() : 0;
        }

        boolean isStruggling = (totalAttempts >= 10 && accuracy.compareTo(BigDecimal.valueOf(70.0)) < 0) ||
                               totalDemerits >= 50 ||
                               totalTierDrops >= 3;

        OffsetDateTime lastActiveAt = resolveLastActiveAt(learner.getLearnerId(), learner.getUpdatedAt(), wordPerformances, statuses);

        // Cumulative reviews for this learner - only real completed mobile sessions (excluded for teacher POV)
        List<CumulativeReviewSession> cumSessions = teacherId != null
                ? Collections.emptyList()
                : cumulativeReviewSessionRepository.findByLearnerLearnerIdOrderByStartTimeDesc(learner.getLearnerId());

        List<CumulativeReviewSession> completedCum = cumSessions.stream()
                .filter(cs -> "COMPLETED".equalsIgnoreCase(cs.getSessionStatus()))
                .collect(Collectors.toList());

        BigDecimal avgCum = null;
        if (!completedCum.isEmpty()) {
            double avgScore = completedCum.stream()
                    .filter(cs -> cs.getAccuracyPercent() != null)
                    .mapToDouble(cs -> cs.getAccuracyPercent().doubleValue())
                    .average()
                    .orElse(0.0);
            avgCum = BigDecimal.valueOf(avgScore).setScale(2, RoundingMode.HALF_UP);
        }

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

        int pointsVal;
        BigDecimal accVal;
        int lessonsVal;
        String masteryVal;

        if (isScoped) {
            pointsVal = classPerf != null && classPerf.getClassPoints() != null ? classPerf.getClassPoints() : 0;
            accVal = classPerf != null && classPerf.getClassAccuracy() != null ? classPerf.getClassAccuracy() : BigDecimal.ZERO;
            lessonsVal = classPerf != null && classPerf.getClassSessionsPlayed() != null ? classPerf.getClassSessionsPlayed() : 0;
            masteryVal = classPerf != null && classPerf.getClassMasteryLevel() != null ? classPerf.getClassMasteryLevel() : "LEARNING";
        } else {
            pointsVal = mastery != null && mastery.getTotalPoints() != null ? mastery.getTotalPoints() : 0;
            accVal = mastery != null && mastery.getOverallAccuracy() != null ? mastery.getOverallAccuracy() : BigDecimal.ZERO;
            if ((accVal == null || accVal.compareTo(BigDecimal.ZERO) == 0) && !wordPerformances.isEmpty()) {
                int totAtt = wordPerformances.stream().mapToInt(wp -> wp.getTotalAttempts() != null ? wp.getTotalAttempts() : 0).sum();
                int totCorr = wordPerformances.stream().mapToInt(wp -> wp.getCorrectCount() != null ? wp.getCorrectCount() : 0).sum();
                if (totAtt > 0) {
                    accVal = BigDecimal.valueOf(totCorr * 100.0 / totAtt).setScale(2, RoundingMode.HALF_UP);
                    accuracy = accVal;
                    totalAttempts = totAtt;
                }
            }
            lessonsVal = completedLessons;
            masteryVal = mastery != null && mastery.getMasteryLevel() != null ? mastery.getMasteryLevel() : "LEARNING";
        }

        UUID resSecId = learner.getSection() != null ? learner.getSection().getSectionId() : null;
        String resSecName = learner.getSection() != null ? learner.getSection().getSectionName() : null;

        if (resSecName == null) {
            if (sectionId != null) {
                resSecId = sectionId;
                resSecName = classroomRepository.findById(sectionId).map(com.vocaboo.entity.Classroom::getName).orElse(null);
            }
            if (resSecName == null) {
                List<com.vocaboo.entity.ClassEnrollment> enrollments = classEnrollmentRepository.findByLearnerLearnerIdAndStatus(learner.getLearnerId(), "ACTIVE");
                if (!enrollments.isEmpty() && enrollments.get(0).getClassroom() != null) {
                    resSecId = enrollments.get(0).getClassroom().getClassId();
                    resSecName = enrollments.get(0).getClassroom().getName();
                }
            }
        }

        int masteredWords;
        if (isScoped) {
            Set<UUID> visibleLessonIds;
            if (sectionId != null) {
                visibleLessonIds = lessonRepository.findByClassroomClassIdAndIsDeletedFalseOrderByLessonOrderAsc(sectionId).stream().map(Lesson::getLessonId).collect(Collectors.toSet());
            } else {
                visibleLessonIds = lessonRepository.findByClassroomTeacherTeacherIdAndIsDeletedFalseOrderByLessonOrderAsc(teacherId).stream().map(Lesson::getLessonId).collect(Collectors.toSet());
            }
            masteredWords = (int) wordPerformances.stream().filter(wp -> {
                if (wp.getWord() == null || wp.getWord().getLesson() == null || !visibleLessonIds.contains(wp.getWord().getLesson().getLessonId())) return false;
                var dpOpt = difficultyProgressRepository.findByLearnerLearnerIdAndWordWordIdAndModuleNumber(learner.getLearnerId(), wp.getWord().getWordId(), 2);
                DifficultyLevel currentLevel = dpOpt.map(DifficultyProgress::getCurrentLevel).orElse(DifficultyLevel.LEARNING);
                return currentLevel == DifficultyLevel.MASTERED;
            }).count();
        } else {
            masteredWords = mastery != null && mastery.getWordsMasteredCount() != null ? mastery.getWordsMasteredCount() : 0;
        }

        return AdminLearnerSummaryResponse.builder()
                .learnerId(learner.getLearnerId())
                .userId(learner.getUserId())
                .displayName(learner.getDisplayName())
                .age(learner.getAge())
                .gradeLevel(learner.getGradeLevel() != null ? learner.getGradeLevel().name() : null)
                .sectionId(resSecId)
                .sectionName(resSecName)
                .languagePreference(learner.getLanguagePreference() != null ? learner.getLanguagePreference().name() : null)
                .avatar(learner.getAvatar())
                .isActive(learner.getIsActive())
                .masteryLevel(masteryVal)
                .totalPoints(pointsVal)
                .overallAccuracy(accVal)
                .completedLessonsCount(lessonsVal)
                .wordsMasteredCount(masteredWords)
                .classPoints(classPerf != null ? classPerf.getClassPoints() : null)
                .classAccuracy(classPerf != null ? classPerf.getClassAccuracy() : null)
                .classMasteryLevel(classPerf != null ? classPerf.getClassMasteryLevel() : null)
                .classSessionsPlayed(classPerf != null ? classPerf.getClassSessionsPlayed() : null)
                .cumulativeReviewsCompleted(completedCum.size())
                .avgCumulativeScore(avgCum)
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

    private String resolveSectionName(Learner learner) {
        if (learner == null) return "Independent";
        if (learner.getSection() != null && learner.getSection().getSectionName() != null) {
            return learner.getSection().getSectionName();
        }
        try {
            List<com.vocaboo.entity.ClassEnrollment> enrollments = classEnrollmentRepository.findByLearnerLearnerIdAndStatus(learner.getLearnerId(), "ACTIVE");
            if (!enrollments.isEmpty() && enrollments.get(0).getClassroom() != null && enrollments.get(0).getClassroom().getName() != null) {
                return enrollments.get(0).getClassroom().getName();
            }
        } catch (Exception ignored) {}
        return "Independent";
    }

    @Transactional(readOnly = true)
    public List<com.vocaboo.dto.response.FlaggedLearnerResponse> getFlaggedLearners(UUID sectionId, GradeLevel gradeLevel) {
        return getFlaggedLearners(sectionId, gradeLevel, null);
    }

    @Transactional(readOnly = true)
    public List<com.vocaboo.dto.response.FlaggedLearnerResponse> getFlaggedLearners(UUID sectionId, GradeLevel gradeLevel, UUID teacherId) {
        List<DifficultyProgress> progressList = difficultyProgressRepository.findAll();

        List<UUID> enrolledIds = null;
        if (teacherId != null) {
            enrolledIds = new ArrayList<>(classEnrollmentRepository.findEnrolledLearnerIdsByTeacherId(teacherId));
            if (sectionId != null) {
                List<UUID> classEnrolledIds = classEnrollmentRepository.findEnrolledLearnerIdsByClassId(sectionId);
                enrolledIds.retainAll(classEnrolledIds);
            }
            if (enrolledIds.isEmpty()) {
                return Collections.emptyList();
            }
        } else if (sectionId != null) {
            List<UUID> classEnrolledIds = classEnrollmentRepository.findEnrolledLearnerIdsByClassId(sectionId);
            if (!classEnrolledIds.isEmpty()) {
                enrolledIds = new ArrayList<>(classEnrolledIds);
            }
        }

        if (enrolledIds != null) {
            final List<UUID> finalIds = enrolledIds;
            progressList = progressList.stream()
                    .filter(dp -> dp.getLearner() != null && finalIds.contains(dp.getLearner().getLearnerId()))
                    .collect(Collectors.toList());
        } else if (sectionId != null) {
            progressList = progressList.stream()
                    .filter(dp -> dp.getLearner() != null && dp.getLearner().getSection() != null && sectionId.equals(dp.getLearner().getSection().getSectionId()))
                    .collect(Collectors.toList());
        }
        if (gradeLevel != null) {
            progressList = progressList.stream()
                    .filter(dp -> dp.getLearner() != null && dp.getLearner().getGradeLevel() == gradeLevel)
                    .collect(Collectors.toList());
        }

        List<com.vocaboo.dto.response.FlaggedLearnerResponse> responses = new ArrayList<>();
        Set<String> processedKeys = new HashSet<>();

        // 1. Process DifficultyProgress flagged items
        for (DifficultyProgress dp : progressList) {
            Learner learner = dp.getLearner();
            VocabularyWord word = dp.getWord();
            if (learner == null || word == null) continue;

            boolean isFlagged = Boolean.TRUE.equals(dp.getNeedsTeacherReview())
                    || (dp.getReintroductionCount() != null && dp.getReintroductionCount() >= 2);

            if (!isFlagged) continue;

            String key = learner.getLearnerId() + "_" + word.getWordId();
            processedKeys.add(key);

            WordPerformance perf = wordPerformanceRepository
                    .findByLearnerLearnerIdAndWordWordId(learner.getLearnerId(), word.getWordId())
                    .orElse(null);

            int reintroCount = dp.getReintroductionCount() != null ? dp.getReintroductionCount() : 0;
            String reason = "Excessive errors at LEARNING floor (" + reintroCount + " visual reintroductions triggered)";

            responses.add(com.vocaboo.dto.response.FlaggedLearnerResponse.builder()
                    .progressId(dp.getProgressId())
                    .learnerId(learner.getLearnerId())
                    .learnerName(learner.getDisplayName())
                    .username(learner.getUserId() != null ? learner.getUserId() : learner.getLearnerId().toString().substring(0, 8))
                    .sectionName(resolveSectionName(learner))
                    .gradeLevel(learner.getGradeLevel() != null ? learner.getGradeLevel().name() : "")
                    .wordId(word.getWordId())
                    .englishWord(word.getEnglishWord())
                    .cebuanoMeaning(word.getCebuanoMeaning())
                    .partOfSpeech(word.getPartOfSpeech())
                    .lessonId(word.getLesson() != null ? word.getLesson().getLessonId() : null)
                    .lessonTitle(word.getLesson() != null ? word.getLesson().getLessonTitle() : "Unknown Lesson")
                    .reintroductionCount(reintroCount)
                    .consecutiveIncorrect(dp.getConsecutiveIncorrect())
                    .currentLevel(dp.getCurrentLevel() != null ? dp.getCurrentLevel().name() : "LEARNING")
                    .flaggedAt(dp.getLastReintroducedAt() != null ? dp.getLastReintroducedAt() : dp.getUpdatedAt())
                    .flagReason(reason)
                    .totalAttempts(perf != null ? perf.getTotalAttempts() : dp.getAttemptCountAtCurrentTier())
                    .accuracy(perf != null && perf.getAccuracy() != null ? perf.getAccuracy() : BigDecimal.ZERO)
                    .build());
        }

        // 2. Process severe struggles from WordPerformance (high demerits or low accuracy)
        List<WordPerformance> performances = wordPerformanceRepository.findAll();
        for (WordPerformance wp : performances) {
            Learner learner = wp.getLearner();
            VocabularyWord word = wp.getWord();
            if (learner == null || word == null) continue;

            if (enrolledIds != null) {
                if (!enrolledIds.contains(learner.getLearnerId())) continue;
            } else if (sectionId != null) {
                if (learner.getSection() == null || !sectionId.equals(learner.getSection().getSectionId())) continue;
            }

            if (gradeLevel != null) {
                if (learner.getGradeLevel() != gradeLevel) continue;
            }

            String key = learner.getLearnerId() + "_" + word.getWordId();
            if (processedKeys.contains(key)) continue;

            int demerits = wp.getDemeritPoints() != null ? wp.getDemeritPoints() : 0;
            int totalAttempts = wp.getTotalAttempts() != null ? wp.getTotalAttempts() : 0;
            BigDecimal accuracy = wp.getAccuracy() != null ? wp.getAccuracy() : BigDecimal.ZERO;
            int incorrectCount = wp.getIncorrectCount() != null ? wp.getIncorrectCount() : 0;

            boolean severeStruggle = demerits >= 20 || (totalAttempts >= 3 && accuracy.compareTo(BigDecimal.valueOf(60.0)) < 0 && incorrectCount >= 2);
            if (!severeStruggle) continue;

            processedKeys.add(key);

            String reason;
            if (demerits >= 20) {
                reason = "High error severity (" + demerits + " demerit points accumulated)";
            } else {
                reason = "Low accuracy (" + accuracy.setScale(1, RoundingMode.HALF_UP) + "% with " + incorrectCount + " mistakes)";
            }

            responses.add(com.vocaboo.dto.response.FlaggedLearnerResponse.builder()
                    .progressId(wp.getPerformanceId())
                    .learnerId(learner.getLearnerId())
                    .learnerName(learner.getDisplayName())
                    .username(learner.getUserId() != null ? learner.getUserId() : learner.getLearnerId().toString().substring(0, 8))
                    .sectionName(resolveSectionName(learner))
                    .gradeLevel(learner.getGradeLevel() != null ? learner.getGradeLevel().name() : "")
                    .wordId(word.getWordId())
                    .englishWord(word.getEnglishWord())
                    .cebuanoMeaning(word.getCebuanoMeaning())
                    .partOfSpeech(word.getPartOfSpeech())
                    .lessonId(word.getLesson() != null ? word.getLesson().getLessonId() : null)
                    .lessonTitle(word.getLesson() != null ? word.getLesson().getLessonTitle() : "Unknown Lesson")
                    .reintroductionCount(0)
                    .consecutiveIncorrect(incorrectCount)
                    .currentLevel("LEARNING")
                    .flaggedAt(wp.getLastPracticedAt() != null ? wp.getLastPracticedAt() : wp.getUpdatedAt())
                    .flagReason(reason)
                    .totalAttempts(totalAttempts)
                    .accuracy(accuracy)
                    .build());
        }

        // Sort: most recent or highest error severity first
        responses.sort((a, b) -> {
            if (a.getFlaggedAt() != null && b.getFlaggedAt() != null) {
                return b.getFlaggedAt().compareTo(a.getFlaggedAt());
            }
            return 0;
        });

        return responses;
    }

    @Transactional
    public void resolveFlaggedLearner(UUID progressId, String adminEmail) {
        difficultyProgressRepository.findById(progressId).ifPresent(dp -> {
            dp.setNeedsTeacherReview(false);
            dp.setReintroductionCount(0);
            dp.setConsecutiveIncorrect(0);
            dp.setUpdatedAt(OffsetDateTime.now());
            difficultyProgressRepository.save(dp);
        });
        wordPerformanceRepository.findById(progressId).ifPresent(wp -> {
            wp.setDemeritPoints(0);
            wp.setUpdatedAt(OffsetDateTime.now());
            wordPerformanceRepository.save(wp);
        });
    }
}
