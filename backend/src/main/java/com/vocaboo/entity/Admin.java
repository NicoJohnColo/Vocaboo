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

    public UUID getAdminId() { return adminId; }
    public String getUsername() { return username; }
    public String getPasswordHash() { return passwordHash; }
    public String getEmail() { return email; }
    public Boolean getIsActive() { return isActive; }
    public Boolean getMustChangePassword() { return mustChangePassword; }
    public String getPasswordResetToken() { return passwordResetToken; }
    public OffsetDateTime getPasswordResetExpiry() { return passwordResetExpiry; }
    public UUID getSchoolId() { return schoolId; }
    public OffsetDateTime getCreatedAt() { return createdAt; }
    public OffsetDateTime getLastLoginAt() { return lastLoginAt; }

    public void setLastLoginAt(OffsetDateTime lastLoginAt) { this.lastLoginAt = lastLoginAt; }
    public void setPasswordHash(String passwordHash) { this.passwordHash = passwordHash; }
    public void setPasswordResetToken(String passwordResetToken) { this.passwordResetToken = passwordResetToken; }
    public void setPasswordResetExpiry(OffsetDateTime passwordResetExpiry) { this.passwordResetExpiry = passwordResetExpiry; }
    public void setMustChangePassword(Boolean mustChangePassword) { this.mustChangePassword = mustChangePassword; }
    public void setIsActive(Boolean isActive) { this.isActive = isActive; }

    public static AdminBuilder builder() { return new AdminBuilder(); }

    public static class AdminBuilder {
        private String username;
        private String passwordHash;
        private String email;
        private Boolean isActive = true;
        private Boolean mustChangePassword = false;
        private UUID schoolId;

        public AdminBuilder username(String username) { this.username = username; return this; }
        public AdminBuilder passwordHash(String passwordHash) { this.passwordHash = passwordHash; return this; }
        public AdminBuilder email(String email) { this.email = email; return this; }
        public AdminBuilder isActive(Boolean isActive) { this.isActive = isActive; return this; }
        public AdminBuilder mustChangePassword(Boolean mustChangePassword) { this.mustChangePassword = mustChangePassword; return this; }
        public AdminBuilder schoolId(UUID schoolId) { this.schoolId = schoolId; return this; }

        public Admin build() {
            Admin a = new Admin();
            a.username = this.username;
            a.passwordHash = this.passwordHash;
            a.email = this.email;
            a.isActive = this.isActive != null ? this.isActive : true;
            a.createdAt = OffsetDateTime.now();
            return a;
        }
    }

    @PrePersist
    protected void onCreate() {
        createdAt = OffsetDateTime.now();
    }
}
