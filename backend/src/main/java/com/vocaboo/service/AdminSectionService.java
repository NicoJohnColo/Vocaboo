package com.vocaboo.service;

import com.vocaboo.dto.request.CreateSectionRequest;
import com.vocaboo.dto.request.UpdateSectionRequest;
import com.vocaboo.dto.response.AdminSectionResponse;
import com.vocaboo.entity.AdminAuditLog;
import com.vocaboo.entity.Learner;
import com.vocaboo.entity.Section;
import com.vocaboo.repository.AdminAuditLogRepository;
import com.vocaboo.repository.LearnerRepository;
import com.vocaboo.repository.SectionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminSectionService {

    private final SectionRepository sectionRepository;
    private final LearnerRepository learnerRepository;
    private final AdminAuditLogRepository auditLogRepository;
    private final com.vocaboo.repository.ClassroomRepository classroomRepository;
    private final com.vocaboo.repository.ClassEnrollmentRepository classEnrollmentRepository;

    public List<AdminSectionResponse> getAllSections() {
        List<Section> sections = sectionRepository.findAllByOrderBySectionNameAsc();
        return sections.stream().map(this::toResponse).collect(Collectors.toList());
    }

    public AdminSectionResponse getSectionById(UUID sectionId) {
        Section section = sectionRepository.findById(sectionId)
                .orElseThrow(() -> new IllegalArgumentException("Section not found: " + sectionId));
        return toResponse(section);
    }

    @Transactional
    public AdminSectionResponse createSection(CreateSectionRequest req, UUID adminId) {
        String trimmedName = req.getSectionName().trim();
        if (sectionRepository.existsBySectionNameIgnoreCase(trimmedName)) {
            throw new IllegalArgumentException("A section with the name '" + trimmedName + "' already exists.");
        }

        Section section = Section.builder()
                .sectionName(trimmedName)
                .build();
        section = sectionRepository.save(section);

        if (adminId != null) {
            auditLogRepository.save(AdminAuditLog.builder()
                    .adminId(adminId)
                    .action("CREATE_SECTION")
                    .targetId(section.getSectionId())
                    .details("Created section: " + section.getSectionName())
                    .build());
        }

        return toResponse(section);
    }

    @Transactional
    public AdminSectionResponse updateSection(UUID sectionId, UpdateSectionRequest req, UUID adminId) {
        Section section = sectionRepository.findById(sectionId)
                .orElseThrow(() -> new IllegalArgumentException("Section not found: " + sectionId));

        String trimmedName = req.getSectionName().trim();
        if (sectionRepository.existsBySectionNameIgnoreCaseAndSectionIdNot(trimmedName, sectionId)) {
            throw new IllegalArgumentException("A section with the name '" + trimmedName + "' already exists.");
        }

        String oldName = section.getSectionName();
        section.setSectionName(trimmedName);
        section = sectionRepository.save(section);

        if (adminId != null) {
            auditLogRepository.save(AdminAuditLog.builder()
                    .adminId(adminId)
                    .action("UPDATE_SECTION")
                    .targetId(section.getSectionId())
                    .details("Renamed section from '" + oldName + "' to '" + trimmedName + "'")
                    .build());
        }

        return toResponse(section);
    }

    @Transactional
    public void deleteSection(UUID sectionId, UUID adminId) {
        Section section = sectionRepository.findById(sectionId)
                .orElseThrow(() -> new IllegalArgumentException("Section not found: " + sectionId));

        // Unassign all learners belonging to this section
        List<Learner> assignedLearners = learnerRepository.findBySectionSectionId(sectionId);
        for (Learner learner : assignedLearners) {
            learner.setSection(null);
            learnerRepository.save(learner);
        }

        sectionRepository.delete(section);

        if (adminId != null) {
            auditLogRepository.save(AdminAuditLog.builder()
                    .adminId(adminId)
                    .action("DELETE_SECTION")
                    .targetId(sectionId)
                    .details("Deleted section '" + section.getSectionName() + "' (unassigned " + assignedLearners.size() + " learners)")
                    .build());
        }
    }

    @Transactional
    public void assignLearnerToSection(UUID learnerId, UUID sectionId, UUID adminId) {
        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner not found: " + learnerId));

        String assignedTargetName = null;
        if (sectionId != null) {
            Optional<Section> secOpt = sectionRepository.findById(sectionId);
            if (secOpt.isPresent()) {
                Section section = secOpt.get();
                learner.setSection(section);
                assignedTargetName = section.getSectionName();
            } else {
                com.vocaboo.entity.Classroom classroom = classroomRepository.findById(sectionId)
                        .orElseThrow(() -> new IllegalArgumentException("Section or Class not found: " + sectionId));
                assignedTargetName = classroom.getName();
                
                // Enroll in class_enrollments
                java.util.Optional<com.vocaboo.entity.ClassEnrollment> existingOpt = 
                        classEnrollmentRepository.findByClassroomClassIdAndLearnerLearnerId(classroom.getClassId(), learner.getLearnerId());
                if (existingOpt.isPresent()) {
                    com.vocaboo.entity.ClassEnrollment enrollment = existingOpt.get();
                    enrollment.setStatus("ACTIVE");
                    classEnrollmentRepository.save(enrollment);
                } else {
                    com.vocaboo.entity.ClassEnrollment enrollment = com.vocaboo.entity.ClassEnrollment.builder()
                            .classroom(classroom)
                            .learner(learner)
                            .status("ACTIVE")
                            .invitedByTeacher(classroom.getTeacher())
                            .build();
                    classEnrollmentRepository.save(enrollment);
                }

                // Sync grade level if indicated in class name
                String cName = classroom.getName();
                if (cName != null) {
                    if (cName.contains("Grade 4") || cName.contains("Grade_4")) {
                        learner.setGradeLevel(com.vocaboo.entity.GradeLevel.GRADE_4);
                    } else if (cName.contains("Grade 5") || cName.contains("Grade_5")) {
                        learner.setGradeLevel(com.vocaboo.entity.GradeLevel.GRADE_5);
                    } else if (cName.contains("Grade 6") || cName.contains("Grade_6")) {
                        learner.setGradeLevel(com.vocaboo.entity.GradeLevel.GRADE_6);
                    }
                }
            }
        } else {
            learner.setSection(null);
        }

        learnerRepository.save(learner);

        if (adminId != null) {
            auditLogRepository.save(AdminAuditLog.builder()
                    .adminId(adminId)
                    .action("ASSIGN_SECTION")
                    .targetId(learnerId)
                    .details(assignedTargetName != null ? "Assigned to section/class: " + assignedTargetName : "Unassigned from section/class")
                    .build());
        }
    }

    private AdminSectionResponse toResponse(Section section) {
        List<Learner> learners = learnerRepository.findBySectionSectionId(section.getSectionId());
        long total = learners.size();
        long active = learners.stream().filter(l -> Boolean.TRUE.equals(l.getIsActive())).count();

        Map<String, Long> gradeDist = learners.stream()
                .filter(l -> l.getGradeLevel() != null)
                .collect(Collectors.groupingBy(l -> l.getGradeLevel().name(), Collectors.counting()));

        return AdminSectionResponse.builder()
                .sectionId(section.getSectionId())
                .sectionName(section.getSectionName())
                .totalLearners(total)
                .activeLearners(active)
                .gradeDistribution(gradeDist)
                .createdAt(section.getCreatedAt())
                .updatedAt(section.getUpdatedAt())
                .build();
    }
}
