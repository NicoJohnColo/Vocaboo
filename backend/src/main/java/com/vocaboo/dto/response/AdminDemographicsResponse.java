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

    public static AdminDemographicsResponseBuilder builder() { return new AdminDemographicsResponseBuilder(); }

    public static class AdminDemographicsResponseBuilder {
        private long totalLearners;
        private long independentLearnersCount;
        private long enrolledLearnersCount;
        private double independentPercentage;
        private double enrolledPercentage;
        private Map<String, Long> languagePreferenceDistribution;
        private Map<String, Long> gradeLevelDistribution;
        private Map<String, Long> masteryTierDistribution;

        public AdminDemographicsResponseBuilder totalLearners(long totalLearners) { this.totalLearners = totalLearners; return this; }
        public AdminDemographicsResponseBuilder independentLearnersCount(long independentLearnersCount) { this.independentLearnersCount = independentLearnersCount; return this; }
        public AdminDemographicsResponseBuilder enrolledLearnersCount(long enrolledLearnersCount) { this.enrolledLearnersCount = enrolledLearnersCount; return this; }
        public AdminDemographicsResponseBuilder independentPercentage(double independentPercentage) { this.independentPercentage = independentPercentage; return this; }
        public AdminDemographicsResponseBuilder enrolledPercentage(double enrolledPercentage) { this.enrolledPercentage = enrolledPercentage; return this; }
        public AdminDemographicsResponseBuilder languagePreferenceDistribution(Map<String, Long> languagePreferenceDistribution) { this.languagePreferenceDistribution = languagePreferenceDistribution; return this; }
        public AdminDemographicsResponseBuilder gradeLevelDistribution(Map<String, Long> gradeLevelDistribution) { this.gradeLevelDistribution = gradeLevelDistribution; return this; }
        public AdminDemographicsResponseBuilder masteryTierDistribution(Map<String, Long> masteryTierDistribution) { this.masteryTierDistribution = masteryTierDistribution; return this; }

        public AdminDemographicsResponse build() {
            AdminDemographicsResponse r = new AdminDemographicsResponse();
            r.totalLearners = this.totalLearners;
            r.independentLearnersCount = this.independentLearnersCount;
            r.enrolledLearnersCount = this.enrolledLearnersCount;
            r.independentPercentage = this.independentPercentage;
            r.enrolledPercentage = this.enrolledPercentage;
            r.languagePreferenceDistribution = this.languagePreferenceDistribution;
            r.gradeLevelDistribution = this.gradeLevelDistribution;
            r.masteryTierDistribution = this.masteryTierDistribution;
            return r;
        }
    }
}
