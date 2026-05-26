package com.vocaboo.repository;

import com.vocaboo.entity.SandboxModuleScore;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface SandboxModuleScoreRepository extends JpaRepository<SandboxModuleScore, UUID> {
    Optional<SandboxModuleScore> findBySessionSessionIdAndModuleNumber(UUID sessionId, Integer moduleNumber);
    List<SandboxModuleScore> findBySessionSessionId(UUID sessionId);
}
