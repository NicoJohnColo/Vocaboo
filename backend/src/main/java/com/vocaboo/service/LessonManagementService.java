package com.vocaboo.service;

import com.vocaboo.dto.request.CreateLessonRequest;
import com.vocaboo.dto.request.UpdateLessonRequest;
import com.vocaboo.dto.response.AdminLessonResponse;
import com.vocaboo.entity.*;
import com.vocaboo.exception.ValidationException;
import com.vocaboo.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import jakarta.annotation.PostConstruct;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class LessonManagementService {

    private final LessonRepository lessonRepository;
    private final VocabularyCategoryRepository categoryRepository;
    private final VocabularyWordRepository wordRepository;
    private final LearnerLessonStatusRepository learnerLessonStatusRepository;
    private final JdbcTemplate jdbcTemplate;

    @PostConstruct
    @Transactional
    public void cleanupSoftDeletedLessons() {
        log.info("Cleaning up previously soft-deleted lessons from Supabase...");
        List<Lesson> deletedLessons = lessonRepository.findAll().stream()
                .filter(l -> Boolean.TRUE.equals(l.getIsDeleted()))
                .toList();

        for (Lesson l : deletedLessons) {
            UUID lessonId = l.getLessonId();
            jdbcTemplate.update("DELETE FROM diagnostic_results WHERE lesson_id = ?", lessonId);
            jdbcTemplate.update("DELETE FROM pronunciation_attempts WHERE lesson_id = ?", lessonId);
            jdbcTemplate.update("DELETE FROM word_progress WHERE lesson_id = ?", lessonId);
            jdbcTemplate.update("DELETE FROM confusable_word_pairs WHERE lesson_id = ?", lessonId);
            jdbcTemplate.update("DELETE FROM learner_lesson_status WHERE lesson_id = ?", lessonId);
            jdbcTemplate.update("DELETE FROM introduction_sessions WHERE lesson_id = ?", lessonId);
            jdbcTemplate.update("DELETE FROM review_items WHERE session_id IN (SELECT session_id FROM review_sessions WHERE lesson_id = ?)", lessonId);
            jdbcTemplate.update("DELETE FROM review_sessions WHERE lesson_id = ?", lessonId);
            jdbcTemplate.update("DELETE FROM asset_uploads WHERE lesson_id = ?", lessonId);
            jdbcTemplate.update("DELETE FROM bulk_import_history WHERE lesson_id = ?", lessonId);
            jdbcTemplate.update("DELETE FROM vocabulary_words WHERE lesson_id = ?", lessonId);
            
            lessonRepository.delete(l);
        }
        log.info("Successfully permanently deleted {} previously soft-deleted lessons.", deletedLessons.size());
    }

    @Transactional(readOnly = true)
    public List<AdminLessonResponse> getAllLessons() {
        return lessonRepository.findByIsDeletedFalseOrderByLessonOrderAsc()
                .stream()
                .map(this::toAdminResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<AdminLessonResponse> getLessonsByCategory(UUID categoryId) {
        return lessonRepository.findByCategoryCategoryIdAndIsDeletedFalseOrderByLessonOrderAsc(categoryId)
                .stream()
                .map(this::toAdminResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public AdminLessonResponse getLessonById(UUID lessonId) {
        Lesson lesson = findActiveLesson(lessonId);
        return toAdminResponse(lesson);
    }

    @Transactional
    public AdminLessonResponse createLesson(CreateLessonRequest req) {
        UUID categoryId = parseUUID(req.getCategoryId(), "category_id");
        VocabularyCategory category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new ValidationException("category_id", "Category not found"));

        int nextOrder = lessonRepository.findMaxLessonOrderByCategoryId(categoryId) + 1;

        LessonType type = LessonType.REGULAR;
        if (req.getLessonType() != null && !req.getLessonType().isBlank()) {
            try { type = LessonType.valueOf(req.getLessonType()); }
            catch (IllegalArgumentException e) {
                throw new ValidationException("lesson_type", "Invalid lesson type: " + req.getLessonType());
            }
        }

        Lesson lesson = Lesson.builder()
                .category(category)
                .lessonTitle(req.getLessonTitle().trim())
                .lessonDescription(req.getLessonDescription().trim())
                .gradeLevel(GradeLevel.valueOf(req.getGradeLevel()))
                .lessonType(type)
                .lessonOrder(nextOrder)
                .totalWordCount(0)
                .contentStatus("DRAFT")
                .isDeleted(false)
                .build();

        Lesson saved = lessonRepository.save(lesson);
        return toAdminResponse(saved);
    }

    @Transactional
    public AdminLessonResponse updateLesson(UUID lessonId, UpdateLessonRequest req) {
        Lesson lesson = findActiveLesson(lessonId);

        if (req.getLessonTitle() != null && !req.getLessonTitle().isBlank()) {
            lesson.setLessonTitle(req.getLessonTitle().trim());
        }
        if (req.getLessonDescription() != null) {
            lesson.setLessonDescription(req.getLessonDescription().trim());
        }
        if (req.getGradeLevel() != null && !req.getGradeLevel().isBlank()) {
            try { lesson.setGradeLevel(GradeLevel.valueOf(req.getGradeLevel())); }
            catch (IllegalArgumentException e) {
                throw new ValidationException("grade_level", "Invalid grade level");
            }
        }

        return toAdminResponse(lessonRepository.save(lesson));
    }

    @Transactional
    public void deleteLesson(UUID lessonId) {
        Lesson lesson = findActiveLesson(lessonId);

        // Manually cascade delete everything tied to the lesson to bypass rogue foreign keys
        jdbcTemplate.update("DELETE FROM diagnostic_results WHERE lesson_id = ?", lessonId);
        jdbcTemplate.update("DELETE FROM pronunciation_attempts WHERE lesson_id = ?", lessonId);
        jdbcTemplate.update("DELETE FROM word_progress WHERE lesson_id = ?", lessonId);
        jdbcTemplate.update("DELETE FROM confusable_word_pairs WHERE lesson_id = ?", lessonId);
        jdbcTemplate.update("DELETE FROM learner_lesson_status WHERE lesson_id = ?", lessonId);
        jdbcTemplate.update("DELETE FROM introduction_sessions WHERE lesson_id = ?", lessonId);
        jdbcTemplate.update("DELETE FROM review_items WHERE session_id IN (SELECT session_id FROM review_sessions WHERE lesson_id = ?)", lessonId);
        jdbcTemplate.update("DELETE FROM review_sessions WHERE lesson_id = ?", lessonId);
        jdbcTemplate.update("DELETE FROM asset_uploads WHERE lesson_id = ?", lessonId);
        jdbcTemplate.update("DELETE FROM bulk_import_history WHERE lesson_id = ?", lessonId);
        jdbcTemplate.update("DELETE FROM vocabulary_words WHERE lesson_id = ?", lessonId);

        // Hard-delete the lesson
        lessonRepository.delete(lesson);
    }

    // ─── helpers ──────────────────────────────────────────────────────────────

    private Lesson findActiveLesson(UUID lessonId) {
        return lessonRepository.findById(lessonId)
                .filter(l -> !Boolean.TRUE.equals(l.getIsDeleted()))
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Lesson not found"));
    }

    private AdminLessonResponse toAdminResponse(Lesson l) {
        return AdminLessonResponse.builder()
                .lessonId(l.getLessonId())
                .lessonTitle(l.getLessonTitle())
                .lessonDescription(l.getLessonDescription())
                .categoryId(l.getCategory().getCategoryId())
                .categoryName(l.getCategory().getCategoryName())
                .gradeLevel(l.getGradeLevel() != null ? l.getGradeLevel().name() : null)
                .lessonOrder(l.getLessonOrder())
                .totalWordCount(l.getTotalWordCount())
                .lessonType(l.getLessonType() != null ? l.getLessonType().name() : "REGULAR")
                .contentStatus(l.getContentStatus())
                .targetGrades(l.getTargetGrades())
                .publishedDate(l.getPublishedDate())
                .createdAt(l.getCreatedAt())
                .updatedAt(l.getUpdatedAt())
                .build();
    }

    private UUID parseUUID(String value, String field) {
        try { return UUID.fromString(value); }
        catch (Exception e) { throw new ValidationException(field, "Invalid UUID format"); }
    }
}
