package com.vocaboo.service;

import com.vocaboo.dto.response.WordMasterySummaryResponse;
import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class DifficultyAdjustmentServiceTest {

    @Mock
    private DifficultyProgressRepository progressRepository;
    @Mock
    private DifficultyAuditLogRepository auditLogRepository;
    @Mock
    private LearnerRepository learnerRepository;
    @Mock
    private VocabularyWordRepository wordRepository;
    @Mock
    private PointTransactionRepository pointTransactionRepository;
    @Mock
    private LearnerMasteryRepository masteryRepository;
    @Mock
    private WordPerformanceRepository wordPerformanceRepository;
    @Mock
    private PracticeResultRepository practiceResultRepository;
    @Mock
    private LessonWordAccuracyRepository lessonWordAccuracyRepository;
    @Mock
    private LearnerLessonStatusRepository lessonStatusRepository;
    @Mock
    private LessonModuleScoreRepository lessonModuleScoreRepository;

    @InjectMocks
    private DifficultyAdjustmentService service;

    private UUID learnerId;
    private UUID lessonId;
    private UUID sessionId;
    private UUID wordId;
    private VocabularyWord word;
    private Lesson lesson;

    @BeforeEach
    void setUp() {
        learnerId = UUID.randomUUID();
        lessonId = UUID.randomUUID();
        sessionId = UUID.randomUUID();
        wordId = UUID.randomUUID();

        lesson = Lesson.builder()
                .lessonId(lessonId)
                .lessonTitle("Test Lesson")
                .build();

        word = VocabularyWord.builder()
                .wordId(wordId)
                .lesson(lesson)
                .englishWord("apple")
                .cebuanoMeaning("mansanas")
                .build();
    }

    @Test
    void testGetWordMasterySummary_PreservesBestScoreWhileReflectingSessionErrors() {
        // Arrange: word has previous best of 100%
        LessonWordAccuracy existingBest = LessonWordAccuracy.builder()
                .bestAccuracy(BigDecimal.valueOf(100.00))
                .attempts(4)
                .build();

        when(wordRepository.findByLessonLessonIdOrderByWordOrderAsc(lessonId))
                .thenReturn(List.of(word));
        when(lessonWordAccuracyRepository.findByLearnerLearnerIdAndLessonLessonIdAndWordWordId(learnerId, lessonId, wordId))
                .thenReturn(Optional.of(existingBest));
        when(progressRepository.findByLearnerLearnerIdAndWordWordIdAndModuleNumber(learnerId, wordId, 2))
                .thenReturn(Optional.empty());
        when(wordPerformanceRepository.findByLearnerLearnerIdAndWordWordId(learnerId, wordId))
                .thenReturn(Optional.empty());

        // Session has 4 attempts: 3 correct, 1 incorrect => 75%
        PracticeResult r1 = PracticeResult.builder().word(word).isCorrect(true).build();
        PracticeResult r2 = PracticeResult.builder().word(word).isCorrect(true).build();
        PracticeResult r3 = PracticeResult.builder().word(word).isCorrect(false).build();
        PracticeResult r4 = PracticeResult.builder().word(word).isCorrect(true).build();

        when(practiceResultRepository.findBySessionSessionId(sessionId))
                .thenReturn(List.of(r1, r2, r3, r4));

        // Act
        List<WordMasterySummaryResponse> summary = service.getWordMasterySummary(learnerId, lessonId, sessionId);

        // Assert
        assertNotNull(summary);
        assertEquals(1, summary.size());
        WordMasterySummaryResponse wordSummary = summary.get(0);

        // Current session accuracy MUST reflect the 75% (NOT overwritten by 100%)
        assertEquals(BigDecimal.valueOf(75.00).setScale(2), wordSummary.getAccuracy());
        assertEquals(BigDecimal.valueOf(75.00).setScale(2), wordSummary.getCurrentAccuracy());

        // Preserved best accuracy MUST retain 100%
        assertEquals(BigDecimal.valueOf(100.00), wordSummary.getBestAccuracy());

        // Correct and total attempts for this session
        assertEquals(4, wordSummary.getTotalAttempts());
        assertEquals(3, wordSummary.getCorrectAttempts());
        assertTrue(wordSummary.getIsRetaken());
        assertFalse(wordSummary.getIsImproved());
    }

    @Test
    void testGetWordMasterySummary_FirstAttemptPerfectScore() {
        when(wordRepository.findByLessonLessonIdOrderByWordOrderAsc(lessonId))
                .thenReturn(List.of(word));
        when(lessonWordAccuracyRepository.findByLearnerLearnerIdAndLessonLessonIdAndWordWordId(learnerId, lessonId, wordId))
                .thenReturn(Optional.empty());
        when(progressRepository.findByLearnerLearnerIdAndWordWordIdAndModuleNumber(learnerId, wordId, 2))
                .thenReturn(Optional.empty());
        when(wordPerformanceRepository.findByLearnerLearnerIdAndWordWordId(learnerId, wordId))
                .thenReturn(Optional.empty());

        // Session has 2 attempts: 2 correct => 100%
        PracticeResult r1 = PracticeResult.builder().word(word).isCorrect(true).build();
        PracticeResult r2 = PracticeResult.builder().word(word).isCorrect(true).build();

        when(practiceResultRepository.findBySessionSessionId(sessionId))
                .thenReturn(List.of(r1, r2));

        // Act
        List<WordMasterySummaryResponse> summary = service.getWordMasterySummary(learnerId, lessonId, sessionId);

        // Assert
        assertEquals(1, summary.size());
        WordMasterySummaryResponse wordSummary = summary.get(0);
        assertEquals(BigDecimal.valueOf(100.00).setScale(2), wordSummary.getAccuracy());
        assertEquals(BigDecimal.valueOf(100.00).setScale(2), wordSummary.getCurrentAccuracy());
        assertEquals(BigDecimal.valueOf(100.00).setScale(2), wordSummary.getBestAccuracy());
        assertEquals(2, wordSummary.getTotalAttempts());
        assertEquals(2, wordSummary.getCorrectAttempts());
        assertFalse(wordSummary.getIsRetaken());
    }
}
