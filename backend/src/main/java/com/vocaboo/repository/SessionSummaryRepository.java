package com.vocaboo.repository;

import com.vocaboo.entity.SessionSummary;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface SessionSummaryRepository extends JpaRepository<SessionSummary, UUID> {
    Optional<SessionSummary> findBySessionId(UUID sessionId);

    @org.springframework.data.jpa.repository.EntityGraph(attributePaths = {"lesson"})
    java.util.List<SessionSummary> findByLearnerLearnerId(UUID learnerId);
    void deleteByLearnerLearnerId(UUID learnerId);
}
