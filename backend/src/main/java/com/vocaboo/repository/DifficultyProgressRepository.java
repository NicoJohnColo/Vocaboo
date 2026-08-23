package com.vocaboo.repository;

import com.vocaboo.entity.DifficultyProgress;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DifficultyProgressRepository extends JpaRepository<DifficultyProgress, UUID> {
    Optional<DifficultyProgress> findByLearnerLearnerIdAndWordWordIdAndModuleNumber(UUID learnerId, UUID wordId, Integer moduleNumber);

    Optional<DifficultyProgress> findFirstByLearnerLearnerIdAndWordWordIdOrderByUpdatedAtDesc(UUID learnerId, UUID wordId);

    default Optional<DifficultyProgress> findByLearnerLearnerIdAndWordWordId(UUID learnerId, UUID wordId) {
        return findFirstByLearnerLearnerIdAndWordWordIdOrderByUpdatedAtDesc(learnerId, wordId);
    }

    List<DifficultyProgress> findByLearnerLearnerIdAndWordLessonLessonIdAndModuleNumber(UUID learnerId, UUID lessonId, Integer moduleNumber);

    List<DifficultyProgress> findByLearnerLearnerIdAndModuleNumber(UUID learnerId, Integer moduleNumber);
    List<DifficultyProgress> findByLearnerLearnerIdAndNeedsReintroductionTrue(UUID learnerId);
    void deleteByLearnerLearnerId(UUID learnerId);
    void deleteByLearnerLearnerIdAndWordLessonLessonId(UUID learnerId, UUID lessonId);

    List<DifficultyProgress> findByLearnerLearnerIdAndWordLessonLessonId(UUID learnerId, UUID lessonId);

    /** Count distinct words MASTERED for the given learner and lesson. */
    @org.springframework.data.jpa.repository.Query(
        "SELECT COUNT(DISTINCT dp.word.wordId) FROM DifficultyProgress dp " +
        "WHERE dp.word.lesson.lessonId = :lessonId " +
        "  AND dp.learner.learnerId = :learnerId " +
        "  AND dp.currentLevel = 'MASTERED'"
    )
    long countMasteredWordsByLearnerAndLesson(
        @org.springframework.data.repository.query.Param("learnerId") UUID learnerId,
        @org.springframework.data.repository.query.Param("lessonId") UUID lessonId);

    /** Count total distinct words MASTERED for the given learner across lessons. */
    @org.springframework.data.jpa.repository.Query(
        "SELECT COUNT(DISTINCT dp.word.wordId) FROM DifficultyProgress dp " +
        "WHERE dp.learner.learnerId = :learnerId AND dp.currentLevel = 'MASTERED'"
    )
    long countTotalMasteredWordsByLearner(
        @org.springframework.data.repository.query.Param("learnerId") UUID learnerId);
}

