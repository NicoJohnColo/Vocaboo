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
}
