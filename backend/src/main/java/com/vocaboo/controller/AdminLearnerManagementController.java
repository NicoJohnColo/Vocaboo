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

import java.util.List;
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
            @RequestParam(defaultValue = "asc") String sortDir,
            Authentication auth) {

        UUID teacherId = isTeacher(auth) ? parseAdminId(auth) : null;
        Sort sort = "desc".equalsIgnoreCase(sortDir) ? Sort.by(sortBy).descending() : Sort.by(sortBy).ascending();
        Pageable pageable = PageRequest.of(page, size, sort);

        Page<AdminLearnerSummaryResponse> result = adminLearnerService.searchLearners(
                search, sectionId, gradeLevel, isActive, cohortType, teacherId, pageable);
        return ResponseEntity.ok(result);
    }

    /**
     * GET /api/admin/learners/{id}
     * Get comprehensive profile & performance report for a student.
     */
    @GetMapping("/{id}")
    public ResponseEntity<AdminLearnerDetailResponse> getLearnerDetail(
            @PathVariable UUID id,
            @RequestParam(required = false) UUID classId,
            Authentication auth) {
        UUID teacherId = isTeacher(auth) ? parseAdminId(auth) : null;
        return ResponseEntity.ok(adminLearnerService.getLearnerDetail(id, teacherId, classId));
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
     * Assign student to a section (Teacher only).
     */
    @PostMapping("/{id}/assign-class")
    public ResponseEntity<Map<String, String>> assignClass(
            @PathVariable UUID id,
            @RequestBody AssignSectionRequest req,
            Authentication auth) {
        if (!isTeacher(auth)) {
            throw new org.springframework.security.access.AccessDeniedException("Administrators cannot assign students to classroom sections. Section assignments are managed by teachers.");
        }
        UUID teacherId = parseAdminId(auth);
        adminSectionService.assignLearnerToSection(id, req.getSectionId(), teacherId);
        return ResponseEntity.ok(Map.of("status", "assigned", "message", "Learner section updated successfully"));
    }

    /**
     * POST /api/admin/learners/{id}/deactivate
     * Soft-deactivate student (Admin only).
     */
    @PostMapping("/{id}/deactivate")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, String>> deactivateLearner(
            @PathVariable UUID id,
            Authentication auth) {
        UUID adminId = parseAdminId(auth);
        adminLearnerService.deactivateLearner(id, adminId);
        return ResponseEntity.ok(Map.of("status", "deactivated", "message", "Student account has been deactivated"));
    }

    /**
     * POST /api/admin/learners/{id}/reactivate
     * Reactivate student (Admin only).
     */
    @PostMapping("/{id}/reactivate")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, String>> reactivateLearner(
            @PathVariable UUID id,
            Authentication auth) {
        UUID adminId = parseAdminId(auth);
        adminLearnerService.reactivateLearner(id, adminId);
        return ResponseEntity.ok(Map.of("status", "reactivated", "message", "Student account has been reactivated"));
    }

    /**
     * DELETE /api/admin/learners/{id}
     * Permanently delete student account and associated data (Admin only).
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, String>> deleteLearner(
            @PathVariable UUID id,
            Authentication auth) {
        UUID adminId = parseAdminId(auth);
        adminLearnerService.deleteLearner(id, adminId);
        return ResponseEntity.ok(Map.of("status", "deleted", "message", "Student account has been permanently deleted"));
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
        boolean isTeacher = isTeacher(auth);
        if (!isTeacher && req.getAction() == com.vocaboo.dto.request.BulkLearnerActionRequest.BulkActionType.ASSIGN_SECTION) {
            throw new org.springframework.security.access.AccessDeniedException("Administrators cannot assign students to teacher classroom sections.");
        }
        if (isTeacher && (req.getAction() == com.vocaboo.dto.request.BulkLearnerActionRequest.BulkActionType.DEACTIVATE || req.getAction() == com.vocaboo.dto.request.BulkLearnerActionRequest.BulkActionType.REACTIVATE)) {
            throw new org.springframework.security.access.AccessDeniedException("Teachers cannot deactivate or reactivate global student accounts.");
        }
        return ResponseEntity.ok(adminLearnerService.executeBulkAction(req, adminId));
    }

    /**
     * GET /api/admin/learners/flagged
     * List learners requiring teacher attention due to repeated reintroductions or excessive mistakes.
     */
    @GetMapping("/flagged")
    public ResponseEntity<List<com.vocaboo.dto.response.FlaggedLearnerResponse>> listFlaggedLearners(
            @RequestParam(required = false) UUID sectionId,
            @RequestParam(required = false) GradeLevel gradeLevel,
            Authentication auth) {
        UUID teacherId = isTeacher(auth) ? parseAdminId(auth) : null;
        return ResponseEntity.ok(adminLearnerService.getFlaggedLearners(sectionId, gradeLevel, teacherId));
    }

    /**
     * POST /api/admin/learners/flagged/{progressId}/resolve
     * Acknowledge and resolve a teacher review flag on a learner's difficulty progress.
     */
    @PostMapping("/flagged/{progressId}/resolve")
    public ResponseEntity<Map<String, String>> resolveFlag(
            @PathVariable UUID progressId,
            Authentication auth) {
        String adminEmail = auth != null ? auth.getName() : "teacher";
        adminLearnerService.resolveFlaggedLearner(progressId, adminEmail);
        return ResponseEntity.ok(Map.of("status", "resolved", "message", "Teacher review flag cleared successfully."));
    }

    /**
     * GET /api/admin/learners/invite-search
     * Search all active learners by name or user ID for teacher invitation purposes.
     * Unlike the main list endpoint, this does NOT scope results to the teacher's own class.
     */
    @GetMapping("/invite-search")
    public ResponseEntity<Page<AdminLearnerSummaryResponse>> inviteSearch(
            @RequestParam(required = false) String search,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            Authentication auth) {
        Sort sort = Sort.by("displayName").ascending();
        Pageable pageable = PageRequest.of(page, size, sort);
        // Pass teacherId=null so results are NOT scoped to the teacher's own students
        Page<AdminLearnerSummaryResponse> result = adminLearnerService.searchLearners(
                search, null, null, null, null, null, pageable);
        return ResponseEntity.ok(result);
    }

    private UUID parseAdminId(Authentication auth) {
        if (auth == null || auth.getName() == null) return null;
        try {
            return UUID.fromString(auth.getName());
        } catch (Exception e) {
            return null;
        }
    }

    private boolean isTeacher(Authentication auth) {
        if (auth == null) return false;
        return auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_TEACHER"));
    }
}
