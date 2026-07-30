package com.vocaboo.repository;

import com.vocaboo.entity.DifficultyLevel;
import com.vocaboo.entity.AdaptiveMetric;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface AdaptiveMetricRepository extends JpaRepository<AdaptiveMetric, UUID> {
    Optional<AdaptiveMetric> findByLearnerLearnerIdAndDifficultyLevel(UUID learnerId, DifficultyLevel difficultyLevel);
    void deleteByLearnerLearnerId(UUID learnerId);
}
