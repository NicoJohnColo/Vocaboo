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
