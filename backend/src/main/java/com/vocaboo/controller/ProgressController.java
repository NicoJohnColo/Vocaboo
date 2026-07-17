package com.vocaboo.controller;

import com.vocaboo.dto.request.PracticeResultRequest;
import com.vocaboo.dto.request.PracticeSessionRequest;
import com.vocaboo.dto.response.LearnerProgressResponse;
import com.vocaboo.dto.response.PracticeResultResponse;
import com.vocaboo.dto.response.PracticeSessionResponse;
import com.vocaboo.service.PracticeSessionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.security.Principal;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class ProgressController {

    private final PracticeSessionService practiceSessionService;

    @PostMapping("/practice-sessions")
    public ResponseEntity<PracticeSessionResponse> startSession(
            @Valid @RequestBody PracticeSessionRequest request,
            Principal principal) {
        UUID learnerId = request.getLearnerId();
        if (learnerId == null && principal != null) {
            learnerId = UUID.fromString(principal.getName());
        }
        if (learnerId == null) {
            throw new IllegalArgumentException("Learner ID is required");
        }
        return ResponseEntity.ok(practiceSessionService.start(learnerId, request.getLessonId(), request.getModuleNumber()));
    }

    @PostMapping("/practice-sessions/{id}/results")
    public ResponseEntity<PracticeResultResponse> recordResult(
            @PathVariable("id") UUID sessionId,
            @Valid @RequestBody PracticeResultRequest request) {
        return ResponseEntity.ok(practiceSessionService.record(sessionId, request.getWordId(), request.getIsCorrect()));
    }

    @PostMapping("/practice-sessions/{id}/end")
    public ResponseEntity<PracticeSessionResponse> endSession(@PathVariable("id") UUID sessionId) {
        return ResponseEntity.ok(practiceSessionService.end(sessionId));
    }

    @GetMapping("/learners/{id}/progress")
    public ResponseEntity<LearnerProgressResponse> getProgress(@PathVariable("id") UUID learnerId) {
        return ResponseEntity.ok(practiceSessionService.getProgress(learnerId));
    }
}
