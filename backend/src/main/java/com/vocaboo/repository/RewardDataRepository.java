package com.vocaboo.repository;

import com.vocaboo.entity.RewardData;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface RewardDataRepository extends JpaRepository<RewardData, UUID> {
    @EntityGraph(attributePaths = {"lesson"})
    List<RewardData> findByLearnerLearnerId(UUID learnerId);
    List<RewardData> findByLearnerLearnerIdAndLessonLessonId(UUID learnerId, UUID lessonId);
    Optional<RewardData> findByLearnerLearnerIdAndLessonLessonIdAndBadgeType(UUID learnerId, UUID lessonId, String badgeType);
    void deleteByLearnerLearnerId(UUID learnerId);
}
