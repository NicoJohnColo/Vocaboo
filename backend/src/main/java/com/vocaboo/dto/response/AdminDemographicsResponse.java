package com.vocaboo.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;

import java.util.Map;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AdminDemographicsResponse {

    @JsonProperty("total_learners")
    private long totalLearners;

    @JsonProperty("independent_learners_count")
    private long independentLearnersCount;

    @JsonProperty("enrolled_learners_count")
    private long enrolledLearnersCount;

    @JsonProperty("independent_percentage")
    private double independentPercentage;

    @JsonProperty("enrolled_percentage")
    private double enrolledPercentage;

    @JsonProperty("language_preference_distribution")
    private Map<String, Long> languagePreferenceDistribution;

    @JsonProperty("grade_level_distribution")
    private Map<String, Long> gradeLevelDistribution;

    @JsonProperty("mastery_tier_distribution")
    private Map<String, Long> masteryTierDistribution;
}
