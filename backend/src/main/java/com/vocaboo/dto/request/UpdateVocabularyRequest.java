package com.vocaboo.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdateVocabularyRequest {

    @Size(min = 2, max = 100, message = "English word must be between 2 and 100 characters")
    private String englishWord;

    @Size(min = 2, max = 200, message = "Cebuano meaning must be between 2 and 200 characters")
    private String cebuanoMeaning;

    @Pattern(regexp = "NOUN|VERB|ADJECTIVE|", message = "Part of speech must be NOUN, VERB, or ADJECTIVE")
    private String partOfSpeech;

    @Size(min = 10, max = 500, message = "English example sentence must be between 10 and 500 characters")
    private String exampleSentenceEnglish;

    @Size(max = 500, message = "Cebuano example sentence cannot exceed 500 characters")
    private String exampleSentenceCebuano;

    private String audioAssetPath;
    private String imageAssetPath;

    // ── Per-word Activity Content Fields ─────────────────────────────────────

    /** Comma-separated wrong-answer candidates (3-5 same-POS words) */
    private String distractorPool;

    /** Sentence with {BLANK} placeholder */
    private String fillBlankSentence;

    /** Full correct sentence for Word Tile Arrangement */
    private String tileSentence;

    /** Optional hint shown only at LEARNING difficulty level */
    private String hintText;

    /** Exact text fed to Cebuano TTS */
    private String audioTextCebuano;

    /** Exact text fed to English TTS */
    private String audioTextEnglish;
}
