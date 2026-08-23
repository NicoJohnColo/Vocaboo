package com.vocaboo.dto.response;

import lombok.*;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DashboardResponse {
    private int completedLessons;
    private int totalLessons;
    private double averageMasteryScore;
    private int totalPronunciationAttempts;
    private int correctPronunciationAttempts;
    private List<SandboxSessionDetails> sandboxHistory;
    private int cumulativeReviewsCompleted;
    private String bestCumulativeBadge;
    private List<CumulativeSessionDetails> cumulativeReviewHistory;

    // ── New: Per-category score breakdown ──────────────────────────────────────
    private List<CategoryBreakdown> categoryBreakdowns;

    // ── Nested DTOs ────────────────────────────────────────────────────────────

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class CategoryBreakdown {
        /** UUID string of the VocabularyCategory */
        private String categoryId;
        /** Human-readable category name, e.g. "Animals" */
        private String categoryName;
        /**
         * List of lessons that the cumulative review for this category covers,
         * each with their independent Module 2+3 accuracy.
         */
        private List<LessonScoreDetail> lessons;
        /**
         * Independent Cumulative Review (Module 4) accuracy percentage.
         * Taken from the latest COMPLETED CumulativeReviewSession for the
         * lesson pair in this category. NOT blended with the 60/40 formula.
         */
        private Double cumulativeAccuracy;
        /**
         * Simple average of all lesson accuracies + cumulativeAccuracy.
         * Each value is weighted equally.
         * e.g. avg(80, 96, 100) = 92%
         */
        private Double overallAccuracy;
        /** Badge from the best completed cumulative session (GOLD/SILVER/BRONZE) */
        private String bestCumulativeBadge;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class LessonScoreDetail {
        private String lessonId;
        private String lessonTitle;
        private int lessonOrder;
        /**
         * Average of Module 2 + Module 3 lesson_module_scores for this lesson.
         * Null if the learner has not yet started this lesson.
         */
        private Double lessonAccuracy;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class CumulativeSessionDetails {
        private UUID sessionId;
        private String lessonPairId;
        private String sessionStatus;
        private Double accuracyPercent;
        private String badgeAwarded;
        private Integer pointsEarned;
        private Object pointsBreakdown;
        private OffsetDateTime startTime;
        private OffsetDateTime endTime;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class SandboxSessionDetails {
        private UUID sessionId;
        private String topic;
        private String customWord;
        private Double masteryScore;
        private OffsetDateTime completedAt;
        private List<String> words;
    }
}
