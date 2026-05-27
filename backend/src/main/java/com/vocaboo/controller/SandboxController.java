package com.vocaboo.controller;

import com.vocaboo.dto.response.SandboxLessonResponse;
import com.vocaboo.entity.SandboxModuleScore;
import com.vocaboo.dto.response.SandboxModuleScoreResponse;
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
        private com.vocaboo.dto.response.SandboxSessionDto session;
        private List<SandboxLessonResponse> words;
    }

    @PostMapping("/generate")
        public ResponseEntity<SandboxSessionResponse> generateSession(@Valid @RequestBody SandboxGenerateRequest request, Principal principal) {
        UUID learnerId = UUID.fromString(principal.getName());
        SandboxSessionGenerationResult generated = sandboxService.createSession(learnerId, request.getCustomWord());
        com.vocaboo.entity.SandboxSession s = generated.getSession();
        com.vocaboo.dto.response.SandboxSessionDto dto = com.vocaboo.dto.response.SandboxSessionDto.builder()
            .sessionId(s.getSessionId())
            .customWord(s.getCustomWord())
            .masteryScore(s.getMasteryScore())
            .createdAt(s.getCreatedAt())
            .completedAt(s.getCompletedAt())
            .build();

        return ResponseEntity.ok(SandboxSessionResponse.builder()
            .session(dto)
            .words(List.of(generated.getLesson()))
            .build());
    }

    @PostMapping("/sessions/{sessionId}/progress")
            public ResponseEntity<com.vocaboo.dto.response.SandboxWordProgressDto> updateProgress(
                @PathVariable UUID sessionId,
                @RequestBody SandboxProgressRequest request) {
            com.vocaboo.dto.response.SandboxWordProgressDto dto = sandboxService.updateProgress(
                sessionId,
                request.getWordId(),
                request.getModuleNumber(),
                request.getStepCompleted(),
                request.getStatus()
            );
            return ResponseEntity.ok(dto);
            }

    @PostMapping("/sessions/{sessionId}/module-score")
        public ResponseEntity<SandboxModuleScoreResponse> saveModuleScore(
            @PathVariable UUID sessionId,
            @Valid @RequestBody SandboxModuleScoreRequest request) {
        SandboxModuleScore score = sandboxService.saveModuleScore(
            sessionId,
            request.getModuleNumber(),
            request.getCorrectCount(),
            request.getTotalCount(),
            request.getScore()
        );
        SandboxModuleScoreResponse resp = SandboxModuleScoreResponse.builder()
            .scoreId(score.getScoreId())
            .moduleNumber(score.getModuleNumber())
            .correct(score.getCorrect())
            .total(score.getTotal())
            .score(score.getScore())
            .recordedAt(score.getRecordedAt())
            .updatedAt(score.getUpdatedAt())
            .build();
        return ResponseEntity.ok(resp);
        }

    @PostMapping("/sessions/{sessionId}/complete")
    public ResponseEntity<com.vocaboo.dto.response.SandboxSessionDto> completeSession(
            @PathVariable UUID sessionId,
            @Valid @RequestBody SandboxCompletionRequest request) {
        com.vocaboo.entity.SandboxSession session = sandboxService.completeSession(sessionId, request.getScore());
        com.vocaboo.dto.response.SandboxSessionDto dto = com.vocaboo.dto.response.SandboxSessionDto.builder()
                .sessionId(session.getSessionId())
                .customWord(session.getCustomWord())
                .masteryScore(session.getMasteryScore())
                .createdAt(session.getCreatedAt())
                .completedAt(session.getCompletedAt())
                .build();
        return ResponseEntity.ok(dto);
    }

    @GetMapping("/sessions/{sessionId}/module-scores")
    public ResponseEntity<List<SandboxModuleScoreResponse>> getModuleScores(@PathVariable UUID sessionId) {
        List<SandboxModuleScore> scores = sandboxService.getModuleScores(sessionId);
        List<SandboxModuleScoreResponse> resp = scores.stream().map(score -> SandboxModuleScoreResponse.builder()
                .scoreId(score.getScoreId())
                .moduleNumber(score.getModuleNumber())
                .correct(score.getCorrect())
                .total(score.getTotal())
                .score(score.getScore())
                .recordedAt(score.getRecordedAt())
                .updatedAt(score.getUpdatedAt())
                .build()).toList();
        return ResponseEntity.ok(resp);
    }

    @GetMapping("/history")
    public ResponseEntity<List<com.vocaboo.dto.response.SandboxSessionDto>> getHistory(Principal principal) {
        UUID learnerId = UUID.fromString(principal.getName());
        List<com.vocaboo.entity.SandboxSession> history = sandboxService.getHistory(learnerId);
        List<com.vocaboo.dto.response.SandboxSessionDto> dto = history.stream().map(s -> com.vocaboo.dto.response.SandboxSessionDto.builder()
                .sessionId(s.getSessionId())
                .customWord(s.getCustomWord())
                .masteryScore(s.getMasteryScore())
                .createdAt(s.getCreatedAt())
                .completedAt(s.getCompletedAt())
                .build()).toList();
        return ResponseEntity.ok(dto);
    }
}
