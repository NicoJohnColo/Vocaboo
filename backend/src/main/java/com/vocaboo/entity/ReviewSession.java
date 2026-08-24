package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "review_sessions")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReviewSession {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "session_id", updatable = false, nullable = false)
    private UUID sessionId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "learner_id", nullable = false)
    private Learner learner;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lesson_id", nullable = false)
    private Lesson lesson;

    @Column(name = "mastery_score")
    private Double masteryScore;

    @Column(name = "completed_at")
    private OffsetDateTime completedAt;

    @Column(name = "created_at", updatable = false)
    @Builder.Default
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "updated_at")
    @Builder.Default
    private OffsetDateTime updatedAt = OffsetDateTime.now();

    public UUID getSessionId() {
        return sessionId;
    }

    public Learner getLearner() { return learner; }
    public Lesson getLesson() { return lesson; }
    public void setMasteryScore(Double masteryScore) { this.masteryScore = masteryScore; }
    public void setCompletedAt(OffsetDateTime completedAt) { this.completedAt = completedAt; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }

    public static ReviewSessionBuilder builder() { return new ReviewSessionBuilder(); }

    public static class ReviewSessionBuilder {
        private Learner learner;
        private Lesson lesson;
        private Double masteryScore;

        public ReviewSessionBuilder learner(Learner learner) { this.learner = learner; return this; }
        public ReviewSessionBuilder lesson(Lesson lesson) { this.lesson = lesson; return this; }
        public ReviewSessionBuilder masteryScore(Double masteryScore) { this.masteryScore = masteryScore; return this; }
        public ReviewSessionBuilder createdAt(OffsetDateTime createdAt) { return this; }
        public ReviewSessionBuilder updatedAt(OffsetDateTime updatedAt) { return this; }

        public ReviewSession build() {
            ReviewSession s = new ReviewSession();
            s.learner = this.learner;
            s.lesson = this.lesson;
            s.masteryScore = this.masteryScore;
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
