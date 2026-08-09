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

    @JsonProperty("hint_text")
    private String hintText;

    @JsonProperty("audio_text_cebuano")
    private String audioTextCebuano;

    @JsonProperty("audio_text_english")
    private String audioTextEnglish;
}
