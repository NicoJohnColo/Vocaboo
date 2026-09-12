package com.vocaboo.service;

import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class LearnerServiceResetProgressTest {

    @Mock private LearnerRepository learnerRepository;
    @Mock private org.springframework.security.crypto.password.PasswordEncoder passwordEncoder;
    @Mock private com.vocaboo.security.JwtUtils jwtUtils;
    @Mock private LearnerLessonStatusRepository lessonStatusRepository;
    @Mock private PronunciationAttemptRepository pronunciationAttemptRepository;
    @Mock private WordProgressRepository wordProgressRepository;
    @Mock private DiagnosticResultRepository diagnosticResultRepository;
    @Mock private IntroductionSessionRepository introductionSessionRepository;
    @Mock private ReviewSessionRepository reviewSessionRepository;
    @Mock private ReviewItemRepository reviewItemRepository;
    @Mock private SandboxSessionRepository sandboxSessionRepository;
    @Mock private SandboxWordRepository sandboxWordRepository;
    @Mock private SandboxWordProgressRepository sandboxWordProgressRepository;
    @Mock private SessionSummaryRepository summaryRepository;
    @Mock private PracticeResultRepository practiceResultRepository;
    @Mock private PracticeSessionRepository practiceSessionRepository;
    @Mock private WordPerformanceRepository performanceRepository;
    @Mock private LearnerMasteryRepository masteryRepository;
    @Mock private DifficultyProgressRepository difficultyProgressRepository;
    @Mock private PointTransactionRepository pointTransactionRepository;
    @Mock private RewardDataRepository rewardDataRepository;
    @Mock private LessonModuleScoreRepository lessonModuleScoreRepository;
    @Mock private SandboxModuleScoreRepository sandboxModuleScoreRepository;
    @Mock private ClassPerformanceRepository classPerformanceRepository;
    @Mock private CumulativeReviewSessionRepository cumulativeReviewSessionRepository;
    @Mock private CumulativeReviewResultRepository cumulativeReviewResultRepository;
    @Mock private LessonWordAccuracyRepository lessonWordAccuracyRepository;
    @Mock private ReinforcementQueueRepository reinforcementQueueRepository;
    @Mock private WrongAnswerRecordRepository wrongAnswerRecordRepository;
    @Mock private DifficultyAuditLogRepository difficultyAuditLogRepository;

    @InjectMocks
    private LearnerService learnerService;

    private UUID learnerId;
    private Learner learner;
    private LearnerMastery mastery;
    private ClassPerformance classPerformance;
    private CumulativeReviewSession cumulativeSession;

    @BeforeEach
    void setUp() {
        learnerId = UUID.randomUUID();
        learner = Learner.builder().learnerId(learnerId).displayName("Test Learner").build();

        mastery = LearnerMastery.builder()
                .masteryId(UUID.randomUUID())
                .learner(learner)
                .totalPoints(500)
                .totalCorrectAnswers(40)
                .totalQuestionsAnswered(50)
                .overallAccuracy(BigDecimal.valueOf(80.00))
                .wordsMasteredCount(5)
                .masteryLevel("PROFICIENT")
                .build();

        classPerformance = ClassPerformance.builder()
                .classPerformanceId(UUID.randomUUID())
                .learner(learner)
                .classPoints(571)
                .classAccuracy(BigDecimal.valueOf(89.40))
                .classTotalQuestions(102)
                .classCorrectAnswers(91)
                .classSessionsPlayed(4)
                .classMasteryLevel("PROFICIENT")
                .build();

        cumulativeSession = CumulativeReviewSession.builder()
                .id(UUID.randomUUID())
                .learner(learner)
                .pointsEarned(100)
                .build();
    }

    @Test
    void testResetProgressComprehensivelyClearsAllData() {
        when(sandboxSessionRepository.findByLearnerLearnerIdOrderByCreatedAtDesc(learnerId)).thenReturn(Collections.emptyList());
        when(reviewSessionRepository.findByLearnerLearnerId(learnerId)).thenReturn(Collections.emptyList());
        when(practiceSessionRepository.findByLearnerLearnerId(learnerId)).thenReturn(Collections.emptyList());
        when(cumulativeReviewSessionRepository.findByLearnerLearnerIdOrderByStartTimeDesc(learnerId))
                .thenReturn(List.of(cumulativeSession));
        when(classPerformanceRepository.findByLearnerLearnerId(learnerId))
                .thenReturn(List.of(classPerformance));
        when(masteryRepository.findByLearnerLearnerId(learnerId)).thenReturn(Optional.of(mastery));

        learnerService.resetProgress(learnerId);

        // 1. Verify cumulative review results and sessions are wiped
        verify(cumulativeReviewResultRepository, times(1)).deleteBySessionId(cumulativeSession.getId());
        verify(cumulativeReviewSessionRepository, times(1)).deleteByLearnerLearnerId(learnerId);

        // 2. Verify lesson word accuracy, error queues, and logs are deleted
        verify(lessonWordAccuracyRepository, times(1)).deleteByLearnerLearnerId(learnerId);
        verify(reinforcementQueueRepository, times(1)).deleteByLearnerLearnerId(learnerId);
        verify(wrongAnswerRecordRepository, times(1)).deleteByLearnerLearnerId(learnerId);
        verify(difficultyAuditLogRepository, times(1)).deleteByLearnerLearnerId(learnerId);

        // 3. Verify points and mastery transactions are deleted
        verify(pointTransactionRepository, times(1)).deleteByLearnerLearnerId(learnerId);
        verify(lessonStatusRepository, times(1)).deleteByLearnerLearnerId(learnerId);
        verify(lessonModuleScoreRepository, times(1)).deleteByLearnerLearnerId(learnerId);

        // 4. Verify class performance is re-zeroed
        assertEquals(0, classPerformance.getClassPoints());
        assertEquals(0, classPerformance.getClassTotalQuestions());
        assertEquals(0, classPerformance.getClassCorrectAnswers());
        assertEquals(0, classPerformance.getClassSessionsPlayed());
        assertEquals(BigDecimal.ZERO, classPerformance.getClassAccuracy());
        assertEquals("LEARNING", classPerformance.getClassMasteryLevel());
        verify(classPerformanceRepository, times(1)).save(classPerformance);

        // 5. Verify LearnerMastery is re-zeroed
        assertEquals(0, mastery.getTotalPoints());
        assertEquals(0, mastery.getTotalCorrectAnswers());
        assertEquals(0, mastery.getTotalQuestionsAnswered());
        assertEquals(BigDecimal.ZERO, mastery.getOverallAccuracy());
        assertEquals(0, mastery.getWordsMasteredCount());
        assertEquals("LEARNING", mastery.getMasteryLevel());
        verify(masteryRepository, times(1)).save(mastery);
    }
}
