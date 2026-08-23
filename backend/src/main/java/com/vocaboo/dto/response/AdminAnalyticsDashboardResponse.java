package com.vocaboo.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AdminAnalyticsDashboardResponse {

    @JsonProperty("kpis")
    private DashboardKpis kpis;

    @JsonProperty("trends")
    private DashboardTrends trends;

    @JsonProperty("struggling_learners")
    private List<StrugglingLearnerSummary> strugglingLearners;

    @JsonProperty("top_performers")
    private List<TopPerformerSummary> topPerformers;

    @JsonProperty("curriculum_analytics")
    private CurriculumAnalytics curriculumAnalytics;

    // ── Subclasses ──

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class DashboardKpis {
        @JsonProperty("total_learners")
        private long totalLearners;

        @JsonProperty("weekly_active_learners")
        private long weeklyActiveLearners;

        @JsonProperty("avg_accuracy")
        private BigDecimal avgAccuracy;

        @JsonProperty("lessons_completed")
        private long lessonsCompleted;

        @JsonProperty("avg_session_length_seconds")
        private long avgSessionLengthSeconds;

        @JsonProperty("total_words_mastered")
        private long totalWordsMastered;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class DashboardTrends {
        @JsonProperty("accuracy_trends")
        private List<DateValuePoint> accuracyTrends;

        @JsonProperty("completion_trends")
        private List<DateValuePoint> completionTrends;

        @JsonProperty("activity_trends")
        private List<DateValuePoint> activityTrends;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class DateValuePoint {
        @JsonProperty("date")
        private String date; // YYYY-MM-DD

        @JsonProperty("value")
        private Double value;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class StrugglingLearnerSummary {
        @JsonProperty("learner_id")
        private UUID learnerId;

        @JsonProperty("display_name")
        private String displayName;

        @JsonProperty("grade_level")
        private String gradeLevel;

        @JsonProperty("section_name")
        private String sectionName;

        @JsonProperty("overall_accuracy")
        private BigDecimal overallAccuracy;

        @JsonProperty("demerit_points")
        private Integer demeritPoints;

        @JsonProperty("tier_drop_count")
        private Integer tierDropCount;

        @JsonProperty("reasons")
        private List<String> reasons;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class TopPerformerSummary {
        @JsonProperty("learner_id")
        private UUID learnerId;

        @JsonProperty("display_name")
        private String displayName;

        @JsonProperty("grade_level")
        private String gradeLevel;

        @JsonProperty("section_name")
        private String sectionName;

        @JsonProperty("total_points")
        private Integer totalPoints;

        @JsonProperty("overall_accuracy")
        private BigDecimal overallAccuracy;

        @JsonProperty("words_mastered_count")
        private Integer wordsMasteredCount;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class CurriculumAnalytics {
        @JsonProperty("hardest_words")
        private List<HardestWordSummary> hardestWords;

        @JsonProperty("fallback_frequency")
        private List<FallbackWordSummary> fallbackFrequency;

        @JsonProperty("lesson_pass_rates")
        private List<LessonPassRateSummary> lessonPassRates;

        @JsonProperty("cumulative_summary")
        private CumulativeAnalyticsSummary cumulativeSummary;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class CumulativeAnalyticsSummary {
        @JsonProperty("total_sessions_completed")
        private Long totalSessionsCompleted;

        @JsonProperty("avg_retention_score")
        private BigDecimal avgRetentionScore;

        @JsonProperty("perfect_gold_count")
        private Long perfectGoldCount;

        @JsonProperty("gold_count")
        private Long goldCount;

        @JsonProperty("silver_count")
        private Long silverCount;

        @JsonProperty("bronze_count")
        private Long bronzeCount;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class HardestWordSummary {
        @JsonProperty("word_id")
        private UUID wordId;

        @JsonProperty("english_word")
        private String englishWord;

        @JsonProperty("cebuano_meaning")
        private String cebuanoMeaning;

        @JsonProperty("lesson_title")
        private String lessonTitle;

        @JsonProperty("avg_demerits")
        private Double avgDemerits;

        @JsonProperty("total_demerits")
        private Integer totalDemerits;

        @JsonProperty("struggling_learner_count")
        private Integer strugglingLearnerCount;

        @JsonProperty("struggle_percentage")
        private Double strugglePercentage;

        @JsonProperty("curriculum_recommendation")
        private String curriculumRecommendation;

        @JsonProperty("avg_accuracy")
        private BigDecimal avgAccuracy;

        @JsonProperty("total_attempts")
        private Integer totalAttempts;

        @JsonProperty("incorrect_count")
        private Integer incorrectCount;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class FallbackWordSummary {
        @JsonProperty("word_id")
        private UUID wordId;

        @JsonProperty("english_word")
        private String englishWord;

        @JsonProperty("cebuano_meaning")
        private String cebuanoMeaning;

        @JsonProperty("lesson_title")
        private String lessonTitle;

        @JsonProperty("fallback_count")
        private Integer fallbackCount;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class LessonPassRateSummary {
        @JsonProperty("lesson_id")
        private UUID lessonId;

        @JsonProperty("lesson_title")
        private String lessonTitle;

        @JsonProperty("grade_level")
        private String gradeLevel;

        @JsonProperty("completion_rate")
        private BigDecimal completionRate; // percentage of enrolled learners who completed

        @JsonProperty("avg_score")
        private BigDecimal avgScore;

        @JsonProperty("total_completions")
        private Long totalCompletions;
    }
}
