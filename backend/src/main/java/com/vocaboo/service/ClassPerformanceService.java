package com.vocaboo.service;

import com.vocaboo.dto.response.ClassPerformanceResponse;
import com.vocaboo.dto.response.LeaderboardEntryResponse;
import com.vocaboo.entity.ClassEnrollment;
import com.vocaboo.entity.ClassPerformance;
import com.vocaboo.entity.Classroom;
import com.vocaboo.entity.Learner;
import com.vocaboo.repository.ClassEnrollmentRepository;
import com.vocaboo.repository.ClassPerformanceRepository;
import com.vocaboo.repository.ClassroomRepository;
import com.vocaboo.repository.LearnerRepository;
import com.vocaboo.repository.PointTransactionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Manages class-scoped performance stats.
 *
 * Design contract:
 *  - Class activity ALWAYS also updates LearnerMastery (global). That happens in
 *    PracticeSessionService / SessionSummaryService as before.
 *  - This service is called ADDITIONALLY when classroomContextId is present to
 *    write the parallel class-scoped row in class_performance.
 */
@Service
@RequiredArgsConstructor
public class ClassPerformanceService {

    private final ClassPerformanceRepository classPerformanceRepository;
    private final ClassroomRepository classroomRepository;
    private final LearnerRepository learnerRepository;
    private final PointTransactionRepository pointTransactionRepository;
    private final ClassEnrollmentRepository classEnrollmentRepository;

    /**
     * Get-or-create the ClassPerformance record for a (learner, classroom) pair.
     */
    @Transactional
    public ClassPerformance getOrCreate(UUID learnerId, UUID classroomId) {
        return classPerformanceRepository
                .findByLearnerLearnerIdAndClassroomClassId(learnerId, classroomId)
                .orElseGet(() -> {
                    Learner learner = learnerRepository.findById(learnerId)
                            .orElseThrow(() -> new IllegalArgumentException("Learner not found"));
                    Classroom classroom = classroomRepository.findById(classroomId)
                            .orElseThrow(() -> new IllegalArgumentException("Classroom not found"));
                    ClassPerformance cp = ClassPerformance.builder()
                            .learner(learner)
                            .classroom(classroom)
                            .build();
                    return classPerformanceRepository.save(cp);
                });
    }

