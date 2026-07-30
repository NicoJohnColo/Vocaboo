package com.vocaboo.service;

import com.vocaboo.dto.response.LearnerProgressResponse;
import com.vocaboo.dto.response.PracticeResultResponse;
import com.vocaboo.dto.response.PracticeSessionResponse;
import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.OffsetDateTime;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class PracticeSessionServiceTest {

    @Mock
    private PracticeSessionRepository sessionRepository;
    @Mock
    private PracticeResultRepository resultRepository;
    @Mock
    private LearnerMasteryRepository masteryRepository;
    @Mock
    private WordPerformanceRepository performanceRepository;
    @Mock
    private LearnerRepository learnerRepository;
    @Mock
    private LessonRepository lessonRepository;
    @Mock
    private PointTransactionRepository pointTransactionRepository;
    @Mock
    private VocabularyWordRepository wordRepository;

    @InjectMocks
    private PracticeSessionService service;

    @Test
    void start_success() {
        UUID learnerId = UUID.randomUUID();
        UUID lessonId = UUID.randomUUID();
        int moduleNumber = 1;

        Learner learner = Learner.builder().learnerId(learnerId).displayName("Test Learner").build();
        Lesson lesson = Lesson.builder().lessonId(lessonId).lessonTitle("Lesson 1").build();
        PracticeSession session = PracticeSession.builder()
                .sessionId(UUID.randomUUID())
                .learner(learner)
                .lesson(lesson)
                .moduleNumber(moduleNumber)
                .createdAt(OffsetDateTime.now())
                .build();

        when(learnerRepository.findById(learnerId)).thenReturn(Optional.of(learner));
        when(lessonRepository.findById(lessonId)).thenReturn(Optional.of(lesson));
        when(sessionRepository.save(any(PracticeSession.class))).thenReturn(session);
        when(masteryRepository.findByLearnerLearnerId(learnerId)).thenReturn(Optional.empty());

        PracticeSessionResponse response = service.start(learnerId, lessonId, moduleNumber);

        assertNotNull(response);
        assertEquals(learnerId, response.getLearnerId());
        assertEquals(lessonId, response.getLessonId());
        assertEquals(moduleNumber, response.getModuleNumber());
        verify(masteryRepository, times(1)).save(any(LearnerMastery.class));
    }

    @Test
    void record_correctResult_updatesPerformanceAndMastery() {
        UUID sessionId = UUID.randomUUID();
        UUID wordId = UUID.randomUUID();
        UUID learnerId = UUID.randomUUID();

        Learner learner = Learner.builder().learnerId(learnerId).build();
        PracticeSession session = PracticeSession.builder().sessionId(sessionId).learner(learner).build();
        VocabularyWord word = VocabularyWord.builder().wordId(wordId).build();
        PracticeResult result = PracticeResult.builder()
                .resultId(UUID.randomUUID())
                .session(session)
                .word(word)
                .isCorrect(true)
                .points(10)
                .recordedAt(OffsetDateTime.now())
                .build();

        when(sessionRepository.findById(sessionId)).thenReturn(Optional.of(session));
        when(wordRepository.findById(wordId)).thenReturn(Optional.of(word));
        when(resultRepository.save(any(PracticeResult.class))).thenReturn(result);

        when(performanceRepository.findByLearnerLearnerIdAndWordWordId(learnerId, wordId))
                .thenReturn(Optional.empty());
        when(masteryRepository.findByLearnerLearnerId(learnerId))
                .thenReturn(Optional.empty());

        PracticeResultResponse response = service.record(sessionId, wordId, true);

        assertNotNull(response);
        assertTrue(response.getIsCorrect());
        assertEquals(10, response.getPoints());
        assertEquals(wordId, response.getWordId());
        assertEquals(sessionId, response.getSessionId());

        verify(performanceRepository, times(1)).save(argThat(performance -> 
                performance.getTotalAttempts() == 1 &&
                performance.getCorrectCount() == 1 &&
                performance.getAccuracy().compareTo(BigDecimal.valueOf(100.00)) == 0
        ));

        verify(masteryRepository, times(1)).save(argThat(mastery -> 
                mastery.getTotalQuestionsAnswered() == 1 &&
                mastery.getTotalCorrectAnswers() == 1 &&
                mastery.getOverallAccuracy().compareTo(BigDecimal.valueOf(100.00)) == 0
        ));
    }

    @Test
    void record_incorrectResult_updatesPerformanceAndMastery() {
        UUID sessionId = UUID.randomUUID();
        UUID wordId = UUID.randomUUID();
        UUID learnerId = UUID.randomUUID();

        Learner learner = Learner.builder().learnerId(learnerId).build();
        PracticeSession session = PracticeSession.builder().sessionId(sessionId).learner(learner).build();
        VocabularyWord word = VocabularyWord.builder().wordId(wordId).build();
        PracticeResult result = PracticeResult.builder()
                .resultId(UUID.randomUUID())
                .session(session)
                .word(word)
                .isCorrect(false)
                .points(0)
                .recordedAt(OffsetDateTime.now())
                .build();

        when(sessionRepository.findById(sessionId)).thenReturn(Optional.of(session));
        when(wordRepository.findById(wordId)).thenReturn(Optional.of(word));
        when(resultRepository.save(any(PracticeResult.class))).thenReturn(result);

        WordPerformance existingPerformance = WordPerformance.builder()
                .learner(learner)
                .word(word)
                .correctCount(1)
                .incorrectCount(0)
                .totalAttempts(1)
                .accuracy(BigDecimal.valueOf(100.0))
                .build();

        when(performanceRepository.findByLearnerLearnerIdAndWordWordId(learnerId, wordId))
                .thenReturn(Optional.of(existingPerformance));

        LearnerMastery existingMastery = LearnerMastery.builder()
                .learner(learner)
                .totalCorrectAnswers(3)
                .totalQuestionsAnswered(4)
                .overallAccuracy(BigDecimal.valueOf(75.0))
                .build();

        when(masteryRepository.findByLearnerLearnerId(learnerId))
                .thenReturn(Optional.of(existingMastery));

        PracticeResultResponse response = service.record(sessionId, wordId, false);

        assertNotNull(response);
        assertFalse(response.getIsCorrect());
        assertEquals(0, response.getPoints());

        verify(performanceRepository, times(1)).save(argThat(performance -> 
                performance.getTotalAttempts() == 2 &&
                performance.getCorrectCount() == 1 &&
                performance.getIncorrectCount() == 1 &&
                performance.getAccuracy().compareTo(BigDecimal.valueOf(50.00)) == 0
        ));

        verify(masteryRepository, times(1)).save(argThat(mastery -> 
                mastery.getTotalQuestionsAnswered() == 5 &&
                mastery.getTotalCorrectAnswers() == 3 &&
                mastery.getOverallAccuracy().compareTo(BigDecimal.valueOf(60.00)) == 0
        ));
    }

    @Test
    void end_calculatesScoreAndMasteredWordsCount() {
        UUID sessionId = UUID.randomUUID();
        UUID learnerId = UUID.randomUUID();

        Learner learner = Learner.builder().learnerId(learnerId).build();
        PracticeSession session = PracticeSession.builder()
                .sessionId(sessionId)
                .learner(learner)
                .lesson(Lesson.builder().lessonId(UUID.randomUUID()).build())
                .build();

        when(sessionRepository.findById(sessionId)).thenReturn(Optional.of(session));
        when(sessionRepository.save(any(PracticeSession.class))).thenAnswer(invocation -> invocation.getArgument(0));

        PracticeResult r1 = PracticeResult.builder().isCorrect(true).build();
        PracticeResult r2 = PracticeResult.builder().isCorrect(false).build();
        PracticeResult r3 = PracticeResult.builder().isCorrect(true).build();
        when(resultRepository.findBySessionSessionId(sessionId)).thenReturn(Arrays.asList(r1, r2, r3));

        LearnerMastery existingMastery = LearnerMastery.builder()
                .learner(learner)
                .totalSessionsPlayed(1)
                .build();
        when(masteryRepository.findByLearnerLearnerId(learnerId)).thenReturn(Optional.of(existingMastery));

        WordPerformance wp1 = WordPerformance.builder().totalAttempts(3).accuracy(BigDecimal.valueOf(80.0)).build(); // Mastered
        WordPerformance wp2 = WordPerformance.builder().totalAttempts(2).accuracy(BigDecimal.valueOf(90.0)).build(); // Not enough attempts
        WordPerformance wp3 = WordPerformance.builder().totalAttempts(4).accuracy(BigDecimal.valueOf(75.0)).build(); // Under accuracy
        when(performanceRepository.findByLearnerLearnerId(learnerId)).thenReturn(Arrays.asList(wp1, wp2, wp3));

        PracticeSessionResponse response = service.end(sessionId);

        assertNotNull(response);
        assertNotNull(response.getCompletedAt());
        // Score calculation: 2/3 = 66.67
        assertEquals(BigDecimal.valueOf(66.67), response.getScore());

        verify(masteryRepository, times(1)).save(argThat(mastery -> 
                mastery.getTotalSessionsPlayed() == 2 &&
                mastery.getWordsMasteredCount() == 2
        ));
    }

    @Test
    void updateMastery_recalculatesAllStats() {
        UUID learnerId = UUID.randomUUID();
        Learner learner = Learner.builder().learnerId(learnerId).build();

        when(learnerRepository.findById(learnerId)).thenReturn(Optional.of(learner));

        WordPerformance wp1 = WordPerformance.builder().correctCount(3).totalAttempts(3).accuracy(BigDecimal.valueOf(100.0)).build(); // Mastered
        WordPerformance wp2 = WordPerformance.builder().correctCount(1).totalAttempts(3).accuracy(BigDecimal.valueOf(33.33)).build(); // Attempted, under accuracy
        when(performanceRepository.findByLearnerLearnerId(learnerId)).thenReturn(Arrays.asList(wp1, wp2));

        PracticeSession s1 = PracticeSession.builder().completedAt(OffsetDateTime.now()).build();
        PracticeSession s2 = PracticeSession.builder().completedAt(null).build(); // active
        when(sessionRepository.findByLearnerLearnerId(learnerId)).thenReturn(Arrays.asList(s1, s2));

        when(masteryRepository.findByLearnerLearnerId(learnerId)).thenReturn(Optional.empty());

        service.updateMastery(learnerId);

        verify(masteryRepository, times(1)).save(argThat(mastery -> 
                mastery.getTotalQuestionsAnswered() == 6 &&
                mastery.getTotalCorrectAnswers() == 4 &&
                mastery.getOverallAccuracy().compareTo(BigDecimal.valueOf(66.67)) == 0 &&
                mastery.getWordsMasteredCount() == 1 &&
                mastery.getTotalSessionsPlayed() == 1
        ));
    }
}
