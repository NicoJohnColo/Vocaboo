package com.vocaboo.repository;

import com.vocaboo.entity.ConfusableWordPair;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface ConfusableWordPairRepository extends JpaRepository<ConfusableWordPair, UUID> {
    List<ConfusableWordPair> findByLessonLessonId(UUID lessonId);
}
