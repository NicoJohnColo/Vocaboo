package com.vocaboo.controller;

import com.vocaboo.entity.Admin;
import com.vocaboo.service.AdminAccountService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admin/accounts")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminAccountController {

    private final AdminAccountService adminAccountService;

    /**
     * GET /api/admin/accounts?school_id=uuid
     * List all admins (optionally filtered by school).
     */
    @GetMapping
    public ResponseEntity<List<Map<String, Object>>> listAdmins(
            @RequestParam(required = false) UUID school_id) {
        return ResponseEntity.ok(adminAccountService.listAllAccounts(school_id));
    }

    /**
     * POST /api/admin/accounts
     * Create a new account (Admin or Teacher).
     *
     * Request: { "username": "...", "email": "...", "role": "ADMIN|TEACHER", "school": "...", "firstname": "...", "lastname": "..." }
     */
    @PostMapping
    public ResponseEntity<Map<String, Object>> createAdmin(
            @RequestBody Map<String, String> body,
            Authentication auth) {

        UUID actingAdminId = UUID.fromString(auth.getName());
        String username = body.get("username");
        String email = body.get("email");
        String role = body.getOrDefault("role", "ADMIN").trim().toUpperCase();

        if ("TEACHER".equals(role)) {
            String school = body.get("school");
            String firstname = body.get("firstname");
            String lastname = body.get("lastname");
            com.vocaboo.entity.Teacher teacher = adminAccountService.createTeacherAccount(actingAdminId, username, email, school, firstname, lastname);
            return ResponseEntity.ok(Map.of(
                    "admin_id", teacher.getTeacherId(),
                    "account_id", teacher.getTeacherId(),
                    "role", "TEACHER",
                    "status", "created",
                    "message", "Teacher account created. Temporary password sent to " + teacher.getEmail()
            ));
        } else {
            UUID schoolId = body.containsKey("school_id") && body.get("school_id") != null && !body.get("school_id").isBlank()
                    ? UUID.fromString(body.get("school_id")) : null;
            Admin created = adminAccountService.createAdminAccount(actingAdminId, username, email, schoolId);
            return ResponseEntity.ok(Map.of(
                    "admin_id", created.getAdminId(),
                    "account_id", created.getAdminId(),
                    "role", "ADMIN",
                    "status", "created",
                    "message", "Admin account created. Temporary password sent to " + created.getEmail()
            ));
        }
    }

    /**
     * PUT /api/admin/accounts/{id}/status
     * Enable or disable an admin account.
     *
     * Request: { "is_active": true|false }
     */
    @PutMapping("/{id}/status")
    public ResponseEntity<Map<String, Object>> updateStatus(
            @PathVariable UUID id,
            @RequestBody Map<String, Boolean> body,
            Authentication auth) {

        UUID actingAdminId = UUID.fromString(auth.getName());
        boolean isActive = Boolean.TRUE.equals(body.get("is_active"));

        Admin updated = isActive
                ? adminAccountService.enableAdminAccount(actingAdminId, id)
                : adminAccountService.disableAdminAccount(actingAdminId, id);

        String status = isActive ? "enabled" : "disabled";
        return ResponseEntity.ok(Map.of(
                "status",  status,
                "message", "Admin account " + status
        ));
    }

    /**
     * POST /api/admin/accounts/{id}/reset-password
     * Send a password reset link to the given admin.
     */
    @PostMapping("/{id}/reset-password")
    public ResponseEntity<Map<String, String>> resetPassword(
            @PathVariable UUID id,
            Authentication auth) {

        UUID actingAdminId = UUID.fromString(auth.getName());
        adminAccountService.resetAdminPassword(actingAdminId, id);

        return ResponseEntity.ok(Map.of(
                "status",  "reset_sent",
                "message", "Password reset link sent to admin's email"
        ));
    }

    /**
     * PUT /api/admin/accounts/me/password
     * Allows an authenticated admin to change their own password.
     *
     * Request: { "new_password": "..." }
     */
    @PutMapping("/me/password")
    public ResponseEntity<Map<String, String>> changeOwnPassword(
            @RequestBody Map<String, String> body,
            Authentication auth) {

        String newPassword = body.get("new_password");
        if (newPassword == null || newPassword.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "new_password is required"));
        }

        UUID actingAdminId = UUID.fromString(auth.getName());
        adminAccountService.changeOwnPassword(actingAdminId, newPassword);

        return ResponseEntity.ok(Map.of(
                "status",  "password_updated",
                "message", "Your password has been changed successfully."
        ));
    }

    /**
     * DELETE /api/admin/accounts/{id}
     * Soft-delete an admin account.
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Map<String, String>> deleteAdmin(
            @PathVariable UUID id,
            Authentication auth) {

        UUID actingAdminId = UUID.fromString(auth.getName());
        adminAccountService.deleteAdminAccount(actingAdminId, id);

        return ResponseEntity.ok(Map.of(
                "status",  "deleted",
                "message", "Admin account has been deactivated"
        ));
    }
}
