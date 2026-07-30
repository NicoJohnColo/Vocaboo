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

    @NotNull(message = "isCorrect is required")
    private Boolean isCorrect;

    private Integer attemptNumber;
    private String activityType;
}
