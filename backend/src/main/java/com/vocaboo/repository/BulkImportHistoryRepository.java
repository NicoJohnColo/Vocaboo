package com.vocaboo.repository;

import com.vocaboo.entity.BulkImportHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface BulkImportHistoryRepository extends JpaRepository<BulkImportHistory, UUID> {
    List<BulkImportHistory> findByLessonIdOrderByImportDateDesc(UUID lessonId);
}
