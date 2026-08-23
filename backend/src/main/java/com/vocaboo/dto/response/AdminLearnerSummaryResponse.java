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
}
