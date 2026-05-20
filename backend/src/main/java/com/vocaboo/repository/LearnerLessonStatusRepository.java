package com.vocaboo.repository;

import com.vocaboo.entity.LearnerLessonStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface LearnerLessonStatusRepository extends JpaRepository<LearnerLessonStatus, UUID> {
    Optional<LearnerLessonStatus> findByLearnerLearnerIdAndLessonLessonId(UUID learnerId, UUID lessonId);
    List<LearnerLessonStatus> findByLearnerLearnerId(UUID learnerId);
}
