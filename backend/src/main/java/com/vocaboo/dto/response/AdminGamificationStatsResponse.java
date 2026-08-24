package com.vocaboo.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;

import java.util.Map;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AdminGamificationStatsResponse {

    @JsonProperty("total_points_awarded")
    private long totalPointsAwarded;

    @JsonProperty("average_points_per_active_learner")
    private double averagePointsPerActiveLearner;

    @JsonProperty("total_sessions_played")
    private long totalSessionsPlayed;

    @JsonProperty("total_badges_unlocked")
    private long totalBadgesUnlocked;

    @JsonProperty("badge_tier_counts")
    private Map<String, Long> badgeTierCounts;

    public static AdminGamificationStatsResponseBuilder builder() { return new AdminGamificationStatsResponseBuilder(); }

    public static class AdminGamificationStatsResponseBuilder {
        private long totalPointsAwarded;
        private double averagePointsPerActiveLearner;
        private long totalSessionsPlayed;
        private long totalBadgesUnlocked;
        private Map<String, Long> badgeTierCounts;

        public AdminGamificationStatsResponseBuilder totalPointsAwarded(long totalPointsAwarded) { this.totalPointsAwarded = totalPointsAwarded; return this; }
        public AdminGamificationStatsResponseBuilder averagePointsPerActiveLearner(double averagePointsPerActiveLearner) { this.averagePointsPerActiveLearner = averagePointsPerActiveLearner; return this; }
        public AdminGamificationStatsResponseBuilder totalSessionsPlayed(long totalSessionsPlayed) { this.totalSessionsPlayed = totalSessionsPlayed; return this; }
        public AdminGamificationStatsResponseBuilder totalBadgesUnlocked(long totalBadgesUnlocked) { this.totalBadgesUnlocked = totalBadgesUnlocked; return this; }
        public AdminGamificationStatsResponseBuilder badgeTierCounts(Map<String, Long> badgeTierCounts) { this.badgeTierCounts = badgeTierCounts; return this; }

        public AdminGamificationStatsResponse build() {
            AdminGamificationStatsResponse r = new AdminGamificationStatsResponse();
            r.totalPointsAwarded = this.totalPointsAwarded;
            r.averagePointsPerActiveLearner = this.averagePointsPerActiveLearner;
            r.totalSessionsPlayed = this.totalSessionsPlayed;
            r.totalBadgesUnlocked = this.totalBadgesUnlocked;
            r.badgeTierCounts = this.badgeTierCounts;
            return r;
        }
    }
}
