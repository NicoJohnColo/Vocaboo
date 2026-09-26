package com.vocaboo.repository;

import com.vocaboo.entity.CumulativeReviewSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CumulativeReviewSessionRepository extends JpaRepository<CumulativeReviewSession, UUID> {
    List<CumulativeReviewSession> findByLearnerLearnerIdOrderByStartTimeDesc(UUID learnerId);

    List<CumulativeReviewSession> findByLearnerLearnerIdAndLessonPairIdOrderByStartTimeDesc(UUID learnerId, String lessonPairId);
    
    Optional<CumulativeReviewSession> findFirstByLearnerLearnerIdAndLessonPairIdAndSessionStatusOrderByStartTimeDesc(
            UUID learnerId, String lessonPairId, String sessionStatus);

    @org.springframework.transaction.annotation.Transactional
    @org.springframework.data.jpa.repository.Modifying
    @org.springframework.data.jpa.repository.Query("DELETE FROM CumulativeReviewSession s WHERE s.learner.learnerId = :learnerId")
    void deleteByLearnerLearnerId(@org.springframework.data.repository.query.Param("learnerId") UUID learnerId);
}
