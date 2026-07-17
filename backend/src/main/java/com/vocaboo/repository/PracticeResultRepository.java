package com.vocaboo.repository;

import com.vocaboo.entity.PracticeResult;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface PracticeResultRepository extends JpaRepository<PracticeResult, UUID> {
    List<PracticeResult> findBySessionSessionId(UUID sessionId);
    List<PracticeResult> findBySessionSessionIdOrderByRecordedAtAsc(UUID sessionId);
}
