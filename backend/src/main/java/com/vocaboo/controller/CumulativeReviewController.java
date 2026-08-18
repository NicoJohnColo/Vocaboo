package com.vocaboo.controller;

import com.vocaboo.entity.CumulativeReviewSession;
import com.vocaboo.service.CumulativeReviewService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/cumulative-review")
@RequiredArgsConstructor
public class CumulativeReviewController {

    private final CumulativeReviewService cumulativeReviewService;

    @PostMapping("/start")
    public ResponseEntity<CumulativeReviewSession> startSession(
            @RequestParam UUID learnerId,
            @RequestParam String lessonPairId) {
        try {
            return ResponseEntity.ok(cumulativeReviewService.startCumulativeReviewSession(learnerId, lessonPairId));
        } catch (IllegalStateException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @GetMapping("/{sessionId}/questions")
    public ResponseEntity<List<Map<String, Object>>> getSessionQuestions(@PathVariable UUID sessionId) {
        return ResponseEntity.ok(cumulativeReviewService.generateSessionQuestions(sessionId));
    }

    @GetMapping("/{sessionId}/sentences")
    public ResponseEntity<List<com.vocaboo.entity.CrossLessonSentence>> getSessionSentences(@PathVariable UUID sessionId) {
        return ResponseEntity.ok(cumulativeReviewService.getSessionSentences(sessionId));
    }

    @PostMapping("/{sessionId}/record")
    public ResponseEntity<Void> recordAnswer(
            @PathVariable UUID sessionId,
            @RequestParam UUID wordId,
            @RequestParam String activityType,
            @RequestParam boolean correct,
            @RequestParam(required = false) UUID crossLessonSentenceId,
            @RequestParam(defaultValue = "1") int attemptNumber) {
        
        cumulativeReviewService.recordCumulativeReviewAnswer(
                sessionId, wordId, activityType, correct, crossLessonSentenceId, attemptNumber);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/{sessionId}/complete")
    public ResponseEntity<CumulativeReviewSession> completeSession(@PathVariable UUID sessionId) {
        return ResponseEntity.ok(cumulativeReviewService.completeCumulativeReviewSession(sessionId));
    }

    @PostMapping("/{sessionId}/abandon")
    public ResponseEntity<CumulativeReviewSession> abandonSession(@PathVariable UUID sessionId) {
        return ResponseEntity.ok(cumulativeReviewService.abandonCumulativeReviewSession(sessionId));
    }

    @GetMapping("/learners/{learnerId}/sessions")
    public ResponseEntity<List<CumulativeReviewSession>> getLearnerSessions(@PathVariable UUID learnerId) {
        return ResponseEntity.ok(cumulativeReviewService.getLearnerSessions(learnerId));
    }

    @GetMapping("/learners/{learnerId}/summary")
    public ResponseEntity<Map<String, Object>> getLearnerSummary(@PathVariable UUID learnerId) {
        return ResponseEntity.ok(cumulativeReviewService.getLearnerCumulativeSummary(learnerId));
    }
}
