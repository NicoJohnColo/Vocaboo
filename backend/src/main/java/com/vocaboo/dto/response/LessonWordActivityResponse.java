package com.vocaboo.dto.response;

import com.vocaboo.entity.GradeLevel;
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
public class LessonWordActivityResponse {
    private UUID wordId;
    private UUID lessonId;
    private String englishWord;
    private String cebuanoMeaning;
    private String exampleSentenceEnglish;
    private String exampleSentenceCebuano;
    private String audioAssetPath;
    private String imageAssetPath;
    private String partOfSpeech;
    private GradeLevel gradeLevel;
    private Integer wordOrder;
    private Boolean isConfusablePairMember;
    private String phonologicalTipKey;
    private String mcDistractor1;
    private String mcDistractor2;
    private String mcDistractor3;
    private String fitbSentence;
    private String fitbAnswer;
    private List<MatchingSetEntryResponse> matchingSet;
    private List<String> sentenceArrangementTokens;
    private String sentenceCompletionSentence;
    private String sentenceCompletionAnswer;
    private String sentenceCompletionOption1;
    private String sentenceCompletionOption2;
    private String sentenceCompletionOption3;
}