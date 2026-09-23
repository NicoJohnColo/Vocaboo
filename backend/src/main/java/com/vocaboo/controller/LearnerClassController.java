package com.vocaboo.controller;

import com.vocaboo.dto.request.JoinClassRequest;
import com.vocaboo.dto.request.RespondInvitationRequest;
import com.vocaboo.dto.response.ClassPerformanceResponse;
import com.vocaboo.dto.response.LearnerClassSummaryResponse;
import com.vocaboo.dto.response.LearnerInvitationResponse;
import com.vocaboo.dto.response.LeaderboardEntryResponse;
import com.vocaboo.dto.response.LessonResponse;
import com.vocaboo.entity.ClassJoinRequest;
import com.vocaboo.service.ClassManagementService;
import com.vocaboo.service.ClassPerformanceService;
import com.vocaboo.service.LessonService;
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

import org.springframework.transaction.annotation.Transactional;

@RestController
@RequestMapping({"/api/learner/classes", "/api/v1/learner/classes"})
@RequiredArgsConstructor
@PreAuthorize("hasRole('LEARNER')")
public class LearnerClassController {

    private final ClassManagementService classManagementService;
    private final LessonService lessonService;
    private final ClassPerformanceService classPerformanceService;

    @PostMapping("/join")
    public ResponseEntity<Map<String, Object>> joinClass(
            @Valid @RequestBody JoinClassRequest req,
            Authentication auth) {
        UUID learnerId = parseLearnerId(auth);
        ClassJoinRequest request = classManagementService.joinClassByCode(req.getClassCode(), learnerId);
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                "status", "PENDING",
                "message", "Join request submitted! Waiting for teacher approval.",
                "requestId", request.getRequestId(),
                "className", request.getClassroom().getName()
        ));
    }

    @GetMapping
    public ResponseEntity<List<LearnerClassSummaryResponse>> getEnrolledClasses(Authentication auth) {
        UUID learnerId = parseLearnerId(auth);
        return ResponseEntity.ok(classManagementService.getLearnerClasses(learnerId));
    }

    @GetMapping("/invitations")
    public ResponseEntity<List<LearnerInvitationResponse>> getInvitations(Authentication auth) {
        UUID learnerId = parseLearnerId(auth);
        return ResponseEntity.ok(classManagementService.getLearnerInvitations(learnerId));
    }

    @PatchMapping("/invitations/{invitationId}")
    public ResponseEntity<Map<String, String>> respondToInvitation(
            @PathVariable UUID invitationId,
            @Valid @RequestBody RespondInvitationRequest req,
            Authentication auth) {
        UUID learnerId = parseLearnerId(auth);
        classManagementService.respondToInvitation(invitationId, req.getStatus(), learnerId);
        return ResponseEntity.ok(Map.of(
                "status", req.getStatus(),
                "message", "Invitation " + req.getStatus().toLowerCase() + " successfully."
        ));
    }

    @GetMapping("/{id}/categories")
    public ResponseEntity<List<com.vocaboo.dto.response.CategoryResponse>> getClassCategories(
            @PathVariable UUID id,
            Authentication auth) {
        UUID learnerId = parseLearnerId(auth);
        return ResponseEntity.ok(lessonService.getCategoriesForClass(id, learnerId));
    }

    @GetMapping("/{id}/lessons")
    public ResponseEntity<List<LessonResponse>> getClassLessons(
            @PathVariable UUID id,
            @RequestParam(required = false) UUID categoryId,
            Authentication auth) {
        UUID learnerId = parseLearnerId(auth);
        return ResponseEntity.ok(lessonService.getLessonsForClass(id, learnerId, categoryId));
    }

    /**
     * Class leaderboard — only classmates ranked by class-context points.
     * Entirely independent from the global leaderboard.
     *
     * @param id    the classroom UUID
     * @param range "weekly" (default) or "all"
     */
    @GetMapping("/{id}/leaderboard")
    public ResponseEntity<List<LeaderboardEntryResponse>> getClassLeaderboard(
            @PathVariable UUID id,
            @RequestParam(defaultValue = "weekly") String range,
            Authentication auth) {
        // Validate learner is enrolled before returning class data
        UUID learnerId = parseLearnerId(auth);
        return ResponseEntity.ok(classPerformanceService.getClassLeaderboard(id, range));
    }

    /**
     * Returns the calling learner's class-scoped performance for a specific class.
     * The mobile app uses this to display the dual score card (global + class).
     */
    @GetMapping("/{id}/performance")
    public ResponseEntity<ClassPerformanceResponse> getClassPerformance(
            @PathVariable UUID id,
            Authentication auth) {
        UUID learnerId = parseLearnerId(auth);
        return classPerformanceService.getPerformanceSummary(learnerId, id)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.ok(
                    classPerformanceService.getEmptyPerformanceSummary(id)));
    }

    /**
     * Returns class performance across ALL classes the learner is enrolled in.
     * Used to populate the learner profile's multi-class summary.
     */
    @GetMapping("/performance/all")
    public ResponseEntity<List<ClassPerformanceResponse>> getAllClassPerformances(Authentication auth) {
        UUID learnerId = parseLearnerId(auth);
        return ResponseEntity.ok(classPerformanceService.getAllClassPerformances(learnerId));
    }

    private UUID parseLearnerId(Authentication auth) {
        if (auth == null || auth.getName() == null) {
            throw new IllegalArgumentException("Unauthorized");
        }
        try {
            return UUID.fromString(auth.getName());
        } catch (Exception e) {
            throw new IllegalArgumentException("Invalid learner ID in token");
        }
    }
}
