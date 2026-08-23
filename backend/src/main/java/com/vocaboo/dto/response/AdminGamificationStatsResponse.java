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
}
