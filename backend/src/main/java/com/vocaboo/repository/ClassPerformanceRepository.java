package com.vocaboo.repository;

import com.vocaboo.entity.ClassPerformance;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ClassPerformanceRepository extends JpaRepository<ClassPerformance, UUID> {

    /** Fetch a single learner's performance record for a given class. */
    Optional<ClassPerformance> findByLearnerLearnerIdAndClassroomClassId(UUID learnerId, UUID classId);

    /** Fetch all performance records for a given class (for class leaderboard). */
    @org.springframework.data.jpa.repository.EntityGraph(attributePaths = {"learner"})
    List<ClassPerformance> findByClassroomClassId(UUID classId);

    /** Fetch all classes a learner has performance data for. */
    @org.springframework.data.jpa.repository.EntityGraph(attributePaths = {"classroom"})
    List<ClassPerformance> findByLearnerLearnerId(UUID learnerId);

    /** Sum of class points for weekly class leaderboard queries. */
    @Query("SELECT COALESCE(SUM(t.pointsAwarded), 0) FROM PointTransaction t " +
           "WHERE t.learner.learnerId = :learnerId " +
           "AND t.classroom.classId = :classId " +
           "AND t.contextType = 'CLASS' " +
           "AND t.createdAt >= :afterDate")
    int sumClassPointsByLearnerAndClassAndDateAfter(
            @Param("learnerId") UUID learnerId,
            @Param("classId") UUID classId,
            @Param("afterDate") java.time.OffsetDateTime afterDate);

    void deleteByLearnerLearnerId(UUID learnerId);
}
