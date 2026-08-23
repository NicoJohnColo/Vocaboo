package com.vocaboo.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;

import java.util.UUID;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AdminLeaderboardEntryResponse {

    @JsonProperty("rank")
    private int rank;

    @JsonProperty("learner_id")
    private UUID learnerId;

    @JsonProperty("display_name")
    private String displayName;

    @JsonProperty("section_name")
    private String sectionName;

    @JsonProperty("independent")
    private boolean independent;

    @JsonProperty("grade_level")
    private String gradeLevel;

    @JsonProperty("tier")
    private String tier;

    @JsonProperty("points")
    private int points;

    @JsonProperty("badges_count")
    private int badgesCount;

    @JsonProperty("overall_accuracy")
    private double overallAccuracy;
}
