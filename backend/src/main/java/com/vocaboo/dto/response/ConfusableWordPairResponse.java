package com.vocaboo.dto.response;

import lombok.*;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ConfusableWordPairResponse {
    private UUID pairId;
    private UUID lessonId;
    private VocabularyWordResponse wordA;
    private VocabularyWordResponse wordB;
    private String contrastiveSentenceA;
    private String contrastiveSentenceB;

    public static ConfusableWordPairResponseBuilder builder() { return new ConfusableWordPairResponseBuilder(); }

    public static class ConfusableWordPairResponseBuilder {
        private UUID pairId;
        private UUID lessonId;
        private VocabularyWordResponse wordA;
        private VocabularyWordResponse wordB;
        private String contrastiveSentenceA;
        private String contrastiveSentenceB;

        public ConfusableWordPairResponseBuilder pairId(UUID pairId) { this.pairId = pairId; return this; }
        public ConfusableWordPairResponseBuilder lessonId(UUID lessonId) { this.lessonId = lessonId; return this; }
        public ConfusableWordPairResponseBuilder wordA(VocabularyWordResponse wordA) { this.wordA = wordA; return this; }
        public ConfusableWordPairResponseBuilder wordB(VocabularyWordResponse wordB) { this.wordB = wordB; return this; }
        public ConfusableWordPairResponseBuilder contrastiveSentenceA(String contrastiveSentenceA) { this.contrastiveSentenceA = contrastiveSentenceA; return this; }
        public ConfusableWordPairResponseBuilder contrastiveSentenceB(String contrastiveSentenceB) { this.contrastiveSentenceB = contrastiveSentenceB; return this; }

        public ConfusableWordPairResponse build() {
            ConfusableWordPairResponse c = new ConfusableWordPairResponse();
            c.pairId = this.pairId;
            c.lessonId = this.lessonId;
            c.wordA = this.wordA;
            c.wordB = this.wordB;
            c.contrastiveSentenceA = this.contrastiveSentenceA;
            c.contrastiveSentenceB = this.contrastiveSentenceB;
            return c;
        }
    }
}
