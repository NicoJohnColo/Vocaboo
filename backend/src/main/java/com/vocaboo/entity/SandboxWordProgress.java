package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcType;
import org.hibernate.dialect.PostgreSQLEnumJdbcType;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(
    name = "sandbox_word_progress",
    uniqueConstraints = {
        @UniqueConstraint(columnNames = {"session_id", "word_id", "module_number"})
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SandboxWordProgress {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "progress_id", updatable = false, nullable = false)
    private UUID progressId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id", nullable = false)
    private SandboxSession session;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "word_id", nullable = false)
    private SandboxWord word;

    @Column(name = "module_number", nullable = false)
    private Integer moduleNumber;

    @Column(name = "step_completed", nullable = false)
    @Builder.Default
    private Integer stepCompleted = 0;

    @Enumerated(EnumType.STRING)
    @JdbcType(PostgreSQLEnumJdbcType.class)
    @Column(name = "status", nullable = false, columnDefinition = "word_status_enum")
    @Builder.Default
    private WordStatus status = WordStatus.INTRODUCED;

    @Column(name = "completed_at")
    private OffsetDateTime completedAt;

    @Column(name = "created_at", updatable = false)
    @Builder.Default
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "updated_at")
    @Builder.Default
    private OffsetDateTime updatedAt = OffsetDateTime.now();

    public UUID getProgressId() { return progressId; }
    public SandboxSession getSession() { return session; }
    public SandboxWord getWord() { return word; }
    public Integer getModuleNumber() { return moduleNumber; }
    public Integer getStepCompleted() { return stepCompleted; }
    public WordStatus getStatus() { return status; }
    public OffsetDateTime getCompletedAt() { return completedAt; }
    public OffsetDateTime getCreatedAt() { return createdAt; }
    public OffsetDateTime getUpdatedAt() { return updatedAt; }

    public void setStepCompleted(Integer stepCompleted) { this.stepCompleted = stepCompleted; }
    public void setStatus(WordStatus status) { this.status = status; }
    public void setCompletedAt(OffsetDateTime completedAt) { this.completedAt = completedAt; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }

    public static SandboxWordProgressBuilder builder() { return new SandboxWordProgressBuilder(); }

    public static class SandboxWordProgressBuilder {
        private SandboxSession session;
        private SandboxWord word;
        private Integer moduleNumber;
        private Integer stepCompleted = 0;
        private WordStatus status = WordStatus.INTRODUCED;

        public SandboxWordProgressBuilder session(SandboxSession session) { this.session = session; return this; }
        public SandboxWordProgressBuilder word(SandboxWord word) { this.word = word; return this; }
        public SandboxWordProgressBuilder moduleNumber(Integer moduleNumber) { this.moduleNumber = moduleNumber; return this; }
        public SandboxWordProgressBuilder stepCompleted(Integer stepCompleted) { this.stepCompleted = stepCompleted; return this; }
        public SandboxWordProgressBuilder status(WordStatus status) { this.status = status; return this; }
        public SandboxWordProgressBuilder createdAt(OffsetDateTime createdAt) { return this; }
        public SandboxWordProgressBuilder updatedAt(OffsetDateTime updatedAt) { return this; }

        public SandboxWordProgress build() {
            SandboxWordProgress p = new SandboxWordProgress();
            p.session = this.session;
            p.word = this.word;
            p.moduleNumber = this.moduleNumber;
            p.stepCompleted = this.stepCompleted;
            p.status = this.status;
            p.createdAt = OffsetDateTime.now();
            p.updatedAt = OffsetDateTime.now();
            return p;
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
