package com.vocaboo.service;

import com.lowagie.text.*;
import com.lowagie.text.Font;
import com.lowagie.text.pdf.*;
import com.opencsv.CSVWriter;
import com.vocaboo.dto.response.AdminLearnerDetailResponse;
import com.vocaboo.dto.response.AdminLearnerDetailResponse.LearnerLessonProgressDetail;
import com.vocaboo.dto.response.AdminLearnerDetailResponse.LearnerWordPerformanceDetail;
import com.vocaboo.dto.response.AdminLearnerSummaryResponse;
import com.vocaboo.entity.GradeLevel;
import com.vocaboo.entity.VocabularyWord;
import com.vocaboo.entity.WordPerformance;
import com.vocaboo.repository.VocabularyWordRepository;
import com.vocaboo.repository.WordPerformanceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.io.StringWriter;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.nio.charset.StandardCharsets;
import java.time.OffsetDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@org.springframework.transaction.annotation.Transactional(readOnly = true)
public class ReportGenerationService {

    private final AdminLearnerService adminLearnerService;
    private final WordPerformanceRepository wordPerformanceRepository;
    private final VocabularyWordRepository vocabularyWordRepository;
    private final com.vocaboo.repository.ClassEnrollmentRepository classEnrollmentRepository;
    private final com.vocaboo.repository.ClassroomRepository classroomRepository;

    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");

    // ──────────────────────────────────────────────────────────────────────────
    // 1. CLASS PERFORMANCE REPORT
    // ──────────────────────────────────────────────────────────────────────────

    public byte[] generateClassReportCsv(UUID sectionId, GradeLevel gradeLevel) {
        return generateClassReportCsv(sectionId, gradeLevel, null);
    }

    public byte[] generateClassReportCsv(UUID sectionId, GradeLevel gradeLevel, UUID teacherId) {
        List<AdminLearnerSummaryResponse> learners = adminLearnerService.getAllLearnersSummary(sectionId, gradeLevel, teacherId);

        String scopeLabel = "ALL CLASSES (COMPREHENSIVE ROSTER)";
        if (sectionId != null) {
            String cName = classroomRepository.findById(sectionId)
                    .map(c -> c.getName() + (c.getClassCode() != null ? " [Code: " + c.getClassCode() + "]" : ""))
                    .orElse("Class ID: " + sectionId);
            scopeLabel = "CLASS: " + cName;
        } else if (teacherId != null) {
            scopeLabel = "ALL MY CLASSES (TEACHER ROSTER)";
        }

        StringWriter sw = new StringWriter();
        try (CSVWriter writer = new CSVWriter(sw)) {
            writer.writeNext(new String[]{"VOCABOO - CLASS PERFORMANCE & ROSTER REPORT"});
            writer.writeNext(new String[]{"Record Scope", scopeLabel});
            if (gradeLevel != null) {
                writer.writeNext(new String[]{"Grade Level Filter", gradeLevel.name()});
            }
            writer.writeNext(new String[]{"Generated On", OffsetDateTime.now().format(DATE_FORMATTER)});
            writer.writeNext(new String[]{"Total Students", String.valueOf(learners.size())});
            writer.writeNext(new String[]{""});

            // Header
            writer.writeNext(new String[]{
                    "Learner ID",
                    "Display Name",
                    "Grade Level",
                    "Section Name",
                    "Language Preference",
                    "Completed Lessons",
                    "Words Mastered",
                    "Total Points",
                    "Overall Accuracy (%)",
                    "Status",
                    "Struggling",
                    "Last Active"
            });

            for (AdminLearnerSummaryResponse l : learners) {
                String learnerIdDisplay = l.getUserId() != null ? l.getUserId() : (l.getLearnerId() != null ? l.getLearnerId().toString() : "");
                writer.writeNext(new String[]{
                        learnerIdDisplay,
                        l.getDisplayName() != null ? l.getDisplayName() : "",
                        l.getGradeLevel() != null ? l.getGradeLevel() : "N/A",
                        l.getSectionName() != null ? l.getSectionName() : "Unassigned",
                        l.getLanguagePreference() != null ? l.getLanguagePreference() : "",
                        String.valueOf(l.getCompletedLessonsCount() != null ? l.getCompletedLessonsCount() : 0),
                        String.valueOf(l.getWordsMasteredCount() != null ? l.getWordsMasteredCount() : 0),
                        String.valueOf(l.getTotalPoints() != null ? l.getTotalPoints() : 0),
                        l.getOverallAccuracy() != null ? l.getOverallAccuracy().setScale(2, RoundingMode.HALF_UP).toString() : "0.00",
                        Boolean.TRUE.equals(l.getIsActive()) ? "ACTIVE" : "INACTIVE",
                        Boolean.TRUE.equals(l.getIsStruggling()) ? "YES" : "NO",
                        l.getLastActiveAt() != null ? l.getLastActiveAt().format(DATE_FORMATTER) : "N/A"
                });
            }
        } catch (Exception e) {
            throw new RuntimeException("Failed to generate Class CSV report", e);
        }

        return sw.toString().getBytes(StandardCharsets.UTF_8);
    }

    public byte[] generateClassReportPdf(UUID sectionId, GradeLevel gradeLevel) {
        return generateClassReportPdf(sectionId, gradeLevel, null);
    }

    public byte[] generateClassReportPdf(UUID sectionId, GradeLevel gradeLevel, UUID teacherId) {
        List<AdminLearnerSummaryResponse> learners = adminLearnerService.getAllLearnersSummary(sectionId, gradeLevel, teacherId);

        String scopeLabel = "Scope: All Classes (Comprehensive Cohort)";
        String classTitle = "Vocaboo - Class Performance Report";
        if (sectionId != null) {
            com.vocaboo.entity.Classroom classroom = classroomRepository.findById(sectionId).orElse(null);
            if (classroom != null) {
                classTitle = "Vocaboo - " + classroom.getName() + " Performance Report";
                scopeLabel = "Class Scope: " + classroom.getName() + (classroom.getClassCode() != null ? " [Code: " + classroom.getClassCode() + "]" : "");
            } else {
                scopeLabel = "Class Scope: ID " + sectionId;
            }
        } else if (teacherId != null) {
            scopeLabel = "Scope: All My Classes (Cumulative Roster)";
        }

        try (ByteArrayOutputStream baos = new ByteArrayOutputStream()) {
            Document document = new Document(PageSize.A4.rotate(), 24, 24, 24, 24);
            PdfWriter.getInstance(document, baos);
            document.open();

            // Styling fonts
            Font titleFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 18, new Color(40, 53, 147));
            Font subTitleFont = FontFactory.getFont(FontFactory.HELVETICA, 10, Color.DARK_GRAY);
            Font tableHeaderFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 9, Color.WHITE);
            Font tableBodyFont = FontFactory.getFont(FontFactory.HELVETICA, 8, Color.BLACK);

            // Title
            Paragraph title = new Paragraph(classTitle, titleFont);
            title.setAlignment(Element.ALIGN_CENTER);
            title.setSpacingAfter(4);
            document.add(title);

            Paragraph meta = new Paragraph(scopeLabel + (gradeLevel != null ? " | Grade Level: " + gradeLevel.name() : "") + " | Generated on: " + OffsetDateTime.now().format(DATE_FORMATTER) +
                    " | Total Students: " + learners.size(), subTitleFont);
            meta.setAlignment(Element.ALIGN_CENTER);
            meta.setSpacingAfter(15);
            document.add(meta);

