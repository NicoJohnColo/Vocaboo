package com.vocaboo.repository;

import com.vocaboo.entity.IntroductionSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface IntroductionSessionRepository extends JpaRepository<IntroductionSession, UUID> {
    Optional<IntroductionSession> findFirstByLearnerLearnerIdAndLessonLessonIdAndIsActiveTrue(UUID learnerId, UUID lessonId);
}
