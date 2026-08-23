package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "introduction_sessions")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class IntroductionSession {

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

    @Column(name = "started_at", nullable = false, updatable = false)
    @Builder.Default
    private OffsetDateTime startedAt = OffsetDateTime.now();

    @Column(name = "completed_at")
    private OffsetDateTime completedAt;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;

    public UUID getSessionId() { return sessionId; }
    public Learner getLearner() { return learner; }
    public Lesson getLesson() { return lesson; }
    public void setIsActive(Boolean isActive) { this.isActive = isActive; }
    public void setCompletedAt(OffsetDateTime completedAt) { this.completedAt = completedAt; }

    public static IntroductionSessionBuilder builder() { return new IntroductionSessionBuilder(); }

    public static class IntroductionSessionBuilder {
        private Learner learner;
        private Lesson lesson;
        private Boolean isActive = true;

        public IntroductionSessionBuilder learner(Learner learner) { this.learner = learner; return this; }
        public IntroductionSessionBuilder lesson(Lesson lesson) { this.lesson = lesson; return this; }
        public IntroductionSessionBuilder isActive(Boolean isActive) { this.isActive = isActive; return this; }

        public IntroductionSession build() {
            IntroductionSession s = new IntroductionSession();
            s.learner = this.learner;
            s.lesson = this.lesson;
            s.isActive = this.isActive;
            s.startedAt = OffsetDateTime.now();
            return s;
        }
    }

    @PrePersist
    protected void onCreate() {
        startedAt = OffsetDateTime.now();
    }
}
