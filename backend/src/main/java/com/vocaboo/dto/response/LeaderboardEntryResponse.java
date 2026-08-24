package com.vocaboo.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LeaderboardEntryResponse {
    private int rank;
    private UUID learnerId;
    private String displayName;
    private int points;
    private String tier;

    public int getPoints() { return points; }
    public void setRank(int rank) { this.rank = rank; }

    public static LeaderboardEntryResponseBuilder builder() { return new LeaderboardEntryResponseBuilder(); }

    public static class LeaderboardEntryResponseBuilder {
        private int rank;
        private UUID learnerId;
        private String displayName;
        private int points;
        private String tier;

        public LeaderboardEntryResponseBuilder rank(int rank) { this.rank = rank; return this; }
        public LeaderboardEntryResponseBuilder learnerId(UUID learnerId) { this.learnerId = learnerId; return this; }
        public LeaderboardEntryResponseBuilder displayName(String displayName) { this.displayName = displayName; return this; }
        public LeaderboardEntryResponseBuilder points(int points) { this.points = points; return this; }
        public LeaderboardEntryResponseBuilder tier(String tier) { this.tier = tier; return this; }

        public LeaderboardEntryResponse build() {
            LeaderboardEntryResponse l = new LeaderboardEntryResponse();
            l.rank = this.rank;
            l.learnerId = this.learnerId;
            l.displayName = this.displayName;
            l.points = this.points;
            l.tier = this.tier;
            return l;
        }
    }
}
