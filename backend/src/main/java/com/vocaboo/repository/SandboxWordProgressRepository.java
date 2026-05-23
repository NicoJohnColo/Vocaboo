package com.vocaboo.repository;

import com.vocaboo.entity.SandboxWordProgress;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface SandboxWordProgressRepository extends JpaRepository<SandboxWordProgress, UUID> {
    List<SandboxWordProgress> findBySessionSessionId(UUID sessionId);
    Optional<SandboxWordProgress> findBySessionSessionIdAndWordWordIdAndModuleNumber(UUID sessionId, UUID wordId, Integer moduleNumber);
    void deleteBySessionSessionId(UUID sessionId);
}
