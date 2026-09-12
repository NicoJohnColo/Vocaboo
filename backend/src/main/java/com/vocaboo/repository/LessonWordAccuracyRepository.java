package com.vocaboo.repository;

import com.vocaboo.entity.LessonWordAccuracy;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface LessonWordAccuracyRepository extends JpaRepository<LessonWordAccuracy, UUID> {
    
    Optional<LessonWordAccuracy> findByLearnerLearnerIdAndLessonLessonIdAndWordWordId(
        UUID learnerId, 
        UUID lessonId, 
        UUID wordId
    );
    
    List<LessonWordAccuracy> findByLearnerLearnerIdAndLessonLessonId(
        UUID learnerId, 
        UUID lessonId
    );
    
    List<LessonWordAccuracy> findByLearnerLearnerId(UUID learnerId);
    
    void deleteByLearnerLearnerId(UUID learnerId);
    
    void deleteByLearnerLearnerIdAndLessonLessonId(UUID learnerId, UUID lessonId);
}