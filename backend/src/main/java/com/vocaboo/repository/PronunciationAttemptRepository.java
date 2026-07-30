package com.vocaboo.repository;

import com.vocaboo.entity.PronunciationAttempt;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface PronunciationAttemptRepository extends JpaRepository<PronunciationAttempt, UUID> {
    List<PronunciationAttempt> findBySessionSessionIdAndWordWordIdAndModuleNumberOrderByAttemptNumberAsc(UUID sessionId, UUID wordId, Integer moduleNumber);
    List<PronunciationAttempt> findByLearnerLearnerIdOrderByRecordedAtAsc(UUID learnerId);
    long countBySessionSessionIdAndWordWordIdAndModuleNumber(UUID sessionId, UUID wordId, Integer moduleNumber);
    long countByLearnerLearnerId(UUID learnerId);
    long countByLearnerLearnerIdAndIsCorrect(UUID learnerId, Boolean isCorrect);
    void deleteByLearnerLearnerId(UUID learnerId);
}
