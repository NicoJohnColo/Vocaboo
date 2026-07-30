package com.vocaboo.dto.response;

import lombok.*;
import java.util.List;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WrongAnswerAnalysisResponse {

    /** Total number of incorrect review items logged class-wide across all learners and sessions. */
    private int totalClassErrors;

    /** Total number of distinct learners who have at least one recorded error. */
    private int learnersWithErrors;

    /** Word pairs that are most frequently confused by the class, sorted by confusion count descending. */
    private List<ConfusedPairDetail> confusedPairs;

    /** Lessons/categories where the highest error rates are concentrated. */
    private List<CurriculumGapDetail> curriculumGaps;

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class ConfusedPairDetail {
        private UUID wordAId;
        private String wordAEnglish;
        private String wordACebuano;
        private UUID wordBId;
        private String wordBEnglish;
        private String wordBCebuano;
        private String lessonTitle;

        /** Number of distinct learners who made at least one error on either word in this pair. */
        private int affectedLearners;

        /** Total number of incorrect review items across all learners for this word pair. */
        private int totalErrors;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class CurriculumGapDetail {
        private UUID lessonId;
        private String lessonTitle;
        private String categoryName;

        /** Number of distinct learners who made at least one error on a word in this lesson. */
        private int affectedLearners;

        /** Total incorrect review items across all learners for words in this lesson. */
        private int totalErrors;

        /** Short human-readable recommendation, e.g. "Review vocabulary in Lesson 3". */
        private String recommendation;
    }
}
