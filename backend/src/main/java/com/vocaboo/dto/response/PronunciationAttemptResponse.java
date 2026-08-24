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
    private Boolean manualTeacherFallback;
    private Integer pointsEarned;

    public static PronunciationAttemptResponseBuilder builder() { return new PronunciationAttemptResponseBuilder(); }

    public static class PronunciationAttemptResponseBuilder {
        private UUID attemptId;
        private Boolean isCorrect;
        private String transcribedText;
        private String phoneticTarget;
        private String phonologicalTip;
        private Integer attemptNumber;
        private Boolean isInconclusive;
        private Double similarityScore;
        private Boolean manualTeacherFallback;
        private Integer pointsEarned;

        public PronunciationAttemptResponseBuilder attemptId(UUID attemptId) { this.attemptId = attemptId; return this; }
        public PronunciationAttemptResponseBuilder isCorrect(Boolean isCorrect) { this.isCorrect = isCorrect; return this; }
        public PronunciationAttemptResponseBuilder transcribedText(String transcribedText) { this.transcribedText = transcribedText; return this; }
        public PronunciationAttemptResponseBuilder phoneticTarget(String phoneticTarget) { this.phoneticTarget = phoneticTarget; return this; }
        public PronunciationAttemptResponseBuilder phonologicalTip(String phonologicalTip) { this.phonologicalTip = phonologicalTip; return this; }
        public PronunciationAttemptResponseBuilder attemptNumber(Integer attemptNumber) { this.attemptNumber = attemptNumber; return this; }
        public PronunciationAttemptResponseBuilder isInconclusive(Boolean isInconclusive) { this.isInconclusive = isInconclusive; return this; }
        public PronunciationAttemptResponseBuilder similarityScore(Double similarityScore) { this.similarityScore = similarityScore; return this; }
        public PronunciationAttemptResponseBuilder manualTeacherFallback(Boolean manualTeacherFallback) { this.manualTeacherFallback = manualTeacherFallback; return this; }
        public PronunciationAttemptResponseBuilder pointsEarned(Integer pointsEarned) { this.pointsEarned = pointsEarned; return this; }

        public PronunciationAttemptResponse build() {
            PronunciationAttemptResponse r = new PronunciationAttemptResponse();
            r.attemptId = this.attemptId;
            r.isCorrect = this.isCorrect;
            r.transcribedText = this.transcribedText;
            r.phoneticTarget = this.phoneticTarget;
            r.phonologicalTip = this.phonologicalTip;
            r.attemptNumber = this.attemptNumber;
            r.isInconclusive = this.isInconclusive;
            r.similarityScore = this.similarityScore;
            r.manualTeacherFallback = this.manualTeacherFallback;
            r.pointsEarned = this.pointsEarned;
            return r;
        }
    }
}
