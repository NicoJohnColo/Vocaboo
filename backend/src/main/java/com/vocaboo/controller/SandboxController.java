package com.vocaboo.controller;

import com.vocaboo.dto.response.SandboxLessonResponse;
import com.vocaboo.entity.SandboxModuleScore;
import com.vocaboo.entity.SandboxSession;
import com.vocaboo.entity.SandboxWordProgress;
import com.vocaboo.repository.SandboxWordRepository;
import com.vocaboo.service.SandboxService;
import com.vocaboo.service.SandboxSessionGenerationResult;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Builder;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

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
        @NotBlank
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
    public static class SandboxModuleScoreRequest {
        @NotNull
        private Integer moduleNumber;
        private Integer correctCount;
        private Integer totalCount;
        private Double score;
    }

    @Data
    public static class SandboxCompletionRequest {
        @NotNull
        private Double score;
    }

    @Data
    @Builder
    public static class SandboxSessionResponse {
        private SandboxSession session;
        private List<SandboxLessonResponse> words;
    }

    @PostMapping("/generate")
    public ResponseEntity<SandboxSessionResponse> generateSession(@Valid @RequestBody SandboxGenerateRequest request, Principal principal) {
        UUID learnerId = UUID.fromString(principal.getName());
        SandboxSessionGenerationResult generated = sandboxService.createSession(learnerId, request.getCustomWord());

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

    @PostMapping("/sessions/{sessionId}/module-score")
    public ResponseEntity<SandboxModuleScore> saveModuleScore(
            @PathVariable UUID sessionId,
            @Valid @RequestBody SandboxModuleScoreRequest request) {
        SandboxModuleScore score = sandboxService.saveModuleScore(
                sessionId,
                request.getModuleNumber(),
                request.getCorrectCount(),
                request.getTotalCount(),
                request.getScore()
        );
        return ResponseEntity.ok(score);
    }

    @PostMapping("/sessions/{sessionId}/complete")
    public ResponseEntity<SandboxSession> completeSession(
            @PathVariable UUID sessionId,
            @Valid @RequestBody SandboxCompletionRequest request) {
        SandboxSession session = sandboxService.completeSession(sessionId, request.getScore());
        return ResponseEntity.ok(session);
    }

    @GetMapping("/sessions/{sessionId}/module-scores")
    public ResponseEntity<List<SandboxModuleScore>> getModuleScores(@PathVariable UUID sessionId) {
        return ResponseEntity.ok(sandboxService.getModuleScores(sessionId));
    }

    @GetMapping("/history")
    public ResponseEntity<List<SandboxSession>> getHistory(Principal principal) {
        UUID learnerId = UUID.fromString(principal.getName());
        List<SandboxSession> history = sandboxService.getHistory(learnerId);
        return ResponseEntity.ok(history);
    }
}
