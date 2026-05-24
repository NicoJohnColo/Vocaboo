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
}
