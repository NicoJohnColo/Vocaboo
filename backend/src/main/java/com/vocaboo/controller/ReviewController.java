package com.vocaboo.controller;

import com.vocaboo.entity.LearnerLessonStatus;
import com.vocaboo.entity.ReviewItem;
import com.vocaboo.entity.ReviewSession;
import com.vocaboo.dto.response.CategoryReviewResponse;
import com.vocaboo.service.ReviewService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class ReviewController {

    private final ReviewService reviewService;

    @Data
    public static class ReviewItemRequest {
        private UUID sessionId;
        private UUID wordId;
        private Boolean isCorrect;

        public UUID getSessionId() { return sessionId; }
        public UUID getWordId() { return wordId; }
        public Boolean getIsCorrect() { return isCorrect; }
    }

    @Data
    public static class ReviewCompletionRequest {
        private UUID lessonId;
        private UUID sessionId;
        private Double score;

        public UUID getLessonId() { return lessonId; }
        public UUID getSessionId() { return sessionId; }
        public Double getScore() { return score; }
    }

    @Data
    public static class CategoryReviewCompletionRequest {
        private UUID categoryId;
        private UUID sessionId;
        private Double score;

        public UUID getCategoryId() { return categoryId; }
        public UUID getSessionId() { return sessionId; }
        public Double getScore() { return score; }
    }

    @Data
    public static class ModuleScoreRequest {
        private UUID lessonId;
        private Integer moduleNumber;
        private Integer correctCount;
        private Integer totalCount;
        private Double score;
        private Integer timeSeconds;

        public UUID getLessonId() { return lessonId; }
        public Integer getModuleNumber() { return moduleNumber; }
        public Integer getCorrectCount() { return correctCount; }
        public Integer getTotalCount() { return totalCount; }
        public Double getScore() { return score; }
        public Integer getTimeSeconds() { return timeSeconds; }
    }

    @Data
    public static class ModuleTimeRequest {
        private UUID lessonId;
        private UUID sessionId;
        private Integer moduleNumber;
        private Integer timeSeconds;
        private Boolean isPartial;

        public UUID getLessonId() { return lessonId; }
        public UUID getSessionId() { return sessionId; }
        public Integer getModuleNumber() { return moduleNumber; }
        public Integer getTimeSeconds() { return timeSeconds; }
        public Boolean getIsPartial() { return isPartial; }
    }

    @PostMapping("/lessons/{lessonId}/review/start")
    public ResponseEntity<ReviewSession> startReview(@PathVariable UUID lessonId, Principal principal) {
        UUID learnerId = UUID.fromString(principal.getName());
        ReviewSession session = reviewService.startReview(learnerId, lessonId);
        return ResponseEntity.ok(session);
    }

    @GetMapping("/lessons/{lessonId}/module4-review")
    public ResponseEntity<java.util.List<java.util.Map<String, Object>>> getModule4Review(
            @PathVariable("lessonId") UUID lessonId,
            @RequestParam(value = "learnerId", required = false) UUID learnerId,
            Principal principal) {
        UUID targetLearnerId = learnerId;
        if (targetLearnerId == null && principal != null) {
            targetLearnerId = UUID.fromString(principal.getName());
        }
        if (targetLearnerId == null) {
            throw new IllegalArgumentException("Learner ID is required");
        }
        return ResponseEntity.ok(reviewService.generateModule4ReviewPayload(targetLearnerId, lessonId));
    }

    @PostMapping("/progress/review-items")
    public ResponseEntity<ReviewItem> submitReviewItem(@RequestBody ReviewItemRequest request) {
        ReviewItem item = reviewService.saveReviewItem(request.getSessionId(), request.getWordId(), request.getIsCorrect());
        return ResponseEntity.ok(item);
    }

    @PostMapping("/progress/module-score")
    public ResponseEntity<Void> saveModuleScore(@RequestBody ModuleScoreRequest request, Principal principal) {
        UUID learnerId = UUID.fromString(principal.getName());
        reviewService.saveModuleScore(
                learnerId,
                request.getLessonId(),
                request.getModuleNumber(),
                request.getCorrectCount(),
                request.getTotalCount(),
                request.getScore(),
                request.getTimeSeconds()
        );
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/progress/module-time")
    public ResponseEntity<Void> recordModuleTime(@RequestBody ModuleTimeRequest request, Principal principal) {
        UUID learnerId = UUID.fromString(principal.getName());
        reviewService.savePartialModuleTime(
                learnerId,
                request.getLessonId(),
                request.getSessionId(),
                request.getModuleNumber(),
                request.getTimeSeconds()
        );
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/progress/lesson-completion")
    public ResponseEntity<LearnerLessonStatus> finalizeReview(@RequestBody ReviewCompletionRequest request, Principal principal) {
        UUID learnerId = UUID.fromString(principal.getName());
        LearnerLessonStatus status = reviewService.completeReview(learnerId, request.getLessonId(), request.getSessionId(), request.getScore());
        return ResponseEntity.ok(status);
    }

    @PostMapping("/progress/category-completion")
    public ResponseEntity<CategoryReviewResponse> finalizeCategoryReview(@RequestBody CategoryReviewCompletionRequest request, Principal principal) {
        UUID learnerId = UUID.fromString(principal.getName());
        CategoryReviewResponse response = reviewService.completeCategoryReview(learnerId, request.getCategoryId(), request.getSessionId(), request.getScore());
        return ResponseEntity.ok(response);
    }
}
