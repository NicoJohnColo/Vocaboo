package com.vocaboo.controller;

import com.vocaboo.dto.request.CreateLessonRequest;
import com.vocaboo.dto.request.UpdateLessonRequest;
import com.vocaboo.dto.response.AdminLessonResponse;
import com.vocaboo.service.LessonManagementService;
import com.vocaboo.service.LessonReorderingService;
import com.vocaboo.service.PublishWorkflowService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/admin/lessons")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
public class AdminLessonController {

    private final LessonManagementService lessonManagementService;
    private final LessonReorderingService lessonReorderingService;
    private final PublishWorkflowService publishWorkflowService;

    /**
     * GET /api/admin/lessons — List non-deleted lessons
     * Optional: ?categoryId=uuid to filter by category
     * Optional: ?classId=uuid to filter by class
     */
    @GetMapping
    public ResponseEntity<List<AdminLessonResponse>> getAllLessons(
            @RequestParam(required = false) UUID categoryId,
            @RequestParam(required = false) UUID classId,
            @RequestParam(required = false) Boolean globalOnly,
            Authentication auth) {
        UUID teacherId = isTeacher(auth) ? parseTeacherId(auth) : null;
        List<AdminLessonResponse> lessons = lessonManagementService.getLessons(categoryId, classId, teacherId, globalOnly);
        return ResponseEntity.ok(lessons);
    }

    /**
     * GET /api/admin/lessons/{id} — Get single lesson
     */
    @GetMapping("/{id}")
    public ResponseEntity<AdminLessonResponse> getLesson(@PathVariable UUID id) {
        return ResponseEntity.ok(lessonManagementService.getLessonById(id));
    }

    /**
     * POST /api/admin/lessons — Create new lesson (starts as DRAFT)
     */
    @PostMapping
    public ResponseEntity<AdminLessonResponse> createLesson(
            @Valid @RequestBody CreateLessonRequest req,
            Authentication auth) {
        UUID teacherId = isTeacher(auth) ? parseTeacherId(auth) : null;
        AdminLessonResponse created = lessonManagementService.createLesson(req, teacherId);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    /**
     * PUT /api/admin/lessons/{id} — Update lesson title/description/gradeLevel
     */
    @PutMapping("/{id}")
    public ResponseEntity<AdminLessonResponse> updateLesson(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateLessonRequest req,
            Authentication auth) {
        UUID teacherId = isTeacher(auth) ? parseTeacherId(auth) : null;
        return ResponseEntity.ok(lessonManagementService.updateLesson(id, req, teacherId));
    }

    /**
     * DELETE /api/admin/lessons/{id} — Soft-delete lesson (cascade to words)
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteLesson(@PathVariable UUID id, Authentication auth) {
        UUID teacherId = isTeacher(auth) ? parseTeacherId(auth) : null;
        lessonManagementService.deleteLesson(id, teacherId);
        return ResponseEntity.noContent().build();
    }

    /**
     * PUT /api/admin/lessons/{id}/order — Move lesson to new position
     * Body: { "new_order": 2 }
     */
    @PutMapping("/{id}/order")
    public ResponseEntity<Map<String, String>> updateOrder(
            @PathVariable UUID id,
            @RequestBody Map<String, Integer> body) {
        Integer newOrder = body.get("new_order");
        if (newOrder == null || newOrder < 1) {
            return ResponseEntity.badRequest().body(Map.of("error", "new_order must be >= 1"));
        }
        lessonReorderingService.updateLessonOrder(id, newOrder);
        return ResponseEntity.ok(Map.of("status", "reordered"));
    }

    /**
     * PUT /api/admin/lessons/{id}/status — Change content status (DRAFT/PUBLISHED/ARCHIVED)
     * Body: { "status": "PUBLISHED", "target_grades": ["GRADE_4", "GRADE_5"] }
     */
    @PutMapping("/{id}/status")
    public ResponseEntity<Map<String, Object>> updateStatus(
            @PathVariable UUID id,
            @RequestBody Map<String, Object> body,
            Authentication auth) {
        String newStatus = (String) body.get("status");
        @SuppressWarnings("unchecked")
        List<String> targetGrades = (List<String>) body.get("target_grades");
        UUID adminId = UUID.fromString(auth.getName());

        publishWorkflowService.updateLessonStatus(id, newStatus, targetGrades, adminId);
        return ResponseEntity.ok(Map.of("status", newStatus, "lesson_id", id));
    }

    /**
     * GET /api/admin/lessons/{id}/validation-report — Content validation check
     */
    @GetMapping("/{id}/validation-report")
    public ResponseEntity<Map<String, Object>> getValidationReport(@PathVariable UUID id) {
        return ResponseEntity.ok(publishWorkflowService.getValidationReport(id));
    }

    private boolean isTeacher(Authentication auth) {
        return auth != null && auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_TEACHER"));
    }

    private UUID parseTeacherId(Authentication auth) {
        if (auth == null || auth.getName() == null) {
            return null;
        }
        try {
            return UUID.fromString(auth.getName());
        } catch (Exception e) {
            return null;
        }
    }
}
