package com.vocaboo.service;

import com.vocaboo.dto.response.LearnerProgressResponse;
import com.vocaboo.dto.response.PracticeResultResponse;
import com.vocaboo.dto.response.PracticeSessionResponse;
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
public class PracticeSessionService {

    private final PracticeSessionRepository sessionRepository;
    private final PracticeResultRepository resultRepository;
    private final LearnerMasteryRepository masteryRepository;
    private final WordPerformanceRepository performanceRepository;
    private final LearnerRepository learnerRepository;
    private final LessonRepository lessonRepository;
    private final VocabularyWordRepository wordRepository;
    private final PointTransactionRepository pointTransactionRepository;

    @Transactional
    public PracticeSessionResponse start(UUID learnerId, UUID lessonId, int moduleNumber) {
        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner not found"));
        Lesson lesson = lessonRepository.findById(lessonId)
                .orElseThrow(() -> new IllegalArgumentException("Lesson not found"));

        PracticeSession session = PracticeSession.builder()
                .learner(learner)
                .lesson(lesson)
                .moduleNumber(moduleNumber)
                .createdAt(OffsetDateTime.now())
                .updatedAt(OffsetDateTime.now())
                .build();

        session = sessionRepository.save(session);

        // Lazily initialize LearnerMastery record if not exists
        if (masteryRepository.findByLearnerLearnerId(learnerId).isEmpty()) {
            LearnerMastery mastery = LearnerMastery.builder()
                    .learner(learner)
                    .totalSessionsPlayed(0)
                    .totalCorrectAnswers(0)
                    .totalQuestionsAnswered(0)
                    .overallAccuracy(BigDecimal.ZERO)
                    .wordsMasteredCount(0)
                    .totalPoints(0)
                    .createdAt(OffsetDateTime.now())
                    .updatedAt(OffsetDateTime.now())
                    .build();
            masteryRepository.save(mastery);
        }

        return toSessionResponse(session);
    }

    @Transactional
    public PracticeResultResponse record(UUID sessionId, UUID wordId, boolean isCorrect) {
        PracticeSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new IllegalArgumentException("Session not found"));
        VocabularyWord word = wordRepository.findById(wordId)
                .orElseThrow(() -> new IllegalArgumentException("Word not found"));

        int pointsEarned = 0;
        if (isCorrect) {
            List<PracticeResult> existingResults = resultRepository.findBySessionSessionId(sessionId);
            long attemptsOnThisWord = existingResults.stream()
                    .filter(r -> r.getWord().getWordId().equals(wordId))
                    .count();
            int attemptNumber = (int) attemptsOnThisWord + 1;

            if (attemptNumber == 1) pointsEarned = 10;
            else if (attemptNumber == 2) pointsEarned = 7;
            else if (attemptNumber == 3) pointsEarned = 5;
            else pointsEarned = 0;
        }

        PracticeResult result = PracticeResult.builder()
                .session(session)
                .word(word)
                .isCorrect(isCorrect)
                .points(pointsEarned)
                .recordedAt(OffsetDateTime.now())
                .build();

        result = resultRepository.save(result);

        if (isCorrect) {
            PointTransaction transaction = PointTransaction.builder()
                    .learner(session.getLearner())
                    .actionType(PointActionType.CORRECT_ANSWER)
                    .pointsAwarded(pointsEarned)
                    .relatedSessionId(sessionId)
                    .relatedWord(word)
                    .createdAt(OffsetDateTime.now())
                    .build();
            pointTransactionRepository.save(transaction);
        }

        // Update WordPerformance
        WordPerformance performance = performanceRepository
                .findByLearnerLearnerIdAndWordWordId(session.getLearner().getLearnerId(), wordId)
                .orElseGet(() -> WordPerformance.builder()
                        .learner(session.getLearner())
                        .word(word)
                        .correctCount(0)
                        .incorrectCount(0)
                        .totalAttempts(0)
                        .accuracy(BigDecimal.ZERO)
                        .createdAt(OffsetDateTime.now())
                        .build());

