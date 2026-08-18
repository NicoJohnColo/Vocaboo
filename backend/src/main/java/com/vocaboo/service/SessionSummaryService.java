package com.vocaboo.service;

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
public class SessionSummaryService {

    private final SessionSummaryRepository summaryRepository;
    private final WordPerformanceRepository performanceRepository;
    private final LearnerRepository learnerRepository;
    private final LessonRepository lessonRepository;
    private final VocabularyWordRepository wordRepository;
    private final PracticeResultRepository resultRepository;
    private final PointTransactionRepository pointTransactionRepository;
    private final LearnerMasteryRepository masteryRepository;
    private final LearnerLessonStatusRepository lessonStatusRepository;
    private final DifficultyProgressRepository difficultyProgressRepository;

    @Transactional
    public SessionSummary saveSessionSummary(UUID learnerId, UUID sessionId, UUID lessonId, Double reviewScore, Boolean isPerfectFirstAttempt) {
        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner not found"));
        Lesson lesson = lessonRepository.findById(lessonId)
                .orElseThrow(() -> new IllegalArgumentException("Lesson not found"));

        String posFocus = learner.getPosFocus();
        List<VocabularyWord> words = wordRepository.findByLessonLessonIdOrderByWordOrderAsc(lessonId).stream()
                .filter(w -> posFocus == null || "ALL".equalsIgnoreCase(posFocus) || posFocus.equalsIgnoreCase(w.getPartOfSpeech()))
                .collect(Collectors.toList());
        int totalWords = words.size();
        int correct = 0;
        int incorrect = 0;
        int attempts = 0;

        if (words != null) {
            for (VocabularyWord word : words) {
                WordPerformance perf = performanceRepository.findByLearnerLearnerIdAndWordWordId(learnerId, word.getWordId())
                        .orElse(null);
                if (perf != null) {
                    correct += perf.getCorrectCount();
                    incorrect += perf.getIncorrectCount();
                    attempts += perf.getTotalAttempts();
                }
            }
        }

        BigDecimal accuracy = BigDecimal.ZERO;
        if (reviewScore != null) {
            accuracy = BigDecimal.valueOf(reviewScore).setScale(2, RoundingMode.HALF_UP);
        } else if (attempts > 0) {
            accuracy = BigDecimal.valueOf((double) correct / attempts * 100.0)
                    .setScale(2, RoundingMode.HALF_UP);
        }

        int demerits = incorrect * 2;

        List<PracticeResult> results = resultRepository.findBySessionSessionId(sessionId);
        int basePoints = results.stream().mapToInt(PracticeResult::getPoints).sum();

        LearnerLessonStatus lessonStatus = lessonStatusRepository
                .findByLearnerLearnerIdAndLessonLessonId(learnerId, lessonId)
                .orElseGet(() -> {
                    LearnerLessonStatus s = LearnerLessonStatus.builder()
                            .learner(learner)
                            .lesson(lesson)
                            .build();
                    return lessonStatusRepository.save(s);
                });

        int deltaBasePoints = 0;
        if (basePoints > lessonStatus.getBestLessonPoints()) {
            deltaBasePoints = basePoints - lessonStatus.getBestLessonPoints();
            lessonStatus.setBestLessonPoints(basePoints);
            lessonStatusRepository.save(lessonStatus);
        }
        
        // Add delta base points to transaction if > 0
        if (deltaBasePoints > 0) {
            PointTransaction tx = PointTransaction.builder()
                    .learner(learner)
                    .actionType(PointActionType.CORRECT_ANSWER)
                    .pointsAwarded(deltaBasePoints)
                    .relatedSessionId(sessionId)
                    .createdAt(OffsetDateTime.now())
                    .build();
            pointTransactionRepository.save(tx);
        }

        BigDecimal sessionAccuracy = accuracy;
        int bonusPoints = 0;

        // The Lesson Completion Bonus (+200) is ONLY awarded when the entire lesson is completely MASTERED.
        // It is no longer based on single session accuracy.
        long masteredWords = difficultyProgressRepository.countMasteredWordsByLearnerAndLesson(learnerId, lessonId);
        long totalWordsForLesson = wordRepository.findByLessonLessonIdOrderByWordOrderAsc(lessonId).size();
        
        if (masteredWords >= totalWordsForLesson && !lessonStatus.getLessonCompletionBonusAwarded()) {
            bonusPoints += 200;
            PointTransaction tx = PointTransaction.builder()
                    .learner(learner)
                    .actionType(PointActionType.LESSON_COMPLETE)
                    .pointsAwarded(200)
                    .relatedSessionId(sessionId)
                    .createdAt(OffsetDateTime.now())
                    .build();
            pointTransactionRepository.save(tx);
            
            lessonStatus.setLessonCompletionBonusAwarded(true);
            
            // Strictly enforce LessonStatus.COMPLETED here (Bug A)
            lessonStatus.setStatus(LessonStatus.COMPLETED);
            lessonStatusRepository.save(lessonStatus);
        }

        boolean isPerfect = (isPerfectFirstAttempt != null && isPerfectFirstAttempt) ||
                (results.isEmpty() ? sessionAccuracy.compareTo(BigDecimal.valueOf(100.0)) == 0 : (results.stream().noneMatch(r -> !r.getIsCorrect()) && sessionAccuracy.compareTo(BigDecimal.valueOf(100.0)) == 0));

        if (isPerfect && !lessonStatus.getPerfectScoreBonusAwarded()) {
            bonusPoints += 100;

            PointTransaction tx = PointTransaction.builder()
                    .learner(learner)
                    .actionType(PointActionType.PERFECT_SESSION)
                    .pointsAwarded(100)
                    .relatedSessionId(sessionId)
                    .createdAt(OffsetDateTime.now())
                    .build();
            pointTransactionRepository.save(tx);
            
            lessonStatus.setPerfectScoreBonusAwarded(true);
            lessonStatusRepository.save(lessonStatus);
        }

        // Update cached totalPoints in LearnerMastery by the total points actually awarded (delta + bonus)
        int totalNewPoints = deltaBasePoints + bonusPoints;
        if (totalNewPoints > 0) {
            LearnerMastery mastery = masteryRepository.findByLearnerLearnerId(learnerId)
                    .orElseGet(() -> LearnerMastery.builder()
                            .learner(learner)
                            .totalSessionsPlayed(0)
                            .totalCorrectAnswers(0)
                            .totalQuestionsAnswered(0)
                            .overallAccuracy(BigDecimal.ZERO)
                            .wordsMasteredCount(0)
                            .totalPoints(0)
                            .createdAt(OffsetDateTime.now())
                            .build());
            mastery.setTotalPoints(mastery.getTotalPoints() + totalNewPoints);
            masteryRepository.save(mastery);
        }

        int totalPointsEarned = basePoints + bonusPoints; // For summary object display

        int starsEarned = PracticeSessionService.calculateStars(accuracy);

        SessionSummary summary = SessionSummary.builder()
                .learner(learner)
                .sessionId(sessionId)
                .lesson(lesson)
                .totalWordsReviewed(totalWords)
                .correctPronunciations(correct)
                .incorrectPronunciations(incorrect)
                .totalAttempts(attempts)
                .accuracyRate(accuracy)
                .demeritPoints(demerits)
                .pointsEarned(totalPointsEarned)
                .starsEarned(starsEarned)
                .build();

        return summaryRepository.save(summary);
    }

    @Transactional
    public SessionSummary saveSessionSummary(UUID learnerId, UUID sessionId, UUID lessonId) {
        return saveSessionSummary(learnerId, sessionId, lessonId, null, null);
    }
}
