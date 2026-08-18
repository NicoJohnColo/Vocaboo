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
}