            // Table
            PdfPTable table = new PdfPTable(9);
            table.setWidthPercentage(100);
            table.setWidths(new float[]{3.0f, 1.8f, 2.2f, 1.8f, 1.8f, 1.8f, 2.0f, 1.5f, 2.5f});

            String[] headers = {"Student Name", "Grade", "Section", "Completed", "Mastered", "Points", "Accuracy", "Status", "Last Active"};
            for (String h : headers) {
                PdfPCell cell = new PdfPCell(new Phrase(h, tableHeaderFont));
                cell.setBackgroundColor(new Color(63, 81, 181));
                cell.setHorizontalAlignment(Element.ALIGN_CENTER);
                cell.setPadding(6);
                table.addCell(cell);
            }

            boolean alternate = false;
            for (AdminLearnerSummaryResponse l : learners) {
                Color bgColor = alternate ? new Color(245, 245, 250) : Color.WHITE;

                String studentDisplay = (l.getDisplayName() != null ? l.getDisplayName() : "Unknown")
                        + (l.getUserId() != null ? "\n[" + l.getUserId() + "]" : "");
                table.addCell(createCell(studentDisplay, tableBodyFont, bgColor, Element.ALIGN_LEFT));
                table.addCell(createCell(l.getGradeLevel() != null ? l.getGradeLevel() : "N/A", tableBodyFont, bgColor, Element.ALIGN_CENTER));
                table.addCell(createCell(l.getSectionName() != null ? l.getSectionName() : "Unassigned", tableBodyFont, bgColor, Element.ALIGN_CENTER));
                table.addCell(createCell(String.valueOf(l.getCompletedLessonsCount() != null ? l.getCompletedLessonsCount() : 0), tableBodyFont, bgColor, Element.ALIGN_CENTER));
                table.addCell(createCell(String.valueOf(l.getWordsMasteredCount() != null ? l.getWordsMasteredCount() : 0), tableBodyFont, bgColor, Element.ALIGN_CENTER));
                table.addCell(createCell(String.valueOf(l.getTotalPoints() != null ? l.getTotalPoints() : 0), tableBodyFont, bgColor, Element.ALIGN_CENTER));
                table.addCell(createCell((l.getOverallAccuracy() != null ? l.getOverallAccuracy().setScale(1, RoundingMode.HALF_UP) : "0.0") + "%", tableBodyFont, bgColor, Element.ALIGN_CENTER));
                table.addCell(createCell(Boolean.TRUE.equals(l.getIsActive()) ? "Active" : "Inactive", tableBodyFont, bgColor, Element.ALIGN_CENTER));
                table.addCell(createCell(l.getLastActiveAt() != null ? l.getLastActiveAt().format(DateTimeFormatter.ofPattern("MM/dd HH:mm")) : "—", tableBodyFont, bgColor, Element.ALIGN_CENTER));

                alternate = !alternate;
            }

