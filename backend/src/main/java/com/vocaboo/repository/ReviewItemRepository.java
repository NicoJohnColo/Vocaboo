package com.vocaboo.repository;

import com.vocaboo.entity.ReviewItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface ReviewItemRepository extends JpaRepository<ReviewItem, UUID> {
    List<ReviewItem> findBySessionSessionId(UUID sessionId);
    void deleteBySessionSessionId(UUID sessionId);

    /**
     * All review items (correct and incorrect) for a learner, ordered by creation time ascending
     * so we can determine the most-recent attempt per word.
     */
    @Query("""
            SELECT r FROM ReviewItem r
            WHERE r.session.learner.learnerId = :learnerId
            ORDER BY r.createdAt ASC
            """)
    List<ReviewItem> findAllByLearnerIdOrderByCreatedAtAsc(@Param("learnerId") UUID learnerId);

    /**
     * All review items class-wide (every learner), ordered by creation time ascending.
     * Used by the admin wrong-answer analysis endpoint.
     */
    @Query("""
            SELECT r FROM ReviewItem r
            ORDER BY r.createdAt ASC
            """)
    List<ReviewItem> findAllOrderByCreatedAtAsc();
}
