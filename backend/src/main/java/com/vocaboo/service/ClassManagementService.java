package com.vocaboo.service;

import com.vocaboo.dto.request.CreateClassRequest;
import com.vocaboo.dto.response.*;
import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.OffsetDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ClassManagementService {

    private static final Logger log = LoggerFactory.getLogger(ClassManagementService.class);
    private static final SecureRandom RANDOM = new SecureRandom();
    private static final String CODE_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

    private final ClassroomRepository classroomRepository;
    private final ClassEnrollmentRepository enrollmentRepository;
    private final ClassInvitationRepository invitationRepository;
    private final ClassJoinRequestRepository joinRequestRepository;
    private final TeacherRepository teacherRepository;
    private final LearnerRepository learnerRepository;
    private final LessonRepository lessonRepository;
    private final com.vocaboo.repository.ClassPerformanceRepository classPerformanceRepository;

    // ── Teacher-Facing Methods ────────────────────────────────────────────────

    @Transactional
    public ClassResponse createClass(CreateClassRequest req, UUID teacherId) {
        Teacher teacher = teacherRepository.findById(teacherId)
                .orElseThrow(() -> new IllegalArgumentException("Teacher not found"));

        String code = generateUniqueClassCode();

        GradeLevel gl = GradeLevel.GRADE_4;
        if (req.getGradeLevel() != null && !req.getGradeLevel().isBlank()) {
            try { gl = GradeLevel.valueOf(req.getGradeLevel().trim().toUpperCase()); }
            catch (Exception ignored) {}
        }

        Classroom classroom = Classroom.builder()
                .name(req.getName().trim())
                .classCode(code)
                .teacher(teacher)
                .gradeLevel(gl)
                .build();

        classroom = classroomRepository.save(classroom);
        log.info("Teacher {} created class '{}' ({}) with code {}", teacher.getUsername(), classroom.getName(), gl, code);

        return toClassResponse(classroom, 0);
    }

    public List<ClassResponse> getClassesForTeacher(UUID teacherId, boolean isAdmin) {
        List<Classroom> classes;
        if (isAdmin) {
            classes = classroomRepository.findAllByOrderByCreatedAtDesc();
        } else {
            classes = classroomRepository.findByTeacherTeacherIdOrderByCreatedAtDesc(teacherId);
        }

        return classes.stream().map(c -> {
            long count = enrollmentRepository.countByClassroomClassIdAndStatus(c.getClassId(), "ACTIVE");
            return toClassResponse(c, count);
        }).collect(Collectors.toList());
    }

    public ClassDetailResponse getClassDetail(UUID classId, UUID requesterId, boolean isAdmin) {
        Classroom classroom = classroomRepository.findById(classId)
                .orElseThrow(() -> new IllegalArgumentException("Class not found"));

        if (!isAdmin && !classroom.getTeacher().getTeacherId().equals(requesterId)) {
            throw new AccessDeniedException("You do not have permission to access this class.");
        }

        List<ClassEnrollment> enrollments = enrollmentRepository.findByClassroomClassIdAndStatus(classId, "ACTIVE");
        List<ClassDetailResponse.EnrolledLearnerDto> enrolledList = enrollments.stream().map(e -> {
            Learner l = e.getLearner();
            com.vocaboo.entity.ClassPerformance cp = classPerformanceRepository
                    .findByLearnerLearnerIdAndClassroomClassId(l.getLearnerId(), classId)
                    .orElse(null);

            return ClassDetailResponse.EnrolledLearnerDto.builder()
                    .enrollmentId(e.getEnrollmentId())
                    .learnerId(l.getLearnerId())
                    .userId(l.getUserId())
                    .displayName(l.getDisplayName())
                    .age(l.getAge())
                    .avatar(l.getAvatar())
                    .gradeLevel(l.getGradeLevel())
                    .enrolledAt(e.getEnrolledAt())
                    .classPoints(cp != null && cp.getClassPoints() != null ? cp.getClassPoints() : 0)
                    .classAccuracy(cp != null && cp.getClassAccuracy() != null ? cp.getClassAccuracy() : java.math.BigDecimal.ZERO)
                    .classSessionsPlayed(cp != null && cp.getClassSessionsPlayed() != null ? cp.getClassSessionsPlayed() : 0)
                    .classMasteryLevel(cp != null && cp.getClassMasteryLevel() != null ? cp.getClassMasteryLevel() : "LEARNING")
                    .build();
        }).collect(Collectors.toList());

        List<ClassJoinRequest> joinRequests = joinRequestRepository.findByClassroomClassIdAndStatusOrderByCreatedAtDesc(classId, "PENDING");
        List<ClassDetailResponse.JoinRequestDto> requestList = joinRequests.stream().map(r -> {
            Learner l = r.getLearner();
            return ClassDetailResponse.JoinRequestDto.builder()
                    .requestId(r.getRequestId())
                    .learnerId(l.getLearnerId())
                    .userId(l.getUserId())
                    .displayName(l.getDisplayName())
                    .age(l.getAge())
                    .avatar(l.getAvatar())
                    .status(r.getStatus())
                    .createdAt(r.getCreatedAt())
                    .build();
        }).collect(Collectors.toList());

        List<ClassInvitation> invitations = invitationRepository.findByClassroomClassIdAndStatusOrderByCreatedAtDesc(classId, "PENDING");
        List<ClassDetailResponse.InvitationDto> inviteList = invitations.stream().map(i -> {
            Learner l = i.getLearner();
            return ClassDetailResponse.InvitationDto.builder()
                    .invitationId(i.getInvitationId())
                    .learnerId(l.getLearnerId())
                    .userId(l.getUserId())
                    .displayName(l.getDisplayName())
                    .avatar(l.getAvatar())
                    .status(i.getStatus())
                    .createdAt(i.getCreatedAt())
                    .build();
        }).collect(Collectors.toList());

        List<Lesson> lessons = lessonRepository.findByClassroomClassIdAndIsDeletedFalseOrderByLessonOrderAsc(classId);
        List<ClassDetailResponse.ClassLessonSummaryDto> lessonList = lessons.stream().map(ls ->
            ClassDetailResponse.ClassLessonSummaryDto.builder()
                    .lessonId(ls.getLessonId())
                    .lessonTitle(ls.getLessonTitle())
                    .lessonDescription(ls.getLessonDescription())
                    .lessonOrder(ls.getLessonOrder())
                    .totalWordCount(ls.getTotalWordCount())
                    .contentStatus(ls.getContentStatus())
                    .build()
        ).collect(Collectors.toList());

        Teacher t = classroom.getTeacher();
        String teacherName = (t.getFirstname() != null ? t.getFirstname() + " " : "") + (t.getLastname() != null ? t.getLastname() : t.getUsername());

        return ClassDetailResponse.builder()
                .classId(classroom.getClassId())
                .name(classroom.getName())
                .classCode(classroom.getClassCode())
                .teacherId(t.getTeacherId())
                .teacherName(teacherName.trim())
                .teacherSchool(t.getSchool())
                .gradeLevel(classroom.getGradeLevel())
                .createdAt(classroom.getCreatedAt())
                .enrolledLearners(enrolledList)
                .pendingJoinRequests(requestList)
                .pendingInvitations(inviteList)
                .lessons(lessonList)
                .build();
    }

    @Transactional
    public ClassDetailResponse.InvitationDto inviteLearner(UUID classId, String learnerIdentifier, UUID teacherId, boolean isAdmin) {
        Classroom classroom = classroomRepository.findById(classId)
                .orElseThrow(() -> new IllegalArgumentException("Class not found"));

        if (!isAdmin && !classroom.getTeacher().getTeacherId().equals(teacherId)) {
            throw new AccessDeniedException("You do not have permission to invite learners to this class.");
        }

        if (learnerIdentifier == null || learnerIdentifier.trim().isEmpty()) {
            throw new IllegalArgumentException("Student User ID, name, or UUID is required.");
        }

        String query = learnerIdentifier.trim();
        Learner learner = null;

        // 1. Try formatted User ID XX-XXXX-XXX
        if (query.matches("^\\d{2}-\\d{4}-\\d{3}$")) {
            learner = learnerRepository.findByUserId(query).orElse(null);
        }

        // 2. Try UUID
        if (learner == null) {
            try {
                UUID uuid = UUID.fromString(query);
                learner = learnerRepository.findById(uuid).orElse(null);
            } catch (IllegalArgumentException ignored) {
            }
        }

        // 3. Try case-insensitive User ID
        if (learner == null) {
            learner = learnerRepository.findByUserIdIgnoreCase(query).orElse(null);
        }

        // 4. Try display name
        if (learner == null) {
            learner = learnerRepository.findByDisplayNameIgnoreCase(query).orElse(null);
        }

        if (learner == null) {
            throw new IllegalArgumentException("Student not found with ID or name: " + learnerIdentifier);
        }

        GradeLevel classGrade = classroom.getGradeLevel() != null ? classroom.getGradeLevel() : GradeLevel.GRADE_4;
        GradeLevel learnerGrade = learner.getGradeLevel() != null ? learner.getGradeLevel() : GradeLevel.GRADE_4;
        if (classGrade != learnerGrade) {
            throw new IllegalArgumentException("Cannot invite " + learner.getDisplayName() + ": Student is in "
                    + learnerGrade.name().replace("GRADE_", "Grade ")
                    + ", but this class is for "
                    + classGrade.name().replace("GRADE_", "Grade ") + ".");
        }

        UUID learnerId = learner.getLearnerId();
        if (enrollmentRepository.existsByClassroomClassIdAndLearnerLearnerIdAndStatus(classId, learnerId, "ACTIVE")) {
            throw new IllegalArgumentException("Learner is already enrolled in this class.");
        }

        if (invitationRepository.existsByClassroomClassIdAndLearnerLearnerIdAndStatus(classId, learnerId, "PENDING")) {
            throw new IllegalArgumentException("Learner already has a pending invitation to this class.");
        }

        Teacher teacher = classroom.getTeacher();

        ClassInvitation invitation = ClassInvitation.builder()
                .classroom(classroom)
                .learner(learner)
                .sentByTeacher(teacher)
                .status("PENDING")
                .build();

        invitation = invitationRepository.save(invitation);
        log.info("Teacher {} invited learner {} to class {}", teacher.getUsername(), learner.getDisplayName(), classroom.getName());

        return ClassDetailResponse.InvitationDto.builder()
                .invitationId(invitation.getInvitationId())
                .learnerId(learner.getLearnerId())
                .userId(learner.getUserId())
                .displayName(learner.getDisplayName())
                .avatar(learner.getAvatar())
                .status(invitation.getStatus())
                .createdAt(invitation.getCreatedAt())
                .build();
    }

    @Transactional
    public ClassDetailResponse.InvitationDto inviteLearner(UUID classId, UUID learnerId, UUID teacherId, boolean isAdmin) {
        return inviteLearner(classId, learnerId != null ? learnerId.toString() : null, teacherId, isAdmin);
    }

    @Transactional
    public void reviewJoinRequest(UUID classId, UUID requestId, String decision, UUID teacherId, boolean isAdmin) {
        Classroom classroom = classroomRepository.findById(classId)
                .orElseThrow(() -> new IllegalArgumentException("Class not found"));

        if (!isAdmin && !classroom.getTeacher().getTeacherId().equals(teacherId)) {
            throw new AccessDeniedException("You do not have permission to review requests for this class.");
        }

        ClassJoinRequest request = joinRequestRepository.findById(requestId)
                .orElseThrow(() -> new IllegalArgumentException("Join request not found"));

        if (!request.getClassroom().getClassId().equals(classId)) {
            throw new IllegalArgumentException("Request does not belong to this class.");
        }

        if (!"PENDING".equalsIgnoreCase(request.getStatus())) {
            throw new IllegalArgumentException("This request has already been reviewed.");
        }

        String resolvedDecision = "APPROVED".equalsIgnoreCase(decision) ? "APPROVED" : "REJECTED";
        request.setStatus(resolvedDecision);
        request.setReviewedAt(OffsetDateTime.now());
        joinRequestRepository.save(request);

        if ("APPROVED".equals(resolvedDecision)) {
            activateEnrollment(classroom, request.getLearner(), null);
            log.info("Approved join request {} for learner {} in class {}", requestId, request.getLearner().getDisplayName(), classroom.getName());
        } else {
            log.info("Rejected join request {} for learner {} in class {}", requestId, request.getLearner().getDisplayName(), classroom.getName());
        }
    }

    // ── Learner-Facing Methods ────────────────────────────────────────────────

    @Transactional
    public ClassJoinRequest joinClassByCode(String classCode, UUID learnerId) {
        if (classCode == null || classCode.trim().isEmpty()) {
            throw new IllegalArgumentException("Class code is required.");
        }

        String normalizedCode = classCode.trim().toUpperCase();
        Classroom classroom = classroomRepository.findByClassCode(normalizedCode)
                .orElseThrow(() -> new IllegalArgumentException("Class code '" + normalizedCode + "' not found. Please check and try again."));

        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner not found"));

        GradeLevel classGrade = classroom.getGradeLevel() != null ? classroom.getGradeLevel() : GradeLevel.GRADE_4;
        GradeLevel learnerGrade = learner.getGradeLevel() != null ? learner.getGradeLevel() : GradeLevel.GRADE_4;
        if (classGrade != learnerGrade) {
            throw new IllegalArgumentException("Cannot join this class: This class is for "
                    + classGrade.name().replace("GRADE_", "Grade ")
                    + ", but your profile is set to "
                    + learnerGrade.name().replace("GRADE_", "Grade ") + ".");
        }

        if (enrollmentRepository.existsByClassroomClassIdAndLearnerLearnerIdAndStatus(classroom.getClassId(), learnerId, "ACTIVE")) {
            throw new IllegalArgumentException("You are already enrolled in " + classroom.getName() + ".");
        }

        if (joinRequestRepository.existsByClassroomClassIdAndLearnerLearnerIdAndStatus(classroom.getClassId(), learnerId, "PENDING")) {
            throw new IllegalArgumentException("You already have a pending join request for " + classroom.getName() + ".");
        }

        ClassJoinRequest request = ClassJoinRequest.builder()
                .classroom(classroom)
                .learner(learner)
                .status("PENDING")
                .build();

        request = joinRequestRepository.save(request);
        log.info("Learner {} requested to join class {} via code {}", learner.getDisplayName(), classroom.getName(), normalizedCode);
        return request;
    }

    public List<LearnerClassSummaryResponse> getLearnerClasses(UUID learnerId) {
        Learner learner = learnerRepository.findById(learnerId).orElse(null);
        GradeLevel learnerGrade = learner != null ? (learner.getGradeLevel() != null ? learner.getGradeLevel() : GradeLevel.GRADE_4) : null;

        List<ClassEnrollment> enrollments = enrollmentRepository.findByLearnerLearnerIdAndStatus(learnerId, "ACTIVE");
        if (learnerGrade != null) {
            enrollments = enrollments.stream()
                    .filter(e -> {
                        if (e.getClassroom() == null) return false;
                        GradeLevel classGrade = e.getClassroom().getGradeLevel() != null ? e.getClassroom().getGradeLevel() : GradeLevel.GRADE_4;
                        return classGrade == learnerGrade;
                    })
                    .collect(Collectors.toList());
        }

        return enrollments.stream().map(e -> {
            Classroom c = e.getClassroom();
            Teacher t = c.getTeacher();
            String teacherName = (t.getFirstname() != null ? t.getFirstname() + " " : "") + (t.getLastname() != null ? t.getLastname() : t.getUsername());
            long count = enrollmentRepository.countByClassroomClassIdAndStatus(c.getClassId(), "ACTIVE");
            List<Lesson> lessons = lessonRepository.findByClassroomClassIdAndContentStatusAndIsDeletedFalseOrderByLessonOrderAsc(c.getClassId(), "PUBLISHED");
            if (learnerGrade != null) {
                lessons = lessons.stream()
                        .filter(l -> l.getGradeLevel() != null && l.getGradeLevel() == learnerGrade)
                        .collect(Collectors.toList());
            }

            return LearnerClassSummaryResponse.builder()
                    .classId(c.getClassId())
                    .name(c.getName())
                    .classCode(c.getClassCode())
                    .teacherName(teacherName.trim())
                    .teacherSchool(t.getSchool())
                    .studentCount(count)
                    .gradeLevel(c.getGradeLevel())
                    .enrolledAt(e.getEnrolledAt())
                    .totalLessons(lessons.size())
                    .build();
        }).collect(Collectors.toList());
    }

    public List<LearnerInvitationResponse> getLearnerInvitations(UUID learnerId) {
        Learner learner = learnerRepository.findById(learnerId).orElse(null);
        GradeLevel learnerGrade = learner != null ? (learner.getGradeLevel() != null ? learner.getGradeLevel() : GradeLevel.GRADE_4) : null;

        List<ClassInvitation> invites = invitationRepository.findByLearnerLearnerIdAndStatusOrderByCreatedAtDesc(learnerId, "PENDING");
        if (learnerGrade != null) {
            invites = invites.stream()
                    .filter(i -> {
                        if (i.getClassroom() == null) return false;
                        GradeLevel classGrade = i.getClassroom().getGradeLevel() != null ? i.getClassroom().getGradeLevel() : GradeLevel.GRADE_4;
                        return classGrade == learnerGrade;
                    })
                    .collect(Collectors.toList());
        }

        return invites.stream().map(i -> {
            Classroom c = i.getClassroom();
            Teacher t = i.getSentByTeacher();
            String teacherName = (t.getFirstname() != null ? t.getFirstname() + " " : "") + (t.getLastname() != null ? t.getLastname() : t.getUsername());

            return LearnerInvitationResponse.builder()
                    .invitationId(i.getInvitationId())
                    .classId(c.getClassId())
                    .className(c.getName())
                    .classCode(c.getClassCode())
                    .teacherName(teacherName.trim())
                    .teacherSchool(t.getSchool())
                    .sentAt(i.getCreatedAt())
                    .status(i.getStatus())
                    .build();
        }).collect(Collectors.toList());
    }

    @Transactional
    public void respondToInvitation(UUID invitationId, String decision, UUID learnerId) {
        ClassInvitation invitation = invitationRepository.findById(invitationId)
                .orElseThrow(() -> new IllegalArgumentException("Invitation not found"));

        if (!invitation.getLearner().getLearnerId().equals(learnerId)) {
            throw new AccessDeniedException("You do not have permission to respond to this invitation.");
        }

        if (!"PENDING".equalsIgnoreCase(invitation.getStatus())) {
            throw new IllegalArgumentException("This invitation has already been answered.");
        }

        String resolved = "ACCEPTED".equalsIgnoreCase(decision) ? "ACCEPTED" : "DECLINED";
        invitation.setStatus(resolved);
        invitation.setRespondedAt(OffsetDateTime.now());
        invitationRepository.save(invitation);

        if ("ACCEPTED".equals(resolved)) {
            activateEnrollment(invitation.getClassroom(), invitation.getLearner(), invitation.getSentByTeacher());
            log.info("Learner {} accepted invitation to class {}", invitation.getLearner().getDisplayName(), invitation.getClassroom().getName());
        } else {
            log.info("Learner {} declined invitation to class {}", invitation.getLearner().getDisplayName(), invitation.getClassroom().getName());
        }
    }

    public List<Lesson> getClassLessons(UUID classId, UUID learnerId) {
        // Confirm learner is actively enrolled or class exists
        boolean isEnrolled = enrollmentRepository.existsByClassroomClassIdAndLearnerLearnerIdAndStatus(classId, learnerId, "ACTIVE");
        if (!isEnrolled) {
            throw new AccessDeniedException("You must be enrolled in this class to view its lessons.");
        }
        return lessonRepository.findByClassroomClassIdAndContentStatusAndIsDeletedFalseOrderByLessonOrderAsc(classId, "PUBLISHED");
    }

    // ── Internal Helpers ──────────────────────────────────────────────────────

    private void activateEnrollment(Classroom classroom, Learner learner, Teacher invitedBy) {
        Optional<ClassEnrollment> existingOpt = enrollmentRepository.findByClassroomClassIdAndLearnerLearnerId(classroom.getClassId(), learner.getLearnerId());
        if (existingOpt.isPresent()) {
            ClassEnrollment enrollment = existingOpt.get();
            enrollment.setStatus("ACTIVE");
            enrollmentRepository.save(enrollment);
        } else {
            ClassEnrollment enrollment = ClassEnrollment.builder()
                    .classroom(classroom)
                    .learner(learner)
                    .status("ACTIVE")
                    .invitedByTeacher(invitedBy)
                    .build();
            enrollmentRepository.save(enrollment);
        }
    }

    @Transactional
    public void unenrollStudent(UUID classId, UUID learnerId, UUID teacherId, boolean isAdmin) {
        Classroom classroom = classroomRepository.findById(classId)
                .orElseThrow(() -> new IllegalArgumentException("Class not found"));

        if (!isAdmin && !classroom.getTeacher().getTeacherId().equals(teacherId)) {
            throw new AccessDeniedException("You do not have permission to modify this class roster.");
        }

        ClassEnrollment enrollment = enrollmentRepository.findByClassroomClassIdAndLearnerLearnerId(classId, learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Student is not enrolled in this class."));

        enrollmentRepository.delete(enrollment);
        log.info("Teacher {} unenrolled student {} from class {}",
                classroom.getTeacher().getUsername(), learnerId, classroom.getName());
    }

    private ClassResponse toClassResponse(Classroom c, long studentCount) {
        Teacher t = c.getTeacher();
        String teacherName = t != null
                ? ((t.getFirstname() != null ? t.getFirstname() + " " : "") + (t.getLastname() != null ? t.getLastname() : t.getUsername())).trim()
                : "Vocaboo Teacher";

        return ClassResponse.builder()
                .classId(c.getClassId())
                .name(c.getName())
                .classCode(c.getClassCode())
                .teacherId(t != null ? t.getTeacherId() : null)
                .teacherName(teacherName)
                .teacherSchool(t != null ? t.getSchool() : null)
                .studentCount(studentCount)
                .gradeLevel(c.getGradeLevel())
                .createdAt(c.getCreatedAt())
                .build();
    }

    private String generateUniqueClassCode() {
        for (int attempt = 0; attempt < 50; attempt++) {
            StringBuilder sb = new StringBuilder("VOC-");
            for (int i = 0; i < 4; i++) {
                sb.append(CODE_CHARS.charAt(RANDOM.nextInt(CODE_CHARS.length())));
            }
            String candidate = sb.toString();
            if (!classroomRepository.existsByClassCode(candidate)) {
                return candidate;
            }
        }
        return "VOC-" + UUID.randomUUID().toString().substring(0, 4).toUpperCase();
    }
}
