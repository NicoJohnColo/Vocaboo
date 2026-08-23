package com.vocaboo.dto.response;

import lombok.*;
import java.util.List;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LearnerWrongAnswersResponse {

    /** Total demerit points = 2 × total error count across all practice sessions. */
    private int demeritPoints;

    /** Words the learner has answered incorrectly at least once, sorted by error count descending. */
    private List<WrongWordDetail> words;

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class WrongWordDetail {
        private UUID wordId;
        private String englishWord;
        private String cebuanoMeaning;
        private String partOfSpeech;
        private String lessonTitle;
        private String categoryName;

        /** Total number of incorrect review items for this word across all sessions. */
        private int errorCount;

        /**
         * True if the learner's most-recent review attempt for this word was correct,
         * indicating they have since recovered. False if their last attempt was still wrong.
         */
        private boolean currentlyCorrect;

        public void setCurrentlyCorrect(boolean currentlyCorrect) { this.currentlyCorrect = currentlyCorrect; }
        public int getErrorCount() { return errorCount; }

        public static WrongWordDetailBuilder builder() { return new WrongWordDetailBuilder(); }

        public static class WrongWordDetailBuilder {
            private UUID wordId;
            private String englishWord;
            private String cebuanoMeaning;
            private String partOfSpeech;
            private String lessonTitle;
            private String categoryName;
            private int errorCount;
            private boolean currentlyCorrect;

            public WrongWordDetailBuilder wordId(UUID wordId) { this.wordId = wordId; return this; }
            public WrongWordDetailBuilder englishWord(String englishWord) { this.englishWord = englishWord; return this; }
            public WrongWordDetailBuilder cebuanoMeaning(String cebuanoMeaning) { this.cebuanoMeaning = cebuanoMeaning; return this; }
            public WrongWordDetailBuilder partOfSpeech(String partOfSpeech) { this.partOfSpeech = partOfSpeech; return this; }
            public WrongWordDetailBuilder lessonTitle(String lessonTitle) { this.lessonTitle = lessonTitle; return this; }
            public WrongWordDetailBuilder categoryName(String categoryName) { this.categoryName = categoryName; return this; }
            public WrongWordDetailBuilder errorCount(int errorCount) { this.errorCount = errorCount; return this; }
            public WrongWordDetailBuilder currentlyCorrect(boolean currentlyCorrect) { this.currentlyCorrect = currentlyCorrect; return this; }

            public WrongWordDetail build() {
                WrongWordDetail d = new WrongWordDetail();
                d.wordId = this.wordId;
                d.englishWord = this.englishWord;
                d.cebuanoMeaning = this.cebuanoMeaning;
                d.partOfSpeech = this.partOfSpeech;
                d.lessonTitle = this.lessonTitle;
                d.categoryName = this.categoryName;
                d.errorCount = this.errorCount;
                d.currentlyCorrect = this.currentlyCorrect;
                return d;
            }
        }
    }

    public static LearnerWrongAnswersResponseBuilder builder() { return new LearnerWrongAnswersResponseBuilder(); }

    public static class LearnerWrongAnswersResponseBuilder {
        private int demeritPoints;
        private List<WrongWordDetail> words;

        public LearnerWrongAnswersResponseBuilder demeritPoints(int demeritPoints) { this.demeritPoints = demeritPoints; return this; }
        public LearnerWrongAnswersResponseBuilder words(List<WrongWordDetail> words) { this.words = words; return this; }

        public LearnerWrongAnswersResponse build() {
            LearnerWrongAnswersResponse r = new LearnerWrongAnswersResponse();
            r.demeritPoints = this.demeritPoints;
            r.words = this.words;
            return r;
        }
    }
}
