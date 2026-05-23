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
