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
public class LessonManagementService {

    private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(LessonManagementService.class);

    private final LessonRepository lessonRepository;
    private final VocabularyCategoryRepository categoryRepository;
    private final VocabularyWordRepository wordRepository;
    private final LearnerLessonStatusRepository learnerLessonStatusRepository;
    private final ClassroomRepository classroomRepository;
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
        return getLessons(null, null, null);
    }

    @Transactional(readOnly = true)
    public List<AdminLessonResponse> getLessonsByCategory(UUID categoryId) {
        return getLessons(categoryId, null, null);
    }

    @Transactional(readOnly = true)
    public List<AdminLessonResponse> getLessons(UUID categoryId, UUID classId, UUID teacherId) {
        return getLessons(categoryId, classId, teacherId, false);
    }

    @Transactional(readOnly = true)
    public List<AdminLessonResponse> getLessons(UUID categoryId, UUID classId, UUID teacherId, Boolean globalOnly) {
        List<Lesson> lessons;
        if (teacherId != null) {
            if (classId != null) {
                lessons = lessonRepository.findByClassroomClassIdAndIsDeletedFalseOrderByLessonOrderAsc(classId)
                        .stream()
                        .filter(l -> l.getClassroom() != null && l.getClassroom().getTeacher() != null
                                && teacherId.equals(l.getClassroom().getTeacher().getTeacherId()))
                        .toList();
            } else if (categoryId != null) {
                lessons = lessonRepository.findVisibleLessonsForTeacherByCategory(teacherId, categoryId);
            } else {
                lessons = lessonRepository.findVisibleLessonsForTeacher(teacherId);
            }
        } else {
            if (Boolean.TRUE.equals(globalOnly)) {
                if (categoryId != null) {
                    lessons = lessonRepository.findByCategoryCategoryIdAndIsDeletedFalseAndClassroomIsNullOrderByLessonOrderAsc(categoryId)
                            .stream()
                            .filter(l -> l.getCategory() == null || l.getCategory().getTeacher() == null)
                            .toList();
                } else {
                    lessons = lessonRepository.findByIsDeletedFalseAndClassroomIsNullOrderByLessonOrderAsc()
                            .stream()
                            .filter(l -> l.getCategory() == null || l.getCategory().getTeacher() == null)
                            .toList();
                }
            } else if (classId != null) {
                lessons = lessonRepository.findByClassroomClassIdAndIsDeletedFalseOrderByLessonOrderAsc(classId);
            } else if (categoryId != null) {
                lessons = lessonRepository.findByCategoryCategoryIdAndIsDeletedFalseOrderByLessonOrderAsc(categoryId);
            } else {
                lessons = lessonRepository.findByIsDeletedFalseOrderByLessonOrderAsc();
            }
        }
        return lessons.stream().map(this::toAdminResponse).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public AdminLessonResponse getLessonById(UUID lessonId) {
        Lesson lesson = findActiveLesson(lessonId);
        return toAdminResponse(lesson);
    }

    @Transactional
    public AdminLessonResponse createLesson(CreateLessonRequest req) {
        return createLesson(req, null);
    }

    @Transactional
    public AdminLessonResponse createLesson(CreateLessonRequest req, UUID teacherId) {
        UUID categoryId = parseUUID(req.getCategoryId(), "category_id");
        VocabularyCategory category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new ValidationException("category_id", "Category not found"));

        if (teacherId != null) {
            if (category.getTeacher() == null || !teacherId.equals(category.getTeacher().getTeacherId())) {
                throw new ValidationException("category_id", "You can only assign lessons to your own categories.");
            }
        } else {
            if (category.getTeacher() != null) {
                throw new ValidationException("category_id", "Admin cannot assign global lessons to teacher-specific categories.");
            }
        }

        int nextOrder = lessonRepository.findMaxLessonOrderByCategoryId(categoryId) + 1;

        LessonType type = LessonType.REGULAR;
        if (req.getLessonType() != null && !req.getLessonType().isBlank()) {
            try { type = LessonType.valueOf(req.getLessonType()); }
            catch (IllegalArgumentException e) {
                throw new ValidationException("lesson_type", "Invalid lesson type: " + req.getLessonType());
            }
        }

        Classroom classroom = null;
        if (req.getClassId() != null && !req.getClassId().isBlank() && !"GLOBAL".equalsIgnoreCase(req.getClassId())) {
            if (teacherId == null) {
                throw new org.springframework.security.access.AccessDeniedException("Administrators can only create global curriculum lessons, not teacher classroom lessons.");
            }
            UUID clsId = parseUUID(req.getClassId(), "class_id");
            classroom = classroomRepository.findById(clsId)
                    .orElseThrow(() -> new ValidationException("class_id", "Classroom not found"));
            if (classroom.getTeacher() == null || !teacherId.equals(classroom.getTeacher().getTeacherId())) {
                throw new ValidationException("class_id", "You can only assign lessons to your own classes.");
            }
        }

        Lesson lesson = Lesson.builder()
                .category(category)
                .classroom(classroom)
                .lessonTitle(req.getLessonTitle().trim())
                .lessonDescription(req.getLessonDescription().trim())
                .gradeLevel(GradeLevel.valueOf(req.getGradeLevel()))
                .lessonType(type)
                .lessonOrder(nextOrder)
                .totalWordCount(0)
                .contentStatus("DRAFT")
                .isDeleted(false)
                .module2Activities(req.getModule2Activities())
                .module3Activities(req.getModule3Activities())
                .module4Activities(req.getModule4Activities())
                .upgradeStreakRequired(req.getUpgradeStreakRequired())
                .demotionThreshold(req.getDemotionThreshold())
                .reintroductionThreshold(req.getReintroductionThreshold())
                .module3UpgradeStreakRequired(req.getModule3UpgradeStreakRequired())
                .module3DemotionThreshold(req.getModule3DemotionThreshold())
                .streakCelebrationThreshold(req.getStreakCelebrationThreshold())
                .contextParagraph(req.getContextParagraph() != null && !req.getContextParagraph().isBlank() ? req.getContextParagraph().trim() : null)
                .build();

        Lesson saved = lessonRepository.save(lesson);
        return toAdminResponse(saved);
    }

    @Transactional
    public AdminLessonResponse createLessonForClass(UUID classId, CreateLessonRequest req, UUID teacherId, boolean isAdmin) {
        Classroom classroom = classroomRepository.findById(classId)
                .orElseThrow(() -> new IllegalArgumentException("Class not found"));

        if (!isAdmin && !classroom.getTeacher().getTeacherId().equals(teacherId)) {
            throw new org.springframework.security.access.AccessDeniedException("You do not have permission to add lessons to this class.");
        }

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
                .classroom(classroom)
                .lessonTitle(req.getLessonTitle().trim())
                .lessonDescription(req.getLessonDescription().trim())
                .gradeLevel(GradeLevel.valueOf(req.getGradeLevel()))
                .lessonType(type)
                .lessonOrder(nextOrder)
                .totalWordCount(0)
                .contentStatus("DRAFT")
                .isDeleted(false)
                .module2Activities(req.getModule2Activities())
                .module3Activities(req.getModule3Activities())
                .module4Activities(req.getModule4Activities())
                .upgradeStreakRequired(req.getUpgradeStreakRequired())
                .demotionThreshold(req.getDemotionThreshold())
                .reintroductionThreshold(req.getReintroductionThreshold())
                .module3UpgradeStreakRequired(req.getModule3UpgradeStreakRequired())
                .module3DemotionThreshold(req.getModule3DemotionThreshold())
                .streakCelebrationThreshold(req.getStreakCelebrationThreshold())
                .contextParagraph(req.getContextParagraph() != null && !req.getContextParagraph().isBlank() ? req.getContextParagraph().trim() : null)
                .build();

        Lesson saved = lessonRepository.save(lesson);
        log.info("Created lesson '{}' for class '{}'", saved.getLessonTitle(), classroom.getName());
        return toAdminResponse(saved);
    }

    @Transactional
    public AdminLessonResponse updateLesson(UUID lessonId, UpdateLessonRequest req) {
        return updateLesson(lessonId, req, null);
    }

    @Transactional
    public AdminLessonResponse updateLesson(UUID lessonId, UpdateLessonRequest req, UUID teacherId) {
        Lesson lesson = findActiveLesson(lessonId);

        if (teacherId != null) {
            boolean isOwner = (lesson.getClassroom() != null && lesson.getClassroom().getTeacher() != null
                    && teacherId.equals(lesson.getClassroom().getTeacher().getTeacherId()))
                    || (lesson.getCategory() != null && lesson.getCategory().getTeacher() != null
                    && teacherId.equals(lesson.getCategory().getTeacher().getTeacherId()));
            if (!isOwner) {
                throw new org.springframework.security.access.AccessDeniedException("You do not have permission to edit this lesson.");
            }
        } else {
            // Main Admin: Cannot modify teacher-authored classroom lessons
            boolean isTeacherLesson = lesson.getClassroom() != null
                    || (lesson.getCategory() != null && lesson.getCategory().getTeacher() != null);
            if (isTeacherLesson) {
                throw new org.springframework.security.access.AccessDeniedException(
                        "Main admin has read-only access to teacher-authored classroom lessons. Only the authoring teacher can edit this lesson.");
            }
        }

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
        if (req.getModule2Activities() != null && !req.getModule2Activities().isBlank()) {
            lesson.setModule2Activities(req.getModule2Activities().trim());
        }
        if (req.getModule3Activities() != null && !req.getModule3Activities().isBlank()) {
            lesson.setModule3Activities(req.getModule3Activities().trim());
        }
        if (req.getModule4Activities() != null && !req.getModule4Activities().isBlank()) {
            lesson.setModule4Activities(req.getModule4Activities().trim());
        }
        if (req.getUpgradeStreakRequired() != null) {
            lesson.setUpgradeStreakRequired(req.getUpgradeStreakRequired());
        }
        if (req.getDemotionThreshold() != null) {
            lesson.setDemotionThreshold(req.getDemotionThreshold());
        }
        if (req.getReintroductionThreshold() != null) {
            lesson.setReintroductionThreshold(req.getReintroductionThreshold());
        }
        if (req.getModule3UpgradeStreakRequired() != null) {
            lesson.setModule3UpgradeStreakRequired(req.getModule3UpgradeStreakRequired());
        }
        if (req.getModule3DemotionThreshold() != null) {
            lesson.setModule3DemotionThreshold(req.getModule3DemotionThreshold());
        }
        if (req.getStreakCelebrationThreshold() != null) {
            lesson.setStreakCelebrationThreshold(req.getStreakCelebrationThreshold());
        }
        if (req.getContextParagraph() != null) {
            lesson.setContextParagraph(req.getContextParagraph().isBlank() ? null : req.getContextParagraph().trim());
        }
        if (req.getClassId() != null) {
            if (req.getClassId().isBlank() || "GLOBAL".equalsIgnoreCase(req.getClassId())) {
                if (teacherId != null) {
                    throw new ValidationException("class_id", "Teacher lessons cannot be converted to global lessons.");
                }
                lesson.setClassroom(null);
            } else {
                UUID clsId = parseUUID(req.getClassId(), "class_id");
                Classroom classroom = classroomRepository.findById(clsId)
                        .orElseThrow(() -> new ValidationException("class_id", "Classroom not found"));
                if (teacherId != null && (classroom.getTeacher() == null || !teacherId.equals(classroom.getTeacher().getTeacherId()))) {
                    throw new ValidationException("class_id", "You can only assign lessons to your own classes.");
                }
                lesson.setClassroom(classroom);
            }
        }

        return toAdminResponse(lessonRepository.save(lesson));
    }

    @Transactional
    public void deleteLesson(UUID lessonId) {
        deleteLesson(lessonId, null);
    }

    @Transactional
    public void deleteLesson(UUID lessonId, UUID teacherId) {
        Lesson lesson = findActiveLesson(lessonId);

        if (teacherId != null) {
            boolean isOwner = (lesson.getClassroom() != null && lesson.getClassroom().getTeacher() != null
                    && teacherId.equals(lesson.getClassroom().getTeacher().getTeacherId()))
                    || (lesson.getCategory() != null && lesson.getCategory().getTeacher() != null
                    && teacherId.equals(lesson.getCategory().getTeacher().getTeacherId()));
            if (!isOwner) {
                throw new org.springframework.security.access.AccessDeniedException("You do not have permission to delete this lesson.");
            }
        } else {
            // Main Admin: Cannot delete teacher-authored classroom lessons
            boolean isTeacherLesson = lesson.getClassroom() != null
                    || (lesson.getCategory() != null && lesson.getCategory().getTeacher() != null);
            if (isTeacherLesson) {
                throw new org.springframework.security.access.AccessDeniedException(
                        "Main admin cannot delete teacher-authored classroom lessons.");
            }
        }

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
                .contextParagraph(l.getContextParagraph())
                .module2Activities(l.getModule2Activities())
                .module3Activities(l.getModule3Activities())
                .module4Activities(l.getModule4Activities())
                .upgradeStreakRequired(l.getUpgradeStreakRequired())
                .demotionThreshold(l.getDemotionThreshold())
                .reintroductionThreshold(l.getReintroductionThreshold())
                .module3UpgradeStreakRequired(l.getModule3UpgradeStreakRequired())
                .module3DemotionThreshold(l.getModule3DemotionThreshold())
                .streakCelebrationThreshold(l.getStreakCelebrationThreshold())
                .classId(l.getClassroom() != null ? l.getClassroom().getClassId() : null)
                .className(l.getClassroom() != null ? l.getClassroom().getName() : null)
                .classCode(l.getClassroom() != null ? l.getClassroom().getClassCode() : null)
                .build();
    }

    private UUID parseUUID(String value, String field) {
        try { return UUID.fromString(value); }
        catch (Exception e) { throw new ValidationException(field, "Invalid UUID format"); }
    }
}
