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

    public int getPoints() { return points; }
    public double getOverallAccuracy() { return overallAccuracy; }
    public void setRank(int rank) { this.rank = rank; }

    public static AdminLeaderboardEntryResponseBuilder builder() { return new AdminLeaderboardEntryResponseBuilder(); }

    public static class AdminLeaderboardEntryResponseBuilder {
        private int rank;
        private UUID learnerId;
        private String displayName;
        private String sectionName;
        private boolean independent;
        private String gradeLevel;
        private String tier;
        private int points;
        private int badgesCount;
        private double overallAccuracy;

        public AdminLeaderboardEntryResponseBuilder rank(int rank) { this.rank = rank; return this; }
        public AdminLeaderboardEntryResponseBuilder learnerId(UUID learnerId) { this.learnerId = learnerId; return this; }
        public AdminLeaderboardEntryResponseBuilder displayName(String displayName) { this.displayName = displayName; return this; }
        public AdminLeaderboardEntryResponseBuilder sectionName(String sectionName) { this.sectionName = sectionName; return this; }
        public AdminLeaderboardEntryResponseBuilder independent(boolean independent) { this.independent = independent; return this; }
        public AdminLeaderboardEntryResponseBuilder gradeLevel(String gradeLevel) { this.gradeLevel = gradeLevel; return this; }
        public AdminLeaderboardEntryResponseBuilder tier(String tier) { this.tier = tier; return this; }
        public AdminLeaderboardEntryResponseBuilder points(int points) { this.points = points; return this; }
        public AdminLeaderboardEntryResponseBuilder badgesCount(int badgesCount) { this.badgesCount = badgesCount; return this; }
        public AdminLeaderboardEntryResponseBuilder overallAccuracy(double overallAccuracy) { this.overallAccuracy = overallAccuracy; return this; }

        public AdminLeaderboardEntryResponse build() {
            AdminLeaderboardEntryResponse r = new AdminLeaderboardEntryResponse();
            r.rank = this.rank;
            r.learnerId = this.learnerId;
            r.displayName = this.displayName;
            r.sectionName = this.sectionName;
            r.independent = this.independent;
            r.gradeLevel = this.gradeLevel;
            r.tier = this.tier;
            r.points = this.points;
            r.badgesCount = this.badgesCount;
            r.overallAccuracy = this.overallAccuracy;
            return r;
        }
    }
}
