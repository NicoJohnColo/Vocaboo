package com.vocaboo.repository;

import com.vocaboo.entity.LearnerMastery;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface LearnerMasteryRepository extends JpaRepository<LearnerMastery, UUID> {
    @Override
    @org.springframework.data.jpa.repository.EntityGraph(attributePaths = {"learner"})
    java.util.List<LearnerMastery> findAll();

    @org.springframework.data.jpa.repository.EntityGraph(attributePaths = {"learner"})
    Optional<LearnerMastery> findByLearnerLearnerId(UUID learnerId);
    void deleteByLearnerLearnerId(UUID learnerId);
}
