package com.vocaboo.controller;

import com.vocaboo.dto.request.MasteryRequest;
import com.vocaboo.dto.response.CategoryResponse;
import com.vocaboo.dto.response.LessonResponse;
import com.vocaboo.dto.response.LessonWordActivityResponse;
import com.vocaboo.dto.response.MasteryResponse;
import com.vocaboo.dto.response.VocabularyWordResponse;
import com.vocaboo.dto.response.ConfusableWordPairResponse;
import com.vocaboo.service.LessonService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class LessonController {

    private final LessonService lessonService;

    @GetMapping("/categories")
    public ResponseEntity<List<CategoryResponse>> getCategories() {
        return ResponseEntity.ok(lessonService.getCategories());
    }

    @GetMapping("/categories/{id}/lessons")
    public ResponseEntity<List<LessonResponse>> getLessons(
            @PathVariable("id") UUID categoryId,
            Principal principal) {
        UUID learnerId = UUID.fromString(principal.getName());
        return ResponseEntity.ok(lessonService.getLessonsForCategory(categoryId, learnerId));
    }

    @GetMapping("/lessons/{id}/vocabulary")
    public ResponseEntity<List<VocabularyWordResponse>> getVocabulary(@PathVariable("id") UUID lessonId) {
        return ResponseEntity.ok(lessonService.getVocabularyForLesson(lessonId));
    }

    @GetMapping("/categories/{id}/activity")
    public ResponseEntity<List<LessonWordActivityResponse>> getCategoryActivity(@PathVariable("id") UUID categoryId) {
        return ResponseEntity.ok(lessonService.getCategoryActivityForCategory(categoryId));
    }

    @GetMapping("/lessons/{id}/activity")
    public ResponseEntity<List<LessonWordActivityResponse>> getLessonActivity(@PathVariable("id") UUID lessonId) {
        return ResponseEntity.ok(lessonService.getLessonActivityForLesson(lessonId));
    }

    @GetMapping("/lessons/{id}/confusable-pairs")
    public ResponseEntity<List<ConfusableWordPairResponse>> getConfusablePairs(@PathVariable("id") UUID lessonId) {
        return ResponseEntity.ok(lessonService.getConfusablePairsForLesson(lessonId));
    }

    @PostMapping("/mastery")
    public ResponseEntity<MasteryResponse> submitMastery(
            @RequestBody MasteryRequest request,
            Principal principal) {
        UUID learnerId = UUID.fromString(principal.getName());
        return ResponseEntity.ok(lessonService.submitMastery(request, learnerId));
    }
}
