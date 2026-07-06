package com.vocaboo.security;

import com.vocaboo.dto.request.AdminLoginRequest;
import com.vocaboo.dto.request.AdminRegisterRequest;
import com.vocaboo.dto.response.AdminAuthResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {

    private final AdminAuthService adminAuthService;

    /**
     * POST /api/admin/login
     * Public endpoint — no JWT required. Returns a JWT with ROLE_ADMIN upon valid credentials.
     */
    @PostMapping("/login")
    public ResponseEntity<AdminAuthResponse> login(@Valid @RequestBody AdminLoginRequest request) {
        AdminAuthResponse response = adminAuthService.login(request);
        return ResponseEntity.ok(response);
    }

    /**
     * POST /api/admin/register
     * Public endpoint — no JWT required. Registers a new admin and returns credentials and JWT token.
     */
    @PostMapping("/register")
    public ResponseEntity<AdminAuthResponse> register(@Valid @RequestBody AdminRegisterRequest request) {
        AdminAuthResponse response = adminAuthService.register(request);
        return ResponseEntity.ok(response);
    }
}
