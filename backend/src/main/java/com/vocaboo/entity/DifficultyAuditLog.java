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

    public static DifficultyAuditLogBuilder builder() { return new DifficultyAuditLogBuilder(); }

    public static class DifficultyAuditLogBuilder {
        private Learner learner;
        private VocabularyWord word;
        private DifficultyLevel oldLevel;
        private DifficultyLevel newLevel;
        private String reason;

        public DifficultyAuditLogBuilder learner(Learner learner) { this.learner = learner; return this; }
        public DifficultyAuditLogBuilder word(VocabularyWord word) { this.word = word; return this; }
        public DifficultyAuditLogBuilder oldLevel(DifficultyLevel oldLevel) { this.oldLevel = oldLevel; return this; }
        public DifficultyAuditLogBuilder newLevel(DifficultyLevel newLevel) { this.newLevel = newLevel; return this; }
        public DifficultyAuditLogBuilder reason(String reason) { this.reason = reason; return this; }
        public DifficultyAuditLogBuilder changedAt(OffsetDateTime changedAt) { return this; }

        public DifficultyAuditLog build() {
            DifficultyAuditLog log = new DifficultyAuditLog();
            log.learner = this.learner;
            log.word = this.word;
            log.oldLevel = this.oldLevel;
            log.newLevel = this.newLevel;
            log.reason = this.reason;
            log.changedAt = OffsetDateTime.now();
            return log;
        }
    }

    @PrePersist
    protected void onCreate() {
        changedAt = OffsetDateTime.now();
    }
}
