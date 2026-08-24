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
public class AdminTrustLayerStatsResponse {
    private UUID learnerId;
    private String displayName;
    
    // Attempt metrics
    private int totalWordAttempts;
    private int totalPronunciationAttempts;
    
    // Pronunciation accuracy
    private double pronunciationAccuracyPercent;
    
    // Difficulty progression metrics
    private int tierDrops;
    private int totalWordsMastered;

    // Module-level active time tracking
    private Integer module2TimeSeconds;
    private Integer module3TimeSeconds;
    private Integer module4TimeSeconds;
    private Integer totalLessonTimeSeconds;

    public static AdminTrustLayerStatsResponseBuilder builder() {
        return new AdminTrustLayerStatsResponseBuilder();
    }

    public static class AdminTrustLayerStatsResponseBuilder {
        private UUID learnerId;
        private String displayName;
        private int totalWordAttempts;
        private int totalPronunciationAttempts;
        private double pronunciationAccuracyPercent;
        private int tierDrops;
        private int totalWordsMastered;
        private Integer module2TimeSeconds;
        private Integer module3TimeSeconds;
        private Integer module4TimeSeconds;
        private Integer totalLessonTimeSeconds;

        public AdminTrustLayerStatsResponseBuilder learnerId(UUID learnerId) { this.learnerId = learnerId; return this; }
        public AdminTrustLayerStatsResponseBuilder displayName(String displayName) { this.displayName = displayName; return this; }
        public AdminTrustLayerStatsResponseBuilder totalWordAttempts(int totalWordAttempts) { this.totalWordAttempts = totalWordAttempts; return this; }
        public AdminTrustLayerStatsResponseBuilder totalPronunciationAttempts(int totalPronunciationAttempts) { this.totalPronunciationAttempts = totalPronunciationAttempts; return this; }
        public AdminTrustLayerStatsResponseBuilder pronunciationAccuracyPercent(double pronunciationAccuracyPercent) { this.pronunciationAccuracyPercent = pronunciationAccuracyPercent; return this; }
        public AdminTrustLayerStatsResponseBuilder tierDrops(int tierDrops) { this.tierDrops = tierDrops; return this; }
        public AdminTrustLayerStatsResponseBuilder totalWordsMastered(int totalWordsMastered) { this.totalWordsMastered = totalWordsMastered; return this; }
        public AdminTrustLayerStatsResponseBuilder module2TimeSeconds(Integer module2TimeSeconds) { this.module2TimeSeconds = module2TimeSeconds; return this; }
        public AdminTrustLayerStatsResponseBuilder module3TimeSeconds(Integer module3TimeSeconds) { this.module3TimeSeconds = module3TimeSeconds; return this; }
        public AdminTrustLayerStatsResponseBuilder module4TimeSeconds(Integer module4TimeSeconds) { this.module4TimeSeconds = module4TimeSeconds; return this; }
        public AdminTrustLayerStatsResponseBuilder totalLessonTimeSeconds(Integer totalLessonTimeSeconds) { this.totalLessonTimeSeconds = totalLessonTimeSeconds; return this; }

        public AdminTrustLayerStatsResponse build() {
            AdminTrustLayerStatsResponse r = new AdminTrustLayerStatsResponse();
            r.learnerId = this.learnerId;
            r.displayName = this.displayName;
            r.totalWordAttempts = this.totalWordAttempts;
            r.totalPronunciationAttempts = this.totalPronunciationAttempts;
            r.pronunciationAccuracyPercent = this.pronunciationAccuracyPercent;
            r.tierDrops = this.tierDrops;
            r.totalWordsMastered = this.totalWordsMastered;
            r.module2TimeSeconds = this.module2TimeSeconds;
            r.module3TimeSeconds = this.module3TimeSeconds;
            r.module4TimeSeconds = this.module4TimeSeconds;
            r.totalLessonTimeSeconds = this.totalLessonTimeSeconds;
            return r;
        }
    }
}