    /**
     * Update class-scoped performance after each answer in a class-context session.
     * Called alongside the global LearnerMastery update.
     *
     * @param learnerId     the learner
     * @param classroomId   the classroom context UUID
     * @param pointsEarned  points for this answer (0 if wrong)
     * @param isCorrect     whether the answer was correct
     * @param totalQuestions number of questions attempted (usually 1, increment)
     */
    @Transactional
    public void updateAfterAnswer(UUID learnerId, UUID classroomId,
                                  int pointsEarned, boolean isCorrect, int totalQuestions) {
        ClassPerformance cp = getOrCreate(learnerId, classroomId);

        cp.setClassPoints(cp.getClassPoints() + pointsEarned);
        cp.setClassTotalQuestions(cp.getClassTotalQuestions() + totalQuestions);
        if (isCorrect) {
            cp.setClassCorrectAnswers(cp.getClassCorrectAnswers() + 1);
        }

        BigDecimal accuracy = cp.getClassTotalQuestions() > 0
                ? BigDecimal.valueOf(cp.getClassCorrectAnswers() * 100.0 / cp.getClassTotalQuestions())
                        .setScale(2, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;
        cp.setClassAccuracy(accuracy);
        cp.setClassMasteryLevel(resolveMasteryLevel(accuracy));
        cp.setUpdatedAt(OffsetDateTime.now());

        classPerformanceRepository.save(cp);
    }

    /**
     * Increment session count after a class-context session ends.
     */
    @Transactional
    public void incrementSessionCount(UUID learnerId, UUID classroomId) {
        ClassPerformance cp = getOrCreate(learnerId, classroomId);
        cp.setClassSessionsPlayed(cp.getClassSessionsPlayed() + 1);
        cp.setUpdatedAt(OffsetDateTime.now());
        classPerformanceRepository.save(cp);
    }

    /**
     * Add bonus points (lesson completion, perfect score) to the class performance row.
     */
    @Transactional
    public void addBonusPoints(UUID learnerId, UUID classroomId, int bonusPoints) {
        if (bonusPoints <= 0) return;
        ClassPerformance cp = getOrCreate(learnerId, classroomId);
        cp.setClassPoints(cp.getClassPoints() + bonusPoints);
        cp.setUpdatedAt(OffsetDateTime.now());
        classPerformanceRepository.save(cp);
    }

    /**
     * Returns the class performance summary for a learner in a specific class.
     */
    @Transactional(readOnly = true)
    public Optional<ClassPerformanceResponse> getPerformanceSummary(UUID learnerId, UUID classroomId) {
        return classPerformanceRepository
                .findByLearnerLearnerIdAndClassroomClassId(learnerId, classroomId)
                .map(this::toResponse);
    }

    /**
     * Returns a real class-scoped zero summary when the learner has not
     * submitted an answer in the class yet.
     */
    @Transactional(readOnly = true)
    public ClassPerformanceResponse getEmptyPerformanceSummary(UUID classroomId) {
        Classroom classroom = classroomRepository.findById(classroomId)
                .orElseThrow(() -> new IllegalArgumentException("Classroom not found"));
        return ClassPerformanceResponse.builder()
                .classId(classroom.getClassId())
                .className(classroom.getName())
                .classCode(classroom.getClassCode())
                .build();
    }

    /**
     * Returns all class performance records for a learner (across all enrolled classes).
     */
    @Transactional(readOnly = true)
    public List<ClassPerformanceResponse> getAllClassPerformances(UUID learnerId) {
        List<ClassEnrollment> enrollments = classEnrollmentRepository
            .findByLearnerLearnerIdAndStatus(learnerId, "ACTIVE");
        List<ClassPerformanceResponse> responses = new ArrayList<>();
        for (ClassEnrollment enrollment : enrollments) {
            Classroom classroom = enrollment.getClassroom();
            if (classroom == null) continue;

            Optional<ClassPerformance> performance = classPerformanceRepository
                .findByLearnerLearnerIdAndClassroomClassId(learnerId, classroom.getClassId());
            responses.add(performance.map(this::toResponse)
                .orElseGet(() -> getEmptyPerformanceSummary(classroom.getClassId())));
        }
        return responses;
    }

    /**
     * Returns the class leaderboard for a specific classroom.
     *
     * @param classId  the classroom UUID
     * @param range    "weekly" or "all" (any other value = all-time)
     */
    @Transactional(readOnly = true)
    public List<LeaderboardEntryResponse> getClassLeaderboard(UUID classId, String range) {
        List<ClassEnrollment> enrollments = classEnrollmentRepository
                .findByClassroomClassIdAndStatus(classId, "ACTIVE");
        List<LeaderboardEntryResponse> leaderboard = new ArrayList<>();

        for (ClassEnrollment enrollment : enrollments) {
            Learner learner = enrollment.getLearner();
            if (learner == null) continue;

            ClassPerformance cp = classPerformanceRepository
                    .findByLearnerLearnerIdAndClassroomClassId(learner.getLearnerId(), classId)
                    .orElse(null);
            int points;
            if ("weekly".equalsIgnoreCase(range)) {
                OffsetDateTime oneWeekAgo = OffsetDateTime.now().minusDays(7);
                points = pointTransactionRepository.sumClassPointsByLearnerAndClassAndDateAfter(
                        learner.getLearnerId(), classId, oneWeekAgo);
            } else {
                points = cp != null && cp.getClassPoints() != null ? cp.getClassPoints() : 0;
            }

            if (points >= 0) { // include 0-point members so teacher sees all classmates
                leaderboard.add(LeaderboardEntryResponse.builder()
                        .learnerId(learner.getLearnerId())
                        .displayName(learner.getDisplayName())
                        .avatar(learner.getAvatar())
                        .points(points)
                        .tier(resolveTier(points, cp != null ? cp.getClassMasteryLevel() : "LEARNING"))
                        .build());
            }
        }

        leaderboard.sort((a, b) -> Integer.compare(b.getPoints(), a.getPoints()));

        int rank = 1;
        for (LeaderboardEntryResponse entry : leaderboard) {
            entry.setRank(rank++);
        }

        return leaderboard;
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private ClassPerformanceResponse toResponse(ClassPerformance cp) {
        return ClassPerformanceResponse.builder()
                .classId(cp.getClassroom().getClassId())
                .className(cp.getClassroom().getName())
                .classCode(cp.getClassroom().getClassCode())
                .classPoints(cp.getClassPoints())
                .classAccuracy(cp.getClassAccuracy())
                .classMasteryLevel(cp.getClassMasteryLevel())
                .classSessionsPlayed(cp.getClassSessionsPlayed())
                .classTotalQuestions(cp.getClassTotalQuestions())
                .classCorrectAnswers(cp.getClassCorrectAnswers())
                .build();
    }

    private String resolveMasteryLevel(BigDecimal accuracy) {
        if (accuracy == null) return "LEARNING";
        double v = accuracy.doubleValue();
        if (v >= 90.0) return "MASTERED";
        if (v >= 75.0) return "PROFICIENT";
        if (v >= 50.0) return "FAMILIAR";
        return "LEARNING";
    }

    private String resolveTier(int points, String masteryLevel) {
        if (points >= 3500 || "MASTERED".equalsIgnoreCase(masteryLevel)) return "DIAMOND";
        if (points >= 2500 || "PROFICIENT".equalsIgnoreCase(masteryLevel)) return "GOLD";
        if (points >= 1000 || "FAMILIAR".equalsIgnoreCase(masteryLevel)) return "SILVER";
        return "BRONZE";
    }
}
