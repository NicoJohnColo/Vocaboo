package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "admins")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Admin {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "admin_id", updatable = false, nullable = false)
    private UUID adminId;

    @Column(name = "username", nullable = false, unique = true, length = 100)
    private String username;

    @Column(name = "password_hash", nullable = false, columnDefinition = "TEXT")
    private String passwordHash;

    @Column(name = "email", nullable = false, unique = true, length = 200)
    private String email;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;

    @Column(name = "created_at", updatable = false)
    @Builder.Default
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "last_login_at")
    private OffsetDateTime lastLoginAt;

    // ── Fields added in V9 migration ────────────────────────────────────────

    /** Optional school association (plain UUID, no FK constraint yet). */
    @Column(name = "school_id")
    private UUID schoolId;

    /** Short-lived JWT token for password reset flow (expires in 1 hour). */
    @Column(name = "password_reset_token", columnDefinition = "TEXT")
    private String passwordResetToken;

    /** Expiry timestamp for the password reset token. */
    @Column(name = "password_reset_expiry")
    private OffsetDateTime passwordResetExpiry;

    /** True if the admin must set a new password on next login (e.g. first login). */
    @Column(name = "must_change_password", nullable = false)
    @Builder.Default
    private Boolean mustChangePassword = false;

    @PrePersist
    protected void onCreate() {
        createdAt = OffsetDateTime.now();
    }
}
