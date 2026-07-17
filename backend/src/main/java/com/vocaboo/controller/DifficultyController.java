package com.vocaboo.controller;

import com.vocaboo.dto.request.DifficultyAdjustmentRequest;
import com.vocaboo.dto.response.DifficultyProgressResponse;
import com.vocaboo.service.DifficultyAdjustmentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.security.Principal;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/words")
@RequiredArgsConstructor
public class DifficultyController {

    private final DifficultyAdjustmentService difficultyService;

    @GetMapping("/{id}/difficulty")
    public ResponseEntity<DifficultyProgressResponse> getDifficulty(
            @PathVariable("id") UUID wordId,
            @RequestParam(name = "learnerId", required = false) UUID learnerId,
            Principal principal) {
        UUID resolvedLearnerId = resolveLearnerId(learnerId, principal);
        return ResponseEntity.ok(difficultyService.getProgress(resolvedLearnerId, wordId));
    }

    @PostMapping("/{id}/difficulty/adjust")
    public ResponseEntity<DifficultyProgressResponse> adjustDifficulty(
            @PathVariable("id") UUID wordId,
            @RequestBody DifficultyAdjustmentRequest request,
            Principal principal) {
        UUID resolvedLearnerId = resolveLearnerId(request.getLearnerId(), principal);

        if (request.getAction() != null) {
            String action = request.getAction().toUpperCase();
            if ("INCREMENT".equals(action)) {
                return ResponseEntity.ok(difficultyService.increment(resolvedLearnerId, wordId));
            } else if ("DECREMENT".equals(action)) {
                return ResponseEntity.ok(difficultyService.decrement(resolvedLearnerId, wordId));
            } else {
                throw new IllegalArgumentException("Unsupported action override: " + request.getAction());
            }
        }

        if (request.getIsCorrect() != null) {
            return ResponseEntity.ok(difficultyService.calculateNext(resolvedLearnerId, wordId, request.getIsCorrect()));
        }

        throw new IllegalArgumentException("Either action override or isCorrect result is required for adjustment");
    }

    private UUID resolveLearnerId(UUID requestLearnerId, Principal principal) {
        if (requestLearnerId != null) {
            return requestLearnerId;
        }
        if (principal != null) {
            return UUID.fromString(principal.getName());
        }
        throw new IllegalArgumentException("Learner ID is required");
    }
}
