package com.vocaboo.controller;

import com.vocaboo.entity.SentenceTemplate;
import com.vocaboo.service.SentenceContextualService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/sentence")
@RequiredArgsConstructor
public class SentenceController {

    private final SentenceContextualService sentenceService;

    @GetMapping("/templates")
    public ResponseEntity<List<SentenceTemplate>> getTemplatesForWord(
            @RequestParam("wordId") UUID wordId) {
        return ResponseEntity.ok(sentenceService.getTemplatesForWord(wordId));
    }

    @PostMapping("/evaluate")
    public ResponseEntity<Map<String, Object>> evaluateSentence(
            @RequestParam("templateId") UUID templateId,
            @RequestBody Map<String, String> body) {
        String assembledSentence = body.get("assembledSentence");
        return ResponseEntity.ok(sentenceService.evaluateSentence(templateId, assembledSentence));
    }
}
