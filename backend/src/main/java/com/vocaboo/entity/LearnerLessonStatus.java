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

    public LessonStatus getStatus() {
        return status;
    }

    public OffsetDateTime getCompletedAt() {
        return completedAt;
    }

    public OffsetDateTime getUpdatedAt() {
        return updatedAt;
    }

    public Learner getLearner() {
        return learner;
    }

    public Lesson getLesson() {
        return lesson;
    }

    public BigDecimal getMasteryScore() {
        return masteryScore;
    }

    public Integer getAttempts() {
        return attempts;
    }

    public Integer getBestLessonPoints() {
        return bestLessonPoints;
    }

    public Boolean getLessonCompletionBonusAwarded() {
        return lessonCompletionBonusAwarded;
    }

    public Boolean getPerfectScoreBonusAwarded() {
        return perfectScoreBonusAwarded;
    }

    public void setStatus(LessonStatus status) { this.status = status; }
    public void setUnlockedAt(OffsetDateTime unlockedAt) { this.unlockedAt = unlockedAt; }
    public void setAttempts(Integer attempts) { this.attempts = attempts; }
    public void setMasteryScore(BigDecimal masteryScore) { this.masteryScore = masteryScore; }
    public void setCompletedAt(OffsetDateTime completedAt) { this.completedAt = completedAt; }
    public void setBestLessonPoints(Integer bestLessonPoints) { this.bestLessonPoints = bestLessonPoints; }
    public void setLessonCompletionBonusAwarded(Boolean lessonCompletionBonusAwarded) { this.lessonCompletionBonusAwarded = lessonCompletionBonusAwarded; }
    public void setPerfectScoreBonusAwarded(Boolean perfectScoreBonusAwarded) { this.perfectScoreBonusAwarded = perfectScoreBonusAwarded; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }

    public static LearnerLessonStatusBuilder builder() { return new LearnerLessonStatusBuilder(); }

    public static class LearnerLessonStatusBuilder {
        private Learner learner;
        private Lesson lesson;
        private LessonStatus status = LessonStatus.LOCKED;
        private OffsetDateTime unlockedAt;
        private Integer attempts = 0;

        public LearnerLessonStatusBuilder learner(Learner learner) { this.learner = learner; return this; }
        public LearnerLessonStatusBuilder lesson(Lesson lesson) { this.lesson = lesson; return this; }
        public LearnerLessonStatusBuilder status(LessonStatus status) { this.status = status; return this; }
        public LearnerLessonStatusBuilder unlockedAt(OffsetDateTime unlockedAt) { this.unlockedAt = unlockedAt; return this; }
        public LearnerLessonStatusBuilder attempts(Integer attempts) { this.attempts = attempts; return this; }

        public LearnerLessonStatus build() {
            LearnerLessonStatus s = new LearnerLessonStatus();
            s.learner = this.learner;
            s.lesson = this.lesson;
            s.status = this.status;
            s.unlockedAt = this.unlockedAt;
            s.attempts = this.attempts != null ? this.attempts : 0;
            s.createdAt = OffsetDateTime.now();
            s.updatedAt = OffsetDateTime.now();
            return s;
        }
    }

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
