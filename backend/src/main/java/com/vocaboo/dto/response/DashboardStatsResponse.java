package com.vocaboo.dto.response;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DashboardStatsResponse {
    private long totalLearners;
    private long totalLessons;
    private long activeSessions;
    private long totalAdmins;

    public static DashboardStatsResponseBuilder builder() { return new DashboardStatsResponseBuilder(); }

    public static class DashboardStatsResponseBuilder {
        private long totalLearners;
        private long totalLessons;
        private long activeSessions;
        private long totalAdmins;

        public DashboardStatsResponseBuilder totalLearners(long totalLearners) { this.totalLearners = totalLearners; return this; }
        public DashboardStatsResponseBuilder totalLessons(long totalLessons) { this.totalLessons = totalLessons; return this; }
        public DashboardStatsResponseBuilder activeSessions(long activeSessions) { this.activeSessions = activeSessions; return this; }
        public DashboardStatsResponseBuilder totalAdmins(long totalAdmins) { this.totalAdmins = totalAdmins; return this; }

        public DashboardStatsResponse build() {
            DashboardStatsResponse r = new DashboardStatsResponse();
            r.totalLearners = this.totalLearners;
            r.totalLessons = this.totalLessons;
            r.activeSessions = this.activeSessions;
            r.totalAdmins = this.totalAdmins;
            return r;
        }
    }
}
