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
public class ReportGenerationService {

    private final AdminLearnerService adminLearnerService;
    private final WordPerformanceRepository wordPerformanceRepository;
    private final VocabularyWordRepository vocabularyWordRepository;

    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");

    // ──────────────────────────────────────────────────────────────────────────
    // 1. CLASS PERFORMANCE REPORT
    // ──────────────────────────────────────────────────────────────────────────

    public byte[] generateClassReportCsv(UUID sectionId, GradeLevel gradeLevel) {
        List<AdminLearnerSummaryResponse> learners = adminLearnerService.getAllLearnersSummary(sectionId, gradeLevel);

        StringWriter sw = new StringWriter();
        try (CSVWriter writer = new CSVWriter(sw)) {
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
                writer.writeNext(new String[]{
                        l.getLearnerId() != null ? l.getLearnerId().toString() : "",
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
        List<AdminLearnerSummaryResponse> learners = adminLearnerService.getAllLearnersSummary(sectionId, gradeLevel);

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
            Paragraph title = new Paragraph("Vocaboo - Class Performance Report", titleFont);
            title.setAlignment(Element.ALIGN_CENTER);
            title.setSpacingAfter(4);
            document.add(title);

            Paragraph meta = new Paragraph("Generated on: " + OffsetDateTime.now().format(DATE_FORMATTER) +
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

                table.addCell(createCell(l.getDisplayName(), tableBodyFont, bgColor, Element.ALIGN_LEFT));
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
        AdminLearnerDetailResponse detail = adminLearnerService.getLearnerDetail(learnerId);

        try (ByteArrayOutputStream baos = new ByteArrayOutputStream()) {
            Document document = new Document(PageSize.A4, 25, 25, 25, 25);
            PdfWriter.getInstance(document, baos);
            document.open();

            Font titleFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 18, new Color(40, 53, 147));
            Font sectionTitleFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 11, new Color(63, 81, 181));
            Font boldFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 8, Color.BLACK);
            Font regularFont = FontFactory.getFont(FontFactory.HELVETICA, 8, Color.BLACK);
            Font tableHeaderFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 7, Color.WHITE);
            Font tableBodyFont = FontFactory.getFont(FontFactory.HELVETICA, 7, Color.BLACK);

            // Title & Header
            Paragraph title = new Paragraph("Vocaboo - Individual Learner Progress & Report Card", titleFont);
            title.setAlignment(Element.ALIGN_CENTER);
            title.setSpacingAfter(3);
            document.add(title);

            Paragraph date = new Paragraph("Generated on: " + OffsetDateTime.now().format(DATE_FORMATTER), regularFont);
            date.setAlignment(Element.ALIGN_CENTER);
            date.setSpacingAfter(12);
            document.add(date);

            // Profile & Performance Summary Box
            PdfPTable profileTable = new PdfPTable(4);
            profileTable.setWidthPercentage(100);
            profileTable.setSpacingAfter(12);

            addProfileRow(profileTable, "Student Name:", detail.getDisplayName(), "Grade Level:", detail.getGradeLevel() != null ? detail.getGradeLevel() : "N/A", boldFont, regularFont);
            addProfileRow(profileTable, "Section:", detail.getSectionName() != null ? detail.getSectionName() : "Unassigned", "Account Status:", Boolean.TRUE.equals(detail.getIsActive()) ? "Active" : "Inactive", boldFont, regularFont);
            addProfileRow(profileTable, "Total Points:", String.valueOf(detail.getTotalPoints()), "Overall Accuracy:", (detail.getOverallAccuracy() != null ? detail.getOverallAccuracy().setScale(1, RoundingMode.HALF_UP) : "0.0") + "%", boldFont, regularFont);
            addProfileRow(profileTable, "Words Mastered:", String.valueOf(detail.getWordsMasteredCount()), "Mastery Tier:", detail.getMasteryLevel() != null ? detail.getMasteryLevel() : "EXPLORER", boldFont, regularFont);

            String retentionScoreStr = (detail.getAvgCumulativeScore() != null && detail.getAvgCumulativeScore().compareTo(BigDecimal.ZERO) > 0)
                    ? detail.getAvgCumulativeScore().setScale(1, RoundingMode.HALF_UP) + "%"
                    : "—";
            String bestBadgeStr = detail.getBestCumulativeBadge() != null ? detail.getBestCumulativeBadge() : "—";
            addProfileRow(profileTable, "Retention Score:", retentionScoreStr, "Best Review Badge:", bestBadgeStr, boldFont, regularFont);

            document.add(profileTable);

            // Struggling Status Alert if present
            if (Boolean.TRUE.equals(detail.getIsStruggling())) {
                Paragraph alertHeader = new Paragraph("⚠️ Learning Attention Needed", sectionTitleFont);
                alertHeader.setSpacingAfter(3);
                document.add(alertHeader);

                for (String reason : detail.getStrugglingReasons()) {
                    Paragraph p = new Paragraph("• " + reason, regularFont);
                    document.add(p);
                }
                document.add(new Paragraph(" ", regularFont));
            }

            // 1. Lesson Progress & Module Breakdown
            Paragraph lessonHeader = new Paragraph("Curriculum Lesson Progress & Module Scores", sectionTitleFont);
            lessonHeader.setSpacingAfter(6);
            document.add(lessonHeader);

            PdfPTable lessonTable = new PdfPTable(9);
            lessonTable.setWidthPercentage(100);
            lessonTable.setWidths(new float[]{3.2f, 1.2f, 1.6f, 1.5f, 1.2f, 1.2f, 1.2f, 1.2f, 1.8f});
            lessonTable.setSpacingAfter(12);

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

                String m1Str = l.getModule1Score() != null ? l.getModule1Score().setScale(0, RoundingMode.HALF_UP) + "%" : (isCompleted || l.getModule2Score() != null ? "100%" : "—");
                String m2Str = l.getModule2Score() != null ? l.getModule2Score().setScale(0, RoundingMode.HALF_UP) + "%" : "—";
                String m3Str = l.getModule3Score() != null ? l.getModule3Score().setScale(0, RoundingMode.HALF_UP) + "%" : "—";
                String m4Str = l.getModule4Score() != null ? l.getModule4Score().setScale(0, RoundingMode.HALF_UP) + "%" : (isCompleted && l.getMasteryScore() != null ? l.getMasteryScore().setScale(0, RoundingMode.HALF_UP) + "%" : "—");

                lessonTable.addCell(createCell(l.getLessonTitle(), tableBodyFont, bg, Element.ALIGN_LEFT));
                lessonTable.addCell(createCell(l.getGradeLevel(), tableBodyFont, bg, Element.ALIGN_CENTER));
                lessonTable.addCell(createCell(l.getStatus(), tableBodyFont, bg, Element.ALIGN_CENTER));
                lessonTable.addCell(createCell(l.getMasteryScore() != null ? l.getMasteryScore().setScale(0, RoundingMode.HALF_UP) + "%" : "—", tableBodyFont, bg, Element.ALIGN_CENTER));
                lessonTable.addCell(createCell(m1Str, tableBodyFont, bg, Element.ALIGN_CENTER));
                lessonTable.addCell(createCell(m2Str, tableBodyFont, bg, Element.ALIGN_CENTER));
                lessonTable.addCell(createCell(m3Str, tableBodyFont, bg, Element.ALIGN_CENTER));
                lessonTable.addCell(createCell(m4Str, tableBodyFont, bg, Element.ALIGN_CENTER));
                lessonTable.addCell(createCell(l.getCompletedAt() != null ? l.getCompletedAt().format(DateTimeFormatter.ofPattern("yyyy-MM-dd")) : "—", tableBodyFont, bg, Element.ALIGN_CENTER));
                alt = !alt;
            }
            document.add(lessonTable);

            // 2. Cumulative Review & Retention Performance Section
            if (detail.getCumulativeReviews() != null && !detail.getCumulativeReviews().isEmpty()) {
                Paragraph cumHeader = new Paragraph("Cumulative Review & Retention Performance (" + detail.getCumulativeReviews().size() + " completed)", sectionTitleFont);
                cumHeader.setSpacingAfter(6);
                document.add(cumHeader);

                PdfPTable cumTable = new PdfPTable(6);
                cumTable.setWidthPercentage(100);
                cumTable.setWidths(new float[]{4.0f, 2.0f, 2.5f, 1.8f, 2.0f, 2.5f});
                cumTable.setSpacingAfter(12);

                String[] cHeaders = {"Category / Lesson Pair", "Accuracy", "Badge Earned", "Points", "Questions", "Date Completed"};
                for (String h : cHeaders) {
                    PdfPCell cell = new PdfPCell(new Phrase(h, tableHeaderFont));
                    cell.setBackgroundColor(new Color(245, 158, 11));
                    cell.setHorizontalAlignment(Element.ALIGN_CENTER);
                    cell.setPadding(4);
                    cumTable.addCell(cell);
                }

                alt = false;
                for (AdminLearnerDetailResponse.CumulativeReviewPerformanceDetail cr : detail.getCumulativeReviews()) {
                    Color bg = alt ? new Color(255, 251, 235) : Color.WHITE;
                    cumTable.addCell(createCell(cr.getLessonPairId() != null ? cr.getLessonPairId() : "Category Review", tableBodyFont, bg, Element.ALIGN_LEFT));
                    cumTable.addCell(createCell(cr.getAccuracyPercent() != null ? cr.getAccuracyPercent().setScale(1, RoundingMode.HALF_UP) + "%" : "—", tableBodyFont, bg, Element.ALIGN_CENTER));
                    cumTable.addCell(createCell(cr.getBadgeAwarded() != null ? cr.getBadgeAwarded() : "BRONZE", tableBodyFont, bg, Element.ALIGN_CENTER));
                    cumTable.addCell(createCell(String.valueOf(cr.getPointsEarned() != null ? cr.getPointsEarned() : 0), tableBodyFont, bg, Element.ALIGN_CENTER));

                    String qStr = (cr.getCorrectCount() != null && cr.getTotalAttempts() != null)
                            ? cr.getCorrectCount() + "/" + cr.getTotalAttempts()
                            : (cr.getTotalAttempts() != null ? String.valueOf(cr.getTotalAttempts()) : "—");
                    cumTable.addCell(createCell(qStr, tableBodyFont, bg, Element.ALIGN_CENTER));
                    cumTable.addCell(createCell(cr.getCompletedAt() != null ? cr.getCompletedAt().format(DateTimeFormatter.ofPattern("yyyy-MM-dd")) : "—", tableBodyFont, bg, Element.ALIGN_CENTER));
                    alt = !alt;
                }
                document.add(cumTable);
            }

            // 3. Words to Practice & Reinforce
            if (detail.getWeakWords() != null && !detail.getWeakWords().isEmpty()) {
                Paragraph weakHeader = new Paragraph("Words to Practice & Reinforce", sectionTitleFont);
                weakHeader.setSpacingAfter(6);
                document.add(weakHeader);

                PdfPTable weakTable = new PdfPTable(5);
                weakTable.setWidthPercentage(100);
                weakTable.setWidths(new float[]{3.0f, 3.5f, 3.5f, 2.0f, 2.5f});

                String[] wHeaders = {"English Word", "Cebuano Meaning", "Lesson Source", "Accuracy", "Practice Status"};
                for (String h : wHeaders) {
                    PdfPCell cell = new PdfPCell(new Phrase(h, tableHeaderFont));
                    cell.setBackgroundColor(new Color(239, 68, 68));
                    cell.setHorizontalAlignment(Element.ALIGN_CENTER);
                    cell.setPadding(4);
                    weakTable.addCell(cell);
                }

                alt = false;
                for (LearnerWordPerformanceDetail w : detail.getWeakWords()) {
                    Color bg = alt ? new Color(255, 245, 245) : Color.WHITE;
                    double acc = w.getAccuracy() != null ? w.getAccuracy().doubleValue() : 0.0;
                    String status = acc < 50.0 ? "Needs Review" : (acc < 75.0 ? "In Progress" : "Nearly Mastered");

                    weakTable.addCell(createCell(w.getEnglishWord(), tableBodyFont, bg, Element.ALIGN_LEFT));
                    weakTable.addCell(createCell(w.getCebuanoMeaning(), tableBodyFont, bg, Element.ALIGN_LEFT));
                    weakTable.addCell(createCell(w.getLessonTitle(), tableBodyFont, bg, Element.ALIGN_LEFT));
                    weakTable.addCell(createCell((w.getAccuracy() != null ? w.getAccuracy().setScale(1, RoundingMode.HALF_UP) : "0.0") + "%", tableBodyFont, bg, Element.ALIGN_CENTER));
                    weakTable.addCell(createCell(status, tableBodyFont, bg, Element.ALIGN_CENTER));
                    alt = !alt;
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
        AdminLearnerDetailResponse detail = adminLearnerService.getLearnerDetail(learnerId);

        StringWriter sw = new StringWriter();
        try (CSVWriter writer = new CSVWriter(sw)) {
            // Profile Summary
            writer.writeNext(new String[]{"STUDENT PROFILE & PERFORMANCE REPORT CARD"});
            writer.writeNext(new String[]{"Learner ID", detail.getLearnerId().toString()});
            writer.writeNext(new String[]{"Display Name", detail.getDisplayName()});
            writer.writeNext(new String[]{"Grade Level", detail.getGradeLevel() != null ? detail.getGradeLevel() : "N/A"});
            writer.writeNext(new String[]{"Section", detail.getSectionName() != null ? detail.getSectionName() : "Unassigned"});
            writer.writeNext(new String[]{"Account Status", Boolean.TRUE.equals(detail.getIsActive()) ? "Active" : "Inactive"});
            writer.writeNext(new String[]{"Overall Accuracy", (detail.getOverallAccuracy() != null ? detail.getOverallAccuracy().toString() : "0") + "%"});
            writer.writeNext(new String[]{"Total Points", String.valueOf(detail.getTotalPoints())});
            writer.writeNext(new String[]{"Words Mastered", String.valueOf(detail.getWordsMasteredCount())});
            writer.writeNext(new String[]{"Retention Score", (detail.getAvgCumulativeScore() != null ? detail.getAvgCumulativeScore().toString() : "0") + "%"});
            writer.writeNext(new String[]{"Best Review Badge", detail.getBestCumulativeBadge() != null ? detail.getBestCumulativeBadge() : "N/A"});
            writer.writeNext(new String[]{""});

            // Lesson Progress
            writer.writeNext(new String[]{"LESSON PROGRESS & MODULE SCORES"});
            writer.writeNext(new String[]{"Lesson Title", "Grade Level", "Status", "Mastery Score (%)", "M1 (Intro)", "M2 (Practice)", "M3 (Sentence)", "M4 (Test)", "Completed At"});
            for (LearnerLessonProgressDetail l : detail.getLessons()) {
                boolean isCompleted = "COMPLETED".equalsIgnoreCase(l.getStatus());
                String m1Str = l.getModule1Score() != null ? l.getModule1Score().toString() + "%" : (isCompleted || l.getModule2Score() != null ? "100%" : "");
                String m2Str = l.getModule2Score() != null ? l.getModule2Score().toString() + "%" : "";
                String m3Str = l.getModule3Score() != null ? l.getModule3Score().toString() + "%" : "";
                String m4Str = l.getModule4Score() != null ? l.getModule4Score().toString() + "%" : (isCompleted && l.getMasteryScore() != null ? l.getMasteryScore().toString() + "%" : "");

                writer.writeNext(new String[]{
                        l.getLessonTitle(),
                        l.getGradeLevel(),
                        l.getStatus(),
                        l.getMasteryScore() != null ? l.getMasteryScore().toString() : "",
                        m1Str,
                        m2Str,
                        m3Str,
                        m4Str,
                        l.getCompletedAt() != null ? l.getCompletedAt().format(DATE_FORMATTER) : ""
                });
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
            writer.writeNext(new String[]{"English Word", "Cebuano Meaning", "Lesson Source", "Accuracy (%)", "Correct", "Incorrect", "Demerit Points", "Fallback Count"});
            for (LearnerWordPerformanceDetail w : detail.getWeakWords()) {
                writer.writeNext(new String[]{
                        w.getEnglishWord(),
                        w.getCebuanoMeaning(),
                        w.getLessonTitle(),
                        w.getAccuracy() != null ? w.getAccuracy().toString() : "0.00",
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
        List<WordPerformance> performances = getWordPerformances(sectionId, lessonId);

        StringWriter sw = new StringWriter();
        try (CSVWriter writer = new CSVWriter(sw)) {
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
                    "Accuracy (%)",
                    "Demerit Points",
                    "Tier Drops",
                    "Fallback Count",
                    "Last Practiced"
            });

            for (WordPerformance wp : performances) {
                VocabularyWord word = wp.getWord();
                writer.writeNext(new String[]{
                        word.getWordId() != null ? word.getWordId().toString() : "",
                        word.getEnglishWord() != null ? word.getEnglishWord() : "",
                        word.getCebuanoMeaning() != null ? word.getCebuanoMeaning() : "",
                        word.getLesson() != null ? word.getLesson().getLessonTitle() : "",
                        word.getGradeLevel() != null ? word.getGradeLevel().name() : "",
                        wp.getLearner() != null ? wp.getLearner().getDisplayName() : "",
                        String.valueOf(wp.getTotalAttempts() != null ? wp.getTotalAttempts() : 0),
                        String.valueOf(wp.getCorrectCount() != null ? wp.getCorrectCount() : 0),
                        String.valueOf(wp.getIncorrectCount() != null ? wp.getIncorrectCount() : 0),
                        wp.getAccuracy() != null ? wp.getAccuracy().setScale(2, RoundingMode.HALF_UP).toString() : "0.00",
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
        List<WordPerformance> performances = getWordPerformances(sectionId, lessonId);

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

            Paragraph title = new Paragraph("Vocaboo - Curriculum & Word Performance Report", titleFont);
            title.setAlignment(Element.ALIGN_CENTER);
            title.setSpacingAfter(4);
            document.add(title);

            Paragraph meta = new Paragraph("Generated on: " + OffsetDateTime.now().format(DATE_FORMATTER) +
                    " | Total Words Evaluated: " + byWord.size(), subTitleFont);
            meta.setAlignment(Element.ALIGN_CENTER);
            meta.setSpacingAfter(15);
            document.add(meta);

            PdfPTable table = new PdfPTable(8);
            table.setWidthPercentage(100);
            table.setWidths(new float[]{3.0f, 3.0f, 3.5f, 1.8f, 1.8f, 1.8f, 1.8f, 1.8f});

            String[] headers = {"English Word", "Cebuano Meaning", "Lesson Title", "Attempts", "Accuracy", "Demerits", "Tier Drops", "Fallbacks"};
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

                double avgAcc = totalAttempts > 0 ? (totalCorrect * 100.0 / totalAttempts) : 0.0;

                Color bgColor = alternate ? new Color(245, 245, 250) : Color.WHITE;

                table.addCell(createCell(word.getEnglishWord(), tableBodyFont, bgColor, Element.ALIGN_LEFT));
                table.addCell(createCell(word.getCebuanoMeaning(), tableBodyFont, bgColor, Element.ALIGN_LEFT));
                table.addCell(createCell(word.getLesson() != null ? word.getLesson().getLessonTitle() : "—", tableBodyFont, bgColor, Element.ALIGN_LEFT));
                table.addCell(createCell(String.valueOf(totalAttempts), tableBodyFont, bgColor, Element.ALIGN_CENTER));
                table.addCell(createCell(BigDecimal.valueOf(avgAcc).setScale(1, RoundingMode.HALF_UP) + "%", tableBodyFont, bgColor, Element.ALIGN_CENTER));
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

    private List<WordPerformance> getWordPerformances(UUID sectionId, UUID lessonId) {
        if (sectionId != null && lessonId != null) {
            return wordPerformanceRepository.findByLearnerSectionSectionIdAndWordLessonLessonId(sectionId, lessonId);
        } else if (sectionId != null) {
            return wordPerformanceRepository.findByLearnerSectionSectionId(sectionId);
        } else if (lessonId != null) {
            return wordPerformanceRepository.findByWordLessonLessonId(lessonId);
        } else {
            return wordPerformanceRepository.findAll();
        }
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
