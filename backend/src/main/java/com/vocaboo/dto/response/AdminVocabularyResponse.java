package com.vocaboo.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AdminVocabularyResponse {
    @JsonProperty("word_id")
    private UUID wordId;
    
    @JsonProperty("lesson_id")
    private UUID lessonId;
    
    @JsonProperty("english_word")
    private String englishWord;
    
    @JsonProperty("cebuano_meaning")
    private String cebuanoMeaning;
    
    @JsonProperty("part_of_speech")
    private String partOfSpeech;
    
    @JsonProperty("grade_level")
    private String gradeLevel;
    
    @JsonProperty("word_order")
    private Integer wordOrder;
    
    @JsonProperty("example_sentence_english")
    private String exampleSentenceEnglish;
    
    @JsonProperty("example_sentence_cebuano")
    private String exampleSentenceCebuano;
    
    @JsonProperty("audio_asset_path")
    private String audioAssetPath;
    
    @JsonProperty("image_asset_path")
    private String imageAssetPath;
    
    @JsonProperty("audio_verified")
    private Boolean audioVerified;
    
    @JsonProperty("image_verified")
    private Boolean imageVerified;
    
    @JsonProperty("is_confusable_pair_member")
    private Boolean isConfusablePairMember;
    
    @JsonProperty("phonological_tip_key")
    private String phonologicalTipKey;
    
    @JsonProperty("created_at")
    private OffsetDateTime createdAt;
    
    @JsonProperty("updated_at")
    private OffsetDateTime updatedAt;

    // ── Per-word Activity Content Fields ─────────────────────────────────────

    @JsonProperty("distractor_pool")
    private String distractorPool;

    @JsonProperty("fill_blank_sentence")
    private String fillBlankSentence;

    @JsonProperty("tile_sentence")
    private String tileSentence;

    @JsonProperty("explanation_text")
    private String explanationText;

    @JsonProperty("audio_text_cebuano")
    private String audioTextCebuano;

    @JsonProperty("audio_text_english")
    private String audioTextEnglish;

    public static AdminVocabularyResponseBuilder builder() {
        return new AdminVocabularyResponseBuilder();
    }

    public static class AdminVocabularyResponseBuilder {
        private UUID wordId;
        private UUID lessonId;
        private String englishWord;
        private String cebuanoMeaning;
        private String partOfSpeech;
        private String gradeLevel;
        private Integer wordOrder;
        private String exampleSentenceEnglish;
        private String exampleSentenceCebuano;
        private String audioAssetPath;
        private String imageAssetPath;
        private Boolean audioVerified;
        private Boolean imageVerified;
        private Boolean isConfusablePairMember;
        private String phonologicalTipKey;
        private OffsetDateTime createdAt;
        private OffsetDateTime updatedAt;
        private String distractorPool;
        private String fillBlankSentence;
        private String tileSentence;
        private String explanationText;
        private String audioTextCebuano;
        private String audioTextEnglish;

        public AdminVocabularyResponseBuilder wordId(UUID wordId) { this.wordId = wordId; return this; }
        public AdminVocabularyResponseBuilder lessonId(UUID lessonId) { this.lessonId = lessonId; return this; }
        public AdminVocabularyResponseBuilder englishWord(String englishWord) { this.englishWord = englishWord; return this; }
        public AdminVocabularyResponseBuilder cebuanoMeaning(String cebuanoMeaning) { this.cebuanoMeaning = cebuanoMeaning; return this; }
        public AdminVocabularyResponseBuilder partOfSpeech(String partOfSpeech) { this.partOfSpeech = partOfSpeech; return this; }
        public AdminVocabularyResponseBuilder gradeLevel(String gradeLevel) { this.gradeLevel = gradeLevel; return this; }
        public AdminVocabularyResponseBuilder wordOrder(Integer wordOrder) { this.wordOrder = wordOrder; return this; }
        public AdminVocabularyResponseBuilder exampleSentenceEnglish(String exampleSentenceEnglish) { this.exampleSentenceEnglish = exampleSentenceEnglish; return this; }
        public AdminVocabularyResponseBuilder exampleSentenceCebuano(String exampleSentenceCebuano) { this.exampleSentenceCebuano = exampleSentenceCebuano; return this; }
        public AdminVocabularyResponseBuilder audioAssetPath(String audioAssetPath) { this.audioAssetPath = audioAssetPath; return this; }
        public AdminVocabularyResponseBuilder imageAssetPath(String imageAssetPath) { this.imageAssetPath = imageAssetPath; return this; }
        public AdminVocabularyResponseBuilder audioVerified(Boolean audioVerified) { this.audioVerified = audioVerified; return this; }
        public AdminVocabularyResponseBuilder imageVerified(Boolean imageVerified) { this.imageVerified = imageVerified; return this; }
        public AdminVocabularyResponseBuilder isConfusablePairMember(Boolean isConfusablePairMember) { this.isConfusablePairMember = isConfusablePairMember; return this; }
        public AdminVocabularyResponseBuilder phonologicalTipKey(String phonologicalTipKey) { this.phonologicalTipKey = phonologicalTipKey; return this; }
        public AdminVocabularyResponseBuilder createdAt(OffsetDateTime createdAt) { this.createdAt = createdAt; return this; }
        public AdminVocabularyResponseBuilder updatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; return this; }
        public AdminVocabularyResponseBuilder distractorPool(String distractorPool) { this.distractorPool = distractorPool; return this; }
        public AdminVocabularyResponseBuilder fillBlankSentence(String fillBlankSentence) { this.fillBlankSentence = fillBlankSentence; return this; }
        public AdminVocabularyResponseBuilder tileSentence(String tileSentence) { this.tileSentence = tileSentence; return this; }
        public AdminVocabularyResponseBuilder explanationText(String explanationText) { this.explanationText = explanationText; return this; }
        public AdminVocabularyResponseBuilder audioTextCebuano(String audioTextCebuano) { this.audioTextCebuano = audioTextCebuano; return this; }
        public AdminVocabularyResponseBuilder audioTextEnglish(String audioTextEnglish) { this.audioTextEnglish = audioTextEnglish; return this; }

        public AdminVocabularyResponse build() {
            AdminVocabularyResponse r = new AdminVocabularyResponse();
            r.wordId = this.wordId;
            r.lessonId = this.lessonId;
            r.englishWord = this.englishWord;
            r.cebuanoMeaning = this.cebuanoMeaning;
            r.partOfSpeech = this.partOfSpeech;
            r.gradeLevel = this.gradeLevel;
            r.wordOrder = this.wordOrder;
            r.exampleSentenceEnglish = this.exampleSentenceEnglish;
            r.exampleSentenceCebuano = this.exampleSentenceCebuano;
            r.audioAssetPath = this.audioAssetPath;
            r.imageAssetPath = this.imageAssetPath;
            r.audioVerified = this.audioVerified;
            r.imageVerified = this.imageVerified;
            r.isConfusablePairMember = this.isConfusablePairMember;
            r.phonologicalTipKey = this.phonologicalTipKey;
            r.createdAt = this.createdAt;
            r.updatedAt = this.updatedAt;
            r.distractorPool = this.distractorPool;
            r.fillBlankSentence = this.fillBlankSentence;
            r.tileSentence = this.tileSentence;
            r.explanationText = this.explanationText;
            r.audioTextCebuano = this.audioTextCebuano;
            r.audioTextEnglish = this.audioTextEnglish;
            return r;
        }
    }
}
