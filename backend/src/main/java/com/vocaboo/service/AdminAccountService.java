package com.vocaboo.service;

import com.vocaboo.entity.Admin;
import com.vocaboo.entity.AdminAuditLog;
import com.vocaboo.repository.AdminAuditLogRepository;
import com.vocaboo.repository.AdminRepository;
import com.vocaboo.security.JwtUtils;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AdminAccountService {

    private static final Logger log = LoggerFactory.getLogger(AdminAccountService.class);

    private final AdminRepository adminRepository;
    private final AdminAuditLogRepository auditLogRepository;
    private final PasswordEncoder passwordEncoder;
    private final AdminEmailService emailService;

    // ── Create ──────────────────────────────────────────────────────────────

    /**
     * Creates a new admin account.
     * Only an existing active admin can call this (enforced at controller level via ROLE_ADMIN).
     *
     * @param invitedByAdminId UUID of the admin creating the new account
     * @param username         desired username
     * @param email            email for the welcome + reset emails
     * @param schoolId         optional school association
     * @return the created Admin entity
     */
    @Transactional
    public Admin createAdminAccount(UUID invitedByAdminId, String username, String email, UUID schoolId) {
        if (adminRepository.findByUsername(username.trim()).isPresent()) {
            throw new IllegalArgumentException("Username '" + username + "' is already taken.");
        }
        if (adminRepository.findByEmail(email.trim()).isPresent()) {
            throw new IllegalArgumentException("An admin with email '" + email + "' already exists.");
        }

        // Generate a temporary password (12 chars)
        String temporaryPassword = generateTemporaryPassword();
        String hashedPassword = passwordEncoder.encode(temporaryPassword);

        Admin newAdmin = Admin.builder()
                .username(username.trim())
                .email(email.trim())
                .passwordHash(hashedPassword)
                .schoolId(schoolId)
                .isActive(true)
                .mustChangePassword(true)  // must reset on first login
                .build();

        newAdmin = adminRepository.save(newAdmin);

        // Audit trail
        audit(invitedByAdminId, "CREATE_ADMIN", newAdmin.getAdminId(),
              "Created admin: " + username + " | email: " + email);

        // Send welcome email (non-blocking — failure is logged, not thrown)
        emailService.sendWelcomeEmail(email, username, temporaryPassword);

        log.info("Admin account created: {} by admin: {}", username, invitedByAdminId);
        return newAdmin;
    }

    // ── Enable / Disable ────────────────────────────────────────────────────

    @Transactional
    public Admin disableAdminAccount(UUID actingAdminId, UUID targetAdminId) {
        Admin target = findOrThrow(targetAdminId);
        target.setIsActive(false);
        adminRepository.save(target);
        audit(actingAdminId, "DISABLE_ADMIN", targetAdminId, "Account disabled");
        log.info("Admin {} disabled by {}", targetAdminId, actingAdminId);
        return target;
    }

    @Transactional
    public Admin enableAdminAccount(UUID actingAdminId, UUID targetAdminId) {
        Admin target = findOrThrow(targetAdminId);
        target.setIsActive(true);
        adminRepository.save(target);
        audit(actingAdminId, "ENABLE_ADMIN", targetAdminId, "Account enabled");
        log.info("Admin {} enabled by {}", targetAdminId, actingAdminId);
        return target;
    }

    // ── Password Reset ───────────────────────────────────────────────────────

    /**
     * Generates a password reset token (valid 1 hour) and sends it by email.
     */
    @Transactional
    public void resetAdminPassword(UUID actingAdminId, UUID targetAdminId) {
        Admin target = findOrThrow(targetAdminId);

        String rawToken = UUID.randomUUID().toString();
        target.setPasswordResetToken(rawToken);
        target.setPasswordResetExpiry(OffsetDateTime.now().plusHours(1));
        adminRepository.save(target);

        emailService.sendPasswordResetEmail(target.getEmail(), target.getUsername(), rawToken);
        audit(actingAdminId, "RESET_PASSWORD", targetAdminId, "Password reset email sent");
        log.info("Password reset requested for admin: {} by: {}", targetAdminId, actingAdminId);
    }

    /**
     * Completes a password reset using the token from the reset link.
     */
    @Transactional
    public void completePasswordReset(String rawToken, String newPassword) {
        Admin admin = adminRepository.findByPasswordResetToken(rawToken)
                .orElseThrow(() -> new IllegalArgumentException("Invalid or expired password reset token."));

        if (admin.getPasswordResetExpiry() == null
                || OffsetDateTime.now().isAfter(admin.getPasswordResetExpiry())) {
            throw new IllegalArgumentException("Password reset token has expired. Request a new one.");
        }

        admin.setPasswordHash(passwordEncoder.encode(newPassword));
        admin.setPasswordResetToken(null);
        admin.setPasswordResetExpiry(null);
        admin.setMustChangePassword(false);
        adminRepository.save(admin);

        audit(admin.getAdminId(), "PASSWORD_RESET_COMPLETE", admin.getAdminId(), "Password updated via reset link");
        log.info("Password reset completed for admin: {}", admin.getUsername());
    }

    /**
     * Authenticated admin changing their own password.
     */
    @Transactional
    public void changeOwnPassword(UUID adminId, String newPassword) {
        Admin admin = findOrThrow(adminId);
        admin.setPasswordHash(passwordEncoder.encode(newPassword));
        admin.setMustChangePassword(false);
        adminRepository.save(admin);

        audit(admin.getAdminId(), "PASSWORD_CHANGE", admin.getAdminId(), "Admin changed their own password");
        log.info("Password changed by admin: {}", admin.getUsername());
    }

    // ── Soft Delete ──────────────────────────────────────────────────────────

    @Transactional
    public void deleteAdminAccount(UUID actingAdminId, UUID targetAdminId) {
        Admin target = findOrThrow(targetAdminId);
        // Soft delete: disable and clear sensitive fields
        target.setIsActive(false);
        target.setPasswordResetToken(null);
        target.setPasswordResetExpiry(null);
        adminRepository.save(target);
        audit(actingAdminId, "DELETE_ADMIN", targetAdminId, "Soft-deleted admin: " + target.getUsername());
        log.info("Admin {} soft-deleted by {}", targetAdminId, actingAdminId);
    }

    // ── Listing ──────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<Admin> listAllAdmins(UUID schoolId) {
        if (schoolId != null) {
            return adminRepository.findBySchoolId(schoolId);
        }
        return adminRepository.findAll();
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private Admin findOrThrow(UUID adminId) {
        return adminRepository.findById(adminId)
                .orElseThrow(() -> new IllegalArgumentException("Admin not found: " + adminId));
    }

    private void audit(UUID adminId, String action, UUID targetId, String details) {
        AdminAuditLog entry = AdminAuditLog.builder()
                .adminId(adminId)
                .action(action)
                .targetId(targetId)
                .details(details)
                .build();
        auditLogRepository.save(entry);
    }

    private String generateTemporaryPassword() {
        // 12-character alphanumeric password
        String chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$";
        StringBuilder sb = new StringBuilder(12);
        java.security.SecureRandom random = new java.security.SecureRandom();
        for (int i = 0; i < 12; i++) {
            sb.append(chars.charAt(random.nextInt(chars.length())));
        }
        return sb.toString();
    }
}
