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
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class WordProgressService {

    private final WordProgressRepository progressRepository;
    private final IntroductionSessionRepository sessionRepository;
    private final VocabularyWordRepository wordRepository;
    private final LearnerLessonStatusRepository lessonStatusRepository;
    private final PronunciationAttemptRepository pronunciationAttemptRepository;
    private final LessonRepository lessonRepository;
    private final SessionSummaryRepository summaryRepository;
    private final WordPerformanceRepository performanceRepository;
    private final LearnerMasteryRepository masteryRepository;
    private final DifficultyProgressRepository difficultyProgressRepository;
    private final PracticeResultRepository practiceResultRepository;

    @Transactional
    public ProgressResponse updateProgress(UUID sessionId, ProgressRequest request) {
        IntroductionSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new IllegalArgumentException("Session not found"));

        int moduleNum = request.getModuleNumber() != null ? request.getModuleNumber() : 1;

        WordProgress progress = progressRepository
                .findBySessionSessionIdAndWordWordIdAndModuleNumber(sessionId, request.getWordId(), moduleNum)
                .orElseGet(() -> WordProgress.builder()
                        .session(session)
                        .learner(session.getLearner())
                        .lesson(session.getLesson())
                        .word(wordRepository.findById(request.getWordId())
                                .orElseThrow(() -> new IllegalArgumentException("Word not found")))
                        .moduleNumber(moduleNum)
                        .build());

        progress.setPathway(request.getPathway());
        progress.setStepCompleted(request.getStepCompleted());
        progress.setStatus(request.getStatus());

        if (request.getStepCompleted() == 4) {
            progress.setCompletedAt(OffsetDateTime.now());
        }

        progress = progressRepository.save(progress);

        // Check if all words in this lesson are completed
        checkAndCompleteLesson(session, moduleNum);

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

    private void checkAndCompleteLesson(IntroductionSession session, int moduleNumber) {
        if (moduleNumber != 3) {
            // Lesson completion is now tied to completing Module 3
            return;
        }

        // Only check for full lesson completion using the ENTIRE lesson word count, not just the focus subset
        List<VocabularyWord> totalWords = wordRepository.findByLessonLessonIdOrderByWordOrderAsc(session.getLesson().getLessonId());
        int totalWordCount = totalWords.size();

        // Check global progress for all words in the lesson for this learner
        long completedWordsCount = totalWords.stream()
                .filter(w -> progressRepository
                        .findByLearnerLearnerIdAndWordWordIdAndModuleNumber(session.getLearner().getLearnerId(), w.getWordId(), 3)
                        .stream()
                        .anyMatch(p -> p.getStepCompleted() == 4))
                .count();

        if (completedWordsCount == totalWordCount && totalWordCount > 0) {
            // Calculate mastery score
            // Let's count how many words were pronounced correctly in either module 1 or 3
            long correctWordsCount = 0;
            for (VocabularyWord word : totalWords) {
                boolean correct = pronunciationAttemptRepository
                        .findBySessionSessionIdAndWordWordIdAndModuleNumberOrderByAttemptNumberAsc(
                                session.getSessionId(), word.getWordId(), 3)
                        .stream()
                        .anyMatch(attempt -> Boolean.TRUE.equals(attempt.getIsCorrect()));
                if (!correct) {
                    correct = pronunciationAttemptRepository
                            .findBySessionSessionIdAndWordWordIdAndModuleNumberOrderByAttemptNumberAsc(
                                    session.getSessionId(), word.getWordId(), 1)
                            .stream()
                            .anyMatch(attempt -> Boolean.TRUE.equals(attempt.getIsCorrect()));
                }
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

            lessonStatus.setStatus(LessonStatus.UNLOCKED);
            lessonStatus.setMasteryScore(score);
            lessonStatus.setAttempts(lessonStatus.getAttempts() + 1);
            lessonStatus.setCompletedAt(OffsetDateTime.now());
            lessonStatusRepository.save(lessonStatus);

            // Create/update SessionSummary
            SessionSummary summary = summaryRepository.findBySessionId(session.getSessionId())
                    .orElseGet(() -> SessionSummary.builder()
                            .sessionId(session.getSessionId())
                            .learner(session.getLearner())
                            .lesson(session.getLesson())
                            .build());

            int stars = score.compareTo(BigDecimal.valueOf(90)) >= 0 ? 3 : (score.compareTo(BigDecimal.valueOf(70)) >= 0 ? 2 : (score.compareTo(BigDecimal.valueOf(50)) >= 0 ? 1 : 0));
            int points = score.intValue() * 2;

            summary.setTotalWordsReviewed(totalWordCount);
            summary.setCorrectPronunciations((int) correctWordsCount);
            summary.setIncorrectPronunciations(totalWordCount - (int) correctWordsCount);
            summary.setTotalAttempts(totalWordCount);
            summary.setAccuracyRate(score);
            summary.setStarsEarned(stars);
            summary.setPointsEarned(points);
            summary.setDemeritPoints(0);
            summary.setCompletedAt(OffsetDateTime.now());
            summaryRepository.save(summary);

            // Update WordPerformance
            for (VocabularyWord word : totalWords) {
                boolean correct = pronunciationAttemptRepository
                        .findBySessionSessionIdAndWordWordIdAndModuleNumberOrderByAttemptNumberAsc(session.getSessionId(), word.getWordId(), 3)
                        .stream().anyMatch(a -> Boolean.TRUE.equals(a.getIsCorrect()));
                if (!correct) {
                    correct = pronunciationAttemptRepository
                            .findBySessionSessionIdAndWordWordIdAndModuleNumberOrderByAttemptNumberAsc(session.getSessionId(), word.getWordId(), 1)
                            .stream().anyMatch(a -> Boolean.TRUE.equals(a.getIsCorrect()));
                }
                if (!correct) {
                    correct = practiceResultRepository
                            .findBySessionLearnerLearnerIdAndWordWordId(session.getLearner().getLearnerId(), word.getWordId())
                            .stream().anyMatch(r -> Boolean.TRUE.equals(r.getIsCorrect()));
                }

                WordPerformance perf = performanceRepository.findByLearnerLearnerIdAndWordWordId(session.getLearner().getLearnerId(), word.getWordId())
                        .orElseGet(() -> WordPerformance.builder()
                                .learner(session.getLearner())
                                .word(word)
                                .build());

                perf.setTotalAttempts(perf.getTotalAttempts() + 1);
                if (correct) {
                    perf.setCorrectCount(perf.getCorrectCount() + 1);
                } else {
                    perf.setIncorrectCount(perf.getIncorrectCount() + 1);
                }
                double wordAcc = (double) perf.getCorrectCount() / perf.getTotalAttempts() * 100.0;
                perf.setAccuracy(BigDecimal.valueOf(wordAcc).setScale(2, RoundingMode.HALF_UP));
                perf.setLastPracticedAt(OffsetDateTime.now());
                performanceRepository.save(perf);
            }

            // Update LearnerMastery
            LearnerMastery mastery = masteryRepository.findByLearnerLearnerId(session.getLearner().getLearnerId())
                    .orElseGet(() -> LearnerMastery.builder()
                            .learner(session.getLearner())
                            .totalSessionsPlayed(0)
                            .totalCorrectAnswers(0)
                            .totalQuestionsAnswered(0)
                            .overallAccuracy(BigDecimal.ZERO)
                            .wordsMasteredCount(0)
                            .totalPoints(0)
                            .build());

            long completedSessionsCount = summaryRepository.findByLearnerLearnerId(session.getLearner().getLearnerId()).size();
            mastery.setTotalSessionsPlayed((int) completedSessionsCount);
            mastery.setTotalQuestionsAnswered(mastery.getTotalQuestionsAnswered() + totalWordCount);
            mastery.setTotalCorrectAnswers(mastery.getTotalCorrectAnswers() + (int) correctWordsCount);

            if (mastery.getTotalQuestionsAnswered() > 0) {
                double overallAcc = (double) mastery.getTotalCorrectAnswers() / mastery.getTotalQuestionsAnswered() * 100.0;
                mastery.setOverallAccuracy(BigDecimal.valueOf(overallAcc).setScale(2, RoundingMode.HALF_UP));
            }

            List<WordPerformance> allPerfs = performanceRepository.findByLearnerLearnerId(session.getLearner().getLearnerId());
            long masteredCount = allPerfs.stream().filter(p -> {
                var dpOpt = difficultyProgressRepository.findByLearnerLearnerIdAndWordWordIdAndModuleNumber(session.getLearner().getLearnerId(), p.getWord().getWordId(), 2);
                DifficultyLevel currentLevel = dpOpt.map(DifficultyProgress::getCurrentLevel).orElse(DifficultyLevel.LEARNING);
                return currentLevel == DifficultyLevel.MASTERED;
            }).count();

            mastery.setWordsMasteredCount((int) masteredCount);
            mastery.setTotalPoints(mastery.getTotalPoints() + points);
            mastery.setMasteryLevel(calculateMasteryLevel(mastery.getOverallAccuracy()));
            masteryRepository.save(mastery);

            // Unlock next lesson in category if exists
            unlockNextLesson(session.getLesson(), session.getLearner());
        }
    }

    private String calculateMasteryLevel(BigDecimal accuracy) {
        if (accuracy == null) return "LEARNING";
        double acc = accuracy.doubleValue();
        if (acc >= 90.0) return "MASTERED";
        if (acc >= 80.0) return "PROFICIENT";
        if (acc >= 70.0) return "FAMILIAR";
        return "LEARNING";
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
                                    .status(LessonStatus.LOCKED)
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
