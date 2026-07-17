package com.vocaboo.repository;

import com.vocaboo.entity.WordPerformance;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface WordPerformanceRepository extends JpaRepository<WordPerformance, UUID> {
    Optional<WordPerformance> findByLearnerLearnerIdAndWordWordId(UUID learnerId, UUID wordId);
    List<WordPerformance> findByLearnerLearnerId(UUID learnerId);
    void deleteByLearnerLearnerId(UUID learnerId);
}
