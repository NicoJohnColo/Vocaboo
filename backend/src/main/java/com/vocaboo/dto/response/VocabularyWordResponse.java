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
    private String explanationText;
    private String audioTextCebuano;
    private String audioTextEnglish;
    /** Which activity format this word uses across all 4 difficulty tiers. */
    private String activityType;
    /** Eligible activity formats for this word. */
    private String eligibleActivityTypes;

    public static VocabularyWordResponseBuilder builder() { return new VocabularyWordResponseBuilder(); }

    public static class VocabularyWordResponseBuilder {
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
        private String distractorPool;
        private String fillBlankSentence;
        private String tileSentence;
        private String explanationText;
        private String audioTextCebuano;
        private String audioTextEnglish;
        private String activityType;
        private String eligibleActivityTypes;

        public VocabularyWordResponseBuilder wordId(UUID wordId) { this.wordId = wordId; return this; }
        public VocabularyWordResponseBuilder lessonId(UUID lessonId) { this.lessonId = lessonId; return this; }
        public VocabularyWordResponseBuilder englishWord(String englishWord) { this.englishWord = englishWord; return this; }
        public VocabularyWordResponseBuilder cebuanoMeaning(String cebuanoMeaning) { this.cebuanoMeaning = cebuanoMeaning; return this; }
        public VocabularyWordResponseBuilder exampleSentenceEnglish(String exampleSentenceEnglish) { this.exampleSentenceEnglish = exampleSentenceEnglish; return this; }
        public VocabularyWordResponseBuilder exampleSentenceCebuano(String exampleSentenceCebuano) { this.exampleSentenceCebuano = exampleSentenceCebuano; return this; }
        public VocabularyWordResponseBuilder audioAssetPath(String audioAssetPath) { this.audioAssetPath = audioAssetPath; return this; }
        public VocabularyWordResponseBuilder imageAssetPath(String imageAssetPath) { this.imageAssetPath = imageAssetPath; return this; }
        public VocabularyWordResponseBuilder partOfSpeech(String partOfSpeech) { this.partOfSpeech = partOfSpeech; return this; }
        public VocabularyWordResponseBuilder gradeLevel(GradeLevel gradeLevel) { this.gradeLevel = gradeLevel; return this; }
        public VocabularyWordResponseBuilder wordOrder(Integer wordOrder) { this.wordOrder = wordOrder; return this; }
        public VocabularyWordResponseBuilder isConfusablePairMember(Boolean isConfusablePairMember) { this.isConfusablePairMember = isConfusablePairMember; return this; }
        public VocabularyWordResponseBuilder phonologicalTipKey(String phonologicalTipKey) { this.phonologicalTipKey = phonologicalTipKey; return this; }
        public VocabularyWordResponseBuilder distractorPool(String distractorPool) { this.distractorPool = distractorPool; return this; }
        public VocabularyWordResponseBuilder fillBlankSentence(String fillBlankSentence) { this.fillBlankSentence = fillBlankSentence; return this; }
        public VocabularyWordResponseBuilder tileSentence(String tileSentence) { this.tileSentence = tileSentence; return this; }
        public VocabularyWordResponseBuilder explanationText(String explanationText) { this.explanationText = explanationText; return this; }
        public VocabularyWordResponseBuilder audioTextCebuano(String audioTextCebuano) { this.audioTextCebuano = audioTextCebuano; return this; }
        public VocabularyWordResponseBuilder audioTextEnglish(String audioTextEnglish) { this.audioTextEnglish = audioTextEnglish; return this; }
        public VocabularyWordResponseBuilder activityType(String activityType) { this.activityType = activityType; return this; }
        public VocabularyWordResponseBuilder eligibleActivityTypes(String eligibleActivityTypes) { this.eligibleActivityTypes = eligibleActivityTypes; return this; }

        public VocabularyWordResponse build() {
            VocabularyWordResponse r = new VocabularyWordResponse();
            r.wordId = this.wordId;
            r.lessonId = this.lessonId;
            r.englishWord = this.englishWord;
            r.cebuanoMeaning = this.cebuanoMeaning;
            r.exampleSentenceEnglish = this.exampleSentenceEnglish;
            r.exampleSentenceCebuano = this.exampleSentenceCebuano;
            r.audioAssetPath = this.audioAssetPath;
            r.imageAssetPath = this.imageAssetPath;
            r.partOfSpeech = this.partOfSpeech;
            r.gradeLevel = this.gradeLevel;
            r.wordOrder = this.wordOrder;
            r.isConfusablePairMember = this.isConfusablePairMember;
            r.phonologicalTipKey = this.phonologicalTipKey;
            r.distractorPool = this.distractorPool;
            r.fillBlankSentence = this.fillBlankSentence;
            r.tileSentence = this.tileSentence;
            r.explanationText = this.explanationText;
            r.audioTextCebuano = this.audioTextCebuano;
            r.audioTextEnglish = this.audioTextEnglish;
            r.activityType = this.activityType;
            r.eligibleActivityTypes = this.eligibleActivityTypes;
            return r;
        }
    }
}
