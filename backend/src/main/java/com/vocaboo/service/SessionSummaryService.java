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

    @Transactional
    public SessionSummary saveSessionSummary(UUID learnerId, UUID sessionId, UUID lessonId) {
        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner not found"));
        Lesson lesson = lessonRepository.findById(lessonId)
                .orElseThrow(() -> new IllegalArgumentException("Lesson not found"));

        List<VocabularyWord> words = wordRepository.findByLessonLessonIdOrderByWordOrderAsc(lessonId);
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
        if (attempts > 0) {
            accuracy = BigDecimal.valueOf((double) correct / attempts * 100.0)
                    .setScale(2, RoundingMode.HALF_UP);
        }

        int demerits = incorrect * 2;

        // Calculate session-level points and bonuses
        List<PracticeResult> results = resultRepository.findBySessionSessionId(sessionId);
        int basePoints = results.stream().mapToInt(PracticeResult::getPoints).sum();

        long sessionIncorrectCount = results.stream().filter(r -> !r.getIsCorrect()).count();
        long sessionTotalAttempts = results.size();
        
        BigDecimal sessionAccuracy = BigDecimal.ZERO;
        if (sessionTotalAttempts > 0) {
            long sessionCorrectCount = results.stream().filter(PracticeResult::getIsCorrect).count();
            sessionAccuracy = BigDecimal.valueOf(sessionCorrectCount * 100.0 / sessionTotalAttempts)
                    .setScale(2, RoundingMode.HALF_UP);
        }

        int bonusPoints = 0;
        if (sessionTotalAttempts > 0) {
            // NOTE: 80% is the gamification lesson-complete bonus threshold (UC-4.1).
            // It is intentionally independent of the 70% mixed review mastery pass gate.
            if (sessionAccuracy.compareTo(BigDecimal.valueOf(80.0)) >= 0) {
                bonusPoints += 200;
                
                PointTransaction tx = PointTransaction.builder()
                        .learner(learner)
                        .actionType(PointActionType.LESSON_COMPLETE)
                        .pointsAwarded(200)
                        .relatedSessionId(sessionId)
                        .createdAt(OffsetDateTime.now())
                        .build();
                pointTransactionRepository.save(tx);
            }
            
            if (sessionIncorrectCount == 0 && sessionAccuracy.compareTo(BigDecimal.valueOf(100.0)) == 0) {
                bonusPoints += 100;
                
                PointTransaction tx = PointTransaction.builder()
                        .learner(learner)
                        .actionType(PointActionType.PERFECT_SESSION)
                        .pointsAwarded(100)
                        .relatedSessionId(sessionId)
                        .createdAt(OffsetDateTime.now())
                        .build();
                pointTransactionRepository.save(tx);
            }
        }

        // Update cached totalPoints in LearnerMastery by the total bonus points awarded
        if (bonusPoints > 0) {
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
            mastery.setTotalPoints(mastery.getTotalPoints() + bonusPoints);
            masteryRepository.save(mastery);
        }

        int totalPointsEarned = basePoints + bonusPoints;

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
                .build();

        return summaryRepository.save(summary);
    }
}
