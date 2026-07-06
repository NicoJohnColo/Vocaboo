package com.vocaboo.service;

import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

/**
 * Email service for admin account management.
 *
 * Requires Spring Mail configuration in application.properties:
 *   spring.mail.host=smtp.example.com
 *   spring.mail.port=587
 *   spring.mail.username=noreply@vocaboo.app
 *   spring.mail.password=<your-smtp-password>
 *   spring.mail.properties.mail.smtp.auth=true
 *   spring.mail.properties.mail.smtp.starttls.enable=true
 */
@Service
@RequiredArgsConstructor
public class AdminEmailService {

    private static final Logger log = LoggerFactory.getLogger(AdminEmailService.class);

    private final JavaMailSender mailSender;

    @Value("${MAIL_FROM:onboarding@resend.dev}")
    private String fromAddress;

    @Value("${app.admin.base-url:https://vocaboo-admin.app}")
    private String adminBaseUrl;

    /**
     * Sends a welcome email to a newly created admin with their temporary password.
     *
     * @param toEmail          the new admin's email address
     * @param username         the new admin's username
     * @param temporaryPassword the plaintext temporary password (generated before hashing)
     */
    public void sendWelcomeEmail(String toEmail, String username, String temporaryPassword) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromAddress);
            message.setTo(toEmail);
            message.setSubject("[Vocaboo] Your Admin Account Has Been Created");
            message.setText(String.format(
                    "Hello %s,%n%n" +
                    "An admin account has been created for you on Vocaboo.%n%n" +
                    "Login URL: %s/login%n" +
                    "Username: %s%n" +
                    "Temporary Password: %s%n%n" +
                    "You will be required to change your password on first login.%n%n" +
                    "If you did not expect this email, please contact your system administrator.%n%n" +
                    "— The Vocaboo Team",
                    username, adminBaseUrl, username, temporaryPassword
            ));
            mailSender.send(message);
            log.info("Welcome email sent to: {}", toEmail);
        } catch (Exception e) {
            log.error("Failed to send welcome email to {}: {}", toEmail, e.getMessage());
            
            // Fallback for local development when SMTP is not configured
            log.warn("=====================================================");
            log.warn("FALLBACK EMAIL LOG (SMTP FAILED)");
            log.warn("To: {}", toEmail);
            log.warn("Subject: [Vocaboo] Your Admin Account Has Been Created");
            log.warn("Login URL: {}/login", adminBaseUrl);
            log.warn("Username: {}", username);
            log.warn("Temporary Password: {}", temporaryPassword);
            log.warn("=====================================================");
            
            // Non-fatal: account is created, email failure is logged
        }
    }

    /**
     * Sends a password reset link to an existing admin.
     *
     * @param toEmail    the admin's email address
     * @param username   the admin's username
     * @param resetToken the raw (unhashed) reset token
     */
    public void sendPasswordResetEmail(String toEmail, String username, String resetToken) {
        try {
            String resetUrl = adminBaseUrl + "/reset-password?token=" + resetToken;

            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromAddress);
            message.setTo(toEmail);
            message.setSubject("[Vocaboo] Password Reset Request");
            message.setText(String.format(
                    "Hello %s,%n%n" +
                    "A password reset was requested for your Vocaboo admin account.%n%n" +
                    "Click the link below to reset your password (expires in 1 hour):%n" +
                    "%s%n%n" +
                    "If you did not request a password reset, you can safely ignore this email.%n%n" +
                    "— The Vocaboo Team",
                    username, resetUrl
            ));
            mailSender.send(message);
            log.info("Password reset email sent to: {}", toEmail);
        } catch (Exception e) {
            log.error("Failed to send password reset email to {}: {}", toEmail, e.getMessage());
            
            // Fallback for local development when SMTP is not configured
            String resetUrl = adminBaseUrl + "/reset-password?token=" + resetToken;
            log.warn("=====================================================");
            log.warn("FALLBACK EMAIL LOG (SMTP FAILED)");
            log.warn("To: {}", toEmail);
            log.warn("Subject: [Vocaboo] Password Reset Request");
            log.warn("Username: {}", username);
            log.warn("Reset Link: {}", resetUrl);
            log.warn("=====================================================");
        }
    }
}
