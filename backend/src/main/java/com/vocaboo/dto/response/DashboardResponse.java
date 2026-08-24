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
    private List<CategoryBreakdown> categoryBreakdowns;

    public static DashboardResponseBuilder builder() { return new DashboardResponseBuilder(); }

    public static class DashboardResponseBuilder {
        private int completedLessons;
        private int totalLessons;
        private double averageMasteryScore;
        private int totalPronunciationAttempts;
        private int correctPronunciationAttempts;
        private List<SandboxSessionDetails> sandboxHistory;
        private int cumulativeReviewsCompleted;
        private String bestCumulativeBadge;
        private List<CumulativeSessionDetails> cumulativeReviewHistory;
        private List<CategoryBreakdown> categoryBreakdowns;

        public DashboardResponseBuilder completedLessons(int completedLessons) { this.completedLessons = completedLessons; return this; }
        public DashboardResponseBuilder totalLessons(int totalLessons) { this.totalLessons = totalLessons; return this; }
        public DashboardResponseBuilder averageMasteryScore(double averageMasteryScore) { this.averageMasteryScore = averageMasteryScore; return this; }
        public DashboardResponseBuilder totalPronunciationAttempts(int totalPronunciationAttempts) { this.totalPronunciationAttempts = totalPronunciationAttempts; return this; }
        public DashboardResponseBuilder correctPronunciationAttempts(int correctPronunciationAttempts) { this.correctPronunciationAttempts = correctPronunciationAttempts; return this; }
        public DashboardResponseBuilder sandboxHistory(List<SandboxSessionDetails> sandboxHistory) { this.sandboxHistory = sandboxHistory; return this; }
        public DashboardResponseBuilder cumulativeReviewsCompleted(int cumulativeReviewsCompleted) { this.cumulativeReviewsCompleted = cumulativeReviewsCompleted; return this; }
        public DashboardResponseBuilder bestCumulativeBadge(String bestCumulativeBadge) { this.bestCumulativeBadge = bestCumulativeBadge; return this; }
        public DashboardResponseBuilder cumulativeReviewHistory(List<CumulativeSessionDetails> cumulativeReviewHistory) { this.cumulativeReviewHistory = cumulativeReviewHistory; return this; }
        public DashboardResponseBuilder categoryBreakdowns(List<CategoryBreakdown> categoryBreakdowns) { this.categoryBreakdowns = categoryBreakdowns; return this; }

        public DashboardResponse build() {
            DashboardResponse r = new DashboardResponse();
            r.completedLessons = this.completedLessons;
            r.totalLessons = this.totalLessons;
            r.averageMasteryScore = this.averageMasteryScore;
            r.totalPronunciationAttempts = this.totalPronunciationAttempts;
            r.correctPronunciationAttempts = this.correctPronunciationAttempts;
            r.sandboxHistory = this.sandboxHistory;
            r.cumulativeReviewsCompleted = this.cumulativeReviewsCompleted;
            r.bestCumulativeBadge = this.bestCumulativeBadge;
            r.cumulativeReviewHistory = this.cumulativeReviewHistory;
            r.categoryBreakdowns = this.categoryBreakdowns;
            return r;
        }
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class CategoryBreakdown {
        private String categoryId;
        private String categoryName;
        private List<LessonScoreDetail> lessons;
        private Double cumulativeAccuracy;
        private Double overallAccuracy;
        private String bestCumulativeBadge;

        public static CategoryBreakdownBuilder builder() { return new CategoryBreakdownBuilder(); }

        public static class CategoryBreakdownBuilder {
            private String categoryId;
            private String categoryName;
            private List<LessonScoreDetail> lessons;
            private Double cumulativeAccuracy;
            private Double overallAccuracy;
            private String bestCumulativeBadge;

            public CategoryBreakdownBuilder categoryId(String categoryId) { this.categoryId = categoryId; return this; }
            public CategoryBreakdownBuilder categoryName(String categoryName) { this.categoryName = categoryName; return this; }
            public CategoryBreakdownBuilder lessons(List<LessonScoreDetail> lessons) { this.lessons = lessons; return this; }
            public CategoryBreakdownBuilder cumulativeAccuracy(Double cumulativeAccuracy) { this.cumulativeAccuracy = cumulativeAccuracy; return this; }
            public CategoryBreakdownBuilder overallAccuracy(Double overallAccuracy) { this.overallAccuracy = overallAccuracy; return this; }
            public CategoryBreakdownBuilder bestCumulativeBadge(String bestCumulativeBadge) { this.bestCumulativeBadge = bestCumulativeBadge; return this; }

            public CategoryBreakdown build() {
                CategoryBreakdown c = new CategoryBreakdown();
                c.categoryId = this.categoryId;
                c.categoryName = this.categoryName;
                c.lessons = this.lessons;
                c.cumulativeAccuracy = this.cumulativeAccuracy;
                c.overallAccuracy = this.overallAccuracy;
                c.bestCumulativeBadge = this.bestCumulativeBadge;
                return c;
            }
        }
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
        private Double lessonAccuracy;

        public static LessonScoreDetailBuilder builder() { return new LessonScoreDetailBuilder(); }

        public static class LessonScoreDetailBuilder {
            private String lessonId;
            private String lessonTitle;
            private int lessonOrder;
            private Double lessonAccuracy;

            public LessonScoreDetailBuilder lessonId(String lessonId) { this.lessonId = lessonId; return this; }
            public LessonScoreDetailBuilder lessonTitle(String lessonTitle) { this.lessonTitle = lessonTitle; return this; }
            public LessonScoreDetailBuilder lessonOrder(int lessonOrder) { this.lessonOrder = lessonOrder; return this; }
            public LessonScoreDetailBuilder lessonAccuracy(Double lessonAccuracy) { this.lessonAccuracy = lessonAccuracy; return this; }

            public LessonScoreDetail build() {
                LessonScoreDetail l = new LessonScoreDetail();
                l.lessonId = this.lessonId;
                l.lessonTitle = this.lessonTitle;
                l.lessonOrder = this.lessonOrder;
                l.lessonAccuracy = this.lessonAccuracy;
                return l;
            }
        }
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

        public static CumulativeSessionDetailsBuilder builder() { return new CumulativeSessionDetailsBuilder(); }

        public static class CumulativeSessionDetailsBuilder {
            private UUID sessionId;
            private String lessonPairId;
            private String sessionStatus;
            private Double accuracyPercent;
            private String badgeAwarded;
            private Integer pointsEarned;
            private Object pointsBreakdown;
            private OffsetDateTime startTime;
            private OffsetDateTime endTime;

            public CumulativeSessionDetailsBuilder sessionId(UUID sessionId) { this.sessionId = sessionId; return this; }
            public CumulativeSessionDetailsBuilder lessonPairId(String lessonPairId) { this.lessonPairId = lessonPairId; return this; }
            public CumulativeSessionDetailsBuilder sessionStatus(String sessionStatus) { this.sessionStatus = sessionStatus; return this; }
            public CumulativeSessionDetailsBuilder accuracyPercent(Double accuracyPercent) { this.accuracyPercent = accuracyPercent; return this; }
            public CumulativeSessionDetailsBuilder badgeAwarded(String badgeAwarded) { this.badgeAwarded = badgeAwarded; return this; }
            public CumulativeSessionDetailsBuilder pointsEarned(Integer pointsEarned) { this.pointsEarned = pointsEarned; return this; }
            public CumulativeSessionDetailsBuilder pointsBreakdown(Object pointsBreakdown) { this.pointsBreakdown = pointsBreakdown; return this; }
            public CumulativeSessionDetailsBuilder startTime(OffsetDateTime startTime) { this.startTime = startTime; return this; }
            public CumulativeSessionDetailsBuilder endTime(OffsetDateTime endTime) { this.endTime = endTime; return this; }

            public CumulativeSessionDetails build() {
                CumulativeSessionDetails c = new CumulativeSessionDetails();
                c.sessionId = this.sessionId;
                c.lessonPairId = this.lessonPairId;
                c.sessionStatus = this.sessionStatus;
                c.accuracyPercent = this.accuracyPercent;
                c.badgeAwarded = this.badgeAwarded;
                c.pointsEarned = this.pointsEarned;
                c.pointsBreakdown = this.pointsBreakdown;
                c.startTime = this.startTime;
                c.endTime = this.endTime;
                return c;
            }
        }
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

        public static SandboxSessionDetailsBuilder builder() { return new SandboxSessionDetailsBuilder(); }

        public static class SandboxSessionDetailsBuilder {
            private UUID sessionId;
            private String topic;
            private String customWord;
            private Double masteryScore;
            private OffsetDateTime completedAt;
            private List<String> words;

            public SandboxSessionDetailsBuilder sessionId(UUID sessionId) { this.sessionId = sessionId; return this; }
            public SandboxSessionDetailsBuilder topic(String topic) { this.topic = topic; return this; }
            public SandboxSessionDetailsBuilder customWord(String customWord) { this.customWord = customWord; return this; }
            public SandboxSessionDetailsBuilder masteryScore(Double masteryScore) { this.masteryScore = masteryScore; return this; }
            public SandboxSessionDetailsBuilder completedAt(OffsetDateTime completedAt) { this.completedAt = completedAt; return this; }
            public SandboxSessionDetailsBuilder words(List<String> words) { this.words = words; return this; }

            public SandboxSessionDetails build() {
                SandboxSessionDetails s = new SandboxSessionDetails();
                s.sessionId = this.sessionId;
                s.topic = this.topic;
                s.customWord = this.customWord;
                s.masteryScore = this.masteryScore;
                s.completedAt = this.completedAt;
                s.words = this.words;
                return s;
            }
        }
    }
}
