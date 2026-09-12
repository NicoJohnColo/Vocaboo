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
    private final ClassPerformanceService classPerformanceService;
    private final com.vocaboo.repository.ClassroomRepository classroomRepository;

    @Transactional
    public SessionSummary saveSessionSummary(UUID learnerId, UUID sessionId, UUID lessonId, Double reviewScore, Boolean isPerfectFirstAttempt) {
        return saveSessionSummary(learnerId, sessionId, lessonId, reviewScore, isPerfectFirstAttempt, null);
    }

    @Transactional
    public SessionSummary saveSessionSummary(UUID learnerId, UUID sessionId, UUID lessonId,
                                              Double reviewScore, Boolean isPerfectFirstAttempt,
                                              UUID classroomContextId) {
        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner not found"));
        Lesson lesson = lessonRepository.findById(lessonId)
                .orElseThrow(() -> new IllegalArgumentException("Lesson not found"));

        List<VocabularyWord> allLessonWords = wordRepository.findByLessonLessonIdOrderByWordOrderAsc(lessonId);
        int totalWords = allLessonWords.size();
        int correct = 0;
        int incorrect = 0;
        int attempts = 0;

        for (VocabularyWord word : allLessonWords) {
            WordPerformance perf = performanceRepository.findByLearnerLearnerIdAndWordWordId(learnerId, word.getWordId())
                    .orElse(null);
            if (perf != null) {
                correct += perf.getCorrectCount();
                incorrect += perf.getIncorrectCount();
                attempts += perf.getTotalAttempts();
            }
        }

        List<PracticeResult> results = resultRepository.findBySessionSessionId(sessionId);
        long sessionCorrect = results.stream().filter(r -> Boolean.TRUE.equals(r.getIsCorrect())).count();
        long sessionTotal = results.size();
        Double sessionAttemptAcc = sessionTotal > 0 ? ((double) sessionCorrect / sessionTotal * 100.0) : null;

        BigDecimal accuracy = BigDecimal.ZERO;
        if (reviewScore != null && reviewScore > 0) {
            accuracy = BigDecimal.valueOf(reviewScore).setScale(2, RoundingMode.HALF_UP);
        } else if (sessionAttemptAcc != null) {
            accuracy = BigDecimal.valueOf(sessionAttemptAcc).setScale(2, RoundingMode.HALF_UP);
        } else if (attempts > 0) {
            accuracy = BigDecimal.valueOf((double) correct / attempts * 100.0)
                    .setScale(2, RoundingMode.HALF_UP);
        }

        int demerits = incorrect * 2;
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
        
        // Resolve class context for tagging transactions
        String contextType = classroomContextId != null ? "CLASS" : "GLOBAL";
        com.vocaboo.entity.Classroom classroomEntity = null;
        if (classroomContextId != null) {
            classroomEntity = classroomRepository.findById(classroomContextId).orElse(null);
        }
        
        // Add delta base points to transaction if > 0
        if (deltaBasePoints > 0) {
            PointTransaction tx = PointTransaction.builder()
                    .learner(learner)
                    .actionType(PointActionType.CORRECT_ANSWER)
                    .pointsAwarded(deltaBasePoints)
                    .relatedSessionId(sessionId)
                    .contextType(contextType)
                    .classroom(classroomEntity)
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
        
        if (masteredWords >= totalWordsForLesson) {
            if (!lessonStatus.getLessonCompletionBonusAwarded()) {
                bonusPoints += 200;
                PointTransaction tx = PointTransaction.builder()
                        .learner(learner)
                        .actionType(PointActionType.LESSON_COMPLETE)
                        .pointsAwarded(200)
                        .relatedSessionId(sessionId)
                        .contextType(contextType)
                        .classroom(classroomEntity)
                        .createdAt(OffsetDateTime.now())
                        .build();
                pointTransactionRepository.save(tx);
                
                lessonStatus.setLessonCompletionBonusAwarded(true);
            }
            lessonStatus.setStatus(LessonStatus.COMPLETED);
            lessonStatus.setCompletedAt(OffsetDateTime.now());
        }

        List<VocabularyWord> lessonWords = wordRepository.findByLessonLessonIdOrderByWordOrderAsc(lessonId);
        int totalLessonAttempts = 0;
        int totalLessonCorrect = 0;
        double wordAccSum = 0.0;
        int wordsWithAcc = 0;
        for (VocabularyWord lw : lessonWords) {
            WordPerformance wp = performanceRepository.findByLearnerLearnerIdAndWordWordId(learnerId, lw.getWordId()).orElse(null);
            if (wp != null && wp.getTotalAttempts() > 0) {
                totalLessonAttempts += wp.getTotalAttempts();
                totalLessonCorrect += wp.getCorrectCount();
                if (wp.getAccuracy() != null && wp.getAccuracy().doubleValue() > 0) {
                    wordAccSum += wp.getAccuracy().doubleValue();
                    wordsWithAcc++;
                } else if (wp.getTotalAttempts() > 0) {
                    wordAccSum += ((double) wp.getCorrectCount() / wp.getTotalAttempts() * 100.0);
                    wordsWithAcc++;
                }
            }
        }

        // Total accuracy of the lesson is the average of the actual overridden word accuracies
        double wholeLessonAvg = wordsWithAcc > 0 
                ? (wordAccSum / wordsWithAcc) 
                : (totalLessonAttempts > 0 ? ((double) totalLessonCorrect / totalLessonAttempts * 100.0) : 0.0);
        BigDecimal wholeLessonAcc = BigDecimal.valueOf(wholeLessonAvg).setScale(2, RoundingMode.HALF_UP);

        BigDecimal candidateScore = wholeLessonAcc;
        if (candidateScore.compareTo(BigDecimal.ZERO) == 0 && reviewScore != null && reviewScore > 0) {
            candidateScore = BigDecimal.valueOf(reviewScore).setScale(2, RoundingMode.HALF_UP);
        }

        // Update lesson mastery score to the high watermark (best preserved score)
        if (candidateScore.compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal existingMastery = lessonStatus.getMasteryScore();
            if (existingMastery == null || candidateScore.compareTo(existingMastery) > 0) {
                lessonStatus.setMasteryScore(candidateScore);
            }
        }
        lessonStatus.setUpdatedAt(OffsetDateTime.now());
        lessonStatusRepository.save(lessonStatus);

        boolean isPerfect = (isPerfectFirstAttempt != null && isPerfectFirstAttempt) ||
                (results.isEmpty() ? sessionAccuracy.compareTo(BigDecimal.valueOf(100.0)) == 0 : (results.stream().noneMatch(r -> !r.getIsCorrect()) && sessionAccuracy.compareTo(BigDecimal.valueOf(100.0)) == 0));

        if (isPerfect && !lessonStatus.getPerfectScoreBonusAwarded()) {
            bonusPoints += 100;

            PointTransaction tx = PointTransaction.builder()
                    .learner(learner)
                    .actionType(PointActionType.PERFECT_SESSION)
                    .pointsAwarded(100)
                    .relatedSessionId(sessionId)
                    .contextType(contextType)
                    .classroom(classroomEntity)
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
                            .overallAccuracy(java.math.BigDecimal.ZERO)
                            .wordsMasteredCount(0)
                            .totalPoints(0)
                            .createdAt(OffsetDateTime.now())
                            .build());
            mastery.setTotalPoints(mastery.getTotalPoints() + totalNewPoints);
            masteryRepository.save(mastery);

            // Double-write bonus points to class performance if in class context
            if (classroomContextId != null) {
                classPerformanceService.addBonusPoints(learnerId, classroomContextId, bonusPoints);
            }
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
                .accuracyRate(candidateScore)
                .demeritPoints(demerits)
                .pointsEarned(totalPointsEarned)
                .starsEarned(starsEarned)
                .contextType(classroomContextId != null ? "CLASS" : "GLOBAL")
                .classroom(classroomEntity)
                .build();

        return summaryRepository.save(summary);
    }

    @Transactional
    public SessionSummary saveSessionSummary(UUID learnerId, UUID sessionId, UUID lessonId) {
        return saveSessionSummary(learnerId, sessionId, lessonId, null, null, null);
    }
}
