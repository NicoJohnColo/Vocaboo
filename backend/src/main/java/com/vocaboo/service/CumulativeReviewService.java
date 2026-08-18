package com.vocaboo.service;

import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class CumulativeReviewService {

    private final CumulativeReviewSessionRepository sessionRepository;
    private final CumulativeReviewResultRepository resultRepository;
    private final CrossLessonSentenceRepository crossLessonSentenceRepository;
    private final DifficultyProgressRepository difficultyProgressRepository;
    private final VocabularyWordRepository wordRepository;
    private final LearnerRepository learnerRepository;
    private final LessonRepository lessonRepository;
    private final WordPerformanceRepository wordPerformanceRepository;

    @Transactional
    public CumulativeReviewSession startCumulativeReviewSession(UUID learnerId, String lessonPairId) {
        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner not found"));

        String[] lessonIds = lessonPairId.split("_");
        if (lessonIds.length != 2) {
            throw new IllegalArgumentException("Invalid lessonPairId format. Expected UUID_UUID");
        }

        UUID lesson1Id = UUID.fromString(lessonIds[0]);
        UUID lesson2Id = UUID.fromString(lessonIds[1]);

        // Precondition Check: ensure both lessons are fully mastered
        long lesson1MasteredCount = difficultyProgressRepository.countMasteredWordsByLearnerAndLesson(learnerId, lesson1Id);
        long lesson2MasteredCount = difficultyProgressRepository.countMasteredWordsByLearnerAndLesson(learnerId, lesson2Id);
        
        long lesson1TotalWords = wordRepository.findByLessonLessonIdAndIsDeletedFalseOrderByWordOrderAsc(lesson1Id).size();
        long lesson2TotalWords = wordRepository.findByLessonLessonIdAndIsDeletedFalseOrderByWordOrderAsc(lesson2Id).size();

        if (lesson1MasteredCount < lesson1TotalWords || lesson2MasteredCount < lesson2TotalWords) {
            throw new IllegalStateException("Precondition failed: Both lessons must be fully mastered (Modules 1-3 complete) before Cumulative Review.");
        }

        CumulativeReviewSession session = CumulativeReviewSession.builder()
                .learner(learner)
                .lessonPairId(lessonPairId)
                .sessionStatus("IN_PROGRESS")
                .build();

        return sessionRepository.save(session);
    }

    @Transactional
    public List<Map<String, Object>> generateSessionQuestions(UUID sessionId) {
        CumulativeReviewSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new IllegalArgumentException("Session not found"));

        String[] lessonIds = session.getLessonPairId().split("_");
        UUID lesson1Id = UUID.fromString(lessonIds[0]);
        UUID lesson2Id = UUID.fromString(lessonIds[1]);

        List<VocabularyWord> allWords = new ArrayList<>();
        allWords.addAll(wordRepository.findByLessonLessonIdAndIsDeletedFalseOrderByWordOrderAsc(lesson1Id));
        allWords.addAll(wordRepository.findByLessonLessonIdAndIsDeletedFalseOrderByWordOrderAsc(lesson2Id));

        if (allWords.isEmpty()) {
            throw new IllegalStateException("No words found for this lesson pair.");
        }

        // We would ideally select 24-48 questions. We will just return the word IDs here for the frontend.
        // In a full implementation, we'd assign exact formats here and send to the frontend.
        // For simplicity and decoupling, we will just send all words and let the frontend use them.
        
        return allWords.stream().map(w -> {
            Map<String, Object> map = new HashMap<>();
            map.put("wordId", w.getWordId());
            map.put("englishWord", w.getEnglishWord());
            map.put("partOfSpeech", w.getPartOfSpeech());
            map.put("cebuanoMeaning", w.getCebuanoMeaning());
            map.put("definition", w.getCebuanoMeaning()); // For compat
            return map;
        }).collect(Collectors.toList());
    }

    @Transactional
    public List<CrossLessonSentence> getSessionSentences(UUID sessionId) {
        CumulativeReviewSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new IllegalArgumentException("Session not found"));
        return crossLessonSentenceRepository.findByLessonPairId(session.getLessonPairId());
    }

    @Transactional
    public void recordCumulativeReviewAnswer(UUID sessionId, UUID wordId, String activityType, boolean correct, UUID crossLessonSentenceId, int attemptNumber) {
        CumulativeReviewSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new IllegalArgumentException("Session not found"));
        VocabularyWord word = wordRepository.findById(wordId)
                .orElseThrow(() -> new IllegalArgumentException("Word not found"));

        CrossLessonSentence cls = null;
        if (crossLessonSentenceId != null) {
            cls = crossLessonSentenceRepository.findById(crossLessonSentenceId).orElse(null);
        }

        CumulativeReviewResult result = CumulativeReviewResult.builder()
                .session(session)
                .word(word)
                .activityType(activityType)
                .correct(correct)
                .attemptNumber(attemptNumber)
                .crossLessonSentence(cls)
                .build();

        resultRepository.save(result);

        // Update word performance for UC-B1
        WordPerformance wp = wordPerformanceRepository.findByLearnerLearnerIdAndWordWordId(session.getLearner().getLearnerId(), wordId)
                .orElseGet(() -> WordPerformance.builder().learner(session.getLearner()).word(word).build());
        
        wp.setTotalAttempts(wp.getTotalAttempts() + 1);
        if (correct) {
            wp.setCorrectCount(wp.getCorrectCount() + 1);
        } else {
            wp.setIncorrectCount(wp.getIncorrectCount() + 1);
        }
        
        if (wp.getTotalAttempts() > 0) {
            double acc = (double) wp.getCorrectCount() / wp.getTotalAttempts() * 100.0;
            wp.setAccuracy(new BigDecimal(acc));
        }
        wordPerformanceRepository.save(wp);
        
        session.setTotalAttempts(session.getTotalAttempts() + 1);
        if (correct) {
            session.setCorrectCount(session.getCorrectCount() + 1);
        }
        
        if (session.getTotalAttempts() > 0) {
            session.setAccuracyPercent(new BigDecimal((double) session.getCorrectCount() / session.getTotalAttempts() * 100));
        }
        sessionRepository.save(session);
    }

    @Transactional
    public CumulativeReviewSession completeCumulativeReviewSession(UUID sessionId) {
        CumulativeReviewSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new IllegalArgumentException("Session not found"));

        session.setSessionStatus("COMPLETED");
        session.setEndTime(OffsetDateTime.now());

        double accuracy = session.getAccuracyPercent() != null ? session.getAccuracyPercent().doubleValue() : 0.0;
        
        String badge = null;
        int badgeBonus = 0;
        
        if (accuracy >= 90.0) {
            badge = "GOLD";
            badgeBonus = 100;
        } else if (accuracy >= 80.0) {
            badge = "SILVER";
            badgeBonus = 50;
        } else if (accuracy >= 70.0) {
            badge = "BRONZE";
            badgeBonus = 0;
        } else {
            session.setSessionStatus("RETRY_REQUIRED");
        }

        session.setBadgeAwarded(badge);
        
        // Calculate total points
        List<CumulativeReviewResult> results = resultRepository.findBySessionId(sessionId);
        int tierMovingPoints = 0;
        int crossLessonBonus = 0;
        
        for (CumulativeReviewResult r : results) {
            if (r.isCorrect()) {
                if ("SENTENCE_PUZZLE".equals(r.getActivityType())) {
                    crossLessonBonus += 15;
                }
                
                // Tier moving points
                if (r.getAttemptNumber() == 1) tierMovingPoints += 10;
                else if (r.getAttemptNumber() == 2) tierMovingPoints += 7;
                else tierMovingPoints += 5;
            }
        }
        
        int totalPoints = tierMovingPoints + crossLessonBonus + badgeBonus;
        session.setPointsEarned(totalPoints);
        
        Map<String, Object> breakdown = new HashMap<>();
        breakdown.put("tier_moving", tierMovingPoints);
        breakdown.put("cross_lesson_bonus", crossLessonBonus);
        breakdown.put("badge_bonus", badgeBonus);
        
        session.setPointsBreakdown(breakdown);

        return sessionRepository.save(session);
    }

    @Transactional(readOnly = true)
    public List<CumulativeReviewSession> getLearnerSessions(UUID learnerId) {
        return sessionRepository.findByLearnerLearnerIdOrderByStartTimeDesc(learnerId);
    }

    @Transactional
    public CumulativeReviewSession abandonCumulativeReviewSession(UUID sessionId) {
        CumulativeReviewSession session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new IllegalArgumentException("Session not found"));
        if (!"COMPLETED".equals(session.getSessionStatus())) {
            session.setSessionStatus("ABANDONED");
            session.setEndTime(OffsetDateTime.now());
            return sessionRepository.save(session);
        }
        return session;
    }

    @Transactional(readOnly = true)
    public Map<String, Object> getLearnerCumulativeSummary(UUID learnerId) {
        List<CumulativeReviewSession> sessions = sessionRepository.findByLearnerLearnerIdOrderByStartTimeDesc(learnerId);
        long completedCount = sessions.stream().filter(s -> "COMPLETED".equals(s.getSessionStatus())).count();
        
        String bestBadge = null;
        if (sessions.stream().anyMatch(s -> "GOLD".equals(s.getBadgeAwarded()))) {
            bestBadge = "GOLD";
        } else if (sessions.stream().anyMatch(s -> "SILVER".equals(s.getBadgeAwarded()))) {
            bestBadge = "SILVER";
        } else if (sessions.stream().anyMatch(s -> "BRONZE".equals(s.getBadgeAwarded()))) {
            bestBadge = "BRONZE";
        }

        int totalPoints = sessions.stream()
                .filter(s -> "COMPLETED".equals(s.getSessionStatus()))
                .mapToInt(s -> s.getPointsEarned() != null ? s.getPointsEarned() : 0)
                .sum();

        Map<String, Object> summary = new HashMap<>();
        summary.put("completedCount", completedCount);
        summary.put("bestBadge", bestBadge);
        summary.put("totalPoints", totalPoints);
        return summary;
    }
}
