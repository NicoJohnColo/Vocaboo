package com.vocaboo.controller;

import com.vocaboo.dto.request.RetrievalSubmissionRequest;
import com.vocaboo.service.RetrievalActivityService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/retrieval")
@RequiredArgsConstructor
public class RetrievalController {

    private final RetrievalActivityService retrievalService;

    @GetMapping("/session/{sessionId}/questions")
    public ResponseEntity<List<Map<String, Object>>> getSessionQuestions(
            @PathVariable("sessionId") UUID sessionId) {
        return ResponseEntity.ok(retrievalService.generateSessionQuestions(sessionId));
    }

    @PostMapping("/session/{sessionId}/submit")
    public ResponseEntity<Map<String, Object>> submitAnswer(
            @PathVariable("sessionId") UUID sessionId,
            @RequestBody RetrievalSubmissionRequest request) {
        return ResponseEntity.ok(retrievalService.submitAnswer(sessionId, request.getWordId(), request.isCorrect(), request.getWrongAnswer(), request.getActivityFormat()));
    }
}
