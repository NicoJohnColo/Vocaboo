package com.vocaboo.service;

import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class RetrievalActivityServiceTest {

    @Mock
    private PracticeSessionRepository sessionRepository;
    @Mock
    private ReinforcementQueueRepository queueRepository;
    @Mock
    private VocabularyWordRepository wordRepository;
    @Mock
    private DynamicQuestionGeneratorService questionGenerator;
    @Mock
    private ReinforcementEngineService reinforcementEngine;
    @Mock
    private PracticeSessionService practiceSessionService;
    @Mock
    private DifficultyAdjustmentService difficultyService;
    @Mock
    private WrongAnswerTrackingService wrongAnswerTrackingService;

    @InjectMocks
    private RetrievalActivityService service;

    @Test
    void generateSessionQuestions_constructsAllActivities() {
        UUID sessionId = UUID.randomUUID();
        UUID learnerId = UUID.randomUUID();
        UUID lessonId = UUID.randomUUID();

        Learner learner = Learner.builder().learnerId(learnerId).build();
        Lesson lesson = Lesson.builder().lessonId(lessonId).build();
        PracticeSession session = PracticeSession.builder()
                .sessionId(sessionId)
                .learner(learner)
                .lesson(lesson)
                .build();

        VocabularyWord word = VocabularyWord.builder()
                .wordId(UUID.randomUUID())
                .englishWord("apple")
                .cebuanoMeaning("saging")
                .lesson(lesson)
                .build();

        when(sessionRepository.findById(sessionId)).thenReturn(Optional.of(session));
        when(wordRepository.findByLessonLessonIdOrderByWordOrderAsc(lessonId)).thenReturn(List.of(word));
        when(queueRepository.findByLearnerLearnerIdAndIsResolvedFalseOrderByScheduledAtAsc(learnerId)).thenReturn(Collections.emptyList());
        
        Map<String, Object> question1 = new HashMap<>();
        question1.put("wordId", word.getWordId().toString());
        question1.put("activityFormat", "MULTIPLE_CHOICE");
        
        Map<String, Object> question2 = new HashMap<>();
        question2.put("wordId", word.getWordId().toString());
        question2.put("activityFormat", "FILL_IN_BLANK");

        when(questionGenerator.generateQuestion(eq(learnerId), eq(word), anyString())).thenAnswer(inv -> {
            String format = inv.getArgument(2);
            Map<String, Object> q = new HashMap<>();
            q.put("wordId", word.getWordId().toString());
            q.put("activityFormat", format);
            return q;
        });

        List<Map<String, Object>> result = service.generateSessionQuestions(sessionId);

        assertNotNull(result);
        assertEquals(2, result.size());
        assertNotNull(result.get(0).get("activityFormat"));
        assertNotNull(result.get(1).get("activityFormat"));
    }

    @Test
    void submitAnswer_invokesTrackingAndSpacedRepetition() {
        UUID sessionId = UUID.randomUUID();
        UUID wordId = UUID.randomUUID();
        UUID learnerId = UUID.randomUUID();

        Learner learner = Learner.builder().learnerId(learnerId).build();
        PracticeSession session = PracticeSession.builder()
                .sessionId(sessionId)
                .learner(learner)
                .build();

        when(sessionRepository.findById(sessionId)).thenReturn(Optional.of(session));
        when(difficultyService.getCurrentLevel(learnerId, wordId)).thenReturn(DifficultyLevel.LEARNING);
        when(difficultyService.calculateNext(eq(learnerId), eq(wordId), anyBoolean()))
                .thenReturn(com.vocaboo.dto.response.DifficultyProgressResponse.builder().currentLevel("FAMILIAR").build());

        // Submit correct answer
        Map<String, Object> res1 = service.submitAnswer(sessionId, wordId, true, null, null);

        verify(practiceSessionService).record(sessionId, wordId, true, null, null);
        verify(difficultyService).calculateNext(learnerId, wordId, true);
        verify(reinforcementEngine).resolve(learnerId, wordId);
        assertEquals(true, res1.get("leveledUp"));
        assertEquals("LEARNING", res1.get("oldLevel"));
        assertEquals("FAMILIAR", res1.get("currentLevel"));

        // Submit incorrect answer
        service.submitAnswer(sessionId, wordId, false, "pencil", "MULTIPLE_CHOICE");

        verify(practiceSessionService).record(sessionId, wordId, false, "MULTIPLE_CHOICE", null);
        verify(difficultyService).calculateNext(learnerId, wordId, false);
        verify(wrongAnswerTrackingService).trackWrongAnswer(learnerId, wordId, "pencil", "MULTIPLE_CHOICE");
    }

    @Test
    void submitAnswer_trueOrFalseStillUpdatesDifficulty() {
        UUID sessionId = UUID.randomUUID();
        UUID wordId = UUID.randomUUID();
        UUID learnerId = UUID.randomUUID();

        Learner learner = Learner.builder().learnerId(learnerId).build();
        PracticeSession session = PracticeSession.builder()
                .sessionId(sessionId)
                .learner(learner)
                .build();

        when(sessionRepository.findById(sessionId)).thenReturn(Optional.of(session));
        when(difficultyService.getCurrentLevel(learnerId, wordId)).thenReturn(DifficultyLevel.LEARNING);
        when(difficultyService.calculateNext(eq(learnerId), eq(wordId), anyBoolean()))
                .thenReturn(com.vocaboo.dto.response.DifficultyProgressResponse.builder().currentLevel("FAMILIAR").build());

        service.submitAnswer(sessionId, wordId, true, null, "TRUE_OR_FALSE");

        verify(practiceSessionService).record(sessionId, wordId, true, "TRUE_OR_FALSE", null);
        verify(difficultyService).calculateNext(learnerId, wordId, true);
        verify(reinforcementEngine).resolve(learnerId, wordId);
        verifyNoInteractions(wrongAnswerTrackingService);
    }
}
