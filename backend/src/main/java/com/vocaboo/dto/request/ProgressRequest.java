package com.vocaboo.dto.request;

import com.vocaboo.entity.Pathway;
import com.vocaboo.entity.WordStatus;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.*;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProgressRequest {

    @NotNull(message = "Word ID is required")
    private UUID wordId;

    @NotNull(message = "Pathway is required")
    private Pathway pathway;

    @NotNull(message = "Step completed is required")
    @Min(0)
    @Max(4)
    private Integer stepCompleted;

    @NotNull(message = "Status is required")
    private WordStatus status;
}
