package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcType;
import org.hibernate.dialect.PostgreSQLEnumJdbcType;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "deleted_learners_audit")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DeletedLearnerAudit {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "audit_id", updatable = false, nullable = false)
    private UUID auditId;

    @Column(name = "learner_id", nullable = false)
    private UUID learnerId;

    @Column(name = "display_name", nullable = false, length = 100)
    private String displayName;

    @Enumerated(EnumType.STRING)
    @JdbcType(PostgreSQLEnumJdbcType.class)
    @Column(name = "language_preference", nullable = false, columnDefinition = "language_medium_enum")
    private LanguageMedium languagePreference;

    @Column(name = "deleted_at", updatable = false)
    @Builder.Default
    private OffsetDateTime deletedAt = OffsetDateTime.now();

    @Column(name = "reason_code", nullable = false, length = 50)
    private String reasonCode;

    @Column(name = "authorized_by", nullable = false, columnDefinition = "TEXT")
    private String authorizedBy;

    @PrePersist
    protected void onCreate() {
        deletedAt = OffsetDateTime.now();
    }
}
