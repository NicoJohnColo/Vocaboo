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
    private BigDecimal currentAccuracy;
    private BigDecimal bestAccuracy;
    private Integer tierDropCount;
    private Boolean isRetaken;
    private BigDecimal previousAccuracy;
    private Boolean isImproved;

    public static WordMasterySummaryResponseBuilder builder() { return new WordMasterySummaryResponseBuilder(); }

    public static class WordMasterySummaryResponseBuilder {
        private UUID wordId;
        private String englishWord;
        private String cebuanoMeaning;
        private String partOfSpeech;
        private String tierState;
        private String wordRating;
        private Integer totalAttempts;
        private Integer correctAttempts;
        private BigDecimal accuracy;
        private BigDecimal currentAccuracy;
        private BigDecimal bestAccuracy;
        private Integer tierDropCount;
        private Boolean isRetaken;
        private BigDecimal previousAccuracy;
        private Boolean isImproved;

        public WordMasterySummaryResponseBuilder wordId(UUID wordId) { this.wordId = wordId; return this; }
        public WordMasterySummaryResponseBuilder englishWord(String englishWord) { this.englishWord = englishWord; return this; }
        public WordMasterySummaryResponseBuilder cebuanoMeaning(String cebuanoMeaning) { this.cebuanoMeaning = cebuanoMeaning; return this; }
        public WordMasterySummaryResponseBuilder partOfSpeech(String partOfSpeech) { this.partOfSpeech = partOfSpeech; return this; }
        public WordMasterySummaryResponseBuilder tierState(String tierState) { this.tierState = tierState; return this; }
        public WordMasterySummaryResponseBuilder wordRating(String wordRating) { this.wordRating = wordRating; return this; }
        public WordMasterySummaryResponseBuilder totalAttempts(Integer totalAttempts) { this.totalAttempts = totalAttempts; return this; }
        public WordMasterySummaryResponseBuilder correctAttempts(Integer correctAttempts) { this.correctAttempts = correctAttempts; return this; }
        public WordMasterySummaryResponseBuilder accuracy(BigDecimal accuracy) { this.accuracy = accuracy; return this; }
        public WordMasterySummaryResponseBuilder currentAccuracy(BigDecimal currentAccuracy) { this.currentAccuracy = currentAccuracy; return this; }
        public WordMasterySummaryResponseBuilder bestAccuracy(BigDecimal bestAccuracy) { this.bestAccuracy = bestAccuracy; return this; }
        public WordMasterySummaryResponseBuilder tierDropCount(Integer tierDropCount) { this.tierDropCount = tierDropCount; return this; }
        public WordMasterySummaryResponseBuilder isRetaken(Boolean isRetaken) { this.isRetaken = isRetaken; return this; }
        public WordMasterySummaryResponseBuilder previousAccuracy(BigDecimal previousAccuracy) { this.previousAccuracy = previousAccuracy; return this; }
        public WordMasterySummaryResponseBuilder isImproved(Boolean isImproved) { this.isImproved = isImproved; return this; }

        public WordMasterySummaryResponse build() {
            WordMasterySummaryResponse r = new WordMasterySummaryResponse();
            r.wordId = this.wordId;
            r.englishWord = this.englishWord;
            r.cebuanoMeaning = this.cebuanoMeaning;
            r.partOfSpeech = this.partOfSpeech;
            r.tierState = this.tierState;
            r.wordRating = this.wordRating;
            r.totalAttempts = this.totalAttempts;
            r.correctAttempts = this.correctAttempts;
            r.accuracy = this.accuracy;
            r.currentAccuracy = this.currentAccuracy;
            r.bestAccuracy = this.bestAccuracy;
            r.tierDropCount = this.tierDropCount;
            r.isRetaken = this.isRetaken;
            r.previousAccuracy = this.previousAccuracy;
            r.isImproved = this.isImproved;
            return r;
        }
    }
}
