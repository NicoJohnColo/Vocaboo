package com.vocaboo.controller;

import com.vocaboo.service.TokenRefreshService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

@RestController
@RequiredArgsConstructor
public class AuthController {

    private final TokenRefreshService tokenRefreshService;

    /**
     * POST /api/auth/refresh
     * Exchange a valid refresh token for a new short-lived access token.
     *
     * Request:  { "refresh_token": "eyJ..." }
     * Response: { "access_token": "...", "token_type": "Bearer", "expires_in": 900 }
     */
    @PostMapping("/api/auth/refresh")
    public ResponseEntity<Map<String, Object>> refresh(@RequestBody Map<String, String> body) {
        String rawRefreshToken = body.get("refresh_token");
        if (rawRefreshToken == null || rawRefreshToken.isBlank()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "refresh_token is required"));
        }

        String newAccessToken = tokenRefreshService.exchangeRefreshTokenForAccessToken(rawRefreshToken);

        return ResponseEntity.ok(Map.of(
                "access_token", newAccessToken,
                "token_type", "Bearer",
                "expires_in", 900
        ));
    }

    /**
     * POST /api/auth/logout
     * Revoke the refresh token (logout from current device).
     *
     * Request:  { "refresh_token": "eyJ..." }
     * Response: { "status": "logged_out", "message": "All tokens revoked" }
     */
    @PostMapping("/api/auth/logout")
    public ResponseEntity<Map<String, String>> logout(@RequestBody Map<String, String> body) {
        String rawRefreshToken = body.get("refresh_token");
        if (rawRefreshToken != null && !rawRefreshToken.isBlank()) {
            tokenRefreshService.revokeRefreshToken(rawRefreshToken);
        }
        return ResponseEntity.ok(Map.of(
                "status", "logged_out",
                "message", "All tokens revoked"
        ));
    }

    /**
     * POST /api/admin/logout-everywhere
     * Force-revoke ALL refresh tokens for a given user (admin only).
     *
     * Request:  { "user_id": "uuid" }
     */
    @PostMapping("/api/admin/logout-everywhere")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, String>> logoutEverywhere(@RequestBody Map<String, String> body) {
        String userIdStr = body.get("user_id");
        if (userIdStr == null || userIdStr.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "user_id is required"));
        }

        UUID userId = UUID.fromString(userIdStr);
        tokenRefreshService.revokeAllTokensForUser(userId);

        return ResponseEntity.ok(Map.of(
                "status", "logged_out",
                "message", "All sessions revoked for user " + userId
        ));
    }
}
