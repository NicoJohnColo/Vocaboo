package com.vocaboo.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReintroductionResponse {
    private UUID wordId;
    private String englishWord;
    private String cebuanoMeaning;
    private String exampleSentenceEnglish;
    private String exampleSentenceCebuano;
    private String highlightedSentenceEnglish;
    private String audioAssetPath;
    private Double pronunciationThreshold;

    public static ReintroductionResponseBuilder builder() { return new ReintroductionResponseBuilder(); }

    public static class ReintroductionResponseBuilder {
        private UUID wordId;
        private String englishWord;
        private String cebuanoMeaning;
        private String exampleSentenceEnglish;
        private String exampleSentenceCebuano;
        private String highlightedSentenceEnglish;
        private String audioAssetPath;
        private Double pronunciationThreshold;

        public ReintroductionResponseBuilder wordId(UUID wordId) { this.wordId = wordId; return this; }
        public ReintroductionResponseBuilder englishWord(String englishWord) { this.englishWord = englishWord; return this; }
        public ReintroductionResponseBuilder cebuanoMeaning(String cebuanoMeaning) { this.cebuanoMeaning = cebuanoMeaning; return this; }
        public ReintroductionResponseBuilder exampleSentenceEnglish(String exampleSentenceEnglish) { this.exampleSentenceEnglish = exampleSentenceEnglish; return this; }
        public ReintroductionResponseBuilder exampleSentenceCebuano(String exampleSentenceCebuano) { this.exampleSentenceCebuano = exampleSentenceCebuano; return this; }
        public ReintroductionResponseBuilder highlightedSentenceEnglish(String highlightedSentenceEnglish) { this.highlightedSentenceEnglish = highlightedSentenceEnglish; return this; }
        public ReintroductionResponseBuilder audioAssetPath(String audioAssetPath) { this.audioAssetPath = audioAssetPath; return this; }
        public ReintroductionResponseBuilder pronunciationThreshold(Double pronunciationThreshold) { this.pronunciationThreshold = pronunciationThreshold; return this; }

        public ReintroductionResponse build() {
            ReintroductionResponse r = new ReintroductionResponse();
            r.wordId = this.wordId;
            r.englishWord = this.englishWord;
            r.cebuanoMeaning = this.cebuanoMeaning;
            r.exampleSentenceEnglish = this.exampleSentenceEnglish;
            r.exampleSentenceCebuano = this.exampleSentenceCebuano;
            r.highlightedSentenceEnglish = this.highlightedSentenceEnglish;
            r.audioAssetPath = this.audioAssetPath;
            r.pronunciationThreshold = this.pronunciationThreshold;
            return r;
        }
    }
}
