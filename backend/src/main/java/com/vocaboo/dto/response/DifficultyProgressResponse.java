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
    /** True if at least one recall-type activity is in the current streak (required for tier advancement). */
    private Boolean recallInCurrentStreak;
    /** Attempts at the current tier level — resets to 1 on every tier change for correct points calculation. */
    private Integer attemptCountAtCurrentTier;
    private Boolean needsReintroduction;
    private Integer reintroductionCount;
    private OffsetDateTime lastReintroducedAt;
    private Boolean needsTeacherReview;
    private Boolean diagnosticAdministered;
    private String diagnosticResult;
    private String diagnosticActivityType;
    private Boolean showHints;
    private OffsetDateTime lastAdjustedAt;
}
