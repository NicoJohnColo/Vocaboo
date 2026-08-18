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

    @GetMapping("/session/{sessionId}/question/{wordId}")
    public ResponseEntity<Map<String, Object>> getSingleQuestion(
            @PathVariable("sessionId") UUID sessionId,
            @PathVariable("wordId") UUID wordId,
            @RequestParam(value = "format", required = false) String format) {
        return ResponseEntity.ok(retrievalService.generateSingleQuestion(sessionId, wordId, format));
    }

    @GetMapping("/session/{sessionId}/diagnostic-question/{wordId}")
    public ResponseEntity<Map<String, Object>> getDiagnosticQuestion(
            @PathVariable("sessionId") UUID sessionId,
            @PathVariable("wordId") UUID wordId) {
        return ResponseEntity.ok(retrievalService.generateDiagnosticQuestion(sessionId, wordId));
    }

    @PostMapping("/session/{sessionId}/submit")
    public ResponseEntity<Map<String, Object>> submitAnswer(
            @PathVariable("sessionId") UUID sessionId,
            @RequestBody RetrievalSubmissionRequest request) {
        return ResponseEntity.ok(retrievalService.submitAnswer(sessionId, request.getWordId(), request.getCorrect(), request.getWrongAnswer(), request.getActivityFormat()));
    }
}
