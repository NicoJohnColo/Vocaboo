package com.vocaboo.controller;

import com.vocaboo.service.AdminAccountService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Public (unauthenticated) controller for completing a password reset.
 * Separated from AdminAccountController to avoid its class-level @PreAuthorize("hasRole('ADMIN')").
 */
@RestController
@RequestMapping("/api/admin/accounts")
@RequiredArgsConstructor
public class PasswordResetController {

    private final AdminAccountService adminAccountService;

    /**
     * POST /api/admin/accounts/request-reset
     * Self-service "Forgot Password" — called from the login page.
     * This endpoint is PUBLIC. Always returns 200 to prevent email enumeration.
     *
     * Request: { "email": "..." }
     */
    @PostMapping("/request-reset")
    public ResponseEntity<Map<String, String>> requestPasswordReset(
            @RequestBody Map<String, String> body) {

        String email = body.get("email");
        if (email == null || email.isBlank()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "email is required"));
        }

        // Always returns 200 — even if the email is not found — to prevent enumeration
        adminAccountService.requestPasswordReset(email);

        return ResponseEntity.ok(Map.of(
                "status",  "sent",
                "message", "If that email is registered, a reset link has been sent."
        ));
    }

    /**
     * POST /api/admin/accounts/complete-reset
     * Called from the reset-password page in the admin panel.
     * This endpoint is PUBLIC — the user clicks a link from their email while not logged in.
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

        adminAccountService.completePasswordReset(token, newPassword);

        return ResponseEntity.ok(Map.of(
                "status",  "password_updated",
                "message", "Password has been reset. You may now log in."
        ));
    }
}
