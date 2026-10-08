package com.vocaboo.service;

import com.vocaboo.dto.response.AdminLearnerDetailResponse;
import com.vocaboo.dto.response.AdminLearnerDetailResponse.LearnerLessonProgressDetail;
import com.vocaboo.dto.response.AdminLearnerDetailResponse.LearnerWordPerformanceDetail;
import com.vocaboo.dto.response.AdminLearnerDetailResponse.PosAccuracyDetail;
import com.vocaboo.dto.response.AdminLearnerDetailResponse.CumulativeReviewPerformanceDetail;
import com.vocaboo.repository.ClassEnrollmentRepository;
import com.vocaboo.repository.ClassroomRepository;
import com.vocaboo.repository.VocabularyWordRepository;
import com.vocaboo.repository.WordPerformanceRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ReportGenerationPdfTest {

    @Mock private AdminLearnerService adminLearnerService;
    @Mock private WordPerformanceRepository wordPerformanceRepository;
    @Mock private VocabularyWordRepository vocabularyWordRepository;
    @Mock private ClassEnrollmentRepository classEnrollmentRepository;
    @Mock private ClassroomRepository classroomRepository;

    @InjectMocks
    private ReportGenerationService reportGenerationService;

    private UUID learnerId;

    @BeforeEach
    void setUp() {
        learnerId = UUID.randomUUID();
    }

    @Test
    void testGenerateIndividualReportPdf_fullData() {
        AdminLearnerDetailResponse detail = AdminLearnerDetailResponse.builder()
                .learnerId(learnerId)
                .userId("STU-12345")
                .displayName("Juan Dela Cruz")
                .gradeLevel("GRADE_4")
                .sectionName("Sampaguita")
                .isActive(true)
                .masteryLevel("MASTER")
                .totalPoints(150)
                .overallAccuracy(BigDecimal.valueOf(88.5))
                .wordsMasteredCount(25)
                .isStruggling(true)
                .strugglingReasons(List.of("Low overall accuracy", "High demerits"))
                .posBreakdown(List.of(
                        PosAccuracyDetail.builder()
                                .partOfSpeech("NOUN")
                                .totalWords(10)
                                .totalAttempts(20)
                                .correctCount(18)
                                .accuracy(BigDecimal.valueOf(90.0))
                                .build()
                ))
                .lessons(List.of(
                        LearnerLessonProgressDetail.builder()
                                .lessonTitle("Lesson 1: Greetings")
                                .gradeLevel("GRADE_4")
                                .status("COMPLETED")
                                .masteryScore(BigDecimal.valueOf(95.0))
                                .module1Score(BigDecimal.valueOf(100.0))
                                .module2Score(BigDecimal.valueOf(90.0))
                                .completedAt(OffsetDateTime.now())
                                .build()
                ))
                .cumulativeReviews(List.of(
                        CumulativeReviewPerformanceDetail.builder()
                                .lessonPairId("pair-1")
                                .accuracyPercent(BigDecimal.valueOf(85.0))
                                .badgeAwarded("GOLD")
                                .pointsEarned(50)
                                .correctCount(8)
                                .totalAttempts(10)
                                .completedAt(OffsetDateTime.now())
                                .build()
                ))
                .weakWords(List.of(
                        LearnerWordPerformanceDetail.builder()
                                .englishWord("Dog")
                                .partOfSpeech("NOUN")
                                .cebuanoMeaning("Iro")
                                .lessonTitle("Animals")
                                .lessonAccuracy(BigDecimal.valueOf(60.0))
                                .lifetimeAccuracy(BigDecimal.valueOf(65.0))
                                .demeritPoints(4)
                                .build()
                ))
                .allWords(List.of())
                .build();

        when(adminLearnerService.getLearnerDetail(learnerId)).thenReturn(detail);

        byte[] pdf = reportGenerationService.generateIndividualReportPdf(learnerId);
        assertNotNull(pdf);

        byte[] csv = reportGenerationService.generateIndividualReportCsv(learnerId);
        assertNotNull(csv);
    }

    @Test
    void testGenerateIndividualReportPdf_emptyData() {
        AdminLearnerDetailResponse detail = AdminLearnerDetailResponse.builder()
                .learnerId(learnerId)
                .displayName("Empty Student")
                .build();

        when(adminLearnerService.getLearnerDetail(learnerId)).thenReturn(detail);

        byte[] pdf = reportGenerationService.generateIndividualReportPdf(learnerId);
        assertNotNull(pdf);

        byte[] csv = reportGenerationService.generateIndividualReportCsv(learnerId);
        assertNotNull(csv);
    }

    @Test
    void testGenerateClassReportPdf_fullData() {
        UUID sectionId = UUID.randomUUID();
        com.vocaboo.dto.response.AdminLearnerSummaryResponse summary = com.vocaboo.dto.response.AdminLearnerSummaryResponse.builder()
                .learnerId(learnerId)
                .userId("STU-100")
                .displayName("Maria Santos")
                .gradeLevel("GRADE_4")
                .sectionName("Section A")
                .completedLessonsCount(5)
                .wordsMasteredCount(20)
                .totalPoints(120)
                .overallAccuracy(BigDecimal.valueOf(92.5))
                .isActive(true)
                .isStruggling(false)
                .lastActiveAt(OffsetDateTime.now())
                .build();

        when(adminLearnerService.getAllLearnersSummary(sectionId, null, null)).thenReturn(List.of(summary));
        when(classroomRepository.findById(sectionId)).thenReturn(java.util.Optional.of(
                com.vocaboo.entity.Classroom.builder().classId(sectionId).name("Grade 4 - Diamond").classCode("G4-DIA").build()
        ));

        byte[] pdf = reportGenerationService.generateClassReportPdf(sectionId, null, null);
        assertNotNull(pdf);

        byte[] csv = reportGenerationService.generateClassReportCsv(sectionId, null, null);
        assertNotNull(csv);
    }

    @Test
    void testGenerateClassReportPdf_emptyData() {
        when(adminLearnerService.getAllLearnersSummary(null, null, null)).thenReturn(List.of());

        byte[] pdf = reportGenerationService.generateClassReportPdf(null, null, null);
        assertNotNull(pdf);

        byte[] csv = reportGenerationService.generateClassReportCsv(null, null, null);
        assertNotNull(csv);
    }
}

