package com.vocaboo.dto.response;

import lombok.*;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DashboardResponse {
    private int completedLessons;
    private int totalLessons;
    private double averageMasteryScore;
    private int totalPronunciationAttempts;
    private int correctPronunciationAttempts;
    private List<SandboxSessionDetails> sandboxHistory;
    private int cumulativeReviewsCompleted;
    private String bestCumulativeBadge;
    private List<CumulativeSessionDetails> cumulativeReviewHistory;

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class CumulativeSessionDetails {
        private UUID sessionId;
        private String lessonPairId;
        private String sessionStatus;
        private Double accuracyPercent;
        private String badgeAwarded;
        private Integer pointsEarned;
        private Object pointsBreakdown;
        private OffsetDateTime startTime;
        private OffsetDateTime endTime;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class SandboxSessionDetails {
        private UUID sessionId;
        private String topic;
        private String customWord;
        private Double masteryScore;
        private OffsetDateTime completedAt;
        private List<String> words;
    }
}
