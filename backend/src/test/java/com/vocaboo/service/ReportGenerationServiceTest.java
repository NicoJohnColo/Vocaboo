package com.vocaboo.service;

import com.vocaboo.dto.response.AdminLearnerDetailResponse;
import com.vocaboo.dto.response.AdminLearnerSummaryResponse;
import com.vocaboo.entity.GradeLevel;
import com.vocaboo.entity.Lesson;
import com.vocaboo.entity.VocabularyWord;
import com.vocaboo.entity.WordPerformance;
import com.vocaboo.repository.VocabularyWordRepository;
import com.vocaboo.repository.WordPerformanceRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ReportGenerationServiceTest {

    @Mock
    private AdminLearnerService adminLearnerService;
    @Mock
    private WordPerformanceRepository wordPerformanceRepository;
    @Mock
    private VocabularyWordRepository vocabularyWordRepository;

    @InjectMocks
    private ReportGenerationService reportService;

    private AdminLearnerSummaryResponse summaryResponse;
    private AdminLearnerDetailResponse detailResponse;

    @BeforeEach
    void setUp() {
        UUID learnerId = UUID.randomUUID();

        summaryResponse = AdminLearnerSummaryResponse.builder()
                .learnerId(learnerId)
                .displayName("Carlos")
                .gradeLevel("GRADE_3_4")
                .sectionName("Sampaguita")
                .languagePreference("CEBUANO")
                .isActive(true)
                .completedLessonsCount(3)
                .wordsMasteredCount(15)
                .totalPoints(1200)
                .overallAccuracy(BigDecimal.valueOf(88.50))
                .isStruggling(false)
                .lastActiveAt(OffsetDateTime.now())
                .build();

        detailResponse = AdminLearnerDetailResponse.builder()
                .learnerId(learnerId)
                .displayName("Carlos")
                .gradeLevel("GRADE_3_4")
                .sectionName("Sampaguita")
                .totalPoints(1200)
                .overallAccuracy(BigDecimal.valueOf(88.50))
                .wordsMasteredCount(15)
                .masteryLevel("PROFICIENT")
                .isActive(true)
                .lessons(List.of(
                        AdminLearnerDetailResponse.LearnerLessonProgressDetail.builder()
                                .lessonId(UUID.randomUUID())
                                .lessonTitle("School Objects")
                                .gradeLevel("GRADE_3_4")
                                .status("COMPLETED")
                                .masteryScore(BigDecimal.valueOf(90.0))
                                .completedAt(OffsetDateTime.now())
                                .build()
                ))
                .weakWords(List.of(
                        AdminLearnerDetailResponse.LearnerWordPerformanceDetail.builder()
                                .wordId(UUID.randomUUID())
                                .englishWord("Eraser")
                                .cebuanoMeaning("Pangpapas")
                                .lessonTitle("School Objects")
                                .accuracy(BigDecimal.valueOf(60.0))
                                .correctCount(3)
                                .incorrectCount(2)
                                .demeritPoints(2)
                                .build()
                ))
                .build();
    }

    @Test
    void generateClassReportCsv_producesValidCsvFormat() {
        when(adminLearnerService.getAllLearnersSummary(null, null)).thenReturn(List.of(summaryResponse));

        byte[] csvBytes = reportService.generateClassReportCsv(null, null);

        assertNotNull(csvBytes);
        assertTrue(csvBytes.length > 0);
        String csvContent = new String(csvBytes, StandardCharsets.UTF_8);
        assertTrue(csvContent.contains("Learner ID"));
        assertTrue(csvContent.contains("Carlos"));
        assertTrue(csvContent.contains("Sampaguita"));
    }

    @Test
    void generateClassReportPdf_producesValidPdfHeader() {
        when(adminLearnerService.getAllLearnersSummary(null, null)).thenReturn(List.of(summaryResponse));

        byte[] pdfBytes = reportService.generateClassReportPdf(null, null);

        assertNotNull(pdfBytes);
        assertTrue(pdfBytes.length > 0);
        String pdfHeader = new String(pdfBytes, 0, Math.min(pdfBytes.length, 5), StandardCharsets.US_ASCII);
        assertEquals("%PDF-", pdfHeader);
    }

    @Test
    void generateIndividualReportPdf_producesValidPdfHeader() {
        UUID learnerId = detailResponse.getLearnerId();
        when(adminLearnerService.getLearnerDetail(learnerId)).thenReturn(detailResponse);

        byte[] pdfBytes = reportService.generateIndividualReportPdf(learnerId);

        assertNotNull(pdfBytes);
        assertTrue(pdfBytes.length > 0);
        String pdfHeader = new String(pdfBytes, 0, Math.min(pdfBytes.length, 5), StandardCharsets.US_ASCII);
        assertEquals("%PDF-", pdfHeader);
    }

    @Test
    void generateWordPerformanceReportCsv_producesValidCsv() {
        Lesson lesson = Lesson.builder().lessonTitle("Animals").build();
        VocabularyWord word = VocabularyWord.builder()
                .wordId(UUID.randomUUID())
                .englishWord("Bird")
                .cebuanoMeaning("Langgam")
                .lesson(lesson)
                .gradeLevel(GradeLevel.GRADE_3_4)
                .build();

        WordPerformance wp = WordPerformance.builder()
                .performanceId(UUID.randomUUID())
                .word(word)
                .totalAttempts(15)
                .correctCount(12)
                .incorrectCount(3)
                .accuracy(BigDecimal.valueOf(80.00))
                .demeritPoints(1)
                .tierDropCount(0)
                .fallbackCount(1)
                .lastPracticedAt(OffsetDateTime.now())
                .build();

        when(wordPerformanceRepository.findAll()).thenReturn(List.of(wp));

        byte[] csvBytes = reportService.generateWordPerformanceReportCsv(null, null);

        assertNotNull(csvBytes);
        assertTrue(csvBytes.length > 0);
        String csvContent = new String(csvBytes, StandardCharsets.UTF_8);
        assertTrue(csvContent.contains("Word ID"));
        assertTrue(csvContent.contains("Bird"));
        assertTrue(csvContent.contains("Langgam"));
    }
}
