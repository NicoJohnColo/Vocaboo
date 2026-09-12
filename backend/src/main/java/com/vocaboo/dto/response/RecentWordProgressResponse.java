package com.vocaboo.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RecentWordProgressResponse {
    private UUID wordId;
    private String englishWord;
    private String cebuanoMeaning;
    private BigDecimal accuracy;
    private String currentLevel; // 'LEARNING', 'FAMILIAR', 'PROFICIENT', 'MASTERED'
    private String partOfSpeech;
    private OffsetDateTime lastPracticedAt;
    private Integer totalAttempts;
    private Integer correctCount;
    private Integer incorrectCount;

    public static RecentWordProgressResponseBuilder builder() { return new RecentWordProgressResponseBuilder(); }

    public static class RecentWordProgressResponseBuilder {
        private UUID wordId;
        private String englishWord;
        private String cebuanoMeaning;
        private BigDecimal accuracy;
        private String currentLevel;
        private String partOfSpeech;
        private OffsetDateTime lastPracticedAt;
        private Integer totalAttempts;
        private Integer correctCount;
        private Integer incorrectCount;

        public RecentWordProgressResponseBuilder wordId(UUID wordId) { this.wordId = wordId; return this; }
        public RecentWordProgressResponseBuilder englishWord(String englishWord) { this.englishWord = englishWord; return this; }
        public RecentWordProgressResponseBuilder cebuanoMeaning(String cebuanoMeaning) { this.cebuanoMeaning = cebuanoMeaning; return this; }
        public RecentWordProgressResponseBuilder accuracy(BigDecimal accuracy) { this.accuracy = accuracy; return this; }
        public RecentWordProgressResponseBuilder currentLevel(String currentLevel) { this.currentLevel = currentLevel; return this; }
        public RecentWordProgressResponseBuilder partOfSpeech(String partOfSpeech) { this.partOfSpeech = partOfSpeech; return this; }
        public RecentWordProgressResponseBuilder lastPracticedAt(OffsetDateTime lastPracticedAt) { this.lastPracticedAt = lastPracticedAt; return this; }
        public RecentWordProgressResponseBuilder totalAttempts(Integer totalAttempts) { this.totalAttempts = totalAttempts; return this; }
        public RecentWordProgressResponseBuilder correctCount(Integer correctCount) { this.correctCount = correctCount; return this; }
        public RecentWordProgressResponseBuilder incorrectCount(Integer incorrectCount) { this.incorrectCount = incorrectCount; return this; }

        public RecentWordProgressResponse build() {
            RecentWordProgressResponse r = new RecentWordProgressResponse();
            r.wordId = this.wordId;
            r.englishWord = this.englishWord;
            r.cebuanoMeaning = this.cebuanoMeaning;
            r.accuracy = this.accuracy;
            r.currentLevel = this.currentLevel;
            r.partOfSpeech = this.partOfSpeech;
            r.lastPracticedAt = this.lastPracticedAt;
            r.totalAttempts = this.totalAttempts;
            r.correctCount = this.correctCount;
            r.incorrectCount = this.incorrectCount;
            return r;
        }
    }
}
