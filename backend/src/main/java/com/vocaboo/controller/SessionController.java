package com.vocaboo.controller;

import com.vocaboo.dto.request.ProgressRequest;
import com.vocaboo.dto.response.ProgressResponse;
import com.vocaboo.service.WordProgressService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/sessions")
@RequiredArgsConstructor
public class SessionController {

    private final WordProgressService progressService;

    @PatchMapping("/{sessionId}/progress")
    public ResponseEntity<ProgressResponse> updateProgress(
            @PathVariable("sessionId") UUID sessionId,
            @Valid @RequestBody ProgressRequest request) {
        return ResponseEntity.ok(progressService.updateProgress(sessionId, request));
    }
}
