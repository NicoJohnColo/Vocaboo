package com.vocaboo.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SandboxLessonResponse {
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
}