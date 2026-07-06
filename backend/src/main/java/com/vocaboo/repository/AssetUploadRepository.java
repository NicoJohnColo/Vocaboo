package com.vocaboo.repository;

import com.vocaboo.entity.AssetUpload;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface AssetUploadRepository extends JpaRepository<AssetUpload, UUID> {
    List<AssetUpload> findByLessonId(UUID lessonId);
    List<AssetUpload> findByWordId(UUID wordId);
    void deleteByWordId(UUID wordId);
    void deleteByLessonId(UUID lessonId);
}
