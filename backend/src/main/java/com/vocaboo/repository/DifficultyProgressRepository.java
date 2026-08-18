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

    List<DifficultyProgress> findByLearnerLearnerIdAndWordLessonLessonId(UUID learnerId, UUID lessonId);

    /** Count words where BOTH Module 2 and Module 3 are MASTERED for the given learner and lesson. */
    @org.springframework.data.jpa.repository.Query(
        "SELECT COUNT(w) FROM VocabularyWord w " +
        "WHERE w.lesson.lessonId = :lessonId " +
        "  AND EXISTS (SELECT 1 FROM DifficultyProgress dp1 WHERE dp1.word = w AND dp1.learner.learnerId = :learnerId AND dp1.moduleNumber = 2 AND dp1.currentLevel = 'MASTERED') " +
        "  AND EXISTS (SELECT 1 FROM DifficultyProgress dp2 WHERE dp2.word = w AND dp2.learner.learnerId = :learnerId AND dp2.moduleNumber = 3 AND dp2.currentLevel = 'MASTERED')"
    )
    long countMasteredWordsByLearnerAndLesson(
        @org.springframework.data.repository.query.Param("learnerId") UUID learnerId,
        @org.springframework.data.repository.query.Param("lessonId") UUID lessonId);

    /** Count total words where BOTH Module 2 and Module 3 are MASTERED for the given learner across all lessons. */
    @org.springframework.data.jpa.repository.Query(
        "SELECT COUNT(w) FROM VocabularyWord w " +
        "WHERE EXISTS (SELECT 1 FROM DifficultyProgress dp1 WHERE dp1.word = w AND dp1.learner.learnerId = :learnerId AND dp1.moduleNumber = 2 AND dp1.currentLevel = 'MASTERED') " +
        "  AND EXISTS (SELECT 1 FROM DifficultyProgress dp2 WHERE dp2.word = w AND dp2.learner.learnerId = :learnerId AND dp2.moduleNumber = 3 AND dp2.currentLevel = 'MASTERED')"
    )
    long countTotalMasteredWordsByLearner(
        @org.springframework.data.repository.query.Param("learnerId") UUID learnerId);
}