            document.add(table);
            document.close();
            return baos.toByteArray();
        } catch (Exception e) {
            throw new RuntimeException("Failed to generate Class PDF report", e);
        }
    }

    // ──────────────────────────────────────────────────────────────────────────
    // 2. INDIVIDUAL STUDENT REPORT
    // ──────────────────────────────────────────────────────────────────────────

    public byte[] generateIndividualReportPdf(UUID learnerId) {
        return generateIndividualReportPdf(learnerId, null, null);
    }

    public byte[] generateIndividualReportPdf(UUID learnerId, UUID teacherId, UUID classId) {
        AdminLearnerDetailResponse detail = (teacherId != null || classId != null)
                ? adminLearnerService.getLearnerDetail(learnerId, teacherId, classId)
                : adminLearnerService.getLearnerDetail(learnerId);

        try (ByteArrayOutputStream baos = new ByteArrayOutputStream()) {
            Document document = new Document(PageSize.A4, 25, 25, 25, 25);
            PdfWriter.getInstance(document, baos);
            document.open();

            Font titleFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 18, new Color(30, 58, 138));
            Font sectionTitleFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 10, new Color(37, 99, 235));
            Font boldFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 8, Color.BLACK);
            Font regularFont = FontFactory.getFont(FontFactory.HELVETICA, 8, Color.BLACK);
            Font tableHeaderFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 7, Color.WHITE);
            Font tableBodyFont = FontFactory.getFont(FontFactory.HELVETICA, 7, Color.BLACK);

            // Title & Header
            com.vocaboo.entity.Classroom scopedClass = classId != null
                    ? classroomRepository.findById(classId).orElse(null)
                    : null;
            String scopedClassName = scopedClass != null ? scopedClass.getName() : detail.getClassName();
            String scopedClassCode = scopedClass != null ? scopedClass.getClassCode() : detail.getClassCode();

            String reportTitle = (scopedClassName != null)
                    ? "Vocaboo - Student Diagnostic Report: " + scopedClassName
                    : "Vocaboo - Student Diagnostic Report Card (All Classes)";
            Paragraph title = new Paragraph(reportTitle, titleFont);
            title.setAlignment(Element.ALIGN_CENTER);
            title.setSpacingAfter(3);
            document.add(title);

            String scopeSub = (scopedClassName != null)
                    ? "Record Scope: Class " + scopedClassName + (scopedClassCode != null ? " (" + scopedClassCode + ")" : "")
                    : "Record Scope: All Classes (Comprehensive Cumulative)";
            String userIdentifier = detail.getUserId() != null ? detail.getUserId() : (detail.getLearnerId() != null ? detail.getLearnerId().toString() : "");
            Paragraph date = new Paragraph(scopeSub + " | Generated on: " + OffsetDateTime.now().format(DATE_FORMATTER) +
                    " | User ID: " + userIdentifier, regularFont);
            date.setAlignment(Element.ALIGN_CENTER);
            date.setSpacingAfter(10);
            document.add(date);

            // ── Active Classroom Context Scope Banner (if enrolled/selected) ──
            if (detail.getClassName() != null || detail.getClassPoints() != null) {
                PdfPTable classScopeTable = new PdfPTable(4);
                classScopeTable.setWidthPercentage(100);
                classScopeTable.setSpacingAfter(10);

                String scopeTitle = (classId != null ? "🏫 Active Classroom-Specific Record: " : "🏫 Active Classroom Context: ")
                        + (detail.getClassName() != null ? detail.getClassName() : "Assigned Class")
                        + (detail.getClassCode() != null ? " [Code: " + detail.getClassCode() + "]" : "");

                PdfPCell headerCell = new PdfPCell(new Phrase(scopeTitle, FontFactory.getFont(FontFactory.HELVETICA_BOLD, 8, new Color(6, 95, 70))));
                headerCell.setColspan(4);
                headerCell.setBackgroundColor(new Color(209, 250, 229));
                headerCell.setPadding(5);
                headerCell.setBorderColor(new Color(16, 185, 129));
                classScopeTable.addCell(headerCell);

                String classPts = detail.getClassPoints() != null ? detail.getClassPoints().toString() + " pts" : "—";
                String classAcc = detail.getClassAccuracy() != null ? detail.getClassAccuracy().setScale(1, RoundingMode.HALF_UP) + "%" : "—";
                String classSessions = detail.getClassSessionsPlayed() != null ? detail.getClassSessionsPlayed() + " sessions" : "—";
                String classTier = detail.getClassMasteryLevel() != null ? detail.getClassMasteryLevel() : "EXPLORER";

                addProfileRow(classScopeTable, "In-Class Score:", classPts, "Class Accuracy:", classAcc, boldFont, regularFont);
                addProfileRow(classScopeTable, "Class Sessions:", classSessions, "Class Tier:", classTier, boldFont, regularFont);
                document.add(classScopeTable);
            }

            // Profile & Performance Summary Box
            PdfPTable profileTable = new PdfPTable(4);
            profileTable.setWidthPercentage(100);
            profileTable.setSpacingAfter(10);

            addProfileRow(profileTable, "Student Name:", detail.getDisplayName(), "User ID:", userIdentifier, boldFont, regularFont);
            addProfileRow(profileTable, "Grade Level:", detail.getGradeLevel() != null ? detail.getGradeLevel() : "N/A", "Account Status:", Boolean.TRUE.equals(detail.getIsActive()) ? "Active" : "Inactive", boldFont, regularFont);
            addProfileRow(profileTable, "Section:", detail.getSectionName() != null ? detail.getSectionName() : "Unassigned", "Mastery Tier:", detail.getMasteryLevel() != null ? detail.getMasteryLevel() : "EXPLORER", boldFont, regularFont);
            addProfileRow(profileTable, "Global Points:", String.valueOf(detail.getTotalPoints()) + " pts", "Overall Accuracy:", (detail.getOverallAccuracy() != null ? detail.getOverallAccuracy().setScale(1, RoundingMode.HALF_UP) : "0.0") + "%", boldFont, regularFont);
            addProfileRow(profileTable, "Words Mastered:", String.valueOf(detail.getWordsMasteredCount()), "Mastery Tier:", detail.getMasteryLevel() != null ? detail.getMasteryLevel() : "EXPLORER", boldFont, regularFont);

            String retentionScoreStr = (detail.getCumulativeReviewsCompleted() != null && detail.getCumulativeReviewsCompleted() > 0 && detail.getAvgCumulativeScore() != null)
                    ? detail.getAvgCumulativeScore().setScale(1, RoundingMode.HALF_UP) + "%"
                    : "—";
            String bestBadgeStr = (detail.getCumulativeReviewsCompleted() != null && detail.getCumulativeReviewsCompleted() > 0 && detail.getBestCumulativeBadge() != null)
                    ? detail.getBestCumulativeBadge()
                    : "—";
            addProfileRow(profileTable, "Retention Score:", retentionScoreStr, "Best Review Badge:", bestBadgeStr, boldFont, regularFont);

            document.add(profileTable);

            // Struggling Status Alert if present
            if (Boolean.TRUE.equals(detail.getIsStruggling()) && detail.getStrugglingReasons() != null && !detail.getStrugglingReasons().isEmpty()) {
                Paragraph alertHeader = new Paragraph("⚠️ Learning Attention Needed / Flagged for Review", sectionTitleFont);
                alertHeader.setSpacingAfter(3);
                document.add(alertHeader);

                for (String reason : detail.getStrugglingReasons()) {
                    Paragraph p = new Paragraph("  • " + reason, regularFont);
                    document.add(p);
                }
                document.add(new Paragraph(" ", regularFont));
            }

            // ── 1. Part of Speech (POS) Mastery Breakdown ──
            if (detail.getPosBreakdown() != null && !detail.getPosBreakdown().isEmpty()) {
                Paragraph posHeader = new Paragraph("Accuracy by Part of Speech (POS)", sectionTitleFont);
                posHeader.setSpacingAfter(4);
                document.add(posHeader);

                PdfPTable posTable = new PdfPTable(6);
                posTable.setWidthPercentage(100);
                posTable.setWidths(new float[]{2.5f, 1.8f, 1.8f, 1.8f, 2.0f, 2.5f});
                posTable.setSpacingAfter(10);

                String[] pHeaders = {"Part of Speech", "Curriculum Words", "Attempts", "Correct", "Accuracy (%)", "Proficiency"};
                for (String h : pHeaders) {
                    PdfPCell cell = new PdfPCell(new Phrase(h, tableHeaderFont));
                    cell.setBackgroundColor(new Color(59, 130, 246));
                    cell.setHorizontalAlignment(Element.ALIGN_CENTER);
                    cell.setPadding(4);
                    posTable.addCell(cell);
                }

                boolean altP = false;
                for (AdminLearnerDetailResponse.PosAccuracyDetail pb : detail.getPosBreakdown()) {
                    Color bg = altP ? new Color(245, 247, 255) : Color.WHITE;
                    double accVal = pb.getAccuracy() != null ? pb.getAccuracy().doubleValue() : 0.0;
                    String rating = accVal >= 85.0 ? "Mastered" : (accVal >= 70.0 ? "Proficient" : (accVal >= 50.0 ? "Developing" : "Needs Focus"));

                    posTable.addCell(createCell(pb.getPartOfSpeech() != null ? pb.getPartOfSpeech() : "OTHER", tableBodyFont, bg, Element.ALIGN_LEFT));
                    posTable.addCell(createCell(String.valueOf(pb.getTotalWords() != null ? pb.getTotalWords() : 0), tableBodyFont, bg, Element.ALIGN_CENTER));
                    posTable.addCell(createCell(String.valueOf(pb.getTotalAttempts() != null ? pb.getTotalAttempts() : 0), tableBodyFont, bg, Element.ALIGN_CENTER));
                    posTable.addCell(createCell(String.valueOf(pb.getCorrectCount() != null ? pb.getCorrectCount() : 0), tableBodyFont, bg, Element.ALIGN_CENTER));
                    posTable.addCell(createCell((pb.getAccuracy() != null ? pb.getAccuracy().setScale(1, RoundingMode.HALF_UP) : "0.0") + "%", tableBodyFont, bg, Element.ALIGN_CENTER));
                    posTable.addCell(createCell(rating, tableBodyFont, bg, Element.ALIGN_CENTER));
                    altP = !altP;
                }
                document.add(posTable);
            }

            // ── 2. Lesson Progress & Module Breakdown ──
            if (detail.getLessons() != null && !detail.getLessons().isEmpty()) {
                Paragraph lessonHeader = new Paragraph("Curriculum Lesson Progress & Module Scores (" + detail.getLessons().size() + " lessons)", sectionTitleFont);
                lessonHeader.setSpacingAfter(4);
                document.add(lessonHeader);

                PdfPTable lessonTable = new PdfPTable(9);
                lessonTable.setWidthPercentage(100);
                lessonTable.setWidths(new float[]{3.2f, 1.2f, 1.6f, 1.5f, 1.2f, 1.2f, 1.2f, 1.2f, 1.8f});
                lessonTable.setSpacingAfter(10);

                String[] lHeaders = {"Lesson Title", "Grade", "Status", "Mastery", "M1 Intro", "M2 Pract", "M3 Sent", "M4 Test", "Date"};
                for (String h : lHeaders) {
                    PdfPCell cell = new PdfPCell(new Phrase(h, tableHeaderFont));
                    cell.setBackgroundColor(new Color(63, 81, 181));
                    cell.setHorizontalAlignment(Element.ALIGN_CENTER);
                    cell.setPadding(4);
                    lessonTable.addCell(cell);
                }

                boolean alt = false;
                for (LearnerLessonProgressDetail l : detail.getLessons()) {
                    Color bg = alt ? new Color(245, 245, 250) : Color.WHITE;
                    boolean isCompleted = "COMPLETED".equalsIgnoreCase(l.getStatus());

                    BigDecimal safeM1 = l.getModule1Score() != null ? l.getModule1Score().min(BigDecimal.valueOf(100)).max(BigDecimal.ZERO) : null;
                    BigDecimal safeM2 = l.getModule2Score() != null ? l.getModule2Score().min(BigDecimal.valueOf(100)).max(BigDecimal.ZERO) : null;
                    BigDecimal safeM3 = l.getModule3Score() != null ? l.getModule3Score().min(BigDecimal.valueOf(100)).max(BigDecimal.ZERO) : null;
                    BigDecimal safeM4 = l.getModule4Score() != null ? l.getModule4Score().min(BigDecimal.valueOf(100)).max(BigDecimal.ZERO) : null;
                    BigDecimal safeMastery = l.getMasteryScore() != null ? l.getMasteryScore().min(BigDecimal.valueOf(100)).max(BigDecimal.ZERO) : null;

                    String m1Str = safeM1 != null ? safeM1.setScale(0, RoundingMode.HALF_UP) + "%" : (isCompleted || safeM2 != null ? "100%" : "—");
                    String m2Str = safeM2 != null ? safeM2.setScale(0, RoundingMode.HALF_UP) + "%" : "—";
                    String m3Str = safeM3 != null ? safeM3.setScale(0, RoundingMode.HALF_UP) + "%" : "—";
                    String m4Str = safeM4 != null ? safeM4.setScale(0, RoundingMode.HALF_UP) + "%" : "—";

                    lessonTable.addCell(createCell(l.getLessonTitle(), tableBodyFont, bg, Element.ALIGN_LEFT));
                    lessonTable.addCell(createCell(l.getGradeLevel(), tableBodyFont, bg, Element.ALIGN_CENTER));
                    lessonTable.addCell(createCell(l.getStatus(), tableBodyFont, bg, Element.ALIGN_CENTER));
                    lessonTable.addCell(createCell(safeMastery != null ? safeMastery.setScale(0, RoundingMode.HALF_UP) + "%" : "—", tableBodyFont, bg, Element.ALIGN_CENTER));
                    lessonTable.addCell(createCell(m1Str, tableBodyFont, bg, Element.ALIGN_CENTER));
                    lessonTable.addCell(createCell(m2Str, tableBodyFont, bg, Element.ALIGN_CENTER));
                    lessonTable.addCell(createCell(m3Str, tableBodyFont, bg, Element.ALIGN_CENTER));
                    lessonTable.addCell(createCell(m4Str, tableBodyFont, bg, Element.ALIGN_CENTER));
                    lessonTable.addCell(createCell(l.getCompletedAt() != null ? l.getCompletedAt().format(DateTimeFormatter.ofPattern("yyyy-MM-dd")) : "—", tableBodyFont, bg, Element.ALIGN_CENTER));
                    alt = !alt;
                }
                document.add(lessonTable);
            }

            // ── 3. Cumulative Review & Retention Performance Section ──
            if (detail.getCumulativeReviews() != null && !detail.getCumulativeReviews().isEmpty()) {
                Paragraph cumHeader = new Paragraph("Cumulative Review & Retention Performance (" + detail.getCumulativeReviews().size() + " completed)", sectionTitleFont);
                cumHeader.setSpacingAfter(4);
                document.add(cumHeader);

                PdfPTable cumTable = new PdfPTable(6);
                cumTable.setWidthPercentage(100);
                cumTable.setWidths(new float[]{4.0f, 2.0f, 2.5f, 1.8f, 2.0f, 2.5f});
                cumTable.setSpacingAfter(10);

                String[] cHeaders = {"Category / Lesson Pair", "Accuracy", "Badge Earned", "Points", "Questions", "Date Completed"};
                for (String h : cHeaders) {
                    PdfPCell cell = new PdfPCell(new Phrase(h, tableHeaderFont));
                    cell.setBackgroundColor(new Color(245, 158, 11));
                    cell.setHorizontalAlignment(Element.ALIGN_CENTER);
                    cell.setPadding(4);
                    cumTable.addCell(cell);
                }

                boolean altC = false;
                for (AdminLearnerDetailResponse.CumulativeReviewPerformanceDetail cr : detail.getCumulativeReviews()) {
                    Color bg = altC ? new Color(255, 251, 235) : Color.WHITE;
                    cumTable.addCell(createCell(cr.getLessonPairId() != null ? cr.getLessonPairId() : "Category Review", tableBodyFont, bg, Element.ALIGN_LEFT));
                    cumTable.addCell(createCell(cr.getAccuracyPercent() != null ? cr.getAccuracyPercent().setScale(1, RoundingMode.HALF_UP) + "%" : "—", tableBodyFont, bg, Element.ALIGN_CENTER));
                    cumTable.addCell(createCell(cr.getBadgeAwarded() != null ? cr.getBadgeAwarded() : "BRONZE", tableBodyFont, bg, Element.ALIGN_CENTER));
                    cumTable.addCell(createCell(String.valueOf(cr.getPointsEarned() != null ? cr.getPointsEarned() : 0), tableBodyFont, bg, Element.ALIGN_CENTER));

                    String qStr = (cr.getCorrectCount() != null && cr.getTotalAttempts() != null)
                            ? cr.getCorrectCount() + "/" + cr.getTotalAttempts()
                            : (cr.getTotalAttempts() != null ? String.valueOf(cr.getTotalAttempts()) : "—");
                    cumTable.addCell(createCell(qStr, tableBodyFont, bg, Element.ALIGN_CENTER));
                    cumTable.addCell(createCell(cr.getCompletedAt() != null ? cr.getCompletedAt().format(DateTimeFormatter.ofPattern("yyyy-MM-dd")) : "—", tableBodyFont, bg, Element.ALIGN_CENTER));
                    altC = !altC;
                }
                document.add(cumTable);
            }

            // ── 4. Words to Practice & Reinforce / Word Diagnostic ──
            List<LearnerWordPerformanceDetail> displayWords = (detail.getWeakWords() != null && !detail.getWeakWords().isEmpty())
                    ? detail.getWeakWords()
                    : (detail.getAllWords() != null ? detail.getAllWords().stream().limit(15).collect(Collectors.toList()) : Collections.emptyList());

            if (!displayWords.isEmpty()) {
                String sectionTitle = (detail.getWeakWords() != null && !detail.getWeakWords().isEmpty())
                        ? "Words to Practice & Reinforce (Weak Words)"
                        : "Vocabulary Performance Diagnostic";
                Paragraph weakHeader = new Paragraph(sectionTitle, sectionTitleFont);
                weakHeader.setSpacingAfter(4);
                document.add(weakHeader);

                PdfPTable weakTable = new PdfPTable(8);
                weakTable.setWidthPercentage(100);
                weakTable.setWidths(new float[]{2.3f, 1.5f, 2.3f, 2.3f, 1.5f, 1.5f, 1.3f, 1.8f});

                String[] wHeaders = {"English Word", "Part of Speech", "Cebuano Meaning", "Lesson Source", "Lesson Acc", "Lifetime Acc", "Demerits", "Status"};
                for (String h : wHeaders) {
                    PdfPCell cell = new PdfPCell(new Phrase(h, tableHeaderFont));
                    cell.setBackgroundColor(new Color(239, 68, 68));
                    cell.setHorizontalAlignment(Element.ALIGN_CENTER);
                    cell.setPadding(4);
                    weakTable.addCell(cell);
                }

                boolean altW = false;
                for (LearnerWordPerformanceDetail w : displayWords) {
                    Color bg = altW ? new Color(255, 245, 245) : Color.WHITE;
                    BigDecimal lessonAcc = w.getLessonAccuracy() != null ? w.getLessonAccuracy() : w.getAccuracy();
                    BigDecimal lifeAcc = w.getLifetimeAccuracy() != null ? w.getLifetimeAccuracy() : w.getAccuracy();
                    double accVal = lifeAcc != null ? lifeAcc.doubleValue() : (lessonAcc != null ? lessonAcc.doubleValue() : 0.0);
                    String status = accVal < 50.0 ? "Needs Review" : (accVal < 75.0 ? "In Progress" : "Nearly Mastered");

                    weakTable.addCell(createCell(w.getEnglishWord(), tableBodyFont, bg, Element.ALIGN_LEFT));
                    weakTable.addCell(createCell(w.getPartOfSpeech() != null ? w.getPartOfSpeech() : "—", tableBodyFont, bg, Element.ALIGN_CENTER));
                    weakTable.addCell(createCell(w.getCebuanoMeaning(), tableBodyFont, bg, Element.ALIGN_LEFT));
                    weakTable.addCell(createCell(w.getLessonTitle(), tableBodyFont, bg, Element.ALIGN_LEFT));
                    weakTable.addCell(createCell((lessonAcc != null ? lessonAcc.setScale(1, RoundingMode.HALF_UP) : "0.0") + "%", tableBodyFont, bg, Element.ALIGN_CENTER));
                    weakTable.addCell(createCell((lifeAcc != null ? lifeAcc.setScale(1, RoundingMode.HALF_UP) : "0.0") + "%", tableBodyFont, bg, Element.ALIGN_CENTER));
                    weakTable.addCell(createCell(String.valueOf(w.getDemeritPoints() != null ? w.getDemeritPoints() : 0), tableBodyFont, bg, Element.ALIGN_CENTER));
                    weakTable.addCell(createCell(status, tableBodyFont, bg, Element.ALIGN_CENTER));
                    altW = !altW;
                }
                document.add(weakTable);
            }

            document.close();
            return baos.toByteArray();
        } catch (Exception e) {
            throw new RuntimeException("Failed to generate Individual PDF report", e);
        }
    }

    public byte[] generateIndividualReportCsv(UUID learnerId) {
        return generateIndividualReportCsv(learnerId, null, null);
    }

    public byte[] generateIndividualReportCsv(UUID learnerId, UUID teacherId, UUID classId) {
        AdminLearnerDetailResponse detail = (teacherId != null || classId != null)
                ? adminLearnerService.getLearnerDetail(learnerId, teacherId, classId)
                : adminLearnerService.getLearnerDetail(learnerId);

        StringWriter sw = new StringWriter();
        try (CSVWriter writer = new CSVWriter(sw)) {
            // Profile Summary
            com.vocaboo.entity.Classroom scopedClass = classId != null
                    ? classroomRepository.findById(classId).orElse(null)
                    : null;
            String scopedClassName = scopedClass != null ? scopedClass.getName() : detail.getClassName();
            String scopedClassCode = scopedClass != null ? scopedClass.getClassCode() : detail.getClassCode();

            String headerTitle = (scopedClassName != null)
                    ? "STUDENT PROFILE & DIAGNOSTIC REPORT CARD (" + scopedClassName.toUpperCase() + ")"
                    : "STUDENT PROFILE & DIAGNOSTIC PERFORMANCE REPORT CARD";
            writer.writeNext(new String[]{headerTitle});
            writer.writeNext(new String[]{"Record Scope", (scopedClassName != null) ? "Specific Class: " + scopedClassName + (scopedClassCode != null ? " (" + scopedClassCode + ")" : "") : "All Classes (Cumulative Lifetime Record)"});
            writer.writeNext(new String[]{"Learner ID", detail.getLearnerId().toString()});
            writer.writeNext(new String[]{"Display Name", detail.getDisplayName()});
            writer.writeNext(new String[]{"Grade Level", detail.getGradeLevel() != null ? detail.getGradeLevel() : "N/A"});
            writer.writeNext(new String[]{"Section", detail.getSectionName() != null ? detail.getSectionName() : "Unassigned"});
            writer.writeNext(new String[]{"Account Status", Boolean.TRUE.equals(detail.getIsActive()) ? "Active" : "Inactive"});
            writer.writeNext(new String[]{"Global Points", String.valueOf(detail.getTotalPoints())});
            writer.writeNext(new String[]{"Overall Accuracy", (detail.getOverallAccuracy() != null ? detail.getOverallAccuracy().toString() : "0") + "%"});
            writer.writeNext(new String[]{"Words Mastered", String.valueOf(detail.getWordsMasteredCount())});
            writer.writeNext(new String[]{"Mastery Tier", detail.getMasteryLevel() != null ? detail.getMasteryLevel() : "EXPLORER"});

            if (detail.getClassName() != null || detail.getClassPoints() != null) {
                writer.writeNext(new String[]{"Classroom Scope", detail.getClassName() != null ? detail.getClassName() : "Assigned Class"});
                writer.writeNext(new String[]{"Class Code", detail.getClassCode() != null ? detail.getClassCode() : "N/A"});
                writer.writeNext(new String[]{"In-Class Score", detail.getClassPoints() != null ? detail.getClassPoints().toString() : "0"});
                writer.writeNext(new String[]{"In-Class Accuracy", detail.getClassAccuracy() != null ? detail.getClassAccuracy().toString() + "%" : "0.0%"});
                writer.writeNext(new String[]{"Class Sessions", detail.getClassSessionsPlayed() != null ? detail.getClassSessionsPlayed().toString() : "0"});
            }

            String retentionScoreStr = (detail.getCumulativeReviewsCompleted() != null && detail.getCumulativeReviewsCompleted() > 0 && detail.getAvgCumulativeScore() != null)
                    ? detail.getAvgCumulativeScore().toString() + "%"
                    : "—";
            String bestBadgeStr = (detail.getCumulativeReviewsCompleted() != null && detail.getCumulativeReviewsCompleted() > 0 && detail.getBestCumulativeBadge() != null)
                    ? detail.getBestCumulativeBadge()
                    : "—";
            writer.writeNext(new String[]{"Retention Score", retentionScoreStr});
            writer.writeNext(new String[]{"Best Review Badge", bestBadgeStr});
            writer.writeNext(new String[]{""});

            // Part of Speech Breakdown
            if (detail.getPosBreakdown() != null && !detail.getPosBreakdown().isEmpty()) {
                writer.writeNext(new String[]{"PART OF SPEECH (POS) ACCURACY BREAKDOWN"});
                writer.writeNext(new String[]{"Part of Speech", "Curriculum Words", "Attempts", "Correct Count", "Accuracy (%)"});
                for (AdminLearnerDetailResponse.PosAccuracyDetail pb : detail.getPosBreakdown()) {
                    writer.writeNext(new String[]{
                            pb.getPartOfSpeech() != null ? pb.getPartOfSpeech() : "OTHER",
                            String.valueOf(pb.getTotalWords() != null ? pb.getTotalWords() : 0),
                            String.valueOf(pb.getTotalAttempts() != null ? pb.getTotalAttempts() : 0),
                            String.valueOf(pb.getCorrectCount() != null ? pb.getCorrectCount() : 0),
                            pb.getAccuracy() != null ? pb.getAccuracy().toString() : "0.00"
                    });
                }
                writer.writeNext(new String[]{""});
            }

            // Lesson Progress
            writer.writeNext(new String[]{"LESSON PROGRESS & MODULE SCORES"});
            writer.writeNext(new String[]{"Lesson Title", "Grade Level", "Status", "Mastery Score (%)", "M1 (Intro)", "M2 (Practice)", "M3 (Sentence)", "M4 (Test)", "Completed At"});
            if (detail.getLessons() != null) {
                for (LearnerLessonProgressDetail l : detail.getLessons()) {
                    boolean isCompleted = "COMPLETED".equalsIgnoreCase(l.getStatus());
                    BigDecimal safeM1 = l.getModule1Score() != null ? l.getModule1Score().min(BigDecimal.valueOf(100)).max(BigDecimal.ZERO) : null;
                    BigDecimal safeM2 = l.getModule2Score() != null ? l.getModule2Score().min(BigDecimal.valueOf(100)).max(BigDecimal.ZERO) : null;
                    BigDecimal safeM3 = l.getModule3Score() != null ? l.getModule3Score().min(BigDecimal.valueOf(100)).max(BigDecimal.ZERO) : null;
                    BigDecimal safeM4 = l.getModule4Score() != null ? l.getModule4Score().min(BigDecimal.valueOf(100)).max(BigDecimal.ZERO) : null;
                    BigDecimal safeMastery = l.getMasteryScore() != null ? l.getMasteryScore().min(BigDecimal.valueOf(100)).max(BigDecimal.ZERO) : null;

                    String m1Str = safeM1 != null ? safeM1.setScale(0, RoundingMode.HALF_UP).toString() + "%" : (isCompleted || safeM2 != null ? "100%" : "");
                    String m2Str = safeM2 != null ? safeM2.setScale(0, RoundingMode.HALF_UP).toString() + "%" : "";
                    String m3Str = safeM3 != null ? safeM3.setScale(0, RoundingMode.HALF_UP).toString() + "%" : "";
                    String m4Str = safeM4 != null ? safeM4.setScale(0, RoundingMode.HALF_UP).toString() + "%" : "";

                    writer.writeNext(new String[]{
                            l.getLessonTitle(),
                            l.getGradeLevel(),
                            l.getStatus(),
                            safeMastery != null ? safeMastery.setScale(0, RoundingMode.HALF_UP).toString() : "",
                            m1Str,
                            m2Str,
                            m3Str,
                            m4Str,
                            l.getCompletedAt() != null ? l.getCompletedAt().format(DATE_FORMATTER) : ""
                    });
                }
            }
            writer.writeNext(new String[]{""});

            // Cumulative Reviews
            if (detail.getCumulativeReviews() != null && !detail.getCumulativeReviews().isEmpty()) {
                writer.writeNext(new String[]{"CUMULATIVE REVIEW & RETENTION PERFORMANCE"});
                writer.writeNext(new String[]{"Category / Lesson Pair", "Accuracy (%)", "Badge Earned", "Points Earned", "Correct Count", "Total Attempts", "Completed At"});
                for (AdminLearnerDetailResponse.CumulativeReviewPerformanceDetail cr : detail.getCumulativeReviews()) {
                    writer.writeNext(new String[]{
                            cr.getLessonPairId() != null ? cr.getLessonPairId() : "Category Review",
                            cr.getAccuracyPercent() != null ? cr.getAccuracyPercent().toString() : "0.00",
                            cr.getBadgeAwarded() != null ? cr.getBadgeAwarded() : "BRONZE",
                            String.valueOf(cr.getPointsEarned() != null ? cr.getPointsEarned() : 0),
                            String.valueOf(cr.getCorrectCount() != null ? cr.getCorrectCount() : 0),
                            String.valueOf(cr.getTotalAttempts() != null ? cr.getTotalAttempts() : 0),
                            cr.getCompletedAt() != null ? cr.getCompletedAt().format(DATE_FORMATTER) : ""
                    });
                }
                writer.writeNext(new String[]{""});
            }

            // Words to Practice
            writer.writeNext(new String[]{"WORDS TO PRACTICE & REINFORCE"});
            writer.writeNext(new String[]{"English Word", "Part of Speech", "Cebuano Meaning", "Lesson Source", "Lesson Accuracy (%)", "Lifetime Accuracy (%)", "Correct", "Incorrect", "Demerit Points", "Fallback Count"});
            List<LearnerWordPerformanceDetail> displayWords = (detail.getWeakWords() != null && !detail.getWeakWords().isEmpty())
                    ? detail.getWeakWords()
                    : (detail.getAllWords() != null ? detail.getAllWords() : Collections.emptyList());
            for (LearnerWordPerformanceDetail w : displayWords) {
                BigDecimal lessonAcc = w.getLessonAccuracy() != null ? w.getLessonAccuracy() : w.getAccuracy();
                BigDecimal lifeAcc = w.getLifetimeAccuracy() != null ? w.getLifetimeAccuracy() : w.getAccuracy();

                writer.writeNext(new String[]{
                        w.getEnglishWord(),
                        w.getPartOfSpeech() != null ? w.getPartOfSpeech() : "",
                        w.getCebuanoMeaning(),
                        w.getLessonTitle(),
                        lessonAcc != null ? lessonAcc.setScale(2, RoundingMode.HALF_UP).toString() : "0.00",
                        lifeAcc != null ? lifeAcc.setScale(2, RoundingMode.HALF_UP).toString() : "0.00",
                        String.valueOf(w.getCorrectCount()),
                        String.valueOf(w.getIncorrectCount()),
                        String.valueOf(w.getDemeritPoints()),
                        String.valueOf(w.getFallbackCount())
                });
            }
        } catch (Exception e) {
            throw new RuntimeException("Failed to generate Individual CSV report", e);
        }

        return sw.toString().getBytes(StandardCharsets.UTF_8);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // 3. WORD PERFORMANCE & CURRICULUM REPORT
    // ──────────────────────────────────────────────────────────────────────────

    public byte[] generateWordPerformanceReportCsv(UUID sectionId, UUID lessonId) {
        return generateWordPerformanceReportCsv(sectionId, lessonId, null, null);
    }

    public byte[] generateWordPerformanceReportCsv(UUID sectionId, UUID lessonId, UUID teacherId) {
        return generateWordPerformanceReportCsv(sectionId, lessonId, null, teacherId);
    }

    public byte[] generateWordPerformanceReportCsv(UUID sectionId, UUID lessonId, UUID categoryId, UUID teacherId) {
        List<WordPerformance> performances = getWordPerformances(sectionId, lessonId, categoryId, teacherId);

        String scopeLabel = "ALL CLASSES (COMPREHENSIVE CURRICULUM)";
        if (sectionId != null) {
            String cName = classroomRepository.findById(sectionId)
                    .map(c -> c.getName() + (c.getClassCode() != null ? " [Code: " + c.getClassCode() + "]" : ""))
                    .orElse("Class ID: " + sectionId);
            scopeLabel = "CLASS: " + cName;
        } else if (teacherId != null) {
            scopeLabel = "ALL MY CLASSES (TEACHER CURRICULUM)";
        }

        StringWriter sw = new StringWriter();
        try (CSVWriter writer = new CSVWriter(sw)) {
            writer.writeNext(new String[]{"VOCABOO - CURRICULUM & WORD PERFORMANCE REPORT"});
            writer.writeNext(new String[]{"Record Scope", scopeLabel});
            writer.writeNext(new String[]{"Generated On", OffsetDateTime.now().format(DATE_FORMATTER)});
            writer.writeNext(new String[]{"Total Evaluated Words", String.valueOf(performances.size())});
            writer.writeNext(new String[]{""});

            writer.writeNext(new String[]{
                    "Word ID",
                    "English Word",
                    "Cebuano Meaning",
                    "Lesson Title",
                    "Grade Level",
                    "Learner Name",
                    "Total Attempts",
                    "Correct Count",
                    "Incorrect Count",
                    "Lesson Accuracy (%)",
                    "Lifetime Accuracy (%)",
                    "Demerit Points",
                    "Tier Drops",
                    "Fallback Count",
                    "Last Practiced"
            });

            for (WordPerformance wp : performances) {
                VocabularyWord word = wp.getWord();
                int totAtt = wp.getTotalAttempts() != null ? wp.getTotalAttempts() : 0;
                int totCorr = wp.getCorrectCount() != null ? wp.getCorrectCount() : 0;
                BigDecimal lessonAcc = wp.getAccuracy() != null ? wp.getAccuracy().setScale(2, RoundingMode.HALF_UP) : BigDecimal.ZERO;
                BigDecimal lifetimeAcc = totAtt > 0
                        ? BigDecimal.valueOf(totCorr * 100.0 / totAtt).setScale(2, RoundingMode.HALF_UP)
                        : lessonAcc;

                writer.writeNext(new String[]{
                        word.getWordId() != null ? word.getWordId().toString() : "",
                        word.getEnglishWord() != null ? word.getEnglishWord() : "",
                        word.getCebuanoMeaning() != null ? word.getCebuanoMeaning() : "",
                        word.getLesson() != null ? word.getLesson().getLessonTitle() : "",
                        word.getGradeLevel() != null ? word.getGradeLevel().name() : "",
                        wp.getLearner() != null ? wp.getLearner().getDisplayName() : "",
                        String.valueOf(totAtt),
                        String.valueOf(totCorr),
                        String.valueOf(wp.getIncorrectCount() != null ? wp.getIncorrectCount() : 0),
                        lessonAcc.toString(),
                        lifetimeAcc.toString(),
                        String.valueOf(wp.getDemeritPoints() != null ? wp.getDemeritPoints() : 0),
                        String.valueOf(wp.getTierDropCount() != null ? wp.getTierDropCount() : 0),
                        String.valueOf(wp.getFallbackCount() != null ? wp.getFallbackCount() : 0),
                        wp.getLastPracticedAt() != null ? wp.getLastPracticedAt().format(DATE_FORMATTER) : ""
                });
            }
        } catch (Exception e) {
            throw new RuntimeException("Failed to generate Word Performance CSV report", e);
        }

        return sw.toString().getBytes(StandardCharsets.UTF_8);
    }

    public byte[] generateWordPerformanceReportPdf(UUID sectionId, UUID lessonId) {
        return generateWordPerformanceReportPdf(sectionId, lessonId, null, null);
    }

    public byte[] generateWordPerformanceReportPdf(UUID sectionId, UUID lessonId, UUID teacherId) {
        return generateWordPerformanceReportPdf(sectionId, lessonId, null, teacherId);
    }

    public byte[] generateWordPerformanceReportPdf(UUID sectionId, UUID lessonId, UUID categoryId, UUID teacherId) {
        List<WordPerformance> performances = getWordPerformances(sectionId, lessonId, categoryId, teacherId);

        String scopeLabel = "Scope: All Classes (Comprehensive Curriculum)";
        String wordTitle = "Vocaboo - Curriculum & Word Performance Report";
        if (sectionId != null) {
            com.vocaboo.entity.Classroom cr = classroomRepository.findById(sectionId).orElse(null);
            if (cr != null) {
                wordTitle = "Vocaboo - " + cr.getName() + " Word Performance Report";
                scopeLabel = "Class Scope: " + cr.getName() + (cr.getClassCode() != null ? " [Code: " + cr.getClassCode() + "]" : "");
            } else {
                scopeLabel = "Class Scope: ID " + sectionId;
            }
        } else if (teacherId != null) {
            scopeLabel = "Scope: All My Classes (Teacher Curriculum)";
        }

        // Aggregate by word for cleaner PDF presentation
        Map<UUID, List<WordPerformance>> byWord = performances.stream()
                .collect(Collectors.groupingBy(wp -> wp.getWord().getWordId()));

        try (ByteArrayOutputStream baos = new ByteArrayOutputStream()) {
            Document document = new Document(PageSize.A4.rotate(), 24, 24, 24, 24);
            PdfWriter.getInstance(document, baos);
            document.open();

            Font titleFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 18, new Color(40, 53, 147));
            Font subTitleFont = FontFactory.getFont(FontFactory.HELVETICA, 10, Color.DARK_GRAY);
            Font tableHeaderFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 9, Color.WHITE);
            Font tableBodyFont = FontFactory.getFont(FontFactory.HELVETICA, 8, Color.BLACK);

            Paragraph title = new Paragraph(wordTitle, titleFont);
            title.setAlignment(Element.ALIGN_CENTER);
            title.setSpacingAfter(4);
            document.add(title);

            Paragraph meta = new Paragraph(scopeLabel + " | Generated on: " + OffsetDateTime.now().format(DATE_FORMATTER) +
                    " | Total Words Evaluated: " + byWord.size(), subTitleFont);
            meta.setAlignment(Element.ALIGN_CENTER);
            meta.setSpacingAfter(15);
            document.add(meta);

            PdfPTable table = new PdfPTable(9);
            table.setWidthPercentage(100);
            table.setWidths(new float[]{2.8f, 2.8f, 3.0f, 1.5f, 1.8f, 1.8f, 1.5f, 1.5f, 1.5f});

            String[] headers = {"English Word", "Cebuano Meaning", "Lesson Title", "Attempts", "Lesson Acc", "Lifetime Acc", "Demerits", "Tier Drops", "Fallbacks"};
            for (String h : headers) {
                PdfPCell cell = new PdfPCell(new Phrase(h, tableHeaderFont));
                cell.setBackgroundColor(new Color(63, 81, 181));
                cell.setHorizontalAlignment(Element.ALIGN_CENTER);
                cell.setPadding(6);
                table.addCell(cell);
            }

            boolean alternate = false;
            for (Map.Entry<UUID, List<WordPerformance>> entry : byWord.entrySet()) {
                List<WordPerformance> list = entry.getValue();
                VocabularyWord word = list.get(0).getWord();

                int totalAttempts = list.stream().mapToInt(wp -> wp.getTotalAttempts() != null ? wp.getTotalAttempts() : 0).sum();
                int totalCorrect = list.stream().mapToInt(wp -> wp.getCorrectCount() != null ? wp.getCorrectCount() : 0).sum();
                int totalDemerits = list.stream().mapToInt(wp -> wp.getDemeritPoints() != null ? wp.getDemeritPoints() : 0).sum();
                int totalDrops = list.stream().mapToInt(wp -> wp.getTierDropCount() != null ? wp.getTierDropCount() : 0).sum();
                int totalFallbacks = list.stream().mapToInt(wp -> wp.getFallbackCount() != null ? wp.getFallbackCount() : 0).sum();

                double avgLessonAcc = list.stream()
                        .map(WordPerformance::getAccuracy)
                        .filter(Objects::nonNull)
                        .mapToDouble(BigDecimal::doubleValue)
                        .average()
                        .orElse(0.0);
                double lifetimeAcc = totalAttempts > 0 ? (totalCorrect * 100.0 / totalAttempts) : 0.0;

                Color bgColor = alternate ? new Color(245, 245, 250) : Color.WHITE;

                table.addCell(createCell(word.getEnglishWord(), tableBodyFont, bgColor, Element.ALIGN_LEFT));
                table.addCell(createCell(word.getCebuanoMeaning(), tableBodyFont, bgColor, Element.ALIGN_LEFT));
                table.addCell(createCell(word.getLesson() != null ? word.getLesson().getLessonTitle() : "—", tableBodyFont, bgColor, Element.ALIGN_LEFT));
                table.addCell(createCell(String.valueOf(totalAttempts), tableBodyFont, bgColor, Element.ALIGN_CENTER));
                table.addCell(createCell(BigDecimal.valueOf(avgLessonAcc).setScale(1, RoundingMode.HALF_UP) + "%", tableBodyFont, bgColor, Element.ALIGN_CENTER));
                table.addCell(createCell(BigDecimal.valueOf(lifetimeAcc).setScale(1, RoundingMode.HALF_UP) + "%", tableBodyFont, bgColor, Element.ALIGN_CENTER));
                table.addCell(createCell(String.valueOf(totalDemerits), tableBodyFont, bgColor, Element.ALIGN_CENTER));
                table.addCell(createCell(String.valueOf(totalDrops), tableBodyFont, bgColor, Element.ALIGN_CENTER));
                table.addCell(createCell(String.valueOf(totalFallbacks), tableBodyFont, bgColor, Element.ALIGN_CENTER));

                alternate = !alternate;
            }

            document.add(table);
            document.close();
            return baos.toByteArray();
        } catch (Exception e) {
            throw new RuntimeException("Failed to generate Word Performance PDF report", e);
        }
    }

    private List<WordPerformance> getWordPerformances(UUID sectionId, UUID lessonId, UUID categoryId, UUID teacherId) {
        List<WordPerformance> perfs;
        if (sectionId != null) {
            List<UUID> classEnrolledIds = classEnrollmentRepository.findEnrolledLearnerIdsByClassId(sectionId);
            if (!classEnrolledIds.isEmpty()) {
                if (lessonId != null) {
                    perfs = wordPerformanceRepository.findByLearnerLearnerIdInAndWordLessonLessonId(classEnrolledIds, lessonId);
                } else {
                    perfs = wordPerformanceRepository.findByLearnerLearnerIdIn(classEnrolledIds);
                }
            } else {
                if (lessonId != null) {
                    perfs = wordPerformanceRepository.findByLearnerSectionSectionIdAndWordLessonLessonId(sectionId, lessonId);
                } else {
                    perfs = wordPerformanceRepository.findByLearnerSectionSectionId(sectionId);
                }
            }
            perfs = perfs.stream()
                    .filter(wp -> wp.getWord() != null && wp.getWord().getLesson() != null
                            && (wp.getWord().getLesson().getClassroom() == null
                            || sectionId.equals(wp.getWord().getLesson().getClassroom().getClassId())))
                    .collect(Collectors.toList());
        } else if (teacherId != null) {
            List<UUID> teacherEnrolledIds = classEnrollmentRepository.findEnrolledLearnerIdsByTeacherId(teacherId);
            if (!teacherEnrolledIds.isEmpty()) {
                if (lessonId != null) {
                    perfs = wordPerformanceRepository.findByLearnerLearnerIdInAndWordLessonLessonId(teacherEnrolledIds, lessonId);
                } else {
                    perfs = wordPerformanceRepository.findByLearnerLearnerIdIn(teacherEnrolledIds);
                }
                perfs = perfs.stream()
                        .filter(wp -> wp.getWord() != null && wp.getWord().getLesson() != null
                                && (wp.getWord().getLesson().getClassroom() == null
                                || (wp.getWord().getLesson().getClassroom().getTeacher() != null
                                && teacherId.equals(wp.getWord().getLesson().getClassroom().getTeacher().getTeacherId()))))
                        .collect(Collectors.toList());
            } else {
                return Collections.emptyList();
            }
        } else if (lessonId != null) {
            perfs = wordPerformanceRepository.findByWordLessonLessonId(lessonId);
        } else {
            perfs = wordPerformanceRepository.findAll();
        }

        if (categoryId != null) {
            perfs = perfs.stream()
                    .filter(wp -> wp.getWord() != null && wp.getWord().getLesson() != null
                            && wp.getWord().getLesson().getCategory() != null
                            && categoryId.equals(wp.getWord().getLesson().getCategory().getCategoryId()))
                    .collect(Collectors.toList());
        }

        perfs = perfs.stream()
                .filter(wp -> wp.getWord() != null)
                .collect(Collectors.toList());

        return perfs;
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Helper Methods for OpenPDF Cells
    // ──────────────────────────────────────────────────────────────────────────

    private PdfPCell createCell(String text, Font font, Color bgColor, int alignment) {
        PdfPCell cell = new PdfPCell(new Phrase(text != null ? text : "", font));
        cell.setBackgroundColor(bgColor);
        cell.setHorizontalAlignment(alignment);
        cell.setVerticalAlignment(Element.ALIGN_MIDDLE);
        cell.setPadding(5);
        cell.setBorderColor(new Color(220, 220, 220));
        return cell;
    }

    private void addProfileRow(PdfPTable table, String label1, String value1, String label2, String value2, Font boldFont, Font regularFont) {
        PdfPCell c1 = new PdfPCell(new Phrase(label1, boldFont));
        c1.setBorder(Rectangle.NO_BORDER);
        c1.setPadding(3);
        table.addCell(c1);

        PdfPCell c2 = new PdfPCell(new Phrase(value1 != null ? value1 : "—", regularFont));
        c2.setBorder(Rectangle.NO_BORDER);
        c2.setPadding(3);
        table.addCell(c2);

        PdfPCell c3 = new PdfPCell(new Phrase(label2, boldFont));
        c3.setBorder(Rectangle.NO_BORDER);
        c3.setPadding(3);
        table.addCell(c3);

        PdfPCell c4 = new PdfPCell(new Phrase(value2 != null ? value2 : "—", regularFont));
        c4.setBorder(Rectangle.NO_BORDER);
        c4.setPadding(3);
        table.addCell(c4);
    }
}
