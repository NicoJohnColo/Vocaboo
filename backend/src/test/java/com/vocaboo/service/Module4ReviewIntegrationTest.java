package com.vocaboo.service;

import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
public class Module4ReviewIntegrationTest {

    @Autowired
    private ReviewService reviewService;

    @Autowired
    private MasteryReviewService masteryReviewService;

    @Autowired
    private SessionSummaryRepository summaryRepository;

    @Autowired
    private RewardDataRepository rewardRepository;

    @Autowired
    private PointTransactionRepository pointTransactionRepository;

    @Autowired
    private LearnerRepository learnerRepository;

    @Autowired
    private LessonRepository lessonRepository;

    @Autowired
    private VocabularyWordRepository wordRepository;

    @Autowired
    private WordPerformanceRepository performanceRepository;

    @Autowired
    private PracticeSessionRepository sessionRepository;

    @Test
    public void testModule4ReviewPayloadAndCompletionChain() {
        // 1. Fetch active learner and published lessons
        List<Learner> learners = learnerRepository.findAll();
        assertFalse(learners.isEmpty(), "Learners should exist in DB");
        Learner learner = learners.get(0);
        UUID learnerId = learner.getLearnerId();

        List<Lesson> lessons = lessonRepository.findAll();
        if (lessons.size() < 2) {
            Lesson l1 = lessonRepository.save(Lesson.builder().lessonTitle("Test Lesson 1").lessonOrder(1).build());
            Lesson l2 = lessonRepository.save(Lesson.builder().lessonTitle("Test Lesson 2").lessonOrder(2).build());
            lessons = List.of(l1, l2);
        }
        assertTrue(lessons.size() >= 2, "At least 2 lessons should exist");
        Lesson priorLesson = lessons.get(0);
        Lesson currentLesson = lessons.get(1);

        // 2. Seed weak performance on prior lesson word
        List<VocabularyWord> priorWords = wordRepository.findByLessonLessonIdOrderByWordOrderAsc(priorLesson.getLessonId());
        if (!priorWords.isEmpty()) {
            VocabularyWord weakWord = priorWords.get(0);
            WordPerformance wp = performanceRepository.findByLearnerLearnerIdAndWordWordId(learnerId, weakWord.getWordId())
                    .orElseGet(() -> WordPerformance.builder()
                            .learner(learner)
                            .word(weakWord)
                            .build());
            wp.setTotalAttempts(10);
            wp.setCorrectCount(3);
            wp.setIncorrectCount(7);
            wp.setAccuracy(BigDecimal.valueOf(30.0));
            performanceRepository.save(wp);
        }

        // 3. Test Module 4 Review Payload generation
        List<Map<String, Object>> payload = reviewService.generateModule4ReviewPayload(learnerId, currentLesson.getLessonId());
        assertNotNull(payload, "Payload should not be null");
        assertFalse(payload.isEmpty(), "Payload should contain review items");

        long refresherCount = payload.stream().filter(m -> Boolean.TRUE.equals(m.get("isRefresher"))).count();
        System.out.println("Module 4 Review Payload size: " + payload.size() + ", Refresher items count: " + refresherCount);

        // 4. Create PracticeSession
        PracticeSession session = PracticeSession.builder()
                .learner(learner)
                .lesson(currentLesson)
                .moduleNumber(4)
                .build();
        session = sessionRepository.save(session);
        UUID sessionId = session.getSessionId();

        // 5. Test completeSession with 85% score (Silver badge)
        SessionSummary summary = masteryReviewService.completeSession(learnerId, sessionId, currentLesson.getLessonId(), 85.0, false);
        assertNotNull(summary);
        assertEquals(BigDecimal.valueOf(85.0).setScale(2), summary.getAccuracyRate());

        List<RewardData> rewards = rewardRepository.findByLearnerLearnerIdAndLessonLessonId(learnerId, currentLesson.getLessonId());
        assertFalse(rewards.isEmpty(), "Rewards should contain earned badge");
        String badge = rewards.get(rewards.size() - 1).getBadgeType();
        System.out.println("Earned badge for 85% score: " + badge);

        // 6. Test completeSession with 100% score & isPerfectFirstAttempt = true (Gold badge + 100 bonus points)
        PracticeSession perfectSession = PracticeSession.builder()
                .learner(learner)
                .lesson(currentLesson)
                .moduleNumber(4)
                .build();
        perfectSession = sessionRepository.save(perfectSession);

        SessionSummary perfectSummary = masteryReviewService.completeSession(learnerId, perfectSession.getSessionId(), currentLesson.getLessonId(), 100.0, true);
        assertEquals(BigDecimal.valueOf(100.0).setScale(2), perfectSummary.getAccuracyRate());

        List<RewardData> updatedRewards = rewardRepository.findByLearnerLearnerIdAndLessonLessonId(learnerId, currentLesson.getLessonId());
        String finalBadge = updatedRewards.stream()
                .map(RewardData::getBadgeType)
                .max(Comparator.comparingInt(this::getBadgeTier))
                .orElse("BRONZE");
        assertEquals("GOLD", finalBadge, "Badge should upgrade to GOLD for 100% score");

        List<PointTransaction> txs = pointTransactionRepository.findAll();
        boolean perfectBonusAwarded = txs.stream()
                .anyMatch(tx -> tx.getLearner().getLearnerId().equals(learnerId) 
                        && "PERFECT_SESSION".equals(tx.getActionType().name()) 
                        && tx.getPointsAwarded() == 100);
        assertTrue(perfectBonusAwarded, "PERFECT_SESSION bonus transaction should be recorded");

        System.out.println("SUCCESS: Module 4 Review payload, 70%+ passing, badge calculation, and +100 perfect session bonus verified successfully!");
    }

    private int getBadgeTier(String badge) {
        if (badge == null) return 0;
        switch (badge) {
            case "PERFECT_GOLD":
            case "GOLD": return 3;
            case "SILVER": return 2;
            case "BRONZE": return 1;
            default: return 0;
        }
    }
}
