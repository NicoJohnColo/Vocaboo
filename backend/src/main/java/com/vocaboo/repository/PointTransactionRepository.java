package com.vocaboo.repository;

import com.vocaboo.entity.PointTransaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.OffsetDateTime;
import java.util.UUID;

@Repository
public interface PointTransactionRepository extends JpaRepository<PointTransaction, UUID> {

    @Query("SELECT COALESCE(SUM(t.pointsAwarded), 0) FROM PointTransaction t WHERE t.learner.learnerId = :learnerId AND t.createdAt >= :afterDate")
    int sumPointsByLearnerAndDateAfter(@Param("learnerId") UUID learnerId, @Param("afterDate") OffsetDateTime afterDate);

    @Query("SELECT CASE WHEN COUNT(t) > 0 THEN true ELSE false END FROM PointTransaction t WHERE t.learner.learnerId = :learnerId AND t.relatedWord.wordId = :wordId AND t.actionType = 'MASTERY_BONUS'")
    boolean existsMasteryBonusForWord(@Param("learnerId") UUID learnerId, @Param("wordId") UUID wordId);

    /** Sum of class-context points for a learner in a specific classroom after a given date. */
    @Query("SELECT COALESCE(SUM(t.pointsAwarded), 0) FROM PointTransaction t " +
           "WHERE t.learner.learnerId = :learnerId " +
           "AND t.classroom.classId = :classId " +
           "AND t.contextType = 'CLASS' " +
           "AND t.createdAt >= :afterDate")
    int sumClassPointsByLearnerAndClassAndDateAfter(
            @Param("learnerId") UUID learnerId,
            @Param("classId") UUID classId,
            @Param("afterDate") OffsetDateTime afterDate);

    /** All-time class-context point total for a learner in a specific classroom. */
    @Query("SELECT COALESCE(SUM(t.pointsAwarded), 0) FROM PointTransaction t " +
           "WHERE t.learner.learnerId = :learnerId " +
           "AND t.classroom.classId = :classId " +
           "AND t.contextType = 'CLASS'")
    int sumAllClassPointsByLearnerAndClass(
            @Param("learnerId") UUID learnerId,
            @Param("classId") UUID classId);

    void deleteByLearnerLearnerId(UUID learnerId);
}
