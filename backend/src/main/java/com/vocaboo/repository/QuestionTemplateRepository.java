package com.vocaboo.repository;

import com.vocaboo.entity.DifficultyLevel;
import com.vocaboo.entity.QuestionTemplate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface QuestionTemplateRepository extends JpaRepository<QuestionTemplate, UUID> {
    List<QuestionTemplate> findByActivityFormatAndDifficultyLevel(String activityFormat, DifficultyLevel difficultyLevel);
}
