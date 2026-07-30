package com.vocaboo.repository;

import com.vocaboo.entity.ReinforcementQueueItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ReinforcementQueueRepository extends JpaRepository<ReinforcementQueueItem, UUID> {
    Optional<ReinforcementQueueItem> findByLearnerLearnerIdAndWordWordId(UUID learnerId, UUID wordId);
    List<ReinforcementQueueItem> findByLearnerLearnerIdAndIsResolvedFalseOrderByScheduledAtAsc(UUID learnerId);
    void deleteByLearnerLearnerId(UUID learnerId);
}
