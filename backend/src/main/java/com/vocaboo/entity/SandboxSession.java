package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "sandbox_sessions")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SandboxSession {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "session_id", updatable = false, nullable = false)
    private UUID sessionId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "learner_id", nullable = false)
    private Learner learner;

    @Column(name = "topic")
    private String topic;

    @Column(name = "custom_word")
    private String customWord;

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

    public String getTopic() { return topic; }
    public String getCustomWord() { return customWord; }
    public Double getMasteryScore() { return masteryScore; }
    public OffsetDateTime getCompletedAt() { return completedAt; }
    public OffsetDateTime getCreatedAt() { return createdAt; }

    public void setMasteryScore(Double masteryScore) { this.masteryScore = masteryScore; }
    public void setCompletedAt(OffsetDateTime completedAt) { this.completedAt = completedAt; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }

    public static SandboxSessionBuilder builder() { return new SandboxSessionBuilder(); }

    public static class SandboxSessionBuilder {
        private Learner learner;
        private String topic;
        private String customWord;

        public SandboxSessionBuilder learner(Learner learner) { this.learner = learner; return this; }
        public SandboxSessionBuilder topic(String topic) { this.topic = topic; return this; }
        public SandboxSessionBuilder customWord(String customWord) { this.customWord = customWord; return this; }
        public SandboxSessionBuilder createdAt(OffsetDateTime createdAt) { return this; }
        public SandboxSessionBuilder updatedAt(OffsetDateTime updatedAt) { return this; }

        public SandboxSession build() {
            SandboxSession s = new SandboxSession();
            s.learner = this.learner;
            s.topic = this.topic;
            s.customWord = this.customWord;
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
