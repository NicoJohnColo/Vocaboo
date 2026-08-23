package com.vocaboo.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MatchingWordResponse {
    private String englishWord;
    private String cebuanoMeaning;
    private String cebuanoTranslation;
    private String imageAssetPath;

    public static MatchingWordResponseBuilder builder() { return new MatchingWordResponseBuilder(); }

    public static class MatchingWordResponseBuilder {
        private String englishWord;
        private String cebuanoMeaning;
        private String cebuanoTranslation;
        private String imageAssetPath;

        public MatchingWordResponseBuilder englishWord(String englishWord) { this.englishWord = englishWord; return this; }
        public MatchingWordResponseBuilder cebuanoMeaning(String cebuanoMeaning) { this.cebuanoMeaning = cebuanoMeaning; return this; }
        public MatchingWordResponseBuilder cebuanoTranslation(String cebuanoTranslation) { this.cebuanoTranslation = cebuanoTranslation; return this; }
        public MatchingWordResponseBuilder imageAssetPath(String imageAssetPath) { this.imageAssetPath = imageAssetPath; return this; }

        public MatchingWordResponse build() {
            MatchingWordResponse r = new MatchingWordResponse();
            r.englishWord = this.englishWord;
            r.cebuanoMeaning = this.cebuanoMeaning;
            r.cebuanoTranslation = this.cebuanoTranslation;
            r.imageAssetPath = this.imageAssetPath;
            return r;
        }
    }
}