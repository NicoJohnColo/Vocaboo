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
    private final com.vocaboo.repository.TeacherRepository teacherRepository;
    private final com.vocaboo.repository.ClassroomRepository classroomRepository;
    private final LessonRepository lessonRepository;
    private final VocabularyWordRepository wordRepository;
    private final JdbcTemplate jdbcTemplate;

    @Transactional(readOnly = true)
    public List<VocabularyCategory> getAllCategories() {
        return getAllCategories(null, null);
    }

    @Transactional(readOnly = true)
    public List<VocabularyCategory> getAllCategories(UUID teacherId) {
        return getAllCategories(teacherId, null);
    }

    @Transactional(readOnly = true)
    public List<VocabularyCategory> getAllCategories(UUID teacherId, UUID classId) {
        if (teacherId != null) {
            if (classId != null) {
                return categoryRepository.findByTeacherTeacherIdAndClassroomClassIdOrderBySortOrderAsc(teacherId, classId);
            }
            return categoryRepository.findByTeacherTeacherIdOrderBySortOrderAsc(teacherId);
        }
        return categoryRepository.findByTeacherIsNullAndClassroomIsNullOrderBySortOrderAsc();
    }

    @Transactional
    public VocabularyCategory createCategory(CreateCategoryRequest req) {
        return createCategory(req, null);
    }

    @Transactional
    public VocabularyCategory createCategory(CreateCategoryRequest req, UUID teacherId) {
        String trimmedName = req.getCategoryName().trim();
        com.vocaboo.entity.Teacher teacher = null;
        com.vocaboo.entity.Classroom classroom = null;
        int sortOrder;

        if (teacherId != null) {
            teacher = teacherRepository.findById(teacherId)
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Teacher not found"));
            if (req.getClassId() == null) {
                throw new ValidationException("class_id", "A classroom must be selected for this category");
            }
            classroom = classroomRepository.findById(req.getClassId())
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Classroom not found"));
            if (!teacherId.equals(classroom.getTeacher().getTeacherId())) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "You can only create categories for your own classrooms");
            }
            if (categoryRepository.existsByCategoryNameIgnoreCaseAndClassroomClassId(trimmedName, classroom.getClassId())) {
                throw new ValidationException("category_name", "A category with this name already exists in this classroom");
            }
            sortOrder = req.getSortOrder() != null
                    ? req.getSortOrder()
                    : categoryRepository.findMaxSortOrderByClassroomId(classroom.getClassId()) + 1;
        } else {
            if (categoryRepository.existsByCategoryNameIgnoreCaseAndTeacherIsNullAndClassroomIsNull(trimmedName)) {
                throw new ValidationException("category_name", "A global category with this name already exists");
            }
            sortOrder = req.getSortOrder() != null
                    ? req.getSortOrder()
                    : categoryRepository.findMaxSortOrderGlobal() + 1;
        }

        VocabularyCategory category = VocabularyCategory.builder()
                .categoryName(trimmedName)
                .description(req.getDescription())
                .sortOrder(sortOrder)
                .teacher(teacher)
                .classroom(classroom)
                .build();

        return categoryRepository.save(category);
    }

    @Transactional
    public VocabularyCategory updateCategory(UUID categoryId, UpdateCategoryRequest req) {
        return updateCategory(categoryId, req, null);
    }

    @Transactional
    public VocabularyCategory updateCategory(UUID categoryId, UpdateCategoryRequest req, UUID teacherId) {
        VocabularyCategory category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Category not found"));

        if (teacherId != null) {
            if (category.getTeacher() == null || !teacherId.equals(category.getTeacher().getTeacherId())) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "You do not have permission to modify this category");
            }
        } else {
            if (category.getTeacher() != null) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Global admin cannot directly modify teacher-owned categories");
            }
        }

        if (req.getClassId() != null && teacherId != null) {
            com.vocaboo.entity.Classroom newClassroom = classroomRepository.findById(req.getClassId())
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Classroom not found"));
            if (!teacherId.equals(newClassroom.getTeacher().getTeacherId())) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "You do not own this classroom");
            }
            category.setClassroom(newClassroom);
        }

        if (req.getCategoryName() != null && !req.getCategoryName().isBlank()) {
            String newName = req.getCategoryName().trim();
            if (!newName.equalsIgnoreCase(category.getCategoryName())) {
                boolean duplicate;
                if (teacherId != null && category.getClassroom() != null) {
                    duplicate = categoryRepository.existsByCategoryNameIgnoreCaseAndClassroomClassId(newName, category.getClassroom().getClassId());
                } else if (teacherId != null) {
                    duplicate = categoryRepository.existsByCategoryNameIgnoreCaseAndTeacherTeacherId(newName, teacherId);
                } else {
                    duplicate = categoryRepository.existsByCategoryNameIgnoreCaseAndTeacherIsNullAndClassroomIsNull(newName);
                }
                if (duplicate) {
                    throw new ValidationException("category_name", "A category with this name already exists in this scope");
                }
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
        deleteCategory(categoryId, null);
    }

    @Transactional
    public void deleteCategory(UUID categoryId, UUID teacherId) {
        VocabularyCategory category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Category not found"));

        if (teacherId != null) {
            if (category.getTeacher() == null || !teacherId.equals(category.getTeacher().getTeacherId())) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "You do not have permission to delete this category");
            }
        } else {
            if (category.getTeacher() != null) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Global admin cannot directly delete teacher-owned categories");
            }
        }

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
        reorderCategories(reorderMap, null);
    }

    @Transactional
    public void reorderCategories(Map<String, Integer> reorderMap, UUID teacherId) {
        reorderMap.forEach((idStr, newOrder) -> {
            UUID id = UUID.fromString(idStr);
            categoryRepository.findById(id).ifPresent(cat -> {
                if (teacherId != null) {
                    if (cat.getTeacher() != null && teacherId.equals(cat.getTeacher().getTeacherId())) {
                        cat.setSortOrder(newOrder);
                        categoryRepository.save(cat);
                    }
                } else {
                    if (cat.getTeacher() == null) {
                        cat.setSortOrder(newOrder);
                        categoryRepository.save(cat);
                    }
                }
            });
        });
    }
}
