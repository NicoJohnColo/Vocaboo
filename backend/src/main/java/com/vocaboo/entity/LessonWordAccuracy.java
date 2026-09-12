package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(
    name = "lesson_word_accuracy",
    uniqueConstraints = {
        @UniqueConstraint(columnNames = {"learner_id", "lesson_id", "word_id"})
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LessonWordAccuracy {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "accuracy_id", updatable = false, nullable = false)
    private UUID accuracyId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "learner_id", nullable = false)
    private Learner learner;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lesson_id", nullable = false)
    private Lesson lesson;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "word_id", nullable = false)
    private VocabularyWord word;

    @Column(name = "best_accuracy", precision = 5, scale = 2, nullable = false)
    @Builder.Default
    private BigDecimal bestAccuracy = BigDecimal.ZERO;

    @Column(name = "attempts", nullable = false)
    @Builder.Default
    private Integer attempts = 0;

    @Column(name = "last_practiced_at")
    private OffsetDateTime lastPracticedAt;

    @Column(name = "created_at", updatable = false)
    @Builder.Default
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "updated_at")
    @Builder.Default
    private OffsetDateTime updatedAt = OffsetDateTime.now();

    @PrePersist
    protected void onCreate() {
        if (bestAccuracy == null) bestAccuracy = BigDecimal.ZERO;
        if (attempts == null) attempts = 0;
        if (createdAt == null) createdAt = OffsetDateTime.now();
        if (updatedAt == null) updatedAt = OffsetDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        if (bestAccuracy == null) bestAccuracy = BigDecimal.ZERO;
        if (attempts == null) attempts = 0;
        updatedAt = OffsetDateTime.now();
    }
}