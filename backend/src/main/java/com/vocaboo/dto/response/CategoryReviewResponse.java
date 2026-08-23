package com.vocaboo.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CategoryReviewResponse {
    private UUID categoryId;
    private Double score;
    private boolean passed;
    private UUID nextCategoryId;

    public static CategoryReviewResponseBuilder builder() { return new CategoryReviewResponseBuilder(); }

    public static class CategoryReviewResponseBuilder {
        private UUID categoryId;
        private Double score;
        private boolean passed;
        private UUID nextCategoryId;

        public CategoryReviewResponseBuilder categoryId(UUID categoryId) { this.categoryId = categoryId; return this; }
        public CategoryReviewResponseBuilder score(Double score) { this.score = score; return this; }
        public CategoryReviewResponseBuilder passed(boolean passed) { this.passed = passed; return this; }
        public CategoryReviewResponseBuilder nextCategoryId(UUID nextCategoryId) { this.nextCategoryId = nextCategoryId; return this; }

        public CategoryReviewResponse build() {
            CategoryReviewResponse r = new CategoryReviewResponse();
            r.categoryId = this.categoryId;
            r.score = this.score;
            r.passed = this.passed;
            r.nextCategoryId = this.nextCategoryId;
            return r;
        }
    }
}