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

        public int getTotalErrors() { return totalErrors; }

        public static ConfusedPairDetailBuilder builder() { return new ConfusedPairDetailBuilder(); }

        public static class ConfusedPairDetailBuilder {
            private UUID wordAId;
            private String wordAEnglish;
            private String wordACebuano;
            private UUID wordBId;
            private String wordBEnglish;
            private String wordBCebuano;
            private String lessonTitle;
            private int affectedLearners;
            private int totalErrors;

            public ConfusedPairDetailBuilder wordAId(UUID wordAId) { this.wordAId = wordAId; return this; }
            public ConfusedPairDetailBuilder wordAEnglish(String wordAEnglish) { this.wordAEnglish = wordAEnglish; return this; }
            public ConfusedPairDetailBuilder wordACebuano(String wordACebuano) { this.wordACebuano = wordACebuano; return this; }
            public ConfusedPairDetailBuilder wordBId(UUID wordBId) { this.wordBId = wordBId; return this; }
            public ConfusedPairDetailBuilder wordBEnglish(String wordBEnglish) { this.wordBEnglish = wordBEnglish; return this; }
            public ConfusedPairDetailBuilder wordBCebuano(String wordBCebuano) { this.wordBCebuano = wordBCebuano; return this; }
            public ConfusedPairDetailBuilder lessonTitle(String lessonTitle) { this.lessonTitle = lessonTitle; return this; }
            public ConfusedPairDetailBuilder affectedLearners(int affectedLearners) { this.affectedLearners = affectedLearners; return this; }
            public ConfusedPairDetailBuilder totalErrors(int totalErrors) { this.totalErrors = totalErrors; return this; }

            public ConfusedPairDetail build() {
                ConfusedPairDetail d = new ConfusedPairDetail();
                d.wordAId = this.wordAId;
                d.wordAEnglish = this.wordAEnglish;
                d.wordACebuano = this.wordACebuano;
                d.wordBId = this.wordBId;
                d.wordBEnglish = this.wordBEnglish;
                d.wordBCebuano = this.wordBCebuano;
                d.lessonTitle = this.lessonTitle;
                d.affectedLearners = this.affectedLearners;
                d.totalErrors = this.totalErrors;
                return d;
            }
        }
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class ProblemWordDetail {
        private UUID wordId;
        private String englishWord;
        private String cebuanoMeaning;
        private int errorCount;
        private int demeritPoints;
        private int mistakeCount;
        private int affectedLearners;

        public static ProblemWordDetailBuilder builder() { return new ProblemWordDetailBuilder(); }

        public static class ProblemWordDetailBuilder {
            private UUID wordId;
            private String englishWord;
            private String cebuanoMeaning;
            private int errorCount;
            private int demeritPoints;
            private int mistakeCount;
            private int affectedLearners;

            public ProblemWordDetailBuilder wordId(UUID wordId) { this.wordId = wordId; return this; }
            public ProblemWordDetailBuilder englishWord(String englishWord) { this.englishWord = englishWord; return this; }
            public ProblemWordDetailBuilder cebuanoMeaning(String cebuanoMeaning) { this.cebuanoMeaning = cebuanoMeaning; return this; }
            public ProblemWordDetailBuilder errorCount(int errorCount) { this.errorCount = errorCount; return this; }
            public ProblemWordDetailBuilder demeritPoints(int demeritPoints) { this.demeritPoints = demeritPoints; return this; }
            public ProblemWordDetailBuilder mistakeCount(int mistakeCount) { this.mistakeCount = mistakeCount; return this; }
            public ProblemWordDetailBuilder affectedLearners(int affectedLearners) { this.affectedLearners = affectedLearners; return this; }

            public ProblemWordDetail build() {
                ProblemWordDetail p = new ProblemWordDetail();
                p.wordId = this.wordId;
                p.englishWord = this.englishWord;
                p.cebuanoMeaning = this.cebuanoMeaning;
                p.errorCount = this.errorCount;
                p.demeritPoints = this.demeritPoints;
                p.mistakeCount = this.mistakeCount;
                p.affectedLearners = this.affectedLearners;
                return p;
            }
        }
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

        /** Specific words in this lesson that caused the errors, sorted descending by mistake count. */
        private List<ProblemWordDetail> problemWords;

        /** Number of distinct learners who made at least one error on a word in this lesson. */
        private int affectedLearners;

        /** Total incorrect review items across all learners for words in this lesson. */
        private int totalErrors;

        /** Short human-readable recommendation, e.g. "Review vocabulary in Lesson 3". */
        private String recommendation;

        public int getTotalErrors() { return totalErrors; }

        public static CurriculumGapDetailBuilder builder() { return new CurriculumGapDetailBuilder(); }

        public static class CurriculumGapDetailBuilder {
            private UUID lessonId;
            private String lessonTitle;
            private String categoryName;
            private List<ProblemWordDetail> problemWords;
            private int affectedLearners;
            private int totalErrors;
            private String recommendation;

            public CurriculumGapDetailBuilder lessonId(UUID lessonId) { this.lessonId = lessonId; return this; }
            public CurriculumGapDetailBuilder lessonTitle(String lessonTitle) { this.lessonTitle = lessonTitle; return this; }
            public CurriculumGapDetailBuilder categoryName(String categoryName) { this.categoryName = categoryName; return this; }
            public CurriculumGapDetailBuilder problemWords(List<ProblemWordDetail> problemWords) { this.problemWords = problemWords; return this; }
            public CurriculumGapDetailBuilder affectedLearners(int affectedLearners) { this.affectedLearners = affectedLearners; return this; }
            public CurriculumGapDetailBuilder totalErrors(int totalErrors) { this.totalErrors = totalErrors; return this; }
            public CurriculumGapDetailBuilder recommendation(String recommendation) { this.recommendation = recommendation; return this; }

            public CurriculumGapDetail build() {
                CurriculumGapDetail d = new CurriculumGapDetail();
                d.lessonId = this.lessonId;
                d.lessonTitle = this.lessonTitle;
                d.categoryName = this.categoryName;
                d.problemWords = this.problemWords;
                d.affectedLearners = this.affectedLearners;
                d.totalErrors = this.totalErrors;
                d.recommendation = this.recommendation;
                return d;
            }
        }
    }

    public static WrongAnswerAnalysisResponseBuilder builder() { return new WrongAnswerAnalysisResponseBuilder(); }

    public static class WrongAnswerAnalysisResponseBuilder {
        private int totalClassErrors;
        private int learnersWithErrors;
        private List<ConfusedPairDetail> confusedPairs;
        private List<CurriculumGapDetail> curriculumGaps;

        public WrongAnswerAnalysisResponseBuilder totalClassErrors(int totalClassErrors) { this.totalClassErrors = totalClassErrors; return this; }
        public WrongAnswerAnalysisResponseBuilder learnersWithErrors(int learnersWithErrors) { this.learnersWithErrors = learnersWithErrors; return this; }
        public WrongAnswerAnalysisResponseBuilder confusedPairs(List<ConfusedPairDetail> confusedPairs) { this.confusedPairs = confusedPairs; return this; }
        public WrongAnswerAnalysisResponseBuilder curriculumGaps(List<CurriculumGapDetail> curriculumGaps) { this.curriculumGaps = curriculumGaps; return this; }

        public WrongAnswerAnalysisResponse build() {
            WrongAnswerAnalysisResponse r = new WrongAnswerAnalysisResponse();
            r.totalClassErrors = this.totalClassErrors;
            r.learnersWithErrors = this.learnersWithErrors;
            r.confusedPairs = this.confusedPairs;
            r.curriculumGaps = this.curriculumGaps;
            return r;
        }
    }
}
