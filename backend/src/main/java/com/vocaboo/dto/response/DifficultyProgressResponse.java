package com.vocaboo.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.OffsetDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DifficultyProgressResponse {
    private UUID progressId;
    private UUID learnerId;
    private UUID wordId;
    private String currentLevel;
    private Integer consecutiveCorrect;
    private Integer consecutiveIncorrect;
    private OffsetDateTime lastAdjustedAt;
}
