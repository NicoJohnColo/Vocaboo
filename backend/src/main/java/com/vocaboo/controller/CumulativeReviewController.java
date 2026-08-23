package com.vocaboo.controller;

import com.vocaboo.entity.CumulativeReviewSession;
import com.vocaboo.entity.Learner;
import com.vocaboo.repository.CumulativeReviewSessionRepository;
import com.vocaboo.repository.LearnerRepository;
import com.vocaboo.service.CumulativeReviewService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.security.Principal;
import java.time.OffsetDateTime;
import java.util.*;

@RestController
@RequestMapping("/api/v1/cumulative-review")
@RequiredArgsConstructor
public class CumulativeReviewController {

    private final CumulativeReviewService cumulativeReviewService;
    private final CumulativeReviewSessionRepository sessionRepository;
    private final LearnerRepository learnerRepository;

    @Data
    public static class StartSessionRequest {
        private String lessonPairId;
        private String categoryId;
        private String sessionId;
    }

    @Data
    public static class CompleteSessionRequest {
        private Double accuracyScore;
        private Integer totalAttempts;
        private Integer correctCount;
        private String badgeAwarded;
        private Integer pointsEarned;
        private Integer timeSpentSeconds;
        private String lessonPairId;
        private String categoryId;
    }

    @PostMapping("/start")
    public ResponseEntity<Map<String, Object>> startSession(@RequestBody(required = false) StartSessionRequest request, Principal principal) {
        UUID learnerId = UUID.fromString(principal.getName());
        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner not found"));

        String pairId = request != null && request.getLessonPairId() != null && !request.getLessonPairId().isBlank()
                ? request.getLessonPairId()
                : (request != null && request.getCategoryId() != null ? request.getCategoryId() : "cumulative");

        UUID sessionUuid = null;
        if (request != null && request.getSessionId() != null) {
            try {
                sessionUuid = UUID.fromString(request.getSessionId());
            } catch (Exception ignored) {}
        }

        CumulativeReviewSession session = null;
        if (sessionUuid != null) {
            session = sessionRepository.findById(sessionUuid).orElse(null);
        }

        if (session == null) {
            session = CumulativeReviewSession.builder()
                    .learner(learner)
                    .lessonPairId(pairId)
                    .sessionStatus("IN_PROGRESS")
                    .startTime(OffsetDateTime.now())
                    .build();
            session = sessionRepository.save(session);
        }

        Map<String, Object> resp = new HashMap<>();
        resp.put("sessionId", session.getId().toString());
        resp.put("lessonPairId", session.getLessonPairId());
        resp.put("sessionStatus", session.getSessionStatus());
        return ResponseEntity.ok(resp);
    }

    @PostMapping("/sessions/{sessionId}/complete")
    public ResponseEntity<Map<String, Object>> completeSession(
            @PathVariable String sessionId,
            @RequestBody(required = false) CompleteSessionRequest request,
            Principal principal) {
        UUID learnerId = UUID.fromString(principal.getName());
        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner not found"));

        UUID sessionUuid = null;
        try {
            sessionUuid = UUID.fromString(sessionId);
        } catch (Exception ignored) {}

        CumulativeReviewSession session = null;
        if (sessionUuid != null) {
            session = sessionRepository.findById(sessionUuid).orElse(null);
        }

        if (session == null) {
            String pairId = request != null && request.getLessonPairId() != null
                    ? request.getLessonPairId()
                    : (request != null && request.getCategoryId() != null ? request.getCategoryId() : "cumulative");

            session = CumulativeReviewSession.builder()
                    .learner(learner)
                    .lessonPairId(pairId)
                    .startTime(OffsetDateTime.now())
                    .build();
        }

        session.setSessionStatus("COMPLETED");
        session.setEndTime(OffsetDateTime.now());

        if (request != null) {
            if (request.getAccuracyScore() != null) {
                session.setAccuracyPercent(BigDecimal.valueOf(request.getAccuracyScore()));
                if (request.getBadgeAwarded() == null) {
                    if (request.getAccuracyScore() >= 90.0) session.setBadgeAwarded("GOLD");
                    else if (request.getAccuracyScore() >= 80.0) session.setBadgeAwarded("SILVER");
                    else if (request.getAccuracyScore() >= 70.0) session.setBadgeAwarded("BRONZE");
                } else {
                    session.setBadgeAwarded(request.getBadgeAwarded());
                }
            }
            if (request.getTotalAttempts() != null) session.setTotalAttempts(request.getTotalAttempts());
            if (request.getCorrectCount() != null) session.setCorrectCount(request.getCorrectCount());
            if (request.getPointsEarned() != null) session.setPointsEarned(request.getPointsEarned());
        }

        session = sessionRepository.save(session);

        Map<String, Object> resp = new HashMap<>();
        resp.put("sessionId", session.getId().toString());
        resp.put("lessonPairId", session.getLessonPairId());
        resp.put("sessionStatus", session.getSessionStatus());
        resp.put("accuracyPercent", session.getAccuracyPercent());
        resp.put("badgeAwarded", session.getBadgeAwarded());
        resp.put("pointsEarned", session.getPointsEarned());
        return ResponseEntity.ok(resp);
    }

    @PostMapping("/sessions/{sessionId}/abandon")
    public ResponseEntity<Map<String, Object>> abandonSession(
            @PathVariable String sessionId,
            Principal principal) {
        UUID sessionUuid = null;
        try {
            sessionUuid = UUID.fromString(sessionId);
        } catch (Exception ignored) {}

        if (sessionUuid != null) {
            cumulativeReviewService.abandonCumulativeReviewSession(sessionUuid);
        }
        return ResponseEntity.ok(Map.of("status", "ABANDONED"));
    }

    @GetMapping("/sessions")
    public ResponseEntity<List<CumulativeReviewSession>> getSessions(Principal principal) {
        UUID learnerId = UUID.fromString(principal.getName());
        return ResponseEntity.ok(cumulativeReviewService.getLearnerSessions(learnerId));
    }
}
