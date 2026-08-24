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

    public static AdminLeaderboardStatsResponseBuilder builder() { return new AdminLeaderboardStatsResponseBuilder(); }

    public static class AdminLeaderboardStatsResponseBuilder {
        private String range;
        private String cohortType;
        private AdminGamificationStatsResponse gamificationSummary;
        private List<AdminLeaderboardEntryResponse> leaderboard;

        public AdminLeaderboardStatsResponseBuilder range(String range) { this.range = range; return this; }
        public AdminLeaderboardStatsResponseBuilder cohortType(String cohortType) { this.cohortType = cohortType; return this; }
        public AdminLeaderboardStatsResponseBuilder gamificationSummary(AdminGamificationStatsResponse gamificationSummary) { this.gamificationSummary = gamificationSummary; return this; }
        public AdminLeaderboardStatsResponseBuilder leaderboard(List<AdminLeaderboardEntryResponse> leaderboard) { this.leaderboard = leaderboard; return this; }

        public AdminLeaderboardStatsResponse build() {
            AdminLeaderboardStatsResponse r = new AdminLeaderboardStatsResponse();
            r.range = this.range;
            r.cohortType = this.cohortType;
            r.gamificationSummary = this.gamificationSummary;
            r.leaderboard = this.leaderboard;
            return r;
        }
    }
}
