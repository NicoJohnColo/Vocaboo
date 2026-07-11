package com.vocaboo.dto.response;

import lombok.*;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PronunciationAttemptResponse {
    private UUID attemptId;
    private Boolean isCorrect;
    private String transcribedText;
    private String phoneticTarget;
    private String phonologicalTip;
    private Integer attemptNumber;
    private Boolean isInconclusive;
    private Double similarityScore;
}
