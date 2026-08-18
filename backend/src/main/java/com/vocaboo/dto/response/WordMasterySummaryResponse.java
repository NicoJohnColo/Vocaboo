package com.vocaboo.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Per-word summary returned by GET /lessons/{id}/word-mastery-summary.
 * Shown on the lesson score screen — one row per word regardless of whether
 * the word was mastered or not.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WordMasterySummaryResponse {

    private UUID wordId;
    private String englishWord;
    private String cebuanoMeaning;
    private String partOfSpeech;

    /**
     * Current difficulty tier: LEARNING / FAMILIAR / PROFICIENT / MASTERED.
     * MASTERED = the learner passed the gate. Any other value = still in progress.
     */
    private String tierState;

    /**
     * Performance rating decoupled from the gate:
     *   GOLD   — accuracy >= 90% AND 0 tier drops
     *   SILVER — (accuracy 70–89%) OR exactly 1 tier drop
     *   BRONZE — accuracy < 70% OR 2+ tier drops
     * Only meaningful when tierState == MASTERED; null otherwise.
     */
    private String wordRating;

    private Integer totalAttempts;
    private Integer correctAttempts;
    private BigDecimal accuracy;
    private Integer tierDropCount;
}
