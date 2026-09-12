package com.vocaboo.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LearnerActivityStatsResponse {
    private UUID learnerId;
    private Integer currentStreak;
    private Integer longestStreak;
    private Integer totalActiveDays;
    private List<String> activeDates;
}
