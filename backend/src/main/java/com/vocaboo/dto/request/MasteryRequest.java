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
    private Double cumulativeReviewScore;
    private double finalScore;
    private boolean passed;
    private int totalItems;
    private int masteredCount;
    private List<String> missedWordIds;

    public double getLessonScore() { return lessonScore; }
    public Double getCumulativeReviewScore() { return cumulativeReviewScore; }
    public boolean isPassed() { return passed; }
    public List<UUID> getLessonIds() { return lessonIds; }
    public int getTotalItems() { return totalItems; }
    public int getMasteredCount() { return masteredCount; }
    public List<String> getMissedWordIds() { return missedWordIds; }
}
