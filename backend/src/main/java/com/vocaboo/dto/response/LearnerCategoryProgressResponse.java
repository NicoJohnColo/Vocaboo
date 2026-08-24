package com.vocaboo.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LearnerCategoryProgressResponse {
    private UUID categoryId;
    private String categoryName;
    private Integer totalLessons;
    private Integer completedLessons;
    private BigDecimal categoryAccuracy;

    public String getCategoryName() { return categoryName; }

    public static LearnerCategoryProgressResponseBuilder builder() { return new LearnerCategoryProgressResponseBuilder(); }

    public static class LearnerCategoryProgressResponseBuilder {
        private UUID categoryId;
        private String categoryName;
        private Integer totalLessons;
        private Integer completedLessons;
        private BigDecimal categoryAccuracy;

        public LearnerCategoryProgressResponseBuilder categoryId(UUID categoryId) { this.categoryId = categoryId; return this; }
        public LearnerCategoryProgressResponseBuilder categoryName(String categoryName) { this.categoryName = categoryName; return this; }
        public LearnerCategoryProgressResponseBuilder totalLessons(Integer totalLessons) { this.totalLessons = totalLessons; return this; }
        public LearnerCategoryProgressResponseBuilder completedLessons(Integer completedLessons) { this.completedLessons = completedLessons; return this; }
        public LearnerCategoryProgressResponseBuilder categoryAccuracy(BigDecimal categoryAccuracy) { this.categoryAccuracy = categoryAccuracy; return this; }

        public LearnerCategoryProgressResponse build() {
            LearnerCategoryProgressResponse r = new LearnerCategoryProgressResponse();
            r.categoryId = this.categoryId;
            r.categoryName = this.categoryName;
            r.totalLessons = this.totalLessons;
            r.completedLessons = this.completedLessons;
            r.categoryAccuracy = this.categoryAccuracy;
            return r;
        }
    }
}
