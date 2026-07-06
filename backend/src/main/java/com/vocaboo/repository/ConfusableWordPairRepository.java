package com.vocaboo.repository;

import com.vocaboo.entity.ConfusableWordPair;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ConfusableWordPairRepository extends JpaRepository<ConfusableWordPair, UUID> {

    List<ConfusableWordPair> findByLessonLessonId(UUID lessonId);

    /**
     * Order-independent duplicate check: returns true if a pair already exists
     * for (wordAId, wordBId) OR (wordBId, wordAId) within the same lesson.
     */
    @Query("""
            SELECT COUNT(p) > 0 FROM ConfusableWordPair p
            WHERE p.lesson.lessonId = :lessonId
              AND (
                (p.wordA.wordId = :wordAId AND p.wordB.wordId = :wordBId)
                OR
                (p.wordA.wordId = :wordBId AND p.wordB.wordId = :wordAId)
              )
            """)
    boolean existsByLessonAndWords(
            @Param("lessonId") UUID lessonId,
            @Param("wordAId") UUID wordAId,
            @Param("wordBId") UUID wordBId
    );

    /**
     * Find all pairs in a lesson where a specific word appears (as either word A or word B).
     * Used to recalculate is_confusable_pair_member after deletion.
     */
    @Query("""
            SELECT p FROM ConfusableWordPair p
            WHERE p.lesson.lessonId = :lessonId
              AND (p.wordA.wordId = :wordId OR p.wordB.wordId = :wordId)
            """)
    List<ConfusableWordPair> findByLessonAndWord(
            @Param("lessonId") UUID lessonId,
            @Param("wordId") UUID wordId
    );
}
