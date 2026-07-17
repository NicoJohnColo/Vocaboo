package com.vocaboo.service;

import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;

@Service
@RequiredArgsConstructor
public class RetrievalActivityService {

    private final PracticeSessionRepository sessionRepository;
    private final ReinforcementQueueRepository queueRepository;
    private final VocabularyWordRepository wordRepository;
    private final DynamicQuestionGeneratorService questionGenerator;
    private final ReinforcementEngineService reinforcementEngine;
    private final PracticeSessionService practiceSessionService;
    private final DifficultyAdjustmentService difficultyService;
    private final WrongAnswerTrackingService wrongAnswerTrackingService;

    @Transactional(readOnly = true)
    public List<Map<String, Object>> generateSessionQuestions(UUID sessionId) {
        PracticeSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new IllegalArgumentException("Session not found"));

        UUID learnerId = session.getLearner().getLearnerId();
        UUID lessonId = session.getLesson().getLessonId();

        // 1. Fetch all words in the lesson
        List<VocabularyWord> lessonWords = wordRepository.findByLessonLessonIdOrderByWordOrderAsc(lessonId);

        // 2. Fetch active reinforcement items for this learner
        List<ReinforcementQueueItem> reinforcementItems = queueRepository
                .findByLearnerLearnerIdAndIsResolvedFalseOrderByScheduledAtAsc(learnerId);

        List<Map<String, Object>> questionsList = new ArrayList<>();

        // 3. Generate questions for lesson words (2 exercises per word in different formats)
        for (int i = 0; i < lessonWords.size(); i++) {
            VocabularyWord word = lessonWords.get(i);
            
            String f1 = selectFormat(i, 0);
            questionsList.add(questionGenerator.generateQuestion(learnerId, word, f1));

            String f2 = selectFormat(i, 1);
            questionsList.add(questionGenerator.generateQuestion(learnerId, word, f2));
        }

        // 4. Intersperse active reinforcement items
        for (int i = 0; i < reinforcementItems.size(); i++) {
            VocabularyWord rWord = reinforcementItems.get(i).getWord();
            int index = Math.min((i * 3) + 2, questionsList.size());
            String format = selectFormat(i, 2);
            questionsList.add(index, questionGenerator.generateQuestion(learnerId, rWord, format));
        }

        return questionsList;
    }

    @Transactional
    public Map<String, Object> submitAnswer(UUID sessionId, UUID wordId, boolean isCorrect, String wrongAnswer, String activityFormat) {
        PracticeSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new IllegalArgumentException("Session not found"));

        UUID learnerId = session.getLearner().getLearnerId();

        // 1. Log the result via PracticeSessionService
        practiceSessionService.record(sessionId, wordId, isCorrect);

        // 2. Update adaptive difficulty level via DifficultyAdjustmentService
        difficultyService.calculateNext(learnerId, wordId, isCorrect);

        // 3. Spaced Repetition Reinforcement updates
        if (isCorrect) {
            reinforcementEngine.resolve(learnerId, wordId);
        } else {
            reinforcementEngine.enqueue(learnerId, wordId);
            wrongAnswerTrackingService.trackWrongAnswer(learnerId, wordId, wrongAnswer, activityFormat);
        }

        Map<String, Object> result = new HashMap<>();
        result.put("sessionId", sessionId.toString());
        result.put("wordId", wordId.toString());
        result.put("isCorrect", isCorrect);
        return result;
    }

    private String selectFormat(int index, int phase) {
        String[] formats = {"MULTIPLE_CHOICE", "FILL_IN_BLANK", "MATCHING", "SENTENCE_ARRANGEMENT"};
        return formats[(index + phase) % formats.length];
    }
}
