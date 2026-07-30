package com.vocaboo.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc(addFilters = false)
@Transactional
public class MasteryCompletionControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private LearnerRepository learnerRepository;

    @Autowired
    private LessonRepository lessonRepository;

    @Autowired
    private PracticeSessionRepository sessionRepository;

    @Autowired
    private SessionSummaryRepository summaryRepository;

    @Autowired
    private RewardDataRepository rewardRepository;

    @Autowired
    private PointTransactionRepository pointTransactionRepository;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    public void testRealMasteryCompletionHttpFlow() throws Exception {
        // 1. Fetch real learner and lesson from DB
        List<Learner> learners = learnerRepository.findAll();
        assertFalse(learners.isEmpty(), "Learner should exist");
        Learner learner = learners.get(0);
        String learnerIdStr = learner.getLearnerId().toString();

        List<Lesson> lessons = lessonRepository.findAll();
        assertFalse(lessons.isEmpty(), "Lesson should exist");
        Lesson lesson = lessons.get(0);
        UUID lessonId = lesson.getLessonId();

        // Create a practice session for Pass test (85.0%)
        PracticeSession sessionPass = PracticeSession.builder()
                .learner(learner)
                .lesson(lesson)
                .moduleNumber(4)
                .build();
        sessionPass = sessionRepository.save(sessionPass);
        UUID sessionIdPass = sessionPass.getSessionId();

        // 2. Perform HTTP POST to completeSession endpoint for Pass Case (85.0%, SILVER)
        System.out.println("=== EXECUTING REAL HTTP POST FOR PASS CASE (85.0%) ===");
        MvcResult passResult = mockMvc.perform(post("/api/v1/mastery/session/{sessionId}/complete", sessionIdPass)
                .param("lessonId", lessonId.toString())
                .param("score", "85.0")
                .param("isPerfectFirstAttempt", "false")
                .principal(() -> learnerIdStr))
                .andExpect(status().isOk())
                .andReturn();

        String passResponseBody = passResult.getResponse().getContentAsString();
        System.out.println("HTTP Response (85% Pass): " + passResponseBody);
        assertTrue(passResponseBody.contains("SILVER"), "Response should contain SILVER badge");
        assertTrue(passResponseBody.contains("85.00"), "Response should contain 85.00 accuracy");

        // Query database to verify written summary and reward row for Pass Case
        SessionSummary summaryPass = summaryRepository.findBySessionId(sessionIdPass)
                .orElseThrow(() -> new AssertionError("Session summary should be persisted"));
        assertEquals(BigDecimal.valueOf(85.00).setScale(2), summaryPass.getAccuracyRate());

        List<RewardData> rewardsPass = rewardRepository.findByLearnerLearnerIdAndLessonLessonId(learner.getLearnerId(), lessonId);
        assertFalse(rewardsPass.isEmpty());
        System.out.println("DB Query Result (Pass Case): Summary Accuracy = " + summaryPass.getAccuracyRate() + "%, Earned Badges = " + rewardsPass.stream().map(RewardData::getBadgeType).toList());

        // 3. Create a practice session for Perfect Case (100.0%, GOLD + +100 bonus)
        PracticeSession sessionPerfect = PracticeSession.builder()
                .learner(learner)
                .lesson(lesson)
                .moduleNumber(4)
                .build();
        sessionPerfect = sessionRepository.save(sessionPerfect);
        UUID sessionIdPerfect = sessionPerfect.getSessionId();

        // Perform HTTP POST for Perfect Case (100.0%, isPerfectFirstAttempt = true)
        System.out.println("\n=== EXECUTING REAL HTTP POST FOR PERFECT CASE (100.0%, FIRST ATTEMPT) ===");
        MvcResult perfectResult = mockMvc.perform(post("/api/v1/mastery/session/{sessionId}/complete", sessionIdPerfect)
                .param("lessonId", lessonId.toString())
                .param("score", "100.0")
                .param("isPerfectFirstAttempt", "true")
                .principal(() -> learnerIdStr))
                .andExpect(status().isOk())
                .andReturn();

        String perfectResponseBody = perfectResult.getResponse().getContentAsString();
        System.out.println("HTTP Response (100% Perfect): " + perfectResponseBody);
        assertTrue(perfectResponseBody.contains("GOLD"), "Response should contain GOLD badge");

        // Query database to verify written summary, reward row, and +100 bonus transaction
        SessionSummary summaryPerfect = summaryRepository.findBySessionId(sessionIdPerfect)
                .orElseThrow(() -> new AssertionError("Perfect session summary should be persisted"));
        assertEquals(BigDecimal.valueOf(100.00).setScale(2), summaryPerfect.getAccuracyRate());

        List<RewardData> rewardsPerfect = rewardRepository.findByLearnerLearnerIdAndLessonLessonId(learner.getLearnerId(), lessonId);
        boolean hasGold = rewardsPerfect.stream().anyMatch(r -> "GOLD".equals(r.getBadgeType()));
        assertTrue(hasGold, "DB should contain GOLD badge");

        List<PointTransaction> txs = pointTransactionRepository.findAll();
        boolean hasPerfectTx = txs.stream().anyMatch(tx -> tx.getLearner().getLearnerId().equals(learner.getLearnerId())
                && "PERFECT_SESSION".equals(tx.getActionType().name())
                && tx.getPointsAwarded() == 100);
        assertTrue(hasPerfectTx, "DB should contain PERFECT_SESSION point transaction with +100 points");

        System.out.println("DB Query Result (Perfect Case): Summary Accuracy = " + summaryPerfect.getAccuracyRate() + "%, Earned Badges = " + rewardsPerfect.stream().map(RewardData::getBadgeType).toList());
        System.out.println("DB Query Result (Perfect Bonus Transaction): " + txs.stream().filter(tx -> "PERFECT_SESSION".equals(tx.getActionType().name())).map(tx -> tx.getActionType() + " +" + tx.getPointsAwarded()).toList());
    }
}
