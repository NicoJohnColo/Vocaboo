package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcType;
import org.hibernate.dialect.PostgreSQLEnumJdbcType;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(
    name = "learner_lesson_status",
    uniqueConstraints = {
        @UniqueConstraint(columnNames = {"learner_id", "lesson_id"})
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LearnerLessonStatus {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "status_id", updatable = false, nullable = false)
    private UUID statusId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "learner_id", nullable = false)
    private Learner learner;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lesson_id", nullable = false)
    private Lesson lesson;

    @Enumerated(EnumType.STRING)
    @JdbcType(PostgreSQLEnumJdbcType.class)
    @Column(name = "status", nullable = false, columnDefinition = "lesson_status_enum")
    @Builder.Default
    private LessonStatus status = LessonStatus.LOCKED;

    @Column(name = "mastery_score", precision = 5, scale = 2)
    private BigDecimal masteryScore;

    @Column(name = "attempts", nullable = false)
    @Builder.Default
    private Integer attempts = 0;

    @Column(name = "best_lesson_points", nullable = false)
    @Builder.Default
    private Integer bestLessonPoints = 0;

    @Column(name = "lesson_completion_bonus_awarded", nullable = false)
    @Builder.Default
    private Boolean lessonCompletionBonusAwarded = false;

    @Column(name = "perfect_score_bonus_awarded", nullable = false)
    @Builder.Default
    private Boolean perfectScoreBonusAwarded = false;

    @Column(name = "unlocked_at")
    private OffsetDateTime unlockedAt;

    @Column(name = "completed_at")
    private OffsetDateTime completedAt;

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
