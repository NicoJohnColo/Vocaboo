package com.vocaboo.dto.request;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DifficultyAdjustmentRequest {
    private UUID learnerId;
    private Boolean correct;
    private String action; // e.g. "INCREMENT", "DECREMENT", "DIAGNOSTIC_BOOST", "DIAGNOSTIC_FAIL"
    private String activityType;

    public UUID getLearnerId() { return learnerId; }
    public Boolean getCorrect() { return correct; }
    public String getAction() { return action; }
    public String getActivityType() { return activityType; }
}
