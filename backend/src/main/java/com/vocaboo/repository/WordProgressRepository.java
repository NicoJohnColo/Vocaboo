package com.vocaboo.repository;

import com.vocaboo.entity.WordProgress;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface WordProgressRepository extends JpaRepository<WordProgress, UUID> {
    Optional<WordProgress> findBySessionSessionIdAndWordWordIdAndModuleNumber(UUID sessionId, UUID wordId, Integer moduleNumber);
    void deleteByLearnerLearnerId(UUID learnerId);
}
