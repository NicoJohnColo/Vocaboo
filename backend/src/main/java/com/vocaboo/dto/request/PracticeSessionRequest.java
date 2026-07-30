package com.vocaboo.dto.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
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
public class PracticeSessionRequest {
    private UUID learnerId;

    @NotNull(message = "Lesson ID is required")
    private UUID lessonId;

    @NotNull(message = "Module number is required")
    @Min(value = 1, message = "Module number must be between 1 and 4")
    @Max(value = 4, message = "Module number must be between 1 and 4")
    private Integer moduleNumber;
}
