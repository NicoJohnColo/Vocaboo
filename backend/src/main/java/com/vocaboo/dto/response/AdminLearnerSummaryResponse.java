package com.vocaboo.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AdminLearnerSummaryResponse {

    @JsonProperty("learner_id")
    private UUID learnerId;

    @JsonProperty("display_name")
    private String displayName;

    @JsonProperty("age")
    private Integer age;

    @JsonProperty("grade_level")
    private String gradeLevel;

    @JsonProperty("section_id")
    private UUID sectionId;

    @JsonProperty("section_name")
    private String sectionName;

    @JsonProperty("language_preference")
    private String languagePreference;

    @JsonProperty("is_active")
    private Boolean isActive;

    @JsonProperty("mastery_level")
    private String masteryLevel;

    @JsonProperty("total_points")
    private Integer totalPoints;

    @JsonProperty("overall_accuracy")
    private BigDecimal overallAccuracy;

    @JsonProperty("completed_lessons_count")
    private Integer completedLessonsCount;

    @JsonProperty("words_mastered_count")
    private Integer wordsMasteredCount;

    @JsonProperty("is_struggling")
    private Boolean isStruggling;

    @JsonProperty("cumulative_reviews_completed")
    private Integer cumulativeReviewsCompleted;

    @JsonProperty("avg_cumulative_score")
    private BigDecimal avgCumulativeScore;

    @JsonProperty("best_cumulative_badge")
    private String bestCumulativeBadge;

    @JsonProperty("last_active_at")
    private OffsetDateTime lastActiveAt;

    @JsonProperty("created_at")
    private OffsetDateTime createdAt;

    public UUID getLearnerId() {
        return learnerId;
    }

    public String getDisplayName() {
        return displayName;
    }

    public String getGradeLevel() {
        return gradeLevel;
    }

    public String getSectionName() {
        return sectionName;
    }

    public String getLanguagePreference() {
        return languagePreference;
    }

    public Integer getCompletedLessonsCount() {
        return completedLessonsCount;
    }

    public Integer getWordsMasteredCount() {
        return wordsMasteredCount;
    }

    public Integer getTotalPoints() {
        return totalPoints;
    }

    public BigDecimal getOverallAccuracy() {
        return overallAccuracy;
    }

    public Boolean getIsActive() {
        return isActive;
    }

    public Boolean getIsStruggling() {
        return isStruggling;
    }

    public OffsetDateTime getLastActiveAt() {
        return lastActiveAt;
    }

    public static AdminLearnerSummaryResponseBuilder builder() {
        return new AdminLearnerSummaryResponseBuilder();
    }

    public static class AdminLearnerSummaryResponseBuilder {
        private UUID learnerId;
        private String displayName;
        private Integer age;
        private String gradeLevel;
        private UUID sectionId;
        private String sectionName;
        private String languagePreference;
        private Boolean isActive;
        private String masteryLevel;
        private Integer totalPoints;
        private BigDecimal overallAccuracy;
        private Integer completedLessonsCount;
        private Integer wordsMasteredCount;
        private Boolean isStruggling;
        private Integer cumulativeReviewsCompleted;
        private BigDecimal avgCumulativeScore;
        private String bestCumulativeBadge;
        private OffsetDateTime lastActiveAt;
        private OffsetDateTime createdAt;

        public AdminLearnerSummaryResponseBuilder learnerId(UUID learnerId) { this.learnerId = learnerId; return this; }
        public AdminLearnerSummaryResponseBuilder displayName(String displayName) { this.displayName = displayName; return this; }
        public AdminLearnerSummaryResponseBuilder age(Integer age) { this.age = age; return this; }
        public AdminLearnerSummaryResponseBuilder gradeLevel(String gradeLevel) { this.gradeLevel = gradeLevel; return this; }
        public AdminLearnerSummaryResponseBuilder sectionId(UUID sectionId) { this.sectionId = sectionId; return this; }
        public AdminLearnerSummaryResponseBuilder sectionName(String sectionName) { this.sectionName = sectionName; return this; }
        public AdminLearnerSummaryResponseBuilder languagePreference(String languagePreference) { this.languagePreference = languagePreference; return this; }
        public AdminLearnerSummaryResponseBuilder isActive(Boolean isActive) { this.isActive = isActive; return this; }
        public AdminLearnerSummaryResponseBuilder masteryLevel(String masteryLevel) { this.masteryLevel = masteryLevel; return this; }
        public AdminLearnerSummaryResponseBuilder totalPoints(Integer totalPoints) { this.totalPoints = totalPoints; return this; }
        public AdminLearnerSummaryResponseBuilder overallAccuracy(BigDecimal overallAccuracy) { this.overallAccuracy = overallAccuracy; return this; }
        public AdminLearnerSummaryResponseBuilder completedLessonsCount(Integer completedLessonsCount) { this.completedLessonsCount = completedLessonsCount; return this; }
        public AdminLearnerSummaryResponseBuilder wordsMasteredCount(Integer wordsMasteredCount) { this.wordsMasteredCount = wordsMasteredCount; return this; }
        public AdminLearnerSummaryResponseBuilder isStruggling(Boolean isStruggling) { this.isStruggling = isStruggling; return this; }
        public AdminLearnerSummaryResponseBuilder cumulativeReviewsCompleted(Integer cumulativeReviewsCompleted) { this.cumulativeReviewsCompleted = cumulativeReviewsCompleted; return this; }
        public AdminLearnerSummaryResponseBuilder avgCumulativeScore(BigDecimal avgCumulativeScore) { this.avgCumulativeScore = avgCumulativeScore; return this; }
        public AdminLearnerSummaryResponseBuilder bestCumulativeBadge(String bestCumulativeBadge) { this.bestCumulativeBadge = bestCumulativeBadge; return this; }
        public AdminLearnerSummaryResponseBuilder lastActiveAt(OffsetDateTime lastActiveAt) { this.lastActiveAt = lastActiveAt; return this; }
        public AdminLearnerSummaryResponseBuilder createdAt(OffsetDateTime createdAt) { this.createdAt = createdAt; return this; }

        public AdminLearnerSummaryResponse build() {
            AdminLearnerSummaryResponse r = new AdminLearnerSummaryResponse();
            r.learnerId = this.learnerId;
            r.displayName = this.displayName;
            r.age = this.age;
            r.gradeLevel = this.gradeLevel;
            r.sectionId = this.sectionId;
            r.sectionName = this.sectionName;
            r.languagePreference = this.languagePreference;
            r.isActive = this.isActive;
            r.masteryLevel = this.masteryLevel;
            r.totalPoints = this.totalPoints;
            r.overallAccuracy = this.overallAccuracy;
            r.completedLessonsCount = this.completedLessonsCount;
            r.wordsMasteredCount = this.wordsMasteredCount;
            r.isStruggling = this.isStruggling;
            r.cumulativeReviewsCompleted = this.cumulativeReviewsCompleted;
            r.avgCumulativeScore = this.avgCumulativeScore;
            r.bestCumulativeBadge = this.bestCumulativeBadge;
            r.lastActiveAt = this.lastActiveAt;
            r.createdAt = this.createdAt;
            return r;
        }
    }
}
