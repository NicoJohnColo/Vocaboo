package com.vocaboo.repository;

import com.vocaboo.entity.DifficultyProgress;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DifficultyProgressRepository extends JpaRepository<DifficultyProgress, UUID> {
    Optional<DifficultyProgress> findByLearnerLearnerIdAndWordWordId(UUID learnerId, UUID wordId);
    List<DifficultyProgress> findByLearnerLearnerId(UUID learnerId);
    void deleteByLearnerLearnerId(UUID learnerId);
}
