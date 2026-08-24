package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "practice_sessions")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PracticeSession {

    @Id
    @Column(name = "session_id", updatable = false, nullable = false)
    private UUID sessionId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "learner_id", nullable = false)
    private Learner learner;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lesson_id", nullable = false)
    private Lesson lesson;

    @Column(name = "module_number", nullable = false)
    private Integer moduleNumber;

    @Column(name = "score", precision = 5, scale = 2)
    private BigDecimal score;

    @Column(name = "stars_earned", nullable = false)
    @Builder.Default
    private Integer starsEarned = 0;

    @Column(name = "completed_at")
    private OffsetDateTime completedAt;

    @Column(name = "created_at", updatable = false)
    @Builder.Default
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "updated_at")
    @Builder.Default
    private OffsetDateTime updatedAt = OffsetDateTime.now();

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public OffsetDateTime getCompletedAt() {
        return completedAt;
    }

    public UUID getSessionId() {
        return sessionId;
    }

    public Learner getLearner() { return learner; }
    public Lesson getLesson() { return lesson; }
    public Integer getModuleNumber() { return moduleNumber; }
    public BigDecimal getScore() { return score; }
    public Integer getStarsEarned() { return starsEarned; }

    public void setScore(BigDecimal score) { this.score = score; }
    public void setStarsEarned(Integer starsEarned) { this.starsEarned = starsEarned; }
    public void setCompletedAt(OffsetDateTime completedAt) { this.completedAt = completedAt; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }

    public static PracticeSessionBuilder builder() { return new PracticeSessionBuilder(); }

    public static class PracticeSessionBuilder {
        private UUID sessionId;
        private Learner learner;
        private Lesson lesson;
        private Integer moduleNumber;
        private BigDecimal score;
        private Integer starsEarned = 0;

        public PracticeSessionBuilder sessionId(UUID sessionId) { this.sessionId = sessionId; return this; }
        public PracticeSessionBuilder learner(Learner learner) { this.learner = learner; return this; }
        public PracticeSessionBuilder lesson(Lesson lesson) { this.lesson = lesson; return this; }
        public PracticeSessionBuilder moduleNumber(Integer moduleNumber) { this.moduleNumber = moduleNumber; return this; }
        public PracticeSessionBuilder score(BigDecimal score) { this.score = score; return this; }
        public PracticeSessionBuilder starsEarned(Integer starsEarned) { this.starsEarned = starsEarned; return this; }
        public PracticeSessionBuilder createdAt(OffsetDateTime createdAt) { return this; }
        public PracticeSessionBuilder updatedAt(OffsetDateTime updatedAt) { return this; }

        public PracticeSession build() {
            PracticeSession s = new PracticeSession();
            s.sessionId = this.sessionId;
            s.learner = this.learner;
            s.lesson = this.lesson;
            s.moduleNumber = this.moduleNumber;
            s.score = this.score;
            s.starsEarned = this.starsEarned;
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
