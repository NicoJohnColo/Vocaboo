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
}
