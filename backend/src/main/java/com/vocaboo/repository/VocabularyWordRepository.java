package com.vocaboo.repository;

import com.vocaboo.entity.VocabularyWord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface VocabularyWordRepository extends JpaRepository<VocabularyWord, UUID> {
    List<VocabularyWord> findByLessonLessonIdOrderByWordOrderAsc(UUID lessonId);
}
