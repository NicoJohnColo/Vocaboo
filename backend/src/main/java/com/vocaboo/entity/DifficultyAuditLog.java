package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "difficulty_audit_logs")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DifficultyAuditLog {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "audit_id", updatable = false, nullable = false)
    private UUID auditId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "learner_id", nullable = false)
    private Learner learner;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "word_id", nullable = false)
    private VocabularyWord word;

    @Enumerated(EnumType.STRING)
    @Column(name = "old_level", nullable = false)
    private DifficultyLevel oldLevel;

    @Enumerated(EnumType.STRING)
    @Column(name = "new_level", nullable = false)
    private DifficultyLevel newLevel;

    @Column(name = "reason", nullable = false, length = 100)
    private String reason;

    @Column(name = "changed_at", updatable = false)
    @Builder.Default
    private OffsetDateTime changedAt = OffsetDateTime.now();

    @PrePersist
    protected void onCreate() {
        changedAt = OffsetDateTime.now();
    }
}
