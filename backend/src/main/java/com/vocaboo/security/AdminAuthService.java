package com.vocaboo.security;

import com.vocaboo.dto.request.AdminRegisterRequest;
import com.vocaboo.dto.request.AdminLoginRequest;
import com.vocaboo.dto.response.AdminAuthResponse;
import com.vocaboo.entity.Admin;
import com.vocaboo.repository.AdminRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;

@Service
@RequiredArgsConstructor
public class AdminAuthService {

    private static final Logger log = LoggerFactory.getLogger(AdminAuthService.class);

    private final AdminRepository adminRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtils jwtUtils;

    /**
     * Validates admin credentials and returns a JWT with ROLE_ADMIN claim.
     */
    @Transactional
    public AdminAuthResponse login(AdminLoginRequest request) {
        Admin admin = adminRepository.findByUsername(request.getUsername().trim())
                .orElseThrow(() -> {
                    log.warn("Admin login failed — username not found: {}", request.getUsername());
                    return new BadCredentialsException("Invalid username or password.");
                });

        if (!Boolean.TRUE.equals(admin.getIsActive())) {
            log.warn("Admin login attempt on disabled account: {}", admin.getUsername());
            throw new DisabledException("This admin account has been disabled. Contact a super-admin.");
        }

        if (!passwordEncoder.matches(request.getPassword(), admin.getPasswordHash())) {
            log.warn("Admin login failed — wrong password for: {}", admin.getUsername());
            throw new BadCredentialsException("Invalid username or password.");
        }

        // Update last login timestamp
        admin.setLastLoginAt(OffsetDateTime.now());
        adminRepository.save(admin);

        String token = jwtUtils.generateAdminToken(admin.getAdminId(), admin.getUsername());
        log.info("Admin logged in successfully: {}", admin.getUsername());

        return AdminAuthResponse.builder()
                .token(token)
                .adminId(admin.getAdminId())
                .username(admin.getUsername())
                .email(admin.getEmail())
                .mustChangePassword(Boolean.TRUE.equals(admin.getMustChangePassword()))
                .build();
    }

    /**
     * Registers a new admin account and returns registration/token details.
     */
    @Transactional
    public AdminAuthResponse register(AdminRegisterRequest request) {
        if (adminRepository.findByUsername(request.getUsername().trim()).isPresent()) {
            throw new IllegalArgumentException("Username '" + request.getUsername().trim() + "' is already taken.");
        }
        if (adminRepository.findByEmail(request.getEmail().trim()).isPresent()) {
            throw new IllegalArgumentException("An admin with email '" + request.getEmail().trim() + "' already exists.");
        }

        Admin newAdmin = Admin.builder()
                .username(request.getUsername().trim())
                .email(request.getEmail().trim())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .isActive(true)
                .mustChangePassword(false)
                .build();

        newAdmin = adminRepository.save(newAdmin);
        log.info("Admin registered successfully: {}", newAdmin.getUsername());

        String token = jwtUtils.generateAdminToken(newAdmin.getAdminId(), newAdmin.getUsername());

        return AdminAuthResponse.builder()
                .token(token)
                .adminId(newAdmin.getAdminId())
                .username(newAdmin.getUsername())
                .email(newAdmin.getEmail())
                .mustChangePassword(Boolean.TRUE.equals(newAdmin.getMustChangePassword()))
                .build();
    }
}
