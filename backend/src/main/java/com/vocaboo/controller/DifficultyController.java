package com.vocaboo.controller;

import com.vocaboo.dto.request.DifficultyAdjustmentRequest;
import com.vocaboo.dto.response.DifficultyProgressResponse;
import com.vocaboo.dto.response.ReintroductionResponse;
import com.vocaboo.service.DifficultyAdjustmentService;
import com.vocaboo.service.ReintroductionService;
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
    private final ReintroductionService reintroductionService;

    @GetMapping("/{id}/difficulty")
    public ResponseEntity<DifficultyProgressResponse> getDifficulty(
            @PathVariable("id") UUID wordId,
            @RequestParam(name = "learnerId", required = false) UUID learnerId,
            @RequestParam(name = "moduleNumber", required = false, defaultValue = "2") Integer moduleNumber,
            Principal principal) {
        UUID resolvedLearnerId = resolveLearnerId(learnerId, principal);
        return ResponseEntity.ok(difficultyService.getProgress(resolvedLearnerId, wordId, moduleNumber));
    }

    @PostMapping("/{id}/difficulty/adjust")
    public ResponseEntity<DifficultyProgressResponse> adjustDifficulty(
            @PathVariable("id") UUID wordId,
            @RequestBody DifficultyAdjustmentRequest request,
            @RequestParam(name = "moduleNumber", required = false, defaultValue = "2") Integer moduleNumber,
            Principal principal) {
        UUID resolvedLearnerId = resolveLearnerId(request.getLearnerId(), principal);

        if (request.getAction() != null) {
            String action = request.getAction().toUpperCase();
            if ("INCREMENT".equals(action)) {
                return ResponseEntity.ok(difficultyService.increment(resolvedLearnerId, wordId, moduleNumber));
            } else if ("DECREMENT".equals(action)) {
                return ResponseEntity.ok(difficultyService.decrement(resolvedLearnerId, wordId, moduleNumber));
            } else if ("DIAGNOSTIC_BOOST".equals(action)) {
                return ResponseEntity.ok(difficultyService.diagnosticBoost(resolvedLearnerId, wordId, request.getActivityType(), moduleNumber));
            } else if ("DIAGNOSTIC_FAIL".equals(action)) {
                return ResponseEntity.ok(difficultyService.recordDiagnosticFail(resolvedLearnerId, wordId, request.getActivityType(), moduleNumber));
            } else {
                throw new IllegalArgumentException("Unsupported action override: " + request.getAction());
            }
        }

        if (request.getCorrect() != null) {
            return ResponseEntity.ok(difficultyService.calculateNext(resolvedLearnerId, wordId, request.getCorrect(), moduleNumber, request.getActivityType()));
        }

        throw new IllegalArgumentException("Either action override or correct result is required for adjustment");
    }

    @GetMapping("/{id}/reintroduction")
    public ResponseEntity<ReintroductionResponse> getReintroductionPayload(
            @PathVariable("id") UUID wordId,
            @RequestParam(name = "learnerId", required = false) UUID learnerId,
            Principal principal) {
        UUID resolvedLearnerId = resolveLearnerId(learnerId, principal);
        return ResponseEntity.ok(reintroductionService.buildPayload(resolvedLearnerId, wordId));
    }

    @PostMapping("/{id}/reintroduction/acknowledge")
    public ResponseEntity<DifficultyProgressResponse> acknowledgeReintroduction(
            @PathVariable("id") UUID wordId,
            @RequestParam(name = "learnerId", required = false) UUID learnerId,
            @RequestParam(name = "moduleNumber", required = false, defaultValue = "2") Integer moduleNumber,
            Principal principal) {
        UUID resolvedLearnerId = resolveLearnerId(learnerId, principal);
        return ResponseEntity.ok(reintroductionService.acknowledgeUnderstanding(resolvedLearnerId, wordId, moduleNumber));
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
