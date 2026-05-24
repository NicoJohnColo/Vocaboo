package com.vocaboo.repository;

import com.vocaboo.entity.LessonModuleScore;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface LessonModuleScoreRepository extends JpaRepository<LessonModuleScore, UUID> {
    Optional<LessonModuleScore> findByLearnerLearnerIdAndLessonLessonIdAndModuleNumber(UUID learnerId, UUID lessonId, Integer moduleNumber);
}