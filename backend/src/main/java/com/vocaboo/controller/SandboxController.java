package com.vocaboo.controller;

import com.vocaboo.entity.SandboxSession;
import com.vocaboo.entity.SandboxWord;
import com.vocaboo.entity.SandboxWordProgress;
import com.vocaboo.dto.response.SandboxLessonResponse;
import com.vocaboo.repository.SandboxWordRepository;
import com.vocaboo.service.SandboxService;
import com.vocaboo.service.SandboxSessionGenerationResult;
import lombok.Builder;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/sandbox")
@RequiredArgsConstructor
public class SandboxController {

    private final SandboxService sandboxService;
    private final SandboxWordRepository sandboxWordRepository;

    @Data
    public static class SandboxGenerateRequest {
        private String topic;
        private String customWord;
    }

    @Data
    public static class SandboxProgressRequest {
        private UUID wordId;
        private Integer moduleNumber;
        private Integer stepCompleted;
        private String status;
    }

    @Data
    public static class SandboxCompletionRequest {
        private Double score;
    }

    @Data
    @Builder
    public static class SandboxSessionResponse {
        private SandboxSession session;
        private List<SandboxLessonResponse> words;
    }

    @PostMapping("/generate")
    public ResponseEntity<SandboxSessionResponse> generateSession(@RequestBody SandboxGenerateRequest request, Principal principal) {
        UUID learnerId = UUID.fromString(principal.getName());
        SandboxSessionGenerationResult generated = sandboxService.createSession(learnerId, request.getTopic(), request.getCustomWord());

        return ResponseEntity.ok(SandboxSessionResponse.builder()
            .session(generated.getSession())
            .words(List.of(generated.getLesson()))
                .build());
    }

    @PostMapping("/sessions/{sessionId}/progress")
    public ResponseEntity<SandboxWordProgress> updateProgress(
            @PathVariable UUID sessionId,
            @RequestBody SandboxProgressRequest request) {
        SandboxWordProgress progress = sandboxService.updateProgress(
                sessionId,
                request.getWordId(),
                request.getModuleNumber(),
                request.getStepCompleted(),
                request.getStatus()
        );
        return ResponseEntity.ok(progress);
    }

    @PostMapping("/sessions/{sessionId}/complete")
    public ResponseEntity<SandboxSession> completeSession(
            @PathVariable UUID sessionId,
            @RequestBody SandboxCompletionRequest request) {
        SandboxSession session = sandboxService.completeSession(sessionId, request.getScore());
        return ResponseEntity.ok(session);
    }

    @GetMapping("/history")
    public ResponseEntity<List<SandboxSession>> getHistory(Principal principal) {
        UUID learnerId = UUID.fromString(principal.getName());
        List<SandboxSession> history = sandboxService.getHistory(learnerId);
        return ResponseEntity.ok(history);
    }
}
