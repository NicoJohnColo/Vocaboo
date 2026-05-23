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
