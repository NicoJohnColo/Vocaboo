package com.vocaboo.repository;

import com.vocaboo.entity.DiagnosticResult;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface DiagnosticResultRepository extends JpaRepository<DiagnosticResult, UUID> {
    List<DiagnosticResult> findBySessionSessionId(UUID sessionId);
}
