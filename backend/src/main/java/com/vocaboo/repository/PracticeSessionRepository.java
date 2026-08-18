package com.vocaboo.repository;

import com.vocaboo.entity.PracticeSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface PracticeSessionRepository extends JpaRepository<PracticeSession, UUID> {
    List<PracticeSession> findByLearnerLearnerId(UUID learnerId);
    List<PracticeSession> findByLearnerLearnerIdOrderByCreatedAtDesc(UUID learnerId);
    void deleteByLearnerLearnerId(UUID learnerId);
    java.util.Optional<PracticeSession> findFirstByLearnerLearnerIdAndLessonLessonIdOrderByCreatedAtDesc(UUID learnerId, UUID lessonId);
}
