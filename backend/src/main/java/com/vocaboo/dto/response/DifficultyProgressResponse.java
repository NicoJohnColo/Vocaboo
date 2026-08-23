package com.vocaboo.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.OffsetDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DifficultyProgressResponse {
    private UUID progressId;
    private UUID learnerId;
    private UUID wordId;
    private String currentLevel;
    private Integer consecutiveCorrect;
    private Integer consecutiveIncorrect;
    /** True if at least one recall-type activity is in the current streak (required for tier advancement). */
    private Boolean recallInCurrentStreak;
    /** Attempts at the current tier level — resets to 1 on every tier change for correct points calculation. */
    private Integer attemptCountAtCurrentTier;
    private Boolean needsReintroduction;
    private Integer reintroductionCount;
    private OffsetDateTime lastReintroducedAt;
    private Boolean needsTeacherReview;
    private Boolean diagnosticAdministered;
    private String diagnosticResult;
    private String diagnosticActivityType;
    private Boolean showExplanations;
    private OffsetDateTime lastAdjustedAt;

    public String getCurrentLevel() { return currentLevel; }

    public static DifficultyProgressResponseBuilder builder() { return new DifficultyProgressResponseBuilder(); }

    public static class DifficultyProgressResponseBuilder {
        private UUID progressId;
        private UUID learnerId;
        private UUID wordId;
        private String currentLevel;
        private Integer consecutiveCorrect;
        private Integer consecutiveIncorrect;
        private Boolean recallInCurrentStreak;
        private Integer attemptCountAtCurrentTier;
        private Boolean needsReintroduction;
        private Integer reintroductionCount;
        private OffsetDateTime lastReintroducedAt;
        private Boolean needsTeacherReview;
        private Boolean diagnosticAdministered;
        private String diagnosticResult;
        private String diagnosticActivityType;
        private Boolean showExplanations;
        private OffsetDateTime lastAdjustedAt;

        public DifficultyProgressResponseBuilder progressId(UUID progressId) { this.progressId = progressId; return this; }
        public DifficultyProgressResponseBuilder learnerId(UUID learnerId) { this.learnerId = learnerId; return this; }
        public DifficultyProgressResponseBuilder wordId(UUID wordId) { this.wordId = wordId; return this; }
        public DifficultyProgressResponseBuilder currentLevel(String currentLevel) { this.currentLevel = currentLevel; return this; }
        public DifficultyProgressResponseBuilder consecutiveCorrect(Integer consecutiveCorrect) { this.consecutiveCorrect = consecutiveCorrect; return this; }
        public DifficultyProgressResponseBuilder consecutiveIncorrect(Integer consecutiveIncorrect) { this.consecutiveIncorrect = consecutiveIncorrect; return this; }
        public DifficultyProgressResponseBuilder recallInCurrentStreak(Boolean recallInCurrentStreak) { this.recallInCurrentStreak = recallInCurrentStreak; return this; }
        public DifficultyProgressResponseBuilder attemptCountAtCurrentTier(Integer attemptCountAtCurrentTier) { this.attemptCountAtCurrentTier = attemptCountAtCurrentTier; return this; }
        public DifficultyProgressResponseBuilder needsReintroduction(Boolean needsReintroduction) { this.needsReintroduction = needsReintroduction; return this; }
        public DifficultyProgressResponseBuilder reintroductionCount(Integer reintroductionCount) { this.reintroductionCount = reintroductionCount; return this; }
        public DifficultyProgressResponseBuilder lastReintroducedAt(OffsetDateTime lastReintroducedAt) { this.lastReintroducedAt = lastReintroducedAt; return this; }
        public DifficultyProgressResponseBuilder needsTeacherReview(Boolean needsTeacherReview) { this.needsTeacherReview = needsTeacherReview; return this; }
        public DifficultyProgressResponseBuilder diagnosticAdministered(Boolean diagnosticAdministered) { this.diagnosticAdministered = diagnosticAdministered; return this; }
        public DifficultyProgressResponseBuilder diagnosticResult(String diagnosticResult) { this.diagnosticResult = diagnosticResult; return this; }
        public DifficultyProgressResponseBuilder diagnosticActivityType(String diagnosticActivityType) { this.diagnosticActivityType = diagnosticActivityType; return this; }
        public DifficultyProgressResponseBuilder showExplanations(Boolean showExplanations) { this.showExplanations = showExplanations; return this; }
        public DifficultyProgressResponseBuilder lastAdjustedAt(OffsetDateTime lastAdjustedAt) { this.lastAdjustedAt = lastAdjustedAt; return this; }

        public DifficultyProgressResponse build() {
            DifficultyProgressResponse r = new DifficultyProgressResponse();
            r.progressId = this.progressId;
            r.learnerId = this.learnerId;
            r.wordId = this.wordId;
            r.currentLevel = this.currentLevel;
            r.consecutiveCorrect = this.consecutiveCorrect;
            r.consecutiveIncorrect = this.consecutiveIncorrect;
            r.recallInCurrentStreak = this.recallInCurrentStreak;
            r.attemptCountAtCurrentTier = this.attemptCountAtCurrentTier;
            r.needsReintroduction = this.needsReintroduction;
            r.reintroductionCount = this.reintroductionCount;
            r.lastReintroducedAt = this.lastReintroducedAt;
            r.needsTeacherReview = this.needsTeacherReview;
            r.diagnosticAdministered = this.diagnosticAdministered;
            r.diagnosticResult = this.diagnosticResult;
            r.diagnosticActivityType = this.diagnosticActivityType;
            r.showExplanations = this.showExplanations;
            r.lastAdjustedAt = this.lastAdjustedAt;
            return r;
        }
    }
}
