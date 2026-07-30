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

    void deleteByLearnerLearnerId(UUID learnerId);
}
