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

        public static DashboardKpisBuilder builder() { return new DashboardKpisBuilder(); }

        public static class DashboardKpisBuilder {
            private long totalLearners;
            private long weeklyActiveLearners;
            private BigDecimal avgAccuracy;
            private long lessonsCompleted;
            private long avgSessionLengthSeconds;
            private long totalWordsMastered;

            public DashboardKpisBuilder totalLearners(long totalLearners) { this.totalLearners = totalLearners; return this; }
            public DashboardKpisBuilder weeklyActiveLearners(long weeklyActiveLearners) { this.weeklyActiveLearners = weeklyActiveLearners; return this; }
            public DashboardKpisBuilder avgAccuracy(BigDecimal avgAccuracy) { this.avgAccuracy = avgAccuracy; return this; }
            public DashboardKpisBuilder lessonsCompleted(long lessonsCompleted) { this.lessonsCompleted = lessonsCompleted; return this; }
            public DashboardKpisBuilder avgSessionLengthSeconds(long avgSessionLengthSeconds) { this.avgSessionLengthSeconds = avgSessionLengthSeconds; return this; }
            public DashboardKpisBuilder totalWordsMastered(long totalWordsMastered) { this.totalWordsMastered = totalWordsMastered; return this; }

            public DashboardKpis build() {
                DashboardKpis k = new DashboardKpis();
                k.totalLearners = this.totalLearners;
                k.weeklyActiveLearners = this.weeklyActiveLearners;
                k.avgAccuracy = this.avgAccuracy;
                k.lessonsCompleted = this.lessonsCompleted;
                k.avgSessionLengthSeconds = this.avgSessionLengthSeconds;
                k.totalWordsMastered = this.totalWordsMastered;
                return k;
            }
        }
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

        public static DashboardTrendsBuilder builder() { return new DashboardTrendsBuilder(); }

        public static class DashboardTrendsBuilder {
            private List<DateValuePoint> accuracyTrends;
            private List<DateValuePoint> completionTrends;
            private List<DateValuePoint> activityTrends;

            public DashboardTrendsBuilder accuracyTrends(List<DateValuePoint> accuracyTrends) { this.accuracyTrends = accuracyTrends; return this; }
            public DashboardTrendsBuilder completionTrends(List<DateValuePoint> completionTrends) { this.completionTrends = completionTrends; return this; }
            public DashboardTrendsBuilder activityTrends(List<DateValuePoint> activityTrends) { this.activityTrends = activityTrends; return this; }

            public DashboardTrends build() {
                DashboardTrends t = new DashboardTrends();
                t.accuracyTrends = this.accuracyTrends;
                t.completionTrends = this.completionTrends;
                t.activityTrends = this.activityTrends;
                return t;
            }
        }
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

        public Integer getDemeritPoints() {
            return demeritPoints;
        }

        public BigDecimal getOverallAccuracy() {
            return overallAccuracy;
        }

        public static StrugglingLearnerSummaryBuilder builder() { return new StrugglingLearnerSummaryBuilder(); }

        public static class StrugglingLearnerSummaryBuilder {
            private UUID learnerId;
            private String displayName;
            private String gradeLevel;
            private String sectionName;
            private BigDecimal overallAccuracy;
            private Integer demeritPoints;
            private Integer tierDropCount;
            private List<String> reasons;

            public StrugglingLearnerSummaryBuilder learnerId(UUID learnerId) { this.learnerId = learnerId; return this; }
            public StrugglingLearnerSummaryBuilder displayName(String displayName) { this.displayName = displayName; return this; }
            public StrugglingLearnerSummaryBuilder gradeLevel(String gradeLevel) { this.gradeLevel = gradeLevel; return this; }
            public StrugglingLearnerSummaryBuilder sectionName(String sectionName) { this.sectionName = sectionName; return this; }
            public StrugglingLearnerSummaryBuilder overallAccuracy(BigDecimal overallAccuracy) { this.overallAccuracy = overallAccuracy; return this; }
            public StrugglingLearnerSummaryBuilder demeritPoints(Integer demeritPoints) { this.demeritPoints = demeritPoints; return this; }
            public StrugglingLearnerSummaryBuilder tierDropCount(Integer tierDropCount) { this.tierDropCount = tierDropCount; return this; }
            public StrugglingLearnerSummaryBuilder reasons(List<String> reasons) { this.reasons = reasons; return this; }

            public StrugglingLearnerSummary build() {
                StrugglingLearnerSummary s = new StrugglingLearnerSummary();
                s.learnerId = this.learnerId;
                s.displayName = this.displayName;
                s.gradeLevel = this.gradeLevel;
                s.sectionName = this.sectionName;
                s.overallAccuracy = this.overallAccuracy;
                s.demeritPoints = this.demeritPoints;
                s.tierDropCount = this.tierDropCount;
                s.reasons = this.reasons;
                return s;
            }
        }
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

        public Integer getTotalPoints() {
            return totalPoints;
        }

        public BigDecimal getOverallAccuracy() {
            return overallAccuracy;
        }

        public static TopPerformerSummaryBuilder builder() { return new TopPerformerSummaryBuilder(); }

        public static class TopPerformerSummaryBuilder {
            private UUID learnerId;
            private String displayName;
            private String gradeLevel;
            private String sectionName;
            private Integer totalPoints;
            private BigDecimal overallAccuracy;
            private Integer wordsMasteredCount;

            public TopPerformerSummaryBuilder learnerId(UUID learnerId) { this.learnerId = learnerId; return this; }
            public TopPerformerSummaryBuilder displayName(String displayName) { this.displayName = displayName; return this; }
            public TopPerformerSummaryBuilder gradeLevel(String gradeLevel) { this.gradeLevel = gradeLevel; return this; }
            public TopPerformerSummaryBuilder sectionName(String sectionName) { this.sectionName = sectionName; return this; }
            public TopPerformerSummaryBuilder totalPoints(Integer totalPoints) { this.totalPoints = totalPoints; return this; }
            public TopPerformerSummaryBuilder overallAccuracy(BigDecimal overallAccuracy) { this.overallAccuracy = overallAccuracy; return this; }
            public TopPerformerSummaryBuilder wordsMasteredCount(Integer wordsMasteredCount) { this.wordsMasteredCount = wordsMasteredCount; return this; }

            public TopPerformerSummary build() {
                TopPerformerSummary t = new TopPerformerSummary();
                t.learnerId = this.learnerId;
                t.displayName = this.displayName;
                t.gradeLevel = this.gradeLevel;
                t.sectionName = this.sectionName;
                t.totalPoints = this.totalPoints;
                t.overallAccuracy = this.overallAccuracy;
                t.wordsMasteredCount = this.wordsMasteredCount;
                return t;
            }
        }
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

        public static CurriculumAnalyticsBuilder builder() { return new CurriculumAnalyticsBuilder(); }

        public static class CurriculumAnalyticsBuilder {
            private List<HardestWordSummary> hardestWords;
            private List<FallbackWordSummary> fallbackFrequency;
            private List<LessonPassRateSummary> lessonPassRates;
            private CumulativeAnalyticsSummary cumulativeSummary;

            public CurriculumAnalyticsBuilder hardestWords(List<HardestWordSummary> hardestWords) { this.hardestWords = hardestWords; return this; }
            public CurriculumAnalyticsBuilder fallbackFrequency(List<FallbackWordSummary> fallbackFrequency) { this.fallbackFrequency = fallbackFrequency; return this; }
            public CurriculumAnalyticsBuilder lessonPassRates(List<LessonPassRateSummary> lessonPassRates) { this.lessonPassRates = lessonPassRates; return this; }
            public CurriculumAnalyticsBuilder cumulativeSummary(CumulativeAnalyticsSummary cumulativeSummary) { this.cumulativeSummary = cumulativeSummary; return this; }

            public CurriculumAnalytics build() {
                CurriculumAnalytics c = new CurriculumAnalytics();
                c.hardestWords = this.hardestWords;
                c.fallbackFrequency = this.fallbackFrequency;
                c.lessonPassRates = this.lessonPassRates;
                c.cumulativeSummary = this.cumulativeSummary;
                return c;
            }
        }
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

        public static CumulativeAnalyticsSummaryBuilder builder() { return new CumulativeAnalyticsSummaryBuilder(); }

        public static class CumulativeAnalyticsSummaryBuilder {
            private Long totalSessionsCompleted;
            private BigDecimal avgRetentionScore;
            private Long perfectGoldCount;
            private Long goldCount;
            private Long silverCount;
            private Long bronzeCount;

            public CumulativeAnalyticsSummaryBuilder totalSessionsCompleted(Long totalSessionsCompleted) { this.totalSessionsCompleted = totalSessionsCompleted; return this; }
            public CumulativeAnalyticsSummaryBuilder avgRetentionScore(BigDecimal avgRetentionScore) { this.avgRetentionScore = avgRetentionScore; return this; }
            public CumulativeAnalyticsSummaryBuilder perfectGoldCount(Long perfectGoldCount) { this.perfectGoldCount = perfectGoldCount; return this; }
            public CumulativeAnalyticsSummaryBuilder goldCount(Long goldCount) { this.goldCount = goldCount; return this; }
            public CumulativeAnalyticsSummaryBuilder silverCount(Long silverCount) { this.silverCount = silverCount; return this; }
            public CumulativeAnalyticsSummaryBuilder bronzeCount(Long bronzeCount) { this.bronzeCount = bronzeCount; return this; }

            public CumulativeAnalyticsSummary build() {
                CumulativeAnalyticsSummary s = new CumulativeAnalyticsSummary();
                s.totalSessionsCompleted = this.totalSessionsCompleted;
                s.avgRetentionScore = this.avgRetentionScore;
                s.perfectGoldCount = this.perfectGoldCount;
                s.goldCount = this.goldCount;
                s.silverCount = this.silverCount;
                s.bronzeCount = this.bronzeCount;
                return s;
            }
        }
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

        public Double getStrugglePercentage() {
            return strugglePercentage;
        }

        public Integer getTotalDemerits() {
            return totalDemerits;
        }

        public BigDecimal getAvgAccuracy() {
            return avgAccuracy;
        }

        public static HardestWordSummaryBuilder builder() { return new HardestWordSummaryBuilder(); }

        public static class HardestWordSummaryBuilder {
            private UUID wordId;
            private String englishWord;
            private String cebuanoMeaning;
            private String lessonTitle;
            private Double avgDemerits;
            private Integer totalDemerits;
            private Integer strugglingLearnerCount;
            private Double strugglePercentage;
            private String curriculumRecommendation;
            private BigDecimal avgAccuracy;
            private Integer totalAttempts;
            private Integer incorrectCount;

            public HardestWordSummaryBuilder wordId(UUID wordId) { this.wordId = wordId; return this; }
            public HardestWordSummaryBuilder englishWord(String englishWord) { this.englishWord = englishWord; return this; }
            public HardestWordSummaryBuilder cebuanoMeaning(String cebuanoMeaning) { this.cebuanoMeaning = cebuanoMeaning; return this; }
            public HardestWordSummaryBuilder lessonTitle(String lessonTitle) { this.lessonTitle = lessonTitle; return this; }
            public HardestWordSummaryBuilder avgDemerits(Double avgDemerits) { this.avgDemerits = avgDemerits; return this; }
            public HardestWordSummaryBuilder totalDemerits(Integer totalDemerits) { this.totalDemerits = totalDemerits; return this; }
            public HardestWordSummaryBuilder strugglingLearnerCount(Integer strugglingLearnerCount) { this.strugglingLearnerCount = strugglingLearnerCount; return this; }
            public HardestWordSummaryBuilder strugglePercentage(Double strugglePercentage) { this.strugglePercentage = strugglePercentage; return this; }
            public HardestWordSummaryBuilder curriculumRecommendation(String curriculumRecommendation) { this.curriculumRecommendation = curriculumRecommendation; return this; }
            public HardestWordSummaryBuilder avgAccuracy(BigDecimal avgAccuracy) { this.avgAccuracy = avgAccuracy; return this; }
            public HardestWordSummaryBuilder totalAttempts(Integer totalAttempts) { this.totalAttempts = totalAttempts; return this; }
            public HardestWordSummaryBuilder incorrectCount(Integer incorrectCount) { this.incorrectCount = incorrectCount; return this; }

            public HardestWordSummary build() {
                HardestWordSummary h = new HardestWordSummary();
                h.wordId = this.wordId;
                h.englishWord = this.englishWord;
                h.cebuanoMeaning = this.cebuanoMeaning;
                h.lessonTitle = this.lessonTitle;
                h.avgDemerits = this.avgDemerits;
                h.totalDemerits = this.totalDemerits;
                h.strugglingLearnerCount = this.strugglingLearnerCount;
                h.strugglePercentage = this.strugglePercentage;
                h.curriculumRecommendation = this.curriculumRecommendation;
                h.avgAccuracy = this.avgAccuracy;
                h.totalAttempts = this.totalAttempts;
                h.incorrectCount = this.incorrectCount;
                return h;
            }
        }
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

        public Integer getFallbackCount() {
            return fallbackCount;
        }

        public static FallbackWordSummaryBuilder builder() { return new FallbackWordSummaryBuilder(); }

        public static class FallbackWordSummaryBuilder {
            private UUID wordId;
            private String englishWord;
            private String cebuanoMeaning;
            private String lessonTitle;
            private Integer fallbackCount;

            public FallbackWordSummaryBuilder wordId(UUID wordId) { this.wordId = wordId; return this; }
            public FallbackWordSummaryBuilder englishWord(String englishWord) { this.englishWord = englishWord; return this; }
            public FallbackWordSummaryBuilder cebuanoMeaning(String cebuanoMeaning) { this.cebuanoMeaning = cebuanoMeaning; return this; }
            public FallbackWordSummaryBuilder lessonTitle(String lessonTitle) { this.lessonTitle = lessonTitle; return this; }
            public FallbackWordSummaryBuilder fallbackCount(Integer fallbackCount) { this.fallbackCount = fallbackCount; return this; }

            public FallbackWordSummary build() {
                FallbackWordSummary f = new FallbackWordSummary();
                f.wordId = this.wordId;
                f.englishWord = this.englishWord;
                f.cebuanoMeaning = this.cebuanoMeaning;
                f.lessonTitle = this.lessonTitle;
                f.fallbackCount = this.fallbackCount;
                return f;
            }
        }
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

        public BigDecimal getCompletionRate() {
            return completionRate;
        }

        public static LessonPassRateSummaryBuilder builder() { return new LessonPassRateSummaryBuilder(); }

        public static class LessonPassRateSummaryBuilder {
            private UUID lessonId;
            private String lessonTitle;
            private String gradeLevel;
            private BigDecimal completionRate;
            private BigDecimal avgScore;
            private Long totalCompletions;

            public LessonPassRateSummaryBuilder lessonId(UUID lessonId) { this.lessonId = lessonId; return this; }
            public LessonPassRateSummaryBuilder lessonTitle(String lessonTitle) { this.lessonTitle = lessonTitle; return this; }
            public LessonPassRateSummaryBuilder gradeLevel(String gradeLevel) { this.gradeLevel = gradeLevel; return this; }
            public LessonPassRateSummaryBuilder completionRate(BigDecimal completionRate) { this.completionRate = completionRate; return this; }
            public LessonPassRateSummaryBuilder avgScore(BigDecimal avgScore) { this.avgScore = avgScore; return this; }
            public LessonPassRateSummaryBuilder totalCompletions(Long totalCompletions) { this.totalCompletions = totalCompletions; return this; }

            public LessonPassRateSummary build() {
                LessonPassRateSummary s = new LessonPassRateSummary();
                s.lessonId = this.lessonId;
                s.lessonTitle = this.lessonTitle;
                s.gradeLevel = this.gradeLevel;
                s.completionRate = this.completionRate;
                s.avgScore = this.avgScore;
                s.totalCompletions = this.totalCompletions;
                return s;
            }
        }
    }

    public static AdminAnalyticsDashboardResponseBuilder builder() { return new AdminAnalyticsDashboardResponseBuilder(); }

    public static class AdminAnalyticsDashboardResponseBuilder {
        private DashboardKpis kpis;
        private DashboardTrends trends;
        private List<StrugglingLearnerSummary> strugglingLearners;
        private List<TopPerformerSummary> topPerformers;
        private CurriculumAnalytics curriculumAnalytics;

        public AdminAnalyticsDashboardResponseBuilder kpis(DashboardKpis kpis) { this.kpis = kpis; return this; }
        public AdminAnalyticsDashboardResponseBuilder trends(DashboardTrends trends) { this.trends = trends; return this; }
        public AdminAnalyticsDashboardResponseBuilder strugglingLearners(List<StrugglingLearnerSummary> strugglingLearners) { this.strugglingLearners = strugglingLearners; return this; }
        public AdminAnalyticsDashboardResponseBuilder topPerformers(List<TopPerformerSummary> topPerformers) { this.topPerformers = topPerformers; return this; }
        public AdminAnalyticsDashboardResponseBuilder curriculumAnalytics(CurriculumAnalytics curriculumAnalytics) { this.curriculumAnalytics = curriculumAnalytics; return this; }

        public AdminAnalyticsDashboardResponse build() {
            AdminAnalyticsDashboardResponse r = new AdminAnalyticsDashboardResponse();
            r.kpis = this.kpis;
            r.trends = this.trends;
            r.strugglingLearners = this.strugglingLearners;
            r.topPerformers = this.topPerformers;
            r.curriculumAnalytics = this.curriculumAnalytics;
            return r;
        }
    }
}
