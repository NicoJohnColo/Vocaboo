package com.vocaboo.controller;

import com.vocaboo.dto.request.PronunciationEvaluationRequest;
import com.vocaboo.dto.response.PronunciationAttemptResponse;
import com.vocaboo.service.PronunciationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.security.Principal;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/pronunciation")
@RequiredArgsConstructor
public class PronunciationController {

    private final PronunciationService pronunciationService;

    @PostMapping("/evaluate")
    public ResponseEntity<PronunciationAttemptResponse> evaluate(
            @Valid @RequestBody PronunciationEvaluationRequest request,
            Principal principal) {
        UUID learnerId = UUID.fromString(principal.getName());
        return ResponseEntity.ok(pronunciationService.evaluate(learnerId, request));
    }
}
