package com.vocaboo.repository;

import com.vocaboo.entity.ReviewSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface ReviewSessionRepository extends JpaRepository<ReviewSession, UUID> {
    List<ReviewSession> findByLearnerLearnerId(UUID learnerId);
    List<ReviewSession> findByLearnerLearnerIdAndLessonLessonId(UUID learnerId, UUID lessonId);
    void deleteByLearnerLearnerId(UUID learnerId);
    long countByCompletedAtIsNull();
}
