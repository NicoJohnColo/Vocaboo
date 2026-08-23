package com.vocaboo.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LearnerLessonProgressResponse {
    private UUID lessonId;
    private String lessonTitle;
    private UUID categoryId;
    private String categoryName;
    private BigDecimal accuracyRate;
    private Integer starsEarned;
    private Integer totalAttempts;
    private OffsetDateTime completedAt;
    private String status; // 'COMPLETED', 'UNLOCKED', 'LOCKED'

    public String getLessonTitle() { return lessonTitle; }
    public UUID getCategoryId() { return categoryId; }
    public String getStatus() { return status; }
    public BigDecimal getAccuracyRate() { return accuracyRate; }

    public static LearnerLessonProgressResponseBuilder builder() { return new LearnerLessonProgressResponseBuilder(); }

    public static class LearnerLessonProgressResponseBuilder {
        private UUID lessonId;
        private String lessonTitle;
        private UUID categoryId;
        private String categoryName;
        private BigDecimal accuracyRate;
        private Integer starsEarned;
        private Integer totalAttempts;
        private OffsetDateTime completedAt;
        private String status;

        public LearnerLessonProgressResponseBuilder lessonId(UUID lessonId) { this.lessonId = lessonId; return this; }
        public LearnerLessonProgressResponseBuilder lessonTitle(String lessonTitle) { this.lessonTitle = lessonTitle; return this; }
        public LearnerLessonProgressResponseBuilder categoryId(UUID categoryId) { this.categoryId = categoryId; return this; }
        public LearnerLessonProgressResponseBuilder categoryName(String categoryName) { this.categoryName = categoryName; return this; }
        public LearnerLessonProgressResponseBuilder accuracyRate(BigDecimal accuracyRate) { this.accuracyRate = accuracyRate; return this; }
        public LearnerLessonProgressResponseBuilder starsEarned(Integer starsEarned) { this.starsEarned = starsEarned; return this; }
        public LearnerLessonProgressResponseBuilder totalAttempts(Integer totalAttempts) { this.totalAttempts = totalAttempts; return this; }
        public LearnerLessonProgressResponseBuilder completedAt(OffsetDateTime completedAt) { this.completedAt = completedAt; return this; }
        public LearnerLessonProgressResponseBuilder status(String status) { this.status = status; return this; }

        public LearnerLessonProgressResponse build() {
            LearnerLessonProgressResponse r = new LearnerLessonProgressResponse();
            r.lessonId = this.lessonId;
            r.lessonTitle = this.lessonTitle;
            r.categoryId = this.categoryId;
            r.categoryName = this.categoryName;
            r.accuracyRate = this.accuracyRate;
            r.starsEarned = this.starsEarned;
            r.totalAttempts = this.totalAttempts;
            r.completedAt = this.completedAt;
            r.status = this.status;
            return r;
        }
    }
}