        performance.setTotalAttempts(performance.getTotalAttempts() + 1);
        if (isCorrect) {
            performance.setCorrectCount(performance.getCorrectCount() + 1);
        } else {
            performance.setIncorrectCount(performance.getIncorrectCount() + 1);
        }

        BigDecimal accuracy = BigDecimal.valueOf(performance.getCorrectCount() * 100.0 / performance.getTotalAttempts())
                .setScale(2, RoundingMode.HALF_UP);
        performance.setAccuracy(accuracy);
        performance.setDemeritPoints(performance.getIncorrectCount() * 2);
        performance.setLastPracticedAt(OffsetDateTime.now());
        performance.setUpdatedAt(OffsetDateTime.now());

        performanceRepository.save(performance);

        // Update LearnerMastery incrementally
        LearnerMastery mastery = masteryRepository.findByLearnerLearnerId(session.getLearner().getLearnerId())
                .orElseGet(() -> LearnerMastery.builder()
                        .learner(session.getLearner())
                        .totalSessionsPlayed(0)
                        .totalCorrectAnswers(0)
                        .totalQuestionsAnswered(0)
                        .overallAccuracy(BigDecimal.ZERO)
                        .wordsMasteredCount(0)
                        .totalPoints(0)
                        .createdAt(OffsetDateTime.now())
                        .build());

        mastery.setTotalQuestionsAnswered(mastery.getTotalQuestionsAnswered() + 1);
        if (isCorrect) {
            mastery.setTotalCorrectAnswers(mastery.getTotalCorrectAnswers() + 1);
            mastery.setTotalPoints(mastery.getTotalPoints() + pointsEarned);
        }

        BigDecimal overallAccuracy = BigDecimal.valueOf(mastery.getTotalCorrectAnswers() * 100.0 / mastery.getTotalQuestionsAnswered())
                .setScale(2, RoundingMode.HALF_UP);
        mastery.setOverallAccuracy(overallAccuracy);
        mastery.setUpdatedAt(OffsetDateTime.now());

        masteryRepository.save(mastery);

