package com.vocaboo.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PracticeResultRequest {
    @NotNull(message = "Word ID is required")
    private UUID wordId;

    @com.fasterxml.jackson.annotation.JsonAlias({"isCorrect", "correct"})
    @NotNull(message = "correct is required")
    private Boolean correct;

    private Integer attemptNumber;
    private String activityType;

    public UUID getWordId() { return wordId; }
    public Boolean getCorrect() { return correct; }
    public Boolean getIsCorrect() { return correct; }
    public void setIsCorrect(Boolean isCorrect) { this.correct = isCorrect; }
    public Integer getAttemptNumber() { return attemptNumber; }
    public String getActivityType() { return activityType; }
}
