package com.vocaboo.service;

import com.vocaboo.dto.response.AdminLearnerDetailResponse;
import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AdminLearnerAccuracyTest {

    @Mock private LearnerRepository learnerRepository;
    @Mock private SectionRepository sectionRepository;
    @Mock private LearnerMasteryRepository masteryRepository;
    @Mock private LearnerLessonStatusRepository lessonStatusRepository;
    @Mock private LessonRepository lessonRepository;
    @Mock private LessonModuleScoreRepository lessonModuleScoreRepository;
    @Mock private LessonWordAccuracyRepository lessonWordAccuracyRepository;
    @Mock private DifficultyProgressRepository difficultyProgressRepository;
    @Mock private WordPerformanceRepository wordPerformanceRepository;
    @Mock private SandboxSessionRepository sandboxSessionRepository;
    @Mock private SandboxWordRepository sandboxWordRepository;
    @Mock private SandboxWordProgressRepository sandboxWordProgressRepository;
    @Mock private SandboxModuleScoreRepository sandboxModuleScoreRepository;
    @Mock private ReviewSessionRepository reviewSessionRepository;
    @Mock private ReviewItemRepository reviewItemRepository;
    @Mock private PracticeSessionRepository practiceSessionRepository;
    @Mock private PracticeResultRepository practiceResultRepository;
    @Mock private SessionSummaryRepository summaryRepository;
    @Mock private PointTransactionRepository pointTransactionRepository;
    @Mock private RewardDataRepository rewardDataRepository;
    @Mock private PronunciationAttemptRepository pronunciationAttemptRepository;
    @Mock private WordProgressRepository wordProgressRepository;
    @Mock private DiagnosticResultRepository diagnosticResultRepository;
    @Mock private IntroductionSessionRepository introductionSessionRepository;
    @Mock private CumulativeReviewSessionRepository cumulativeReviewSessionRepository;
    @Mock private AdminAuditLogRepository auditLogRepository;
    @Mock private com.vocaboo.repository.ClassEnrollmentRepository classEnrollmentRepository;
    @Mock private com.vocaboo.repository.ClassPerformanceRepository classPerformanceRepository;
    @Mock private com.vocaboo.repository.ClassroomRepository classroomRepository;
    @Mock private LearnerService learnerService;

    @InjectMocks
    private AdminLearnerService adminLearnerService;

    private UUID learnerId;
    private Learner learner;
    private Lesson lesson1;
    private VocabularyWord fishWord;

    @BeforeEach
    void setUp() {
        learnerId = UUID.randomUUID();
        learner = Learner.builder()
                .learnerId(learnerId)
                .displayName("Nico")
                .build();

        lesson1 = Lesson.builder()
                .lessonId(UUID.randomUUID())
                .lessonTitle("Animals")
                .lessonOrder(1)
                .build();

        fishWord = VocabularyWord.builder()
                .wordId(UUID.randomUUID())
                .englishWord("Fish")
                .cebuanoMeaning("Isda")
                .partOfSpeech("NOUN")
                .lesson(lesson1)
                .build();
    }

    @Test
    void testPerWordDiagnosticCalculatesRealAccuracyInsteadOfStuck100() {
        when(learnerRepository.findById(learnerId)).thenReturn(Optional.of(learner));
        when(masteryRepository.findByLearnerLearnerId(learnerId)).thenReturn(Optional.empty());
        when(lessonStatusRepository.findByLearnerLearnerId(learnerId)).thenReturn(List.of());
        when(lessonModuleScoreRepository.findByLearnerLearnerId(learnerId)).thenReturn(List.of());
        when(classEnrollmentRepository.findByLearnerLearnerIdAndStatus(learnerId, "ACTIVE")).thenReturn(List.of());
        when(lessonRepository.findByIsDeletedFalseAndClassroomIsNullOrderByLessonOrderAsc()).thenReturn(List.of(lesson1));

        // Word performance has 5 attempts, 4 correct (80%), but accuracy was locked at 100% in DB
        WordPerformance wp = WordPerformance.builder()
                .learner(learner)
                .word(fishWord)
                .totalAttempts(5)
                .correctCount(4)
                .incorrectCount(1)
                .demeritPoints(2)
                .accuracy(BigDecimal.valueOf(100.00)) // corrupted/stuck
                .build();

        when(wordPerformanceRepository.findByLearnerLearnerId(learnerId)).thenReturn(new ArrayList<>(List.of(wp)));

        // In practice results: 4 correct, 1 incorrect in the session
        PracticeSession session = PracticeSession.builder()
                .sessionId(UUID.randomUUID())
                .learner(learner)
                .lesson(lesson1)
                .build();

        List<PracticeResult> prList = List.of(
                PracticeResult.builder().session(session).word(fishWord).isCorrect(true).build(),
                PracticeResult.builder().session(session).word(fishWord).isCorrect(true).build(),
                PracticeResult.builder().session(session).word(fishWord).isCorrect(true).build(),
                PracticeResult.builder().session(session).word(fishWord).isCorrect(true).build(),
                PracticeResult.builder().session(session).word(fishWord).isCorrect(false).build()
        );
        when(practiceResultRepository.findBySessionLearnerLearnerId(learnerId)).thenReturn(prList);

        AdminLearnerDetailResponse detail = adminLearnerService.getLearnerDetail(learnerId, null, null);

        assertNotNull(detail);
        assertEquals(1, detail.getAllWords().size());
        AdminLearnerDetailResponse.LearnerWordPerformanceDetail wordDetail = detail.getAllWords().get(0);

        // Lesson best accuracy must be 80.00%, NOT 100.00%!
        assertEquals(BigDecimal.valueOf(80.0).setScale(2), wordDetail.getLessonAccuracy());
        assertEquals(BigDecimal.valueOf(80.0).setScale(2), wordDetail.getLifetimeAccuracy());

        // And wordPerformanceRepository.save should have been invoked to self-heal the DB record
        verify(wordPerformanceRepository, atLeastOnce()).save(any(WordPerformance.class));
    }

    @Test
    void testResetLearnerProgressFullWipeDelegatesToLearnerService() {
        when(learnerRepository.findById(learnerId)).thenReturn(Optional.of(learner));
        UUID adminId = UUID.randomUUID();

        adminLearnerService.resetLearnerProgress(learnerId, null, adminId);

        verify(learnerService, times(1)).resetProgress(learnerId);
        verify(auditLogRepository, times(1)).save(any(AdminAuditLog.class));
    }
}
