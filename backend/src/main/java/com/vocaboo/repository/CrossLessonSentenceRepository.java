package com.vocaboo.repository;

import com.vocaboo.entity.CrossLessonSentence;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface CrossLessonSentenceRepository extends JpaRepository<CrossLessonSentence, UUID> {
    List<CrossLessonSentence> findByLessonPairId(String lessonPairId);

    @Query("SELECT c FROM CrossLessonSentence c WHERE c.wordA.wordId = :wordId OR c.wordB.wordId = :wordId")
    List<CrossLessonSentence> findByWordId(@Param("wordId") UUID wordId);
}
