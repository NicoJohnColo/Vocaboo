package com.vocaboo.repository;

import com.vocaboo.entity.LearnerMastery;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface LearnerMasteryRepository extends JpaRepository<LearnerMastery, UUID> {
    Optional<LearnerMastery> findByLearnerLearnerId(UUID learnerId);
    void deleteByLearnerLearnerId(UUID learnerId);
}
