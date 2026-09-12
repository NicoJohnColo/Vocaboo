package com.vocaboo.controller;

import com.vocaboo.entity.GradeLevel;
import com.vocaboo.service.ReportGenerationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/admin/reports")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
public class AdminReportController {

    private final ReportGenerationService reportGenerationService;
    private final com.vocaboo.repository.ClassEnrollmentRepository classEnrollmentRepository;
    private final com.vocaboo.repository.ClassroomRepository classroomRepository;
    private static final DateTimeFormatter FILE_DATE_FORMAT = DateTimeFormatter.ofPattern("yyyyMMdd");

    /**
     * GET /api/admin/reports/class
     * Export class performance report as CSV or PDF.
     */
    @GetMapping("/class")
    public ResponseEntity<byte[]> exportClassReport(
            @RequestParam(defaultValue = "csv") String format,
            @RequestParam(required = false) UUID sectionId,
            @RequestParam(required = false) GradeLevel gradeLevel,
            Authentication auth) {

        // Admin can only export global school-wide reports (sectionId == null), not specific teacher classes
        if (!isTeacher(auth) && sectionId != null) {
            return ResponseEntity.status(org.springframework.http.HttpStatus.FORBIDDEN).build();
        }

        final UUID teacherId = isTeacher(auth) ? parseUserId(auth) : null;
        if (teacherId != null && sectionId != null) {
            boolean ownsClass = classroomRepository.findById(sectionId)
                    .map(c -> c.getTeacher() != null && teacherId.equals(c.getTeacher().getTeacherId()))
                    .orElse(false);
            if (!ownsClass) {
                return ResponseEntity.status(org.springframework.http.HttpStatus.FORBIDDEN).build();
            }
        }

        String dateStr = LocalDate.now().format(FILE_DATE_FORMAT);
        String classSlug = resolveClassSlug(sectionId);

        if ("pdf".equalsIgnoreCase(format)) {
            byte[] pdfBytes = reportGenerationService.generateClassReportPdf(sectionId, gradeLevel, teacherId);
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"class_report_" + classSlug + "_" + dateStr + ".pdf\"")
                    .contentType(MediaType.APPLICATION_PDF)
                    .body(pdfBytes);
        } else {
            byte[] csvBytes = reportGenerationService.generateClassReportCsv(sectionId, gradeLevel, teacherId);
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"class_report_" + classSlug + "_" + dateStr + ".csv\"")
                    .contentType(MediaType.parseMediaType("text/csv; charset=UTF-8"))
                    .body(csvBytes);
        }
    }

    /**
     * GET /api/admin/reports/individual/{learnerId}
     * Export student report card as PDF or CSV.
     */
    @GetMapping("/individual/{learnerId}")
    public ResponseEntity<byte[]> exportIndividualReport(
            @PathVariable UUID learnerId,
            @RequestParam(defaultValue = "pdf") String format,
            @RequestParam(required = false) UUID classId,
            Authentication auth) {

        // Admin can only export global student reports (classId == null), not specific teacher classroom reports
        if (!isTeacher(auth) && classId != null) {
            return ResponseEntity.status(org.springframework.http.HttpStatus.FORBIDDEN).build();
        }

        final UUID teacherId = isTeacher(auth) ? parseUserId(auth) : null;
        if (teacherId != null) {
            List<UUID> enrolledIds = classEnrollmentRepository.findEnrolledLearnerIdsByTeacherId(teacherId);
            if (!enrolledIds.contains(learnerId)) {
                return ResponseEntity.status(org.springframework.http.HttpStatus.FORBIDDEN).build();
            }
            if (classId != null) {
                boolean ownsClass = classroomRepository.findById(classId)
                        .map(c -> c.getTeacher() != null && teacherId.equals(c.getTeacher().getTeacherId()))
                        .orElse(false);
                if (!ownsClass) {
                    return ResponseEntity.status(org.springframework.http.HttpStatus.FORBIDDEN).build();
                }
            }
        }

        if (classId != null) {
            boolean isEnrolled = classEnrollmentRepository.existsByClassroomClassIdAndLearnerLearnerIdAndStatus(classId, learnerId, "ACTIVE");
            if (!isEnrolled) {
                return ResponseEntity.status(org.springframework.http.HttpStatus.BAD_REQUEST).build();
            }
        }

        String dateStr = LocalDate.now().format(FILE_DATE_FORMAT);
        String classSlug = resolveClassSlug(classId);

        if ("csv".equalsIgnoreCase(format)) {
            byte[] csvBytes = reportGenerationService.generateIndividualReportCsv(learnerId, teacherId, classId);
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"student_report_" + learnerId + "_" + classSlug + "_" + dateStr + ".csv\"")
                    .contentType(MediaType.parseMediaType("text/csv; charset=UTF-8"))
                    .body(csvBytes);
        } else {
            byte[] pdfBytes = reportGenerationService.generateIndividualReportPdf(learnerId, teacherId, classId);
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"student_report_" + learnerId + "_" + classSlug + "_" + dateStr + ".pdf\"")
                    .contentType(MediaType.APPLICATION_PDF)
                    .body(pdfBytes);
        }
    }

    /**
     * GET /api/admin/reports/word-performance
     * Export curriculum & word-level performance report as CSV or PDF.
     */
    @GetMapping("/word-performance")
    public ResponseEntity<byte[]> exportWordPerformanceReport(
            @RequestParam(defaultValue = "csv") String format,
            @RequestParam(required = false) UUID sectionId,
            @RequestParam(required = false) UUID lessonId,
            @RequestParam(required = false) UUID categoryId,
            Authentication auth) {

        // Admin can only export global curriculum reports (sectionId == null), not specific teacher classes
        if (!isTeacher(auth) && sectionId != null) {
            return ResponseEntity.status(org.springframework.http.HttpStatus.FORBIDDEN).build();
        }

        final UUID teacherId = isTeacher(auth) ? parseUserId(auth) : null;
        if (teacherId != null && sectionId != null) {
            boolean ownsClass = classroomRepository.findById(sectionId)
                    .map(c -> c.getTeacher() != null && teacherId.equals(c.getTeacher().getTeacherId()))
                    .orElse(false);
            if (!ownsClass) {
                return ResponseEntity.status(org.springframework.http.HttpStatus.FORBIDDEN).build();
            }
        }

        String dateStr = LocalDate.now().format(FILE_DATE_FORMAT);
        String classSlug = resolveClassSlug(sectionId);

        if ("pdf".equalsIgnoreCase(format)) {
            byte[] pdfBytes = categoryId != null
                    ? reportGenerationService.generateWordPerformanceReportPdf(sectionId, lessonId, categoryId, teacherId)
                    : reportGenerationService.generateWordPerformanceReportPdf(sectionId, lessonId, teacherId);
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"word_performance_" + classSlug + "_" + dateStr + ".pdf\"")
                    .contentType(MediaType.APPLICATION_PDF)
                    .body(pdfBytes);
        } else {
            byte[] csvBytes = categoryId != null
                    ? reportGenerationService.generateWordPerformanceReportCsv(sectionId, lessonId, categoryId, teacherId)
                    : reportGenerationService.generateWordPerformanceReportCsv(sectionId, lessonId, teacherId);
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"word_performance_" + classSlug + "_" + dateStr + ".csv\"")
                    .contentType(MediaType.parseMediaType("text/csv; charset=UTF-8"))
                    .body(csvBytes);
        }
    }

    public ResponseEntity<byte[]> exportWordPerformanceReport(
            String format,
            UUID sectionId,
            UUID lessonId,
            Authentication auth) {
        return exportWordPerformanceReport(format, sectionId, lessonId, null, auth);
    }

    private String resolveClassSlug(UUID classId) {
        if (classId == null) return "all_classes";
        return classroomRepository.findById(classId)
                .map(c -> c.getName().trim().replaceAll("[^a-zA-Z0-9_-]+", "_"))
                .orElse("class_" + classId.toString().substring(0, 8));
    }

    private UUID parseUserId(Authentication auth) {
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