        return toResultResponse(result);
    }

    @Transactional
    public PracticeSessionResponse end(UUID sessionId) {
        PracticeSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new IllegalArgumentException("Session not found"));

        if (session.getCompletedAt() != null) {
            return toSessionResponse(session);
        }

        final Learner learner = session.getLearner();

        BigDecimal score = calculateScore(sessionId);
        session.setScore(score);
        session.setStarsEarned(calculateStars(score));
        session.setCompletedAt(OffsetDateTime.now());
        session.setUpdatedAt(OffsetDateTime.now());
        session = sessionRepository.save(session);

        // Update LearnerMastery sessions played and mastered count
        LearnerMastery mastery = masteryRepository.findByLearnerLearnerId(learner.getLearnerId())
                .orElseGet(() -> LearnerMastery.builder()
                        .learner(learner)
                        .totalSessionsPlayed(0)
                        .totalCorrectAnswers(0)
                        .totalQuestionsAnswered(0)
                        .overallAccuracy(BigDecimal.ZERO)
                        .wordsMasteredCount(0)
                        .createdAt(OffsetDateTime.now())
                        .build());

        mastery.setTotalSessionsPlayed(mastery.getTotalSessionsPlayed() + 1);

        // Recalculate mastered words (accuracy >= 80% and attempts >= 3)
        List<WordPerformance> performances = performanceRepository.findByLearnerLearnerId(learner.getLearnerId());
        long masteredCount = performances.stream()
                .filter(p -> p.getTotalAttempts() >= 3 && p.getAccuracy().compareTo(BigDecimal.valueOf(80.0)) >= 0)
                .count();

        mastery.setWordsMasteredCount((int) masteredCount);
        mastery.setUpdatedAt(OffsetDateTime.now());
        masteryRepository.save(mastery);

        return toSessionResponse(session);
    }

    @Transactional(readOnly = true)
    public BigDecimal calculateScore(UUID sessionId) {
        List<PracticeResult> results = resultRepository.findBySessionSessionId(sessionId);
        if (results.isEmpty()) {
            return BigDecimal.ZERO;
        }

        long totalCount = results.size();
        long correctCount = results.stream().filter(PracticeResult::getIsCorrect).count();

        return BigDecimal.valueOf(correctCount * 100.0 / totalCount).setScale(2, RoundingMode.HALF_UP);
    }

    @Transactional
    public void updateMastery(UUID learnerId) {
        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner not found"));

        List<WordPerformance> performances = performanceRepository.findByLearnerLearnerId(learnerId);
        int totalQuestions = performances.stream().mapToInt(WordPerformance::getTotalAttempts).sum();
        int totalCorrect = performances.stream().mapToInt(WordPerformance::getCorrectCount).sum();

        BigDecimal overallAccuracy = totalQuestions > 0
                ? BigDecimal.valueOf(totalCorrect * 100.0 / totalQuestions).setScale(2, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        long masteredCount = performances.stream()
                .filter(p -> p.getTotalAttempts() >= 3 && p.getAccuracy().compareTo(BigDecimal.valueOf(80.0)) >= 0)
                .count();

        List<PracticeSession> sessions = sessionRepository.findByLearnerLearnerId(learnerId);
        long completedSessions = sessions.stream().filter(s -> s.getCompletedAt() != null).count();

        LearnerMastery mastery = masteryRepository.findByLearnerLearnerId(learnerId)
                .orElseGet(() -> LearnerMastery.builder()
                        .learner(learner)
                        .build());

        mastery.setTotalQuestionsAnswered(totalQuestions);
        mastery.setTotalCorrectAnswers(totalCorrect);
        mastery.setOverallAccuracy(overallAccuracy);
        mastery.setWordsMasteredCount((int) masteredCount);
        mastery.setTotalSessionsPlayed((int) completedSessions);
        mastery.setUpdatedAt(OffsetDateTime.now());

        masteryRepository.save(mastery);
    }

    @Transactional(readOnly = true)
    public LearnerProgressResponse getProgress(UUID learnerId) {
        LearnerMastery mastery = masteryRepository.findByLearnerLearnerId(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Mastery data not found for learner. Begin a practice session first."));

        return toProgressResponse(mastery);
    }

    public static int calculateStars(BigDecimal accuracy) {
        if (accuracy == null) return 0;
        double val = accuracy.doubleValue();
        if (val >= 90.0) return 3;
        if (val >= 80.0) return 2;
        if (val >= 70.0) return 1;
        return 0;
    }

    private PracticeSessionResponse toSessionResponse(PracticeSession session) {
        return PracticeSessionResponse.builder()
                .sessionId(session.getSessionId())
                .learnerId(session.getLearner().getLearnerId())
                .lessonId(session.getLesson().getLessonId())
                .moduleNumber(session.getModuleNumber())
                .score(session.getScore())
                .starsEarned(session.getStarsEarned())
                .completedAt(session.getCompletedAt())
                .createdAt(session.getCreatedAt())
                .build();
    }

    private PracticeResultResponse toResultResponse(PracticeResult result) {
        return PracticeResultResponse.builder()
                .resultId(result.getResultId())
                .sessionId(result.getSession().getSessionId())
                .wordId(result.getWord().getWordId())
                .isCorrect(result.getIsCorrect())
                .points(result.getPoints())
                .recordedAt(result.getRecordedAt())
                .build();
    }

    private LearnerProgressResponse toProgressResponse(LearnerMastery mastery) {
        int pointsThisWeek = pointTransactionRepository.sumPointsByLearnerAndDateAfter(
                mastery.getLearner().getLearnerId(),
                OffsetDateTime.now().minusDays(7)
        );

        return LearnerProgressResponse.builder()
                .learnerId(mastery.getLearner().getLearnerId())
                .totalSessionsPlayed(mastery.getTotalSessionsPlayed())
                .totalCorrectAnswers(mastery.getTotalCorrectAnswers())
                .totalQuestionsAnswered(mastery.getTotalQuestionsAnswered())
                .overallAccuracy(mastery.getOverallAccuracy())
                .wordsMasteredCount(mastery.getWordsMasteredCount())
                .totalPoints(mastery.getTotalPoints())
                .pointsThisWeek(pointsThisWeek)
                .build();
    }
}
