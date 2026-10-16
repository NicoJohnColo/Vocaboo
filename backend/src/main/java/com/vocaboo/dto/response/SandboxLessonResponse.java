package com.vocaboo.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SandboxLessonResponse {
    private UUID sandboxWordId;
    private String englishWord;
    private String cebuanoMeaning;
    private String englishExampleSentence;
    private String exampleSentenceCebuano;
    private String phonologicalTip;
    private List<String> multipleChoiceDistractors;
    private String fillInTheBlankSentence;
    private List<MatchingWordResponse> matchingSet;
    private List<String> sentenceArrangementTokens;
    private String sentenceCompletionBlank;
    private List<String> sentenceCompletionOptions;
    private String trueOrFalseStatement;
    private Boolean trueOrFalseAnswer;
    private String hintClue;
    private String confusablePartnerWord;
    private String confusableCebuanoDistinction;
    private String confusableContrastSentenceA;
    private String confusableContrastSentenceB;

    public static SandboxLessonResponseBuilder builder() { return new SandboxLessonResponseBuilder(); }

    public static class SandboxLessonResponseBuilder {
        private UUID sandboxWordId;
        private String englishWord;
        private String cebuanoMeaning;
        private String englishExampleSentence;
        private String exampleSentenceCebuano;
        private String phonologicalTip;
        private List<String> multipleChoiceDistractors;
        private String fillInTheBlankSentence;
        private List<MatchingWordResponse> matchingSet;
        private List<String> sentenceArrangementTokens;
        private String sentenceCompletionBlank;
        private List<String> sentenceCompletionOptions;
        private String trueOrFalseStatement;
        private Boolean trueOrFalseAnswer;
        private String hintClue;
        private String confusablePartnerWord;
        private String confusableCebuanoDistinction;
        private String confusableContrastSentenceA;
        private String confusableContrastSentenceB;

        public SandboxLessonResponseBuilder sandboxWordId(UUID sandboxWordId) { this.sandboxWordId = sandboxWordId; return this; }
        public SandboxLessonResponseBuilder englishWord(String englishWord) { this.englishWord = englishWord; return this; }
        public SandboxLessonResponseBuilder cebuanoMeaning(String cebuanoMeaning) { this.cebuanoMeaning = cebuanoMeaning; return this; }
        public SandboxLessonResponseBuilder englishExampleSentence(String englishExampleSentence) { this.englishExampleSentence = englishExampleSentence; return this; }
        public SandboxLessonResponseBuilder exampleSentenceCebuano(String exampleSentenceCebuano) { this.exampleSentenceCebuano = exampleSentenceCebuano; return this; }
        public SandboxLessonResponseBuilder phonologicalTip(String phonologicalTip) { this.phonologicalTip = phonologicalTip; return this; }
        public SandboxLessonResponseBuilder multipleChoiceDistractors(List<String> multipleChoiceDistractors) { this.multipleChoiceDistractors = multipleChoiceDistractors; return this; }
        public SandboxLessonResponseBuilder fillInTheBlankSentence(String fillInTheBlankSentence) { this.fillInTheBlankSentence = fillInTheBlankSentence; return this; }
        public SandboxLessonResponseBuilder matchingSet(List<MatchingWordResponse> matchingSet) { this.matchingSet = matchingSet; return this; }
        public SandboxLessonResponseBuilder sentenceArrangementTokens(List<String> sentenceArrangementTokens) { this.sentenceArrangementTokens = sentenceArrangementTokens; return this; }
        public SandboxLessonResponseBuilder sentenceCompletionBlank(String sentenceCompletionBlank) { this.sentenceCompletionBlank = sentenceCompletionBlank; return this; }
        public SandboxLessonResponseBuilder sentenceCompletionOptions(List<String> sentenceCompletionOptions) { this.sentenceCompletionOptions = sentenceCompletionOptions; return this; }
        public SandboxLessonResponseBuilder trueOrFalseStatement(String trueOrFalseStatement) { this.trueOrFalseStatement = trueOrFalseStatement; return this; }
        public SandboxLessonResponseBuilder trueOrFalseAnswer(Boolean trueOrFalseAnswer) { this.trueOrFalseAnswer = trueOrFalseAnswer; return this; }
        public SandboxLessonResponseBuilder hintClue(String hintClue) { this.hintClue = hintClue; return this; }
        public SandboxLessonResponseBuilder confusablePartnerWord(String confusablePartnerWord) { this.confusablePartnerWord = confusablePartnerWord; return this; }
        public SandboxLessonResponseBuilder confusableCebuanoDistinction(String confusableCebuanoDistinction) { this.confusableCebuanoDistinction = confusableCebuanoDistinction; return this; }
        public SandboxLessonResponseBuilder confusableContrastSentenceA(String confusableContrastSentenceA) { this.confusableContrastSentenceA = confusableContrastSentenceA; return this; }
        public SandboxLessonResponseBuilder confusableContrastSentenceB(String confusableContrastSentenceB) { this.confusableContrastSentenceB = confusableContrastSentenceB; return this; }

        public SandboxLessonResponse build() {
            SandboxLessonResponse r = new SandboxLessonResponse();
            r.sandboxWordId = this.sandboxWordId;
            r.englishWord = this.englishWord;
            r.cebuanoMeaning = this.cebuanoMeaning;
            r.englishExampleSentence = this.englishExampleSentence;
            r.exampleSentenceCebuano = this.exampleSentenceCebuano;
            r.phonologicalTip = this.phonologicalTip;
            r.multipleChoiceDistractors = this.multipleChoiceDistractors;
            r.fillInTheBlankSentence = this.fillInTheBlankSentence;
            r.matchingSet = this.matchingSet;
            r.sentenceArrangementTokens = this.sentenceArrangementTokens;
            r.sentenceCompletionBlank = this.sentenceCompletionBlank;
            r.sentenceCompletionOptions = this.sentenceCompletionOptions;
            r.trueOrFalseStatement = this.trueOrFalseStatement;
            r.trueOrFalseAnswer = this.trueOrFalseAnswer;
            r.hintClue = this.hintClue;
            r.confusablePartnerWord = this.confusablePartnerWord;
            r.confusableCebuanoDistinction = this.confusableCebuanoDistinction;
            r.confusableContrastSentenceA = this.confusableContrastSentenceA;
            r.confusableContrastSentenceB = this.confusableContrastSentenceB;
            return r;
        }
    }
}