package com.vocaboo.repository;

import com.vocaboo.entity.VocabularyCategory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface VocabularyCategoryRepository extends JpaRepository<VocabularyCategory, UUID> {
    List<VocabularyCategory> findAllByOrderBySortOrderAsc();
}
