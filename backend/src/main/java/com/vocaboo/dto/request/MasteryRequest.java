package com.vocaboo.dto.request;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class MasteryRequest {
    private UUID learnerId;
    private UUID categoryId;
    private List<UUID> lessonIds;
    private double lessonScore;
    private double cumulativeReviewScore;
    private double finalScore;
    private boolean passed;
    private int totalItems;
    private int masteredCount;
    private List<String> missedWordIds;
}
