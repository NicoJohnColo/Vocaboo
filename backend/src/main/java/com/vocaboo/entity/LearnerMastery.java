package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "learner_mastery")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LearnerMastery {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "mastery_id", updatable = false, nullable = false)
    private UUID masteryId;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "learner_id", unique = true, nullable = false)
    private Learner learner;

    @Column(name = "total_sessions_played", nullable = false)
    @Builder.Default
    private Integer totalSessionsPlayed = 0;

    @Column(name = "total_correct_answers", nullable = false)
    @Builder.Default
    private Integer totalCorrectAnswers = 0;

    @Column(name = "total_questions_answered", nullable = false)
    @Builder.Default
    private Integer totalQuestionsAnswered = 0;

    @Column(name = "overall_accuracy", nullable = false, precision = 5, scale = 2)
    @Builder.Default
    private BigDecimal overallAccuracy = BigDecimal.ZERO;

    @Column(name = "words_mastered_count", nullable = false)
    @Builder.Default
    private Integer wordsMasteredCount = 0;

    @Column(name = "mastery_level", nullable = false, length = 20)
    @Builder.Default
    private String masteryLevel = "LEARNING";

    @Column(name = "total_points", nullable = false)
    @Builder.Default
    private Integer totalPoints = 0;

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
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = OffsetDateTime.now();
    }
}
