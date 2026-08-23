package com.vocaboo.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;

import java.util.List;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AdminLeaderboardStatsResponse {

    @JsonProperty("range")
    private String range;

    @JsonProperty("cohort_type")
    private String cohortType;

    @JsonProperty("gamification_summary")
    private AdminGamificationStatsResponse gamificationSummary;

    @JsonProperty("leaderboard")
    private List<AdminLeaderboardEntryResponse> leaderboard;
}
