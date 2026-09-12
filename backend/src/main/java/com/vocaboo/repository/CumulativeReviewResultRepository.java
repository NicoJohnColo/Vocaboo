package com.vocaboo.repository;

import com.vocaboo.entity.CumulativeReviewResult;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface CumulativeReviewResultRepository extends JpaRepository<CumulativeReviewResult, UUID> {
    List<CumulativeReviewResult> findBySessionId(UUID sessionId);
    List<CumulativeReviewResult> findBySessionIdAndWordWordId(UUID sessionId, UUID wordId);

    @org.springframework.data.jpa.repository.Modifying
    @org.springframework.data.jpa.repository.Query("DELETE FROM CumulativeReviewResult r WHERE r.session.id = :sessionId")
    void deleteBySessionId(@org.springframework.data.repository.query.Param("sessionId") UUID sessionId);

    @org.springframework.data.jpa.repository.Modifying
    @org.springframework.data.jpa.repository.Query("DELETE FROM CumulativeReviewResult r WHERE r.session.learner.learnerId = :learnerId")
    void deleteBySessionLearnerLearnerId(@org.springframework.data.repository.query.Param("learnerId") UUID learnerId);
}
