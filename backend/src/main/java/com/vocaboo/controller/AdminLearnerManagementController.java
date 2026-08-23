package com.vocaboo.controller;

import com.vocaboo.dto.request.AssignSectionRequest;
import com.vocaboo.dto.request.BulkLearnerActionRequest;
import com.vocaboo.dto.request.ResetLearnerProgressRequest;
import com.vocaboo.dto.request.UpdateLearnerAdminRequest;
import com.vocaboo.dto.response.AdminLearnerDetailResponse;
import com.vocaboo.dto.response.AdminLearnerSummaryResponse;
import com.vocaboo.entity.GradeLevel;
import com.vocaboo.service.AdminLearnerService;
import com.vocaboo.service.AdminSectionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/admin/learners")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
public class AdminLearnerManagementController {

    private final AdminLearnerService adminLearnerService;
    private final AdminSectionService adminSectionService;

    /**
     * GET /api/admin/learners
     * List / search learners with filters and pagination.
     */
    @GetMapping
    public ResponseEntity<Page<AdminLearnerSummaryResponse>> listLearners(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) UUID sectionId,
            @RequestParam(required = false) GradeLevel gradeLevel,
            @RequestParam(required = false) Boolean isActive,
            @RequestParam(required = false) String cohortType,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "displayName") String sortBy,
            @RequestParam(defaultValue = "asc") String sortDir) {

        Sort sort = "desc".equalsIgnoreCase(sortDir) ? Sort.by(sortBy).descending() : Sort.by(sortBy).ascending();
        Pageable pageable = PageRequest.of(page, size, sort);

        Page<AdminLearnerSummaryResponse> result = adminLearnerService.searchLearners(
                search, sectionId, gradeLevel, isActive, cohortType, pageable);
        return ResponseEntity.ok(result);
    }

    /**
     * GET /api/admin/learners/{id}
     * Get comprehensive profile & performance report for a student.
     */
    @GetMapping("/{id}")
    public ResponseEntity<AdminLearnerDetailResponse> getLearnerDetail(@PathVariable UUID id) {
        return ResponseEntity.ok(adminLearnerService.getLearnerDetail(id));
    }

    /**
     * PATCH /api/admin/learners/{id}
     * Update student profile fields (grade, section, name, etc.).
     */
    @PatchMapping("/{id}")
    public ResponseEntity<AdminLearnerSummaryResponse> updateLearner(
            @PathVariable UUID id,
            @RequestBody UpdateLearnerAdminRequest req,
            Authentication auth) {
        UUID adminId = parseAdminId(auth);
        return ResponseEntity.ok(adminLearnerService.updateLearner(id, req, adminId));
    }

    /**
     * POST /api/admin/learners/{id}/assign-class
     * Assign student to a section.
     */
    @PostMapping("/{id}/assign-class")
    public ResponseEntity<Map<String, String>> assignClass(
            @PathVariable UUID id,
            @RequestBody AssignSectionRequest req,
            Authentication auth) {
        UUID adminId = parseAdminId(auth);
        adminSectionService.assignLearnerToSection(id, req.getSectionId(), adminId);
        return ResponseEntity.ok(Map.of("status", "assigned", "message", "Learner section updated successfully"));
    }

    /**
     * POST /api/admin/learners/{id}/deactivate
     * Soft-deactivate student.
     */
    @PostMapping("/{id}/deactivate")
    public ResponseEntity<Map<String, String>> deactivateLearner(
            @PathVariable UUID id,
            Authentication auth) {
        UUID adminId = parseAdminId(auth);
        adminLearnerService.deactivateLearner(id, adminId);
        return ResponseEntity.ok(Map.of("status", "deactivated", "message", "Student account has been deactivated"));
    }

    /**
     * POST /api/admin/learners/{id}/reactivate
     * Reactivate student.
     */
    @PostMapping("/{id}/reactivate")
    public ResponseEntity<Map<String, String>> reactivateLearner(
            @PathVariable UUID id,
            Authentication auth) {
        UUID adminId = parseAdminId(auth);
        adminLearnerService.reactivateLearner(id, adminId);
        return ResponseEntity.ok(Map.of("status", "reactivated", "message", "Student account has been reactivated"));
    }

    /**
     * POST /api/admin/learners/{id}/reset-progress
     * Reset progress (full wipe or lesson-specific).
     */
    @PostMapping("/{id}/reset-progress")
    public ResponseEntity<Map<String, String>> resetProgress(
            @PathVariable UUID id,
            @RequestBody(required = false) ResetLearnerProgressRequest req,
            Authentication auth) {
        UUID adminId = parseAdminId(auth);
        UUID lessonId = (req != null) ? req.getLessonId() : null;
        adminLearnerService.resetLearnerProgress(id, lessonId, adminId);
        String msg = lessonId == null
                ? "All learner progress has been reset back to LEARNING baseline."
                : "Progress for lesson " + lessonId + " has been reset.";
        return ResponseEntity.ok(Map.of("status", "reset_complete", "message", msg));
    }

    /**
     * POST /api/admin/learners/bulk-action
     * Bulk actions (ASSIGN_SECTION, DEACTIVATE, REACTIVATE, RESET_PROGRESS).
     */
    @PostMapping("/bulk-action")
    public ResponseEntity<Map<String, Object>> bulkAction(
            @Valid @RequestBody BulkLearnerActionRequest req,
            Authentication auth) {
        UUID adminId = parseAdminId(auth);
        return ResponseEntity.ok(adminLearnerService.executeBulkAction(req, adminId));
    }

    private UUID parseAdminId(Authentication auth) {
        if (auth == null || auth.getName() == null) return null;
        try {
            return UUID.fromString(auth.getName());
        } catch (Exception e) {
            return null;
        }
    }
}
