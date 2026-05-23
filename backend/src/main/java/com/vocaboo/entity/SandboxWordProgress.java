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
