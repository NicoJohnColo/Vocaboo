package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "admin_audit_logs", indexes = {
        @Index(name = "idx_admin_audit_logs_admin_id",  columnList = "admin_id"),
        @Index(name = "idx_admin_audit_logs_timestamp", columnList = "timestamp")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AdminAuditLog {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "audit_id", updatable = false, nullable = false)
    private UUID auditId;

    @Column(name = "admin_id", nullable = false)
    private UUID adminId;

    /** e.g. CREATE_ADMIN, DISABLE_ADMIN, ENABLE_ADMIN, RESET_PASSWORD, DELETE_ADMIN */
    @Column(name = "action", nullable = false, length = 100)
    private String action;

    /** UUID of the affected entity (another admin, learner, etc.) */
    @Column(name = "target_id")
    private UUID targetId;

    /** JSON or plain-text details about the action */
    @Column(name = "details", columnDefinition = "TEXT")
    private String details;

    @Column(name = "timestamp", nullable = false, updatable = false)
    @Builder.Default
    private OffsetDateTime timestamp = OffsetDateTime.now();

    @PrePersist
    protected void onCreate() {
        if (timestamp == null) timestamp = OffsetDateTime.now();
    }

    public static AdminAuditLogBuilder builder() {
        return new AdminAuditLogBuilder();
    }

    public static class AdminAuditLogBuilder {
        private UUID adminId;
        private String action;
        private UUID targetId;
        private String details;

        public AdminAuditLogBuilder adminId(UUID adminId) { this.adminId = adminId; return this; }
        public AdminAuditLogBuilder action(String action) { this.action = action; return this; }
        public AdminAuditLogBuilder targetId(UUID targetId) { this.targetId = targetId; return this; }
        public AdminAuditLogBuilder details(String details) { this.details = details; return this; }

        public AdminAuditLog build() {
            AdminAuditLog log = new AdminAuditLog();
            log.adminId = this.adminId;
            log.action = this.action;
            log.targetId = this.targetId;
            log.details = this.details;
            log.timestamp = OffsetDateTime.now();
            return log;
        }
    }
}
