package com.vocaboo.dto.response;

import com.vocaboo.entity.GradeLevel;
import lombok.*;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VocabularyWordResponse {
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
    
    // Per-word activity content fields
    private String distractorPool;
    private String fillBlankSentence;
    private String tileSentence;
    private String hintText;
    private String audioTextCebuano;
    private String audioTextEnglish;
    /** Which activity format this word uses across all 4 difficulty tiers. */
    private String activityType;
    /** Eligible activity formats for this word. */
    private String eligibleActivityTypes;
}
