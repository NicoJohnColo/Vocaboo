package com.vocaboo.service;

import com.vocaboo.dto.request.CreateCategoryRequest;
import com.vocaboo.dto.request.UpdateCategoryRequest;
import com.vocaboo.entity.VocabularyCategory;
import com.vocaboo.exception.ValidationException;
import com.vocaboo.repository.LessonRepository;
import com.vocaboo.repository.VocabularyCategoryRepository;
import com.vocaboo.repository.VocabularyWordRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CategoryManagementService {

    private final VocabularyCategoryRepository categoryRepository;
    private final LessonRepository lessonRepository;
    private final VocabularyWordRepository wordRepository;
    private final JdbcTemplate jdbcTemplate;

    @Transactional(readOnly = true)
    public List<VocabularyCategory> getAllCategories() {
        return categoryRepository.findAllByOrderBySortOrderAsc();
    }

    @Transactional
    public VocabularyCategory createCategory(CreateCategoryRequest req) {
        if (categoryRepository.existsByCategoryNameIgnoreCase(req.getCategoryName().trim())) {
            throw new ValidationException("category_name", "A category with this name already exists");
        }

        int sortOrder = req.getSortOrder() != null
                ? req.getSortOrder()
                : categoryRepository.findMaxSortOrder() + 1;

        VocabularyCategory category = VocabularyCategory.builder()
                .categoryName(req.getCategoryName().trim())
                .description(req.getDescription())
                .sortOrder(sortOrder)
                .build();

        return categoryRepository.save(category);
    }

    @Transactional
    public VocabularyCategory updateCategory(UUID categoryId, UpdateCategoryRequest req) {
        VocabularyCategory category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Category not found"));

        if (req.getCategoryName() != null && !req.getCategoryName().isBlank()) {
            String newName = req.getCategoryName().trim();
            if (!newName.equalsIgnoreCase(category.getCategoryName())
                    && categoryRepository.existsByCategoryNameIgnoreCase(newName)) {
                throw new ValidationException("category_name", "A category with this name already exists");
            }
            category.setCategoryName(newName);
        }
        if (req.getDescription() != null) {
            category.setDescription(req.getDescription());
        }
        if (req.getSortOrder() != null) {
            category.setSortOrder(req.getSortOrder());
        }

        return categoryRepository.save(category);
    }

    @Transactional
    public void deleteCategory(UUID categoryId) {
        VocabularyCategory category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Category not found"));

        // Manually delete all child records to bypass rogue Hibernate foreign key constraints
        jdbcTemplate.update("DELETE FROM diagnostic_results WHERE lesson_id IN (SELECT lesson_id FROM lessons WHERE category_id = ?)", categoryId);
        jdbcTemplate.update("DELETE FROM pronunciation_attempts WHERE lesson_id IN (SELECT lesson_id FROM lessons WHERE category_id = ?)", categoryId);
        jdbcTemplate.update("DELETE FROM word_progress WHERE lesson_id IN (SELECT lesson_id FROM lessons WHERE category_id = ?)", categoryId);
        jdbcTemplate.update("DELETE FROM confusable_word_pairs WHERE lesson_id IN (SELECT lesson_id FROM lessons WHERE category_id = ?)", categoryId);
        jdbcTemplate.update("DELETE FROM learner_lesson_status WHERE lesson_id IN (SELECT lesson_id FROM lessons WHERE category_id = ?)", categoryId);
        jdbcTemplate.update("DELETE FROM introduction_sessions WHERE lesson_id IN (SELECT lesson_id FROM lessons WHERE category_id = ?)", categoryId);
        jdbcTemplate.update("DELETE FROM review_items WHERE session_id IN (SELECT session_id FROM review_sessions WHERE lesson_id IN (SELECT lesson_id FROM lessons WHERE category_id = ?))", categoryId);
        jdbcTemplate.update("DELETE FROM review_sessions WHERE lesson_id IN (SELECT lesson_id FROM lessons WHERE category_id = ?)", categoryId);
        jdbcTemplate.update("DELETE FROM asset_uploads WHERE lesson_id IN (SELECT lesson_id FROM lessons WHERE category_id = ?)", categoryId);
        jdbcTemplate.update("DELETE FROM bulk_import_history WHERE lesson_id IN (SELECT lesson_id FROM lessons WHERE category_id = ?)", categoryId);
        
        // Now it's safe to delete words and lessons, and finally the category
        jdbcTemplate.update("DELETE FROM vocabulary_words WHERE lesson_id IN (SELECT lesson_id FROM lessons WHERE category_id = ?)", categoryId);
        jdbcTemplate.update("DELETE FROM lessons WHERE category_id = ?", categoryId);

        categoryRepository.delete(category);
    }

    @Transactional
    public void reorderCategories(Map<String, Integer> reorderMap) {
        reorderMap.forEach((idStr, newOrder) -> {
            UUID id = UUID.fromString(idStr);
            categoryRepository.findById(id).ifPresent(cat -> {
                cat.setSortOrder(newOrder);
                categoryRepository.save(cat);
            });
        });
    }
}
