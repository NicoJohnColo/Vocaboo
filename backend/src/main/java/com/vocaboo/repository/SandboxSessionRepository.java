package com.vocaboo.repository;

import com.vocaboo.entity.SandboxSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface SandboxSessionRepository extends JpaRepository<SandboxSession, UUID> {
    List<SandboxSession> findByLearnerLearnerIdOrderByCreatedAtDesc(UUID learnerId);
    void deleteByLearnerLearnerId(UUID learnerId);
}
