package com.vocaboo.repository;

import com.vocaboo.entity.LessonModuleScore;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface LessonModuleScoreRepository extends JpaRepository<LessonModuleScore, UUID> {
    Optional<LessonModuleScore> findByLearnerLearnerIdAndLessonLessonIdAndModuleNumber(UUID learnerId, UUID lessonId, Integer moduleNumber);
    List<LessonModuleScore> findByLearnerLearnerIdAndModuleNumber(UUID learnerId, Integer moduleNumber);
    List<LessonModuleScore> findByLearnerLearnerId(UUID learnerId);
    List<LessonModuleScore> findByLearnerLearnerIdAndLessonLessonId(UUID learnerId, UUID lessonId);
    void deleteByLearnerLearnerId(UUID learnerId);
    void deleteByLearnerLearnerIdAndLessonLessonId(UUID learnerId, UUID lessonId);
}