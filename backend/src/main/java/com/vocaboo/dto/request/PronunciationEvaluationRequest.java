package com.vocaboo.dto.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PronunciationEvaluationRequest {

    @NotNull(message = "Session ID is required")
    private UUID sessionId;

    @NotNull(message = "Word ID is required")
    private UUID wordId;

    @NotNull(message = "Lesson ID is required")
    private UUID lessonId;

    @NotNull(message = "Module number is required")
    @Min(1)
    @Max(3)
    private Integer moduleNumber;

    @NotBlank(message = "Target word is required")
    private String targetWord;

    @NotBlank(message = "Audio data (Base64) is required")
    private String audioBase64;

    @NotNull(message = "Attempt number is required")
    @Min(1)
    @Max(3)
    private Integer attemptNumber;

    public UUID getSessionId() { return sessionId; }
    public UUID getWordId() { return wordId; }
    public UUID getLessonId() { return lessonId; }
    public Integer getModuleNumber() { return moduleNumber; }
    public String getTargetWord() { return targetWord; }
    public String getAudioBase64() { return audioBase64; }
    public Integer getAttemptNumber() { return attemptNumber; }
}
