package com.vocaboo.repository;

import com.vocaboo.entity.SandboxWord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface SandboxWordRepository extends JpaRepository<SandboxWord, UUID> {
    List<SandboxWord> findBySessionSessionIdOrderByWordOrderAsc(UUID sessionId);
    void deleteBySessionSessionId(UUID sessionId);
}
