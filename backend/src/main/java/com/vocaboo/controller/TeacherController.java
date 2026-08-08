package com.vocaboo.controller;

import com.vocaboo.dto.request.TeacherRegisterRequest;
import com.vocaboo.dto.response.TeacherRegisterResponse;
import com.vocaboo.service.TeacherService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/teachers")
@RequiredArgsConstructor
public class TeacherController {

    private static final Logger log = LoggerFactory.getLogger(TeacherController.class);

    private final TeacherService teacherService;

    /**
     * POST /api/teachers/register
     * Public endpoint — allows a teacher to self-register.
     * The password is hashed server-side; it is never stored in plaintext.
     *
     * Request body:
     * {
     *   "username":   "teacher_username",
     *   "email":      "teacher@school.edu.ph",
     *   "password":   "secretPass123",
     *   "firstname":  "Juan",
     *   "middlename": "Santos",   // optional
     *   "lastname":   "Dela Cruz",
     *   "gender":     "Male",     // optional
     *   "school":     "Bagong Silang High School" // optional
     * }
     */
    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody TeacherRegisterRequest request) {
        try {
            TeacherRegisterResponse response = teacherService.register(request);
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (IllegalArgumentException ex) {
            log.warn("Teacher registration rejected: {}", ex.getMessage());
            return ResponseEntity
                    .status(HttpStatus.CONFLICT)
                    .body(Map.of("message", ex.getMessage()));
        } catch (Exception ex) {
            log.error("Unexpected error during teacher registration", ex);
            return ResponseEntity
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("message", "An unexpected error occurred. Please try again."));
        }
    }

    /**
     * POST /api/teachers/request-reset
     * Public endpoint — teacher self-service "Forgot Password".
     * Always returns 200 to prevent email enumeration.
     *
     * Request: { "email": "teacher@school.edu.ph" }
     */
    @PostMapping("/request-reset")
    public ResponseEntity<Map<String, String>> requestPasswordReset(
            @RequestBody Map<String, String> body) {

        String email = body.get("email");
        if (email == null || email.isBlank()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "email is required"));
        }

        teacherService.requestPasswordReset(email);

        return ResponseEntity.ok(Map.of(
                "status",  "sent",
                "message", "If that email is registered, a reset link has been sent."
        ));
    }

    /**
     * POST /api/teachers/complete-reset
     * Public endpoint — called from the reset-password page.
     *
     * Request: { "token": "...", "new_password": "..." }
     */
    @PostMapping("/complete-reset")
    public ResponseEntity<Map<String, String>> completePasswordReset(
            @RequestBody Map<String, String> body) {

        String token = body.get("token");
        String newPassword = body.get("new_password");

        if (token == null || newPassword == null) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "token and new_password are required"));
        }

        try {
            teacherService.completePasswordReset(token, newPassword);
            return ResponseEntity.ok(Map.of(
                    "status",  "password_updated",
                    "message", "Password has been reset. You may now log in."
            ));
        } catch (IllegalArgumentException ex) {
            log.warn("Teacher password reset failed: {}", ex.getMessage());
            return ResponseEntity.badRequest()
                    .body(Map.of("error", ex.getMessage()));
        }
    }
}
