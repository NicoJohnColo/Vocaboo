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
public class MatchingSetEntryResponse {
    private String englishWord;
    private String cebuanoMeaning;
    private String imageAssetPath;

    public static MatchingSetEntryResponseBuilder builder() { return new MatchingSetEntryResponseBuilder(); }

    public static class MatchingSetEntryResponseBuilder {
        private String englishWord;
        private String cebuanoMeaning;
        private String imageAssetPath;

        public MatchingSetEntryResponseBuilder englishWord(String englishWord) { this.englishWord = englishWord; return this; }
        public MatchingSetEntryResponseBuilder cebuanoMeaning(String cebuanoMeaning) { this.cebuanoMeaning = cebuanoMeaning; return this; }
        public MatchingSetEntryResponseBuilder imageAssetPath(String imageAssetPath) { this.imageAssetPath = imageAssetPath; return this; }

        public MatchingSetEntryResponse build() {
            MatchingSetEntryResponse r = new MatchingSetEntryResponse();
            r.englishWord = this.englishWord;
            r.cebuanoMeaning = this.cebuanoMeaning;
            r.imageAssetPath = this.imageAssetPath;
            return r;
        }
    }
}