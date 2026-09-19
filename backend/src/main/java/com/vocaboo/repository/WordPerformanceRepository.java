package com.vocaboo.repository;

import com.vocaboo.entity.VocabularyWord;
import com.vocaboo.entity.WordPerformance;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface WordPerformanceRepository extends JpaRepository<WordPerformance, UUID> {
    Optional<WordPerformance> findByLearnerLearnerIdAndWordWordId(UUID learnerId, UUID wordId);

    @org.springframework.data.jpa.repository.EntityGraph(attributePaths = {"word", "word.lesson"})
    List<WordPerformance> findByLearnerLearnerId(UUID learnerId);
    List<WordPerformance> findByLearnerLearnerIdOrderByLastPracticedAtDesc(UUID learnerId, org.springframework.data.domain.Pageable pageable);
    /** All performance rows for a learner within a specific lesson. */
    List<WordPerformance> findByLearnerLearnerIdAndWordLessonLessonId(UUID learnerId, UUID lessonId);
    void deleteByLearnerLearnerId(UUID learnerId);
    void deleteByLearnerLearnerIdAndWordLessonLessonId(UUID learnerId, UUID lessonId);

    List<WordPerformance> findByWordLessonLessonId(UUID lessonId);
    List<WordPerformance> findByLearnerSectionSectionId(UUID sectionId);
    List<WordPerformance> findByLearnerSectionSectionIdAndWordLessonLessonId(UUID sectionId, UUID lessonId);
    List<WordPerformance> findByLearnerLearnerIdIn(List<UUID> learnerIds);
    List<WordPerformance> findByLearnerLearnerIdInAndWordLessonLessonId(List<UUID> learnerIds, UUID lessonId);

    @Query("SELECT wp FROM WordPerformance wp WHERE wp.learner.learnerId = :learnerId AND wp.accuracy >= :threshold")
    List<WordPerformance> findKnownWordsPool(@Param("learnerId") UUID learnerId, @Param("threshold") BigDecimal threshold);

    @Query("SELECT wp FROM WordPerformance wp WHERE wp.learner.learnerId = :learnerId AND wp.accuracy < :threshold")
    List<WordPerformance> findWeakWords(@Param("learnerId") UUID learnerId, @Param("threshold") BigDecimal threshold);

    @Query("SELECT wp.word FROM WordPerformance wp WHERE wp.learner.learnerId = :learnerId AND wp.accuracy >= :threshold")
    List<VocabularyWord> findKnownVocabularyWordsPool(@Param("learnerId") UUID learnerId, @Param("threshold") BigDecimal threshold);

    @Query("SELECT wp.word FROM WordPerformance wp WHERE wp.learner.learnerId = :learnerId AND wp.accuracy < :threshold")
    List<VocabularyWord> findWeakVocabularyWords(@Param("learnerId") UUID learnerId, @Param("threshold") BigDecimal threshold);
}
