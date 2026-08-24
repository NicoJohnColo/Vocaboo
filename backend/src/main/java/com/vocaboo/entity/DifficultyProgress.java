package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(
    name = "difficulty_progress",
    uniqueConstraints = {
        @UniqueConstraint(columnNames = {"learner_id", "word_id", "module_number"})
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DifficultyProgress {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "progress_id", updatable = false, nullable = false)
    private UUID progressId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "learner_id", nullable = false)
    private Learner learner;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "word_id", nullable = false)
    private VocabularyWord word;

    @Column(name = "module_number", nullable = false)
    @Builder.Default
    private Integer moduleNumber = 2;


    @Enumerated(EnumType.STRING)
    @Column(name = "current_level", nullable = false)
    @Builder.Default
    private DifficultyLevel currentLevel = DifficultyLevel.LEARNING;

    @Column(name = "consecutive_correct", nullable = false)
    @Builder.Default
    private Integer consecutiveCorrect = 0;

    @Column(name = "consecutive_incorrect", nullable = false)
    @Builder.Default
    private Integer consecutiveIncorrect = 0;

    /**
     * True if at least one RECALL-type activity (Fill-in-Blank, Word Scramble, Matching,
     * Sentence Completion, Sentence Rearrangement) has been answered correctly during
     * the current consecutive-correct streak. Reset to false whenever the streak resets.
     * Required by the anti-guessing gate: a streak only triggers tier advancement when
     * this flag is true.
     */
    @Column(name = "recall_in_current_streak", nullable = false)
    @Builder.Default
    private Boolean recallInCurrentStreak = false;

    @Column(name = "sentence_completion_cleared", nullable = false)
    @Builder.Default
    private Boolean sentenceCompletionClearedAtCurrentTier = false;

    @Column(name = "sentence_rearrangement_cleared", nullable = false)
    @Builder.Default
    private Boolean sentenceRearrangementClearedAtCurrentTier = false;

    /**
     * Counts attempts made at the current tier level. Resets to 1 on every tier change
     * (up OR down) so that the first correct answer at any new tier always earns 10 pts.
     */
    @Column(name = "attempt_count_at_current_tier", nullable = false)
    @Builder.Default
    private Integer attemptCountAtCurrentTier = 1;

    @Column(name = "mastery_bonus_awarded", nullable = false)
    @Builder.Default
    private Boolean masteryBonusAwarded = false;



    @Column(name = "needs_reintroduction", nullable = false)
    @Builder.Default
    private Boolean needsReintroduction = false;

    @Column(name = "reintroduction_count", nullable = false)
    @Builder.Default
    private Integer reintroductionCount = 0;

    @Column(name = "last_reintroduced_at")
    private OffsetDateTime lastReintroducedAt;

    @Column(name = "needs_teacher_review", nullable = false)
    @Builder.Default
    private Boolean needsTeacherReview = false;

    @Column(name = "diagnostic_administered", nullable = false)
    @Builder.Default
    private Boolean diagnosticAdministered = false;

    @Column(name = "diagnostic_result", length = 20)
    @Builder.Default
    private String diagnosticResult = "not_administered";

    @Column(name = "diagnostic_activity_type", length = 50)
    private String diagnosticActivityType;

    @Column(name = "last_adjusted_at", nullable = false)
    @Builder.Default
    private OffsetDateTime lastAdjustedAt = OffsetDateTime.now();

    @Column(name = "created_at", updatable = false)
    @Builder.Default
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "updated_at")
    @Builder.Default
    private OffsetDateTime updatedAt = OffsetDateTime.now();

    public Integer getReintroductionCount() {
        return reintroductionCount;
    }

    public DifficultyLevel getCurrentLevel() { return currentLevel; }
    public Integer getConsecutiveCorrect() { return consecutiveCorrect; }
    public Integer getConsecutiveIncorrect() { return consecutiveIncorrect; }
    public Boolean getRecallInCurrentStreak() { return recallInCurrentStreak; }
    public Boolean getSentenceCompletionClearedAtCurrentTier() { return sentenceCompletionClearedAtCurrentTier; }
    public Boolean getSentenceRearrangementClearedAtCurrentTier() { return sentenceRearrangementClearedAtCurrentTier; }
    public VocabularyWord getWord() { return word; }
    public Integer getAttemptCountAtCurrentTier() { return attemptCountAtCurrentTier; }

    public void setCurrentLevel(DifficultyLevel currentLevel) { this.currentLevel = currentLevel; }
    public void setConsecutiveCorrect(Integer consecutiveCorrect) { this.consecutiveCorrect = consecutiveCorrect; }
    public void setConsecutiveIncorrect(Integer consecutiveIncorrect) { this.consecutiveIncorrect = consecutiveIncorrect; }
    public void setRecallInCurrentStreak(Boolean recallInCurrentStreak) { this.recallInCurrentStreak = recallInCurrentStreak; }
    public void setSentenceCompletionClearedAtCurrentTier(Boolean sentenceCompletionClearedAtCurrentTier) { this.sentenceCompletionClearedAtCurrentTier = sentenceCompletionClearedAtCurrentTier; }
    public void setSentenceRearrangementClearedAtCurrentTier(Boolean sentenceRearrangementClearedAtCurrentTier) { this.sentenceRearrangementClearedAtCurrentTier = sentenceRearrangementClearedAtCurrentTier; }
    public void setAttemptCountAtCurrentTier(Integer attemptCountAtCurrentTier) { this.attemptCountAtCurrentTier = attemptCountAtCurrentTier; }
    public void setLastAdjustedAt(OffsetDateTime lastAdjustedAt) { this.lastAdjustedAt = lastAdjustedAt; }
    public Learner getLearner() { return learner; }
    public UUID getProgressId() { return progressId; }
    public Boolean getNeedsReintroduction() { return needsReintroduction; }
    public OffsetDateTime getLastReintroducedAt() { return lastReintroducedAt; }
    public Boolean getNeedsTeacherReview() { return needsTeacherReview; }
    public Boolean getDiagnosticAdministered() { return diagnosticAdministered; }
    public String getDiagnosticResult() { return diagnosticResult; }
    public String getDiagnosticActivityType() { return diagnosticActivityType; }
    public OffsetDateTime getLastAdjustedAt() { return lastAdjustedAt; }
    public Boolean getMasteryBonusAwarded() { return masteryBonusAwarded; }

    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }
    public void setMasteryBonusAwarded(Boolean masteryBonusAwarded) { this.masteryBonusAwarded = masteryBonusAwarded; }
    public void setNeedsReintroduction(Boolean needsReintroduction) { this.needsReintroduction = needsReintroduction; }
    public void setReintroductionCount(Integer reintroductionCount) { this.reintroductionCount = reintroductionCount; }
    public void setLastReintroducedAt(OffsetDateTime lastReintroducedAt) { this.lastReintroducedAt = lastReintroducedAt; }
    public void setDiagnosticAdministered(Boolean diagnosticAdministered) { this.diagnosticAdministered = diagnosticAdministered; }
    public void setDiagnosticResult(String diagnosticResult) { this.diagnosticResult = diagnosticResult; }
    public void setDiagnosticActivityType(String diagnosticActivityType) { this.diagnosticActivityType = diagnosticActivityType; }

    public static DifficultyProgressBuilder builder() { return new DifficultyProgressBuilder(); }

    public static class DifficultyProgressBuilder {
        private Learner learner;
        private VocabularyWord word;
        private Integer moduleNumber = 2;
        private DifficultyLevel currentLevel = DifficultyLevel.LEARNING;
        private Integer consecutiveCorrect = 0;
        private Integer consecutiveIncorrect = 0;
        private Boolean recallInCurrentStreak = false;
        private Boolean sentenceCompletionClearedAtCurrentTier = false;
        private Boolean sentenceRearrangementClearedAtCurrentTier = false;
        private Integer attemptCountAtCurrentTier = 1;
        private Boolean masteryBonusAwarded = false;
        private Boolean needsReintroduction = false;

        public DifficultyProgressBuilder learner(Learner learner) { this.learner = learner; return this; }
        public DifficultyProgressBuilder word(VocabularyWord word) { this.word = word; return this; }
        public DifficultyProgressBuilder moduleNumber(Integer moduleNumber) { this.moduleNumber = moduleNumber; return this; }
        public DifficultyProgressBuilder currentLevel(DifficultyLevel currentLevel) { this.currentLevel = currentLevel; return this; }
        public DifficultyProgressBuilder consecutiveCorrect(Integer consecutiveCorrect) { this.consecutiveCorrect = consecutiveCorrect; return this; }
        public DifficultyProgressBuilder consecutiveIncorrect(Integer consecutiveIncorrect) { this.consecutiveIncorrect = consecutiveIncorrect; return this; }
        public DifficultyProgressBuilder recallInCurrentStreak(Boolean recallInCurrentStreak) { this.recallInCurrentStreak = recallInCurrentStreak; return this; }
        public DifficultyProgressBuilder sentenceCompletionClearedAtCurrentTier(Boolean sentenceCompletionClearedAtCurrentTier) { this.sentenceCompletionClearedAtCurrentTier = sentenceCompletionClearedAtCurrentTier; return this; }
        public DifficultyProgressBuilder sentenceRearrangementClearedAtCurrentTier(Boolean sentenceRearrangementClearedAtCurrentTier) { this.sentenceRearrangementClearedAtCurrentTier = sentenceRearrangementClearedAtCurrentTier; return this; }
        public DifficultyProgressBuilder attemptCountAtCurrentTier(Integer attemptCountAtCurrentTier) { this.attemptCountAtCurrentTier = attemptCountAtCurrentTier; return this; }
        public DifficultyProgressBuilder masteryBonusAwarded(Boolean masteryBonusAwarded) { this.masteryBonusAwarded = masteryBonusAwarded; return this; }
        public DifficultyProgressBuilder needsReintroduction(Boolean needsReintroduction) { this.needsReintroduction = needsReintroduction; return this; }
        public DifficultyProgressBuilder reintroductionCount(Integer reintroductionCount) { return this; }
        public DifficultyProgressBuilder createdAt(OffsetDateTime createdAt) { return this; }
        public DifficultyProgressBuilder updatedAt(OffsetDateTime updatedAt) { return this; }

        public DifficultyProgress build() {
            DifficultyProgress p = new DifficultyProgress();
            p.learner = this.learner;
            p.word = this.word;
            p.moduleNumber = this.moduleNumber;
            p.currentLevel = this.currentLevel;
            p.consecutiveCorrect = this.consecutiveCorrect;
            p.consecutiveIncorrect = this.consecutiveIncorrect;
            p.recallInCurrentStreak = this.recallInCurrentStreak;
            p.sentenceCompletionClearedAtCurrentTier = this.sentenceCompletionClearedAtCurrentTier;
            p.sentenceRearrangementClearedAtCurrentTier = this.sentenceRearrangementClearedAtCurrentTier;
            p.attemptCountAtCurrentTier = this.attemptCountAtCurrentTier;
            p.masteryBonusAwarded = this.masteryBonusAwarded;
            p.lastAdjustedAt = OffsetDateTime.now();
            p.createdAt = OffsetDateTime.now();
            p.updatedAt = OffsetDateTime.now();
            return p;
        }
    }

    @PrePersist
    protected void onCreate() {
        createdAt = OffsetDateTime.now();
        updatedAt = OffsetDateTime.now();
        lastAdjustedAt = OffsetDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = OffsetDateTime.now();
    }
}
