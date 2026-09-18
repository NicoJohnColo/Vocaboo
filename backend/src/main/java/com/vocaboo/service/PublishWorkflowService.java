package com.vocaboo.service;

import com.vocaboo.entity.Lesson;
import com.vocaboo.repository.LessonRepository;
import com.vocaboo.repository.VocabularyWordRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.OffsetDateTime;
import java.util.*;

@Service
@RequiredArgsConstructor
public class PublishWorkflowService {

    private final LessonRepository lessonRepository;
    private final VocabularyWordRepository wordRepository;

    /**
     * Update lesson content status (DRAFT / PUBLISHED / ARCHIVED).
     */
    @Transactional
    public Lesson updateLessonStatus(UUID lessonId, String newStatus, List<String> targetGrades, UUID adminId) {
        Lesson lesson = findActiveLesson(lessonId);

        Set<String> valid = Set.of("DRAFT", "PUBLISHED", "ARCHIVED");
        if (!valid.contains(newStatus)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid status: " + newStatus);
        }

        boolean isTeacherLesson = lesson.getClassroom() != null
                || (lesson.getCategory() != null && lesson.getCategory().getTeacher() != null);
        if (isTeacherLesson) {
            UUID ownerTeacherId = lesson.getClassroom() != null && lesson.getClassroom().getTeacher() != null
                    ? lesson.getClassroom().getTeacher().getTeacherId()
                    : (lesson.getCategory() != null && lesson.getCategory().getTeacher() != null
                        ? lesson.getCategory().getTeacher().getTeacherId()
                        : null);
            if (adminId == null || !adminId.equals(ownerTeacherId)) {
                throw new org.springframework.security.access.AccessDeniedException(
                        "Main admin cannot modify the publish status of teacher-authored classroom lessons.");
            }
        }

        // Validate before publishing
        if ("PUBLISHED".equals(newStatus)) {
            Map<String, Object> report = buildValidationReport(lessonId, lesson);
            if (!Boolean.TRUE.equals(report.get("is_valid"))) {
                throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY,
                        "Lesson cannot be published: validation failed. Use the validation report endpoint for details.");
            }
        }

        lesson.setContentStatus(newStatus);

        if ("PUBLISHED".equals(newStatus)) {
            lesson.setPublishedDate(OffsetDateTime.now());
            lesson.setPublishedByAdminId(adminId);
            if (targetGrades != null && !targetGrades.isEmpty()) {
                lesson.setTargetGrades(String.join(",", targetGrades));
            }
        } else if ("DRAFT".equals(newStatus)) {
            // Unpublish: clear publish info
            lesson.setPublishedDate(null);
            lesson.setPublishedByAdminId(null);
        }

        return lessonRepository.save(lesson);
    }

    /**
     * Validate lesson content: word count, field completeness, etc.
     */
    @Transactional(readOnly = true)
    public Map<String, Object> getValidationReport(UUID lessonId) {
        Lesson lesson = findActiveLesson(lessonId);
        return buildValidationReport(lessonId, lesson);
    }

    // ─── helpers ─────────────────────────────────────────────────────────────

    private Map<String, Object> buildValidationReport(UUID lessonId, Lesson lesson) {
        List<String> errors = new ArrayList<>();
        List<String> warnings = new ArrayList<>();

        long wordCount = wordRepository.countByLessonLessonIdAndIsDeletedFalse(lessonId);

        if (wordCount < 1) errors.add("Lesson must have at least 1 vocabulary word (currently has " + wordCount + ")");
        if (wordCount > 20) warnings.add("Lesson has " + wordCount + " words; recommended maximum is 20");
        if (lesson.getLessonTitle() == null || lesson.getLessonTitle().isBlank()) errors.add("Lesson title is missing");
        if (lesson.getLessonDescription() == null || lesson.getLessonDescription().isBlank()) warnings.add("Lesson description is missing");

        boolean isValid = errors.isEmpty();
        Map<String, Object> report = new LinkedHashMap<>();
        report.put("lesson_id", lessonId);
        report.put("is_valid", isValid);
        report.put("word_count", wordCount);
        report.put("errors", errors);
        report.put("warnings", warnings);
        return report;
    }

    private Lesson findActiveLesson(UUID lessonId) {
        return lessonRepository.findById(lessonId)
                .filter(l -> !Boolean.TRUE.equals(l.getIsDeleted()))
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Lesson not found"));
    }
}
