package com.vocaboo.repository;

import com.vocaboo.entity.VocabularyWord;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface VocabularyWordRepository extends JpaRepository<VocabularyWord, UUID> {

    @Query("SELECT w FROM VocabularyWord w JOIN FETCH w.lesson")
    List<VocabularyWord> findAllWithLesson();

    @Override
    @EntityGraph(attributePaths = {"lesson"})
    List<VocabularyWord> findAll();

    @Query("SELECT w FROM VocabularyWord w WHERE w.isDeleted = true")
    List<VocabularyWord> findAllSoftDeleted();


    // Learner-facing (existing)
    List<VocabularyWord> findByLessonLessonIdOrderByWordOrderAsc(UUID lessonId);

    // Admin-facing (soft-delete aware)
    List<VocabularyWord> findByLessonLessonIdAndIsDeletedFalseOrderByWordOrderAsc(UUID lessonId);

    long countByLessonLessonIdAndIsDeletedFalse(UUID lessonId);

    boolean existsByLessonLessonIdAndEnglishWordIgnoreCaseAndCebuanoMeaningIgnoreCaseAndIsDeletedFalse(UUID lessonId, String englishWord, String cebuanoMeaning);

    // Includes soft-deleted rows — word_order must be unique across ALL rows in the lesson,
    // not just active ones, to prevent unique constraint violations on insert.
    @Query("SELECT COALESCE(MAX(w.wordOrder), 0) FROM VocabularyWord w WHERE w.lesson.lessonId = :lessonId")
    int findMaxWordOrderByLessonId(@Param("lessonId") UUID lessonId);

    @Query("SELECT w FROM VocabularyWord w WHERE w.lesson.lessonId = :lessonId AND w.wordId IN :ids AND w.isDeleted = false")
    List<VocabularyWord> findByLessonIdAndWordIdIn(@Param("lessonId") UUID lessonId, @Param("ids") List<UUID> ids);

    List<VocabularyWord> findByLessonLessonIdAndPartOfSpeechIgnoreCaseAndIsDeletedFalseOrderByWordOrderAsc(UUID lessonId, String partOfSpeech);

    @Query("SELECT DISTINCT UPPER(w.partOfSpeech) FROM VocabularyWord w WHERE w.lesson.lessonId = :lessonId AND w.isDeleted = false AND w.partOfSpeech IS NOT NULL")
    List<String> findDistinctPartsOfSpeechByLessonId(@Param("lessonId") UUID lessonId);
}

