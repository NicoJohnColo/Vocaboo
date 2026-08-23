package com.vocaboo.controller;

import com.vocaboo.entity.GradeLevel;
import com.vocaboo.service.ReportGenerationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.UUID;

@RestController
@RequestMapping("/api/admin/reports")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
public class AdminReportController {

    private final ReportGenerationService reportGenerationService;
    private static final DateTimeFormatter FILE_DATE_FORMAT = DateTimeFormatter.ofPattern("yyyyMMdd");

    /**
     * GET /api/admin/reports/class
     * Export class performance report as CSV or PDF.
     */
    @GetMapping("/class")
    public ResponseEntity<byte[]> exportClassReport(
            @RequestParam(defaultValue = "csv") String format,
            @RequestParam(required = false) UUID sectionId,
            @RequestParam(required = false) GradeLevel gradeLevel) {

        String dateStr = LocalDate.now().format(FILE_DATE_FORMAT);

        if ("pdf".equalsIgnoreCase(format)) {
            byte[] pdfBytes = reportGenerationService.generateClassReportPdf(sectionId, gradeLevel);
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"class_report_" + dateStr + ".pdf\"")
                    .contentType(MediaType.APPLICATION_PDF)
                    .body(pdfBytes);
        } else {
            byte[] csvBytes = reportGenerationService.generateClassReportCsv(sectionId, gradeLevel);
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"class_report_" + dateStr + ".csv\"")
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
            @RequestParam(defaultValue = "pdf") String format) {

        String dateStr = LocalDate.now().format(FILE_DATE_FORMAT);

        if ("csv".equalsIgnoreCase(format)) {
            byte[] csvBytes = reportGenerationService.generateIndividualReportCsv(learnerId);
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"student_report_" + learnerId + "_" + dateStr + ".csv\"")
                    .contentType(MediaType.parseMediaType("text/csv; charset=UTF-8"))
                    .body(csvBytes);
        } else {
            byte[] pdfBytes = reportGenerationService.generateIndividualReportPdf(learnerId);
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"student_report_" + learnerId + "_" + dateStr + ".pdf\"")
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
            @RequestParam(required = false) UUID lessonId) {

        String dateStr = LocalDate.now().format(FILE_DATE_FORMAT);

        if ("pdf".equalsIgnoreCase(format)) {
            byte[] pdfBytes = reportGenerationService.generateWordPerformanceReportPdf(sectionId, lessonId);
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"word_performance_" + dateStr + ".pdf\"")
                    .contentType(MediaType.APPLICATION_PDF)
                    .body(pdfBytes);
        } else {
            byte[] csvBytes = reportGenerationService.generateWordPerformanceReportCsv(sectionId, lessonId);
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"word_performance_" + dateStr + ".csv\"")
                    .contentType(MediaType.parseMediaType("text/csv; charset=UTF-8"))
                    .body(csvBytes);
        }
    }
}
