package com.vocaboo.service;

import com.vocaboo.dto.request.UpdateLearnerAdminRequest;
import com.vocaboo.dto.response.AdminLearnerSummaryResponse;
import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AdminLearnerServiceTest {

    @Mock
    private LearnerRepository learnerRepository;
    @Mock
    private SectionRepository sectionRepository;
    @Mock
    private LearnerMasteryRepository masteryRepository;
    @Mock
    private LearnerLessonStatusRepository lessonStatusRepository;
    @Mock
    private LessonRepository lessonRepository;
    @Mock
    private LessonModuleScoreRepository lessonModuleScoreRepository;
    @Mock
    private DifficultyProgressRepository difficultyProgressRepository;
    @Mock
    private WordPerformanceRepository wordPerformanceRepository;
    @Mock
    private SandboxSessionRepository sandboxSessionRepository;
    @Mock
    private SandboxWordRepository sandboxWordRepository;
    @Mock
    private SandboxWordProgressRepository sandboxWordProgressRepository;
    @Mock
    private SandboxModuleScoreRepository sandboxModuleScoreRepository;
    @Mock
    private ReviewSessionRepository reviewSessionRepository;
    @Mock
    private ReviewItemRepository reviewItemRepository;
    @Mock
    private PracticeSessionRepository practiceSessionRepository;
    @Mock
    private PracticeResultRepository practiceResultRepository;
    @Mock
    private SessionSummaryRepository summaryRepository;
    @Mock
    private PointTransactionRepository pointTransactionRepository;
    @Mock
    private RewardDataRepository rewardDataRepository;
    @Mock
    private PronunciationAttemptRepository pronunciationAttemptRepository;
    @Mock
    private WordProgressRepository wordProgressRepository;
    @Mock
    private DiagnosticResultRepository diagnosticResultRepository;
    @Mock
    private IntroductionSessionRepository introductionSessionRepository;
    @Mock
    private CumulativeReviewSessionRepository cumulativeReviewSessionRepository;
    @Mock
    private AdminAuditLogRepository auditLogRepository;

    @InjectMocks
    private AdminLearnerService adminLearnerService;

    private Learner learner;
    private Section section;
    private UUID adminId;

    @BeforeEach
    void setUp() {
        adminId = UUID.randomUUID();

        section = Section.builder()
                .sectionId(UUID.randomUUID())
                .sectionName("Grade 3 - Rose")
                .build();

        learner = Learner.builder()
                .learnerId(UUID.randomUUID())
                .displayName("Ana")
                .age(9)
                .gradeLevel(GradeLevel.GRADE_3_4)
                .section(section)
                .isActive(true)
                .build();
    }

    @Test
    void updateLearner_updatesProfileAndLogsAudit() {
        UUID learnerId = learner.getLearnerId();
        when(learnerRepository.findById(learnerId)).thenReturn(Optional.of(learner));
        when(learnerRepository.existsByDisplayNameIgnoreCaseAndLearnerIdNot("Ana Maria", learnerId)).thenReturn(false);
        when(learnerRepository.save(any(Learner.class))).thenAnswer(invocation -> invocation.getArgument(0));

        UpdateLearnerAdminRequest req = UpdateLearnerAdminRequest.builder()
                .displayName("Ana Maria")
                .age(10)
                .gradeLevel(GradeLevel.GRADE_5_6)
                .build();

        AdminLearnerSummaryResponse response = adminLearnerService.updateLearner(learnerId, req, adminId);

        assertNotNull(response);
        assertEquals("Ana Maria", response.getDisplayName());
        assertEquals(10, response.getAge());
        assertEquals(GradeLevel.GRADE_5_6.name(), response.getGradeLevel());
        verify(auditLogRepository, times(1)).save(any(AdminAuditLog.class));
    }

    @Test
    void deactivateLearner_setsIsActiveFalse() {
        UUID learnerId = learner.getLearnerId();
        when(learnerRepository.findById(learnerId)).thenReturn(Optional.of(learner));

        adminLearnerService.deactivateLearner(learnerId, adminId);

        assertFalse(learner.getIsActive());
        verify(learnerRepository).save(learner);
        verify(auditLogRepository).save(any(AdminAuditLog.class));
    }

    @Test
    void reactivateLearner_setsIsActiveTrue() {
        learner.setIsActive(false);
        UUID learnerId = learner.getLearnerId();
        when(learnerRepository.findById(learnerId)).thenReturn(Optional.of(learner));

        adminLearnerService.reactivateLearner(learnerId, adminId);

        assertTrue(learner.getIsActive());
        verify(learnerRepository).save(learner);
        verify(auditLogRepository).save(any(AdminAuditLog.class));
    }

    @Test
    void resetLearnerProgress_fullReset_clearsAllAndRecreatesMastery() {
        UUID learnerId = learner.getLearnerId();
        when(learnerRepository.findById(learnerId)).thenReturn(Optional.of(learner));

        adminLearnerService.resetLearnerProgress(learnerId, null, adminId);

        verify(sandboxSessionRepository).deleteByLearnerLearnerId(learnerId);
        verify(reviewSessionRepository).deleteByLearnerLearnerId(learnerId);
        verify(practiceSessionRepository).deleteByLearnerLearnerId(learnerId);
        verify(wordPerformanceRepository).deleteByLearnerLearnerId(learnerId);
        verify(difficultyProgressRepository).deleteByLearnerLearnerId(learnerId);
        verify(masteryRepository).deleteByLearnerLearnerId(learnerId);
        verify(masteryRepository).save(any(LearnerMastery.class));
        verify(auditLogRepository).save(any(AdminAuditLog.class));
    }

    @Test
    void resetLearnerProgress_lessonSpecific_clearsOnlyTargetLessonData() {
        UUID learnerId = learner.getLearnerId();
        UUID lessonId = UUID.randomUUID();
        Lesson lesson = Lesson.builder().lessonId(lessonId).lessonTitle("Basic Greetings").build();

        when(learnerRepository.findById(learnerId)).thenReturn(Optional.of(learner));
        when(lessonRepository.findById(lessonId)).thenReturn(Optional.of(lesson));
        when(masteryRepository.findByLearnerLearnerId(learnerId)).thenReturn(Optional.of(
                LearnerMastery.builder().learner(learner).overallAccuracy(BigDecimal.valueOf(90)).build()
        ));

        adminLearnerService.resetLearnerProgress(learnerId, lessonId, adminId);

        verify(lessonStatusRepository).deleteByLearnerLearnerIdAndLessonLessonId(learnerId, lessonId);
        verify(lessonModuleScoreRepository).deleteByLearnerLearnerIdAndLessonLessonId(learnerId, lessonId);
        verify(difficultyProgressRepository).deleteByLearnerLearnerIdAndWordLessonLessonId(learnerId, lessonId);
        verify(wordPerformanceRepository).deleteByLearnerLearnerIdAndWordLessonLessonId(learnerId, lessonId);
        verify(auditLogRepository).save(any(AdminAuditLog.class));
    }
}
