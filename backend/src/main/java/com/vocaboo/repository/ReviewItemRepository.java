package com.vocaboo.repository;

import com.vocaboo.entity.ReviewItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface ReviewItemRepository extends JpaRepository<ReviewItem, UUID> {
    List<ReviewItem> findBySessionSessionId(UUID sessionId);
    void deleteBySessionSessionId(UUID sessionId);
}
