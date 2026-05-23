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
    }

    @Data
    public static class ReviewCompletionRequest {
        private UUID lessonId;
        private UUID sessionId;
        private Double score;
    }

    @Data
    public static class CategoryReviewCompletionRequest {
        private UUID categoryId;
        private UUID sessionId;
        private Double score;
    }

    @PostMapping("/lessons/{lessonId}/review/start")
    public ResponseEntity<ReviewSession> startReview(@PathVariable UUID lessonId, Principal principal) {
        UUID learnerId = UUID.fromString(principal.getName());
        ReviewSession session = reviewService.startReview(learnerId, lessonId);
        return ResponseEntity.ok(session);
    }

    @PostMapping("/progress/review-items")
    public ResponseEntity<ReviewItem> submitReviewItem(@RequestBody ReviewItemRequest request) {
        ReviewItem item = reviewService.saveReviewItem(request.getSessionId(), request.getWordId(), request.getIsCorrect());
        return ResponseEntity.ok(item);
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
