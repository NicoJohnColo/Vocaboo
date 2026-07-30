package com.vocaboo.controller;

import com.vocaboo.entity.RewardData;
import com.vocaboo.entity.SessionSummary;
import com.vocaboo.repository.RewardDataRepository;
import com.vocaboo.repository.SessionSummaryRepository;
import com.vocaboo.service.MasteryReviewService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.security.Principal;
import java.util.*;

@RestController
@RequestMapping("/api/v1/mastery")
@RequiredArgsConstructor
public class MasteryController {

    private final MasteryReviewService masteryService;
    private final SessionSummaryRepository summaryRepository;
    private final RewardDataRepository rewardRepository;

    @PostMapping("/session/{sessionId}/complete")
    public ResponseEntity<Map<String, Object>> completeSession(
            @PathVariable("sessionId") UUID sessionId,
            @RequestParam("lessonId") UUID lessonId,
            @RequestParam(value = "score", required = false) Double score,
            @RequestParam(value = "isPerfectFirstAttempt", required = false) Boolean isPerfectFirstAttempt,
            Principal principal) {
        UUID learnerId = UUID.fromString(principal.getName());
        SessionSummary summary = masteryService.completeSession(learnerId, sessionId, lessonId, score, isPerfectFirstAttempt);

        // Fetch the badge earned for this lesson
        List<RewardData> rewards = rewardRepository.findByLearnerLearnerIdAndLessonLessonId(learnerId, lessonId);
        String badge = rewards.stream()
                .map(RewardData::getBadgeType)
                .max(Comparator.comparingInt(this::getBadgeTier))
                .orElse("BRONZE");

        return ResponseEntity.ok(mapToResponse(summary, badge));
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

    @GetMapping("/session/{sessionId}/summary")
    public ResponseEntity<Map<String, Object>> getSessionSummary(
            @PathVariable("sessionId") UUID sessionId,
            Principal principal) {
        UUID learnerId = UUID.fromString(principal.getName());
        SessionSummary summary = summaryRepository.findBySessionId(sessionId)
                .orElseThrow(() -> new IllegalArgumentException("Session summary not found"));

        List<RewardData> rewards = rewardRepository.findByLearnerLearnerIdAndLessonLessonId(learnerId, summary.getLesson().getLessonId());
        String badge = rewards.stream()
                .map(RewardData::getBadgeType)
                .reduce((first, second) -> second)
                .orElse("BRONZE");

        return ResponseEntity.ok(mapToResponse(summary, badge));
    }

    @GetMapping("/learners/{learnerId}/badges")
    public ResponseEntity<List<Map<String, Object>>> getLearnerBadges(
            @PathVariable("learnerId") UUID learnerId) {
        List<RewardData> rewards = rewardRepository.findByLearnerLearnerId(learnerId);
        List<Map<String, Object>> list = new ArrayList<>();
        for (RewardData reward : rewards) {
            Map<String, Object> map = new HashMap<>();
            map.put("lessonId", reward.getLesson().getLessonId());
            map.put("lessonTitle", reward.getLesson().getLessonTitle());
            map.put("badgeType", reward.getBadgeType());
            map.put("earnedAt", reward.getEarnedAt());
            list.add(map);
        }
        return ResponseEntity.ok(list);
    }

    private Map<String, Object> mapToResponse(SessionSummary summary, String badge) {
        Map<String, Object> response = new HashMap<>();
        response.put("summaryId", summary.getSummaryId());
        response.put("sessionId", summary.getSessionId());
        response.put("lessonId", summary.getLesson().getLessonId());
        response.put("totalWordsReviewed", summary.getTotalWordsReviewed());
        response.put("correctPronunciations", summary.getCorrectPronunciations());
        response.put("incorrectPronunciations", summary.getIncorrectPronunciations());
        response.put("totalAttempts", summary.getTotalAttempts());
        response.put("accuracyRate", summary.getAccuracyRate());
        response.put("demeritPoints", summary.getDemeritPoints());
        response.put("pointsEarned", summary.getPointsEarned());
        response.put("badgeType", badge);
        response.put("completedAt", summary.getCompletedAt());
        return response;
    }
}
