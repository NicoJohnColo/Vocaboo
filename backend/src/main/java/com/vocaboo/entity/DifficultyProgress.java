package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(
    name = "difficulty_progress",
    uniqueConstraints = {
        @UniqueConstraint(columnNames = {"learner_id", "word_id"})
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

    @Column(name = "needs_reintroduction", nullable = false)
    @Builder.Default
    private Boolean needsReintroduction = false;

    @Column(name = "reintroduction_count", nullable = false)
    @Builder.Default
    private Integer reintroductionCount = 0;

    @Column(name = "last_reintroduced_at")
    private OffsetDateTime lastReintroducedAt;

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
