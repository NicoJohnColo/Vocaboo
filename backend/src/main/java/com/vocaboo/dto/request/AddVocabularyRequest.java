package com.vocaboo.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AddVocabularyRequest {

    @NotBlank(message = "English word is required")
    @Size(min = 2, max = 100, message = "English word must be between 2 and 100 characters")
    private String englishWord;

    @NotBlank(message = "Cebuano meaning is required")
    @Size(min = 2, max = 200, message = "Cebuano meaning must be between 2 and 200 characters")
    private String cebuanoMeaning;

    @NotBlank(message = "Part of speech is required")
    @Pattern(regexp = "NOUN|VERB|ADJECTIVE", message = "Part of speech must be NOUN, VERB, or ADJECTIVE")
    private String partOfSpeech;

    @NotBlank(message = "Grade level is required")
    @Pattern(regexp = "GRADE_4|GRADE_5|GRADE_6", message = "Grade level must be GRADE_4, GRADE_5, or GRADE_6")
    private String gradeLevel;

    @NotBlank(message = "English example sentence is required")
    @Size(min = 10, max = 500, message = "English example sentence must be between 10 and 500 characters")
    private String exampleSentenceEnglish;

    @Size(max = 500, message = "Cebuano example sentence cannot exceed 500 characters")
    private String exampleSentenceCebuano;

    private String audioAssetPath;
    private String imageAssetPath;

    // ── Per-word Activity Content Fields ─────────────────────────────────────

    /** Comma-separated wrong-answer candidates (3-5 same-POS words), e.g. "eraser,ruler,scissors" */
    private String distractorPool;

    /** Sentence with {BLANK} placeholder, e.g. "I sharpen my {BLANK} before class." */
    private String fillBlankSentence;

    /** Full correct sentence for Word Tile Arrangement (app scrambles at runtime) */
    private String tileSentence;

    /** Optional hint shown only at LEARNING difficulty level */
    private String explanationText;

    /** Exact text fed to Cebuano TTS */
    private String audioTextCebuano;

    /** Exact text fed to English TTS */
    private String audioTextEnglish;
    
    private String eligibleActivityTypes;

    private String phonologicalTipKey;
    
    private Boolean isConfusablePairMember;

    /** Short English definition/synonym clue for HINT_TO_WORD activity (FAMILIAR/PROFICIENT) */
    private String hintDefinition;

    /** Short Cebuano clue for HINT_TO_WORD activity (LEARNING) */
    private String hintCebuanoSentence;

    public String getEnglishWord() { return englishWord; }
    public String getCebuanoMeaning() { return cebuanoMeaning; }
    public String getPartOfSpeech() { return partOfSpeech; }
    public String getGradeLevel() { return gradeLevel; }
    public String getExampleSentenceEnglish() { return exampleSentenceEnglish; }
    public String getExampleSentenceCebuano() { return exampleSentenceCebuano; }
    public String getAudioAssetPath() { return audioAssetPath; }
    public String getImageAssetPath() { return imageAssetPath; }
    public String getDistractorPool() { return distractorPool; }
    public String getFillBlankSentence() { return fillBlankSentence; }
    public String getTileSentence() { return tileSentence; }
    public String getExplanationText() { return explanationText; }
    public String getAudioTextCebuano() { return audioTextCebuano; }
    public String getAudioTextEnglish() { return audioTextEnglish; }
    public String getEligibleActivityTypes() { return eligibleActivityTypes; }
    public String getPhonologicalTipKey() { return phonologicalTipKey; }
    public Boolean getIsConfusablePairMember() { return isConfusablePairMember; }
    public String getHintDefinition() { return hintDefinition; }
    public String getHintCebuanoSentence() { return hintCebuanoSentence; }
}
