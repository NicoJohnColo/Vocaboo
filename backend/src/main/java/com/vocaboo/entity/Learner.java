package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcType;
import org.hibernate.dialect.PostgreSQLEnumJdbcType;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "learners")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Learner {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "learner_id", updatable = false, nullable = false)
    private UUID learnerId;

    @Column(name = "display_name", nullable = false, length = 100)
    private String displayName;

    @Column(name = "age", nullable = false)
    private Integer age;

    @Column(name = "pin_hash", nullable = false, columnDefinition = "TEXT")
    private String pinHash;

    @Enumerated(EnumType.STRING)
    @JdbcType(PostgreSQLEnumJdbcType.class)
    @Column(name = "language_preference", nullable = false, columnDefinition = "language_medium_enum")
    private LanguageMedium languagePreference;

    @Column(name = "onboarding_complete", nullable = false)
    @Builder.Default
    private Boolean onboardingComplete = false;

    @Column(name = "mastery_apply_immediately", nullable = false)
    @Builder.Default
    private Boolean masteryApplyImmediately = true;

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
