package com.vocaboo.service;

import com.vocaboo.dto.request.TeacherRegisterRequest;
import com.vocaboo.dto.response.TeacherRegisterResponse;
import com.vocaboo.entity.Teacher;
import com.vocaboo.repository.TeacherRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class TeacherService {

    private static final Logger log = LoggerFactory.getLogger(TeacherService.class);

    private final TeacherRepository teacherRepository;
    private final PasswordEncoder passwordEncoder;
    private final AdminEmailService emailService;

    // ── Registration ─────────────────────────────────────────────────────────

    /**
     * Registers a new teacher account.
     * The password is BCrypt-hashed before storage — never stored in plaintext.
     *
     * @param request teacher registration form data from the frontend
     * @return a response DTO containing the saved teacher's details
     */
    @Transactional
    public TeacherRegisterResponse register(TeacherRegisterRequest request) {
        String normalizedEmail = request.getEmail().trim().toLowerCase();
        String normalizedUsername = request.getUsername().trim();

        if (teacherRepository.existsByUsername(normalizedUsername)) {
            throw new IllegalArgumentException(
                    "Username '" + normalizedUsername + "' is already taken.");
        }
        if (teacherRepository.existsByEmail(normalizedEmail)) {
            throw new IllegalArgumentException(
                    "An account with email '" + normalizedEmail + "' already exists.");
        }

        Teacher teacher = Teacher.builder()
                .username(normalizedUsername)
                .email(normalizedEmail)
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .firstname(request.getFirstname() != null ? request.getFirstname().trim() : null)
                .middlename(request.getMiddlename() != null ? request.getMiddlename().trim() : null)
                .lastname(request.getLastname() != null ? request.getLastname().trim() : null)
                .gender(request.getGender())
                .school(request.getSchool() != null ? request.getSchool().trim() : null)
                .build();

        teacher = teacherRepository.save(teacher);
        log.info("Teacher registered successfully: {} | {} ({})", normalizedUsername, normalizedEmail, teacher.getTeacherId());

        return TeacherRegisterResponse.builder()
                .teacherId(teacher.getTeacherId())
                .username(teacher.getUsername())
                .email(teacher.getEmail())
                .firstname(teacher.getFirstname())
                .middlename(teacher.getMiddlename())
                .lastname(teacher.getLastname())
                .gender(teacher.getGender())
                .school(teacher.getSchool())
                .message("Teacher account created successfully.")
                .build();
    }

    // ── Forgot Password ───────────────────────────────────────────────────────

    /**
     * Self-service "Forgot Password" — called from the public login page.
     * Looks up the teacher by email, generates a 1-hour reset token, and sends the link.
     * Always returns silently even if the email is not found (prevents enumeration).
     *
     * @param email the teacher's registered email address
     */
    @Transactional
    public void requestPasswordReset(String email) {
        teacherRepository.findByEmail(email.trim().toLowerCase()).ifPresent(teacher -> {
            String rawToken = UUID.randomUUID().toString();
            teacher.setPasswordResetToken(rawToken);
            teacher.setPasswordResetExpiry(OffsetDateTime.now().plusHours(1));
            teacherRepository.save(teacher);

            // Reuse the existing email service — pass "teacher" so the reset link includes role=teacher
            emailService.sendPasswordResetEmail(
                    teacher.getEmail(),
                    teacher.getUsername() != null ? teacher.getUsername() : teacher.getEmail(),
                    rawToken,
                    "teacher"
            );
            log.info("Password reset email sent to teacher: {}", email);
        });
    }

    /**
     * Completes a teacher password reset using the token from the reset link.
     *
     * @param rawToken    the token from the reset URL query param
     * @param newPassword the new plaintext password (will be hashed)
     */
    @Transactional
    public void completePasswordReset(String rawToken, String newPassword) {
        Teacher teacher = teacherRepository.findByPasswordResetToken(rawToken)
                .orElseThrow(() -> new IllegalArgumentException("Invalid or expired password reset token."));

        if (teacher.getPasswordResetExpiry() == null
                || OffsetDateTime.now().isAfter(teacher.getPasswordResetExpiry())) {
            throw new IllegalArgumentException("Password reset token has expired. Please request a new one.");
        }

        teacher.setPasswordHash(passwordEncoder.encode(newPassword));
        teacher.setPasswordResetToken(null);
        teacher.setPasswordResetExpiry(null);
        teacherRepository.save(teacher);

        log.info("Password reset completed for teacher: {}", teacher.getEmail());
    }
}
