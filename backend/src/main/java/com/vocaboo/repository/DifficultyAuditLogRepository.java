package com.vocaboo.repository;

import com.vocaboo.entity.DifficultyAuditLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface DifficultyAuditLogRepository extends JpaRepository<DifficultyAuditLog, UUID> {
    List<DifficultyAuditLog> findByLearnerLearnerIdAndWordWordIdOrderByChangedAtDesc(UUID learnerId, UUID wordId);
    List<DifficultyAuditLog> findByLearnerLearnerIdOrderByChangedAtDesc(UUID learnerId);
    void deleteByLearnerLearnerId(UUID learnerId);
}
