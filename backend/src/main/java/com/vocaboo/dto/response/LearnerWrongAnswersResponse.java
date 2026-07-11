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
    }
}
