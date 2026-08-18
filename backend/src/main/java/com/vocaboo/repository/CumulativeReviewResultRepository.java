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
}
