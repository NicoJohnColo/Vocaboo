package com.vocaboo.controller;

import com.vocaboo.dto.request.CreateClassRequest;
import com.vocaboo.dto.request.CreateLessonRequest;
import com.vocaboo.dto.request.InviteLearnerRequest;
import com.vocaboo.dto.request.ReviewJoinRequestDto;
import com.vocaboo.dto.response.AdminLessonResponse;
import com.vocaboo.dto.response.ClassDetailResponse;
import com.vocaboo.dto.response.ClassResponse;
import com.vocaboo.entity.Lesson;
import com.vocaboo.repository.LessonRepository;
import com.vocaboo.service.ClassManagementService;
import com.vocaboo.service.LessonManagementService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@RestController
@RequestMapping("/api/teacher/classes")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('TEACHER', 'ADMIN')")
public class TeacherClassController {

    private final ClassManagementService classManagementService;
    private final LessonManagementService lessonManagementService;
    private final LessonRepository lessonRepository;

    @PostMapping
    public ResponseEntity<ClassResponse> createClass(
            @Valid @RequestBody CreateClassRequest req,
            Authentication auth) {
        if (isAdmin(auth)) {
            throw new org.springframework.security.access.AccessDeniedException("Main admin has view-only access. Only teachers can create classroom cohorts.");
        }
        UUID teacherId = parseUserId(auth);
        ClassResponse response = classManagementService.createClass(req, teacherId);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping
    public ResponseEntity<List<ClassResponse>> getClasses(
            @RequestParam(required = false) String cohortType,
            Authentication auth) {
        boolean isAdmin = isAdmin(auth);
        UUID teacherId = parseUserIdSafe(auth);
        return ResponseEntity.ok(classManagementService.getClassesForTeacher(teacherId, isAdmin, cohortType));
    }

    @GetMapping("/search")
    public ResponseEntity<List<Map<String, Object>>> searchLearners(
            @RequestParam("q") String query) {
        return ResponseEntity.ok(classManagementService.searchLearnersForInvitation(query));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ClassDetailResponse> getClassDetail(
            @PathVariable UUID id,
            Authentication auth) {
        boolean isAdmin = isAdmin(auth);
        UUID teacherId = parseUserIdSafe(auth);
        return ResponseEntity.ok(classManagementService.getClassDetail(id, teacherId, isAdmin));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Map<String, String>> deleteClass(
            @PathVariable UUID id,
            Authentication auth) {
        boolean isAdmin = isAdmin(auth);
        UUID teacherId = parseUserIdSafe(auth);
        classManagementService.deleteClass(id, teacherId, isAdmin);
        return ResponseEntity.ok(Map.of("message", "Class deleted successfully"));
    }

    @PostMapping("/{id}/invitations")
    public ResponseEntity<ClassDetailResponse.InvitationDto> inviteLearner(
            @PathVariable UUID id,
            @Valid @RequestBody InviteLearnerRequest req,
            Authentication auth) {
        if (isAdmin(auth)) {
            throw new org.springframework.security.access.AccessDeniedException("Main admin has view-only access to teacher classrooms.");
        }
        UUID teacherId = parseUserId(auth);
        ClassDetailResponse.InvitationDto dto = classManagementService.inviteLearner(id, req.getLearnerId(), teacherId, false);
        return ResponseEntity.status(HttpStatus.CREATED).body(dto);
    }
    @DeleteMapping("/{id}/invitations/{invitationId}")
    public ResponseEntity<Map<String, String>> cancelInvitation(
            @PathVariable UUID id,
            @PathVariable UUID invitationId,
            Authentication auth) {
        if (isAdmin(auth)) {
            throw new org.springframework.security.access.AccessDeniedException("Main admin has view-only access to teacher classrooms.");
        }
        UUID teacherId = parseUserId(auth);
        classManagementService.cancelInvitation(id, invitationId, teacherId, false);
        return ResponseEntity.ok(Map.of("message", "Invitation cancelled successfully"));
    }
    @GetMapping("/learners/search")
    public ResponseEntity<List<Map<String, Object>>> searchLearnersDeprecated(
            @RequestParam("q") String query) {
        return ResponseEntity.ok(classManagementService.searchLearnersForInvitation(query));
    }

    @PatchMapping("/{id}/requests/{requestId}")
    public ResponseEntity<Map<String, String>> reviewJoinRequest(
            @PathVariable UUID id,
            @PathVariable UUID requestId,
            @Valid @RequestBody ReviewJoinRequestDto req,
            Authentication auth) {
        if (isAdmin(auth)) {
            throw new org.springframework.security.access.AccessDeniedException("Main admin has view-only access to teacher classrooms.");
        }
        UUID teacherId = parseUserId(auth);
        classManagementService.reviewJoinRequest(id, requestId, req.getStatus(), teacherId, false);
        return ResponseEntity.ok(Map.of("status", req.getStatus(), "message", "Join request " + req.getStatus().toLowerCase()));
    }

    @PostMapping("/{id}/lessons")
    public ResponseEntity<AdminLessonResponse> createClassLesson(
            @PathVariable UUID id,
            @Valid @RequestBody CreateLessonRequest req,
            Authentication auth) {
        if (isAdmin(auth)) {
            throw new org.springframework.security.access.AccessDeniedException("Main admin cannot author lessons for teacher classrooms.");
        }
        UUID teacherId = parseUserId(auth);
        AdminLessonResponse response = lessonManagementService.createLessonForClass(id, req, teacherId, false);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/{id}/lessons")
    @Transactional(readOnly = true)
    public ResponseEntity<List<Lesson>> getClassLessons(@PathVariable UUID id) {
        List<Lesson> lessons = lessonRepository.findByClassroomClassIdAndIsDeletedFalseOrderByLessonOrderAsc(id);
        return ResponseEntity.ok(lessons);
    }

    @DeleteMapping("/{id}/students/{learnerId}")
    public ResponseEntity<Map<String, String>> unenrollStudent(
            @PathVariable UUID id,
            @PathVariable UUID learnerId,
            Authentication auth) {
        if (isAdmin(auth)) {
            throw new org.springframework.security.access.AccessDeniedException("Main admin has view-only access to teacher classrooms.");
        }
        UUID teacherId = parseUserId(auth);
        classManagementService.unenrollStudent(id, learnerId, teacherId, false);
        return ResponseEntity.ok(Map.of("message", "Student successfully unenrolled from class"));
    }

    private UUID parseUserIdSafe(Authentication auth) {
        if (auth == null || auth.getName() == null) return null;
        try {
            return UUID.fromString(auth.getName());
        } catch (Exception e) {
            return null;
        }
    }

    private UUID parseUserId(Authentication auth) {
        if (auth == null || auth.getName() == null) {
            throw new IllegalArgumentException("Unauthorized");
        }
        try {
            return UUID.fromString(auth.getName());
        } catch (Exception e) {
            throw new IllegalArgumentException("Invalid user ID in token");
        }
    }

    private boolean isAdmin(Authentication auth) {
        if (auth == null) return false;
        return auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
    }
}
