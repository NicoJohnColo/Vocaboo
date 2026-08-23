package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(
    name = "word_performance",
    uniqueConstraints = {
        @UniqueConstraint(columnNames = {"learner_id", "word_id"})
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WordPerformance {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "performance_id", updatable = false, nullable = false)
    private UUID performanceId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "learner_id", nullable = false)
    private Learner learner;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "word_id", nullable = false)
    private VocabularyWord word;

    @Column(name = "correct_count", nullable = false)
    @Builder.Default
    private Integer correctCount = 0;

    @Column(name = "incorrect_count", nullable = false)
    @Builder.Default
    private Integer incorrectCount = 0;

    @Column(name = "demerit_points", nullable = false)
    @Builder.Default
    private Integer demeritPoints = 0;

    /**
     * Number of times this word's difficulty tier was downgraded (wrong answer at
     * FAMILIAR/PROFICIENT/MASTERED). Used with accuracy to compute Gold/Silver/Bronze
     * word-level performance rating on the score screen.
     */
    @Column(name = "tier_drop_count", nullable = false)
    @Builder.Default
    private Integer tierDropCount = 0;

    /**
     * Number of times this word experienced asset fallbacks in Module 4 practice.
     */
    @Column(name = "fallback_count", nullable = false)
    @Builder.Default
    private Integer fallbackCount = 0;

    @Column(name = "total_attempts", nullable = false)
    @Builder.Default
    private Integer totalAttempts = 0;

    @Column(name = "accuracy", nullable = false, precision = 5, scale = 2)
    @Builder.Default
    private BigDecimal accuracy = BigDecimal.ZERO;

    @Column(name = "last_practiced_at", nullable = false)
    @Builder.Default
    private OffsetDateTime lastPracticedAt = OffsetDateTime.now();

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
        lastPracticedAt = OffsetDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = OffsetDateTime.now();
    }
}
