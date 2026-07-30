package com.vocaboo.repository;

import com.vocaboo.entity.SentenceTemplate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface SentenceTemplateRepository extends JpaRepository<SentenceTemplate, UUID> {
    List<SentenceTemplate> findByWordWordId(UUID wordId);
}
