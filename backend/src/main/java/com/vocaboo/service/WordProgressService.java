package com.vocaboo.service;

import com.vocaboo.dto.request.ProgressRequest;
import com.vocaboo.dto.response.ProgressResponse;
import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class WordProgressService {

    private final WordProgressRepository progressRepository;
    private final IntroductionSessionRepository sessionRepository;
    private final VocabularyWordRepository wordRepository;
    private final LearnerLessonStatusRepository lessonStatusRepository;
    private final PronunciationAttemptRepository pronunciationAttemptRepository;
    private final LessonRepository lessonRepository;

    @Transactional
    public ProgressResponse updateProgress(UUID sessionId, ProgressRequest request) {
        IntroductionSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new IllegalArgumentException("Session not found"));

        WordProgress progress = progressRepository
                .findBySessionSessionIdAndWordWordIdAndModuleNumber(sessionId, request.getWordId(), 1)
                .orElseGet(() -> WordProgress.builder()
                        .session(session)
                        .learner(session.getLearner())
                        .lesson(session.getLesson())
                        .word(wordRepository.findById(request.getWordId())
                                .orElseThrow(() -> new IllegalArgumentException("Word not found")))
                        .moduleNumber(1)
                        .build());

        progress.setPathway(request.getPathway());
        progress.setStepCompleted(request.getStepCompleted());
        progress.setStatus(request.getStatus());

        if (request.getStepCompleted() == 4) {
            progress.setCompletedAt(OffsetDateTime.now());
        }

        progress = progressRepository.save(progress);

        // Check if all words in this lesson are completed
        checkAndCompleteLesson(session);

        return ProgressResponse.builder()
                .progressId(progress.getProgressId())
                .sessionId(sessionId)
                .wordId(progress.getWord().getWordId())
                .pathway(progress.getPathway())
                .stepCompleted(progress.getStepCompleted())
                .status(progress.getStatus())
                .completedAt(progress.getCompletedAt())
                .build();
    }

    private void checkAndCompleteLesson(IntroductionSession session) {
        List<VocabularyWord> totalWords = wordRepository.findByLessonLessonIdOrderByWordOrderAsc(session.getLesson().getLessonId());
        int totalWordCount = totalWords.size();

        long completedWordsCount = totalWords.stream()
                .filter(w -> progressRepository
                        .findBySessionSessionIdAndWordWordIdAndModuleNumber(session.getSessionId(), w.getWordId(), 1)
                        .map(p -> p.getStepCompleted() == 4)
                        .orElse(false))
                .count();

        if (completedWordsCount == totalWordCount && totalWordCount > 0) {
            // Calculate mastery score
            // Let's count how many words were pronounced correctly in the session
            long correctWordsCount = 0;
            for (VocabularyWord word : totalWords) {
                boolean correct = pronunciationAttemptRepository
                        .findBySessionSessionIdAndWordWordIdAndModuleNumberOrderByAttemptNumberAsc(
                                session.getSessionId(), word.getWordId(), 1)
                        .stream()
                        .anyMatch(attempt -> Boolean.TRUE.equals(attempt.getIsCorrect()));
                if (correct) {
                    correctWordsCount++;
                }
            }

            BigDecimal score = BigDecimal.valueOf((double) correctWordsCount / totalWordCount * 100.0)
                    .setScale(2, RoundingMode.HALF_UP);

            // Update session
            session.setIsActive(false);
            session.setCompletedAt(OffsetDateTime.now());
            sessionRepository.save(session);

            // Update learner_lesson_status
            LearnerLessonStatus lessonStatus = lessonStatusRepository
                    .findByLearnerLearnerIdAndLessonLessonId(session.getLearner().getLearnerId(), session.getLesson().getLessonId())
                    .orElseGet(() -> LearnerLessonStatus.builder()
                            .learner(session.getLearner())
                            .lesson(session.getLesson())
                            .build());

            lessonStatus.setStatus(LessonStatus.COMPLETED);
            lessonStatus.setMasteryScore(score);
            lessonStatus.setAttempts(lessonStatus.getAttempts() + 1);
            lessonStatus.setCompletedAt(OffsetDateTime.now());
            lessonStatusRepository.save(lessonStatus);

            // Unlock next lesson in category if exists
            unlockNextLesson(session.getLesson(), session.getLearner());
        }
    }

    private void unlockNextLesson(Lesson completedLesson, Learner learner) {
        // Find lessons in the same category
        List<Lesson> lessons = lessonRepository.findByCategoryCategoryIdOrderByLessonOrderAsc(completedLesson.getCategory().getCategoryId());
        
        int nextOrder = completedLesson.getLessonOrder() + 1;
        lessons.stream()
                .filter(l -> l.getLessonOrder() == nextOrder)
                .findFirst()
                .ifPresent(nextLesson -> {
                    LearnerLessonStatus nextStatus = lessonStatusRepository
                            .findByLearnerLearnerIdAndLessonLessonId(learner.getLearnerId(), nextLesson.getLessonId())
                            .orElseGet(() -> LearnerLessonStatus.builder()
                                    .learner(learner)
                                    .lesson(nextLesson)
                                    .attempts(0)
                                    .build());

                    if (nextStatus.getStatus() == LessonStatus.LOCKED) {
                        nextStatus.setStatus(LessonStatus.UNLOCKED);
                        nextStatus.setUnlockedAt(OffsetDateTime.now());
                        lessonStatusRepository.save(nextStatus);
                    }
                });
    }
}
