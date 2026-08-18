package com.vocaboo.controller;

import com.vocaboo.dto.request.MasteryRequest;
import com.vocaboo.dto.response.CategoryResponse;
import com.vocaboo.dto.response.LessonResponse;
import com.vocaboo.dto.response.LessonWordActivityResponse;
import com.vocaboo.dto.response.MasteryResponse;
import com.vocaboo.dto.response.VocabularyWordResponse;
import com.vocaboo.dto.response.ConfusableWordPairResponse;
import com.vocaboo.dto.response.LessonMasteryStatusResponse;
import com.vocaboo.dto.response.WordMasterySummaryResponse;
import com.vocaboo.service.LessonService;
import com.vocaboo.service.DifficultyAdjustmentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class LessonController {

    private final LessonService lessonService;
    private final DifficultyAdjustmentService difficultyService;

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
    public ResponseEntity<List<VocabularyWordResponse>> getVocabulary(
            @PathVariable("id") UUID lessonId,
            @RequestParam(value = "partOfSpeech", required = false) String partOfSpeech) {
        return ResponseEntity.ok(lessonService.getVocabularyForLesson(lessonId, partOfSpeech));
    }

    @GetMapping("/lessons/{id}/word-difficulties")
    public ResponseEntity<Map<UUID, String>> getWordDifficulties(
            @PathVariable("id") UUID lessonId,
            @RequestParam(value = "moduleNumber", required = false, defaultValue = "2") Integer moduleNumber,
            Principal principal) {
        UUID learnerId = UUID.fromString(principal.getName());
        return ResponseEntity.ok(difficultyService.getDifficultiesForLesson(learnerId, lessonId, moduleNumber));
    }


    @GetMapping("/categories/{id}/activity")
    public ResponseEntity<List<LessonWordActivityResponse>> getCategoryActivity(@PathVariable("id") UUID categoryId) {
        return ResponseEntity.ok(lessonService.getCategoryActivityForCategory(categoryId));
    }

    @GetMapping("/lessons/{id}/activity")
    public ResponseEntity<List<LessonWordActivityResponse>> getLessonActivity(
            @PathVariable("id") UUID lessonId,
            @RequestParam(value = "partOfSpeech", required = false) String partOfSpeech) {
        return ResponseEntity.ok(lessonService.getLessonActivityForLesson(lessonId, partOfSpeech));
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

    @GetMapping("/lessons/{id}/mastery-status")
    public ResponseEntity<LessonMasteryStatusResponse> getLessonMasteryStatus(
            @PathVariable("id") UUID lessonId,
            @RequestParam(value = "moduleNumber", required = false, defaultValue = "2") Integer moduleNumber,
            Principal principal) {
        UUID learnerId = UUID.fromString(principal.getName());
        return ResponseEntity.ok(lessonService.getLessonMasteryStatus(lessonId, learnerId, moduleNumber));
    }

    /**
     * Returns per-word tier state + Gold/Silver/Bronze rating for the lesson score screen.
     * Always returns all words for the lesson (including unplayed ones as LEARNING / no rating).
     */
    @GetMapping("/lessons/{id}/word-mastery-summary")
    public ResponseEntity<List<WordMasterySummaryResponse>> getWordMasterySummary(
            @PathVariable("id") UUID lessonId,
            Principal principal) {
        UUID learnerId = UUID.fromString(principal.getName());
        return ResponseEntity.ok(difficultyService.getWordMasterySummary(learnerId, lessonId));
    }
}
