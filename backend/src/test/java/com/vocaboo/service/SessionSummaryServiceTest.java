package com.vocaboo.service;

import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
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
class SessionSummaryServiceTest {

    @Mock
    private SessionSummaryRepository summaryRepository;
    @Mock
    private WordPerformanceRepository performanceRepository;
    @Mock
    private LearnerRepository learnerRepository;
    @Mock
    private LessonRepository lessonRepository;
    @Mock
    private VocabularyWordRepository wordRepository;
    @Mock
    private PracticeResultRepository resultRepository;
    @Mock
    private PointTransactionRepository pointTransactionRepository;
    @Mock
    private LearnerMasteryRepository masteryRepository;

    @InjectMocks
    private SessionSummaryService service;

    @Test
    void saveSessionSummary_PerfectGoldBonus() {
        UUID learnerId = UUID.randomUUID();
        UUID sessionId = UUID.randomUUID();
        UUID lessonId = UUID.randomUUID();

        Learner learner = Learner.builder().learnerId(learnerId).build();
        Lesson lesson = Lesson.builder().lessonId(lessonId).build();

        VocabularyWord word = VocabularyWord.builder().wordId(UUID.randomUUID()).build();
        List<VocabularyWord> words = List.of(word);

        when(learnerRepository.findById(learnerId)).thenReturn(Optional.of(learner));
        when(lessonRepository.findById(lessonId)).thenReturn(Optional.of(lesson));
        when(wordRepository.findByLessonLessonIdOrderByWordOrderAsc(lessonId)).thenReturn(words);

        // Word performance mocks
        WordPerformance performance = WordPerformance.builder()
                .correctCount(3)
                .incorrectCount(0)
                .totalAttempts(3)
                .build();
        when(performanceRepository.findByLearnerLearnerIdAndWordWordId(learnerId, word.getWordId()))
                .thenReturn(Optional.of(performance));

        // Practice results: 2 correct, 0 incorrect -> 100% accuracy
        PracticeResult r1 = PracticeResult.builder().isCorrect(true).points(10).word(word).build();
        PracticeResult r2 = PracticeResult.builder().isCorrect(true).points(10).word(word).build();
        when(resultRepository.findBySessionSessionId(sessionId)).thenReturn(List.of(r1, r2));

        // Mastery stub for cache update
        when(masteryRepository.findByLearnerLearnerId(learnerId))
                .thenReturn(Optional.of(LearnerMastery.builder().learner(learner).totalPoints(0).build()));
        when(masteryRepository.save(any(LearnerMastery.class))).thenAnswer(inv -> inv.getArgument(0));

        when(summaryRepository.save(any(SessionSummary.class))).thenAnswer(inv -> inv.getArgument(0));

        SessionSummary summary = service.saveSessionSummary(learnerId, sessionId, lessonId);

        assertNotNull(summary);
        // Base: 20pts, LESSON_COMPLETE (>=80% accuracy): +200, PERFECT_SESSION (100%, 0 incorrect): +100
        // These two bonuses now STACK as per UC-4.1. Total: 20 + 200 + 100 = 320
        assertEquals(320, summary.getPointsEarned());
        verify(summaryRepository).save(any(SessionSummary.class));
    }

    @Test
    void saveSessionSummary_PassingBonus() {
        UUID learnerId = UUID.randomUUID();
        UUID sessionId = UUID.randomUUID();
        UUID lessonId = UUID.randomUUID();

        Learner learner = Learner.builder().learnerId(learnerId).build();
        Lesson lesson = Lesson.builder().lessonId(lessonId).build();

        VocabularyWord word = VocabularyWord.builder().wordId(UUID.randomUUID()).build();
        List<VocabularyWord> words = List.of(word);

        when(learnerRepository.findById(learnerId)).thenReturn(Optional.of(learner));
        when(lessonRepository.findById(lessonId)).thenReturn(Optional.of(lesson));
        when(wordRepository.findByLessonLessonIdOrderByWordOrderAsc(lessonId)).thenReturn(words);

        WordPerformance performance = WordPerformance.builder()
                .correctCount(3)
                .incorrectCount(1)
                .totalAttempts(4)
                .build();
        when(performanceRepository.findByLearnerLearnerIdAndWordWordId(learnerId, word.getWordId()))
                .thenReturn(Optional.of(performance));

        // Practice results: 3 correct, 1 incorrect -> 75% session accuracy
        // 75% is below the 80% LESSON_COMPLETE threshold (UC-4.1), so no bonus applies.
        // Note: 70% is only the Module 4 mastery pass gate (UC-4.2) — an independent system.
        PracticeResult r1 = PracticeResult.builder().isCorrect(true).points(10).word(word).build();
        PracticeResult r2 = PracticeResult.builder().isCorrect(true).points(10).word(word).build();
        PracticeResult r3 = PracticeResult.builder().isCorrect(false).points(0).word(word).build();
        PracticeResult r4 = PracticeResult.builder().isCorrect(true).points(10).word(word).build();
        when(resultRepository.findBySessionSessionId(sessionId)).thenReturn(List.of(r1, r2, r3, r4));

        when(summaryRepository.save(any(SessionSummary.class))).thenAnswer(inv -> inv.getArgument(0));

        SessionSummary summary = service.saveSessionSummary(learnerId, sessionId, lessonId);

        assertNotNull(summary);
        // Base points: 30, no bonus (75% < 80% threshold) -> Total: 30
        assertEquals(30, summary.getPointsEarned());
    }


    @Test
    void saveSessionSummary_NoBonus() {
        UUID learnerId = UUID.randomUUID();
        UUID sessionId = UUID.randomUUID();
        UUID lessonId = UUID.randomUUID();

        Learner learner = Learner.builder().learnerId(learnerId).build();
        Lesson lesson = Lesson.builder().lessonId(lessonId).build();

        VocabularyWord word = VocabularyWord.builder().wordId(UUID.randomUUID()).build();
        List<VocabularyWord> words = List.of(word);

        when(learnerRepository.findById(learnerId)).thenReturn(Optional.of(learner));
        when(lessonRepository.findById(lessonId)).thenReturn(Optional.of(lesson));
        when(wordRepository.findByLessonLessonIdOrderByWordOrderAsc(lessonId)).thenReturn(words);

        WordPerformance performance = WordPerformance.builder()
                .correctCount(1)
                .incorrectCount(3)
                .totalAttempts(4)
                .build();
        when(performanceRepository.findByLearnerLearnerIdAndWordWordId(learnerId, word.getWordId()))
                .thenReturn(Optional.of(performance));

        // Practice results for the session: 1 correct, 2 incorrect -> 33.3% accuracy
        PracticeResult r1 = PracticeResult.builder().isCorrect(true).points(10).build();
        PracticeResult r2 = PracticeResult.builder().isCorrect(false).points(0).build();
        PracticeResult r3 = PracticeResult.builder().isCorrect(false).points(0).build();
        when(resultRepository.findBySessionSessionId(sessionId)).thenReturn(List.of(r1, r2, r3));

        when(summaryRepository.save(any(SessionSummary.class))).thenAnswer(inv -> inv.getArgument(0));

        SessionSummary summary = service.saveSessionSummary(learnerId, sessionId, lessonId);

        assertNotNull(summary);
        // Base points: 10, No bonus (< 70% accuracy) -> Total points: 10
        assertEquals(10, summary.getPointsEarned());
    }
}
