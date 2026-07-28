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
    private final IntroductionSessionRepository introductionSessionRepository;
    private final ReinforcementQueueRepository queueRepository;
    private final VocabularyWordRepository wordRepository;
    private final DynamicQuestionGeneratorService questionGenerator;
    private final ReinforcementEngineService reinforcementEngine;
    private final PracticeSessionService practiceSessionService;
    private final DifficultyAdjustmentService difficultyService;
    private final WrongAnswerTrackingService wrongAnswerTrackingService;

    private static final List<String> CORE_FORMATS = List.of("MULTIPLE_CHOICE", "FILL_IN_BLANK", "MATCHING");

    private static class FormatBag {
        private final List<String> available = new ArrayList<>();
        private final Random random;

        public FormatBag(Random random) {
            this.random = random;
            refill();
        }

        private void refill() {
            available.clear();
            available.addAll(CORE_FORMATS);
            Collections.shuffle(available, random);
        }

        public String draw() {
            if (available.isEmpty()) {
                refill();
            }
            return available.remove(0);
        }

        public String drawExcept(String exclude) {
            if (available.isEmpty()) {
                refill();
            }
            for (int i = 0; i < available.size(); i++) {
                if (!available.get(i).equals(exclude)) {
                    return available.remove(i);
                }
            }
            refill();
            for (int i = 0; i < available.size(); i++) {
                if (!available.get(i).equals(exclude)) {
                    return available.remove(i);
                }
            }
            return available.remove(0);
        }
    }

    @Transactional
    public List<Map<String, Object>> generateSessionQuestions(UUID sessionId) {
        PracticeSession session = sessionRepository.findById(sessionId).orElse(null);
        if (session == null) {
            var introOpt = introductionSessionRepository.findById(sessionId);
            if (introOpt.isPresent()) {
                Learner learner = introOpt.get().getLearner();
                Lesson lesson = introOpt.get().getLesson();
                session = sessionRepository.save(PracticeSession.builder()
                        .learner(learner)
                        .lesson(lesson)
                        .moduleNumber(2)
                        .build());
            } else {
                throw new IllegalArgumentException("Session not found");
            }
        }

        UUID learnerId = session.getLearner().getLearnerId();
        UUID lessonId = session.getLesson().getLessonId();

        // 1. Fetch all words in the lesson
        List<VocabularyWord> lessonWords = wordRepository.findByLessonLessonIdOrderByWordOrderAsc(lessonId);

        // 2. Fetch active reinforcement items for this learner
        List<ReinforcementQueueItem> reinforcementItems = queueRepository
                .findByLearnerLearnerIdAndIsResolvedFalseOrderByScheduledAtAsc(learnerId);

        List<Map<String, Object>> questionsList = new ArrayList<>();

        FormatBag bag = new FormatBag(new Random());

        // 3. Generate questions for lesson words (2 exercises per word in different formats)
        for (int i = 0; i < lessonWords.size(); i++) {
            VocabularyWord word = lessonWords.get(i);
            
            String f1 = bag.draw();
            questionsList.add(questionGenerator.generateQuestion(learnerId, word, f1));

            String f2 = bag.drawExcept(f1);
            questionsList.add(questionGenerator.generateQuestion(learnerId, word, f2));
        }

        // 4. Intersperse active reinforcement items
        for (int i = 0; i < reinforcementItems.size(); i++) {
            VocabularyWord rWord = reinforcementItems.get(i).getWord();
            int index = Math.min((i * 3) + 2, questionsList.size());
            String format = bag.draw();
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
        String[] formats = {"MULTIPLE_CHOICE", "FILL_IN_BLANK", "MATCHING"};
        return formats[(index + phase) % formats.length];
    }
}
