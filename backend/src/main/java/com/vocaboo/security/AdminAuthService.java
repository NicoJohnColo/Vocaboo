package com.vocaboo.security;

import com.vocaboo.dto.request.AdminRegisterRequest;
import com.vocaboo.dto.request.AdminLoginRequest;
import com.vocaboo.dto.response.AdminAuthResponse;
import com.vocaboo.entity.Admin;
import com.vocaboo.entity.Teacher;
import com.vocaboo.repository.AdminRepository;
import com.vocaboo.repository.TeacherRepository;
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
    private final TeacherRepository teacherRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtils jwtUtils;

    /**
     * Validates credentials against both the admins and teachers tables.
     * Checks admins first; if the username is not found there, tries teachers.
     * Returns a JWT with the appropriate role claim (ROLE_ADMIN or ROLE_TEACHER).
     */
    @Transactional
    public AdminAuthResponse login(AdminLoginRequest request) {
        String username = request.getUsername().trim();
        String password = request.getPassword();

        // ── 1. Try admin table ───────────────────────────────────────────────
        var adminOpt = adminRepository.findByUsername(username);
        if (adminOpt.isPresent()) {
            Admin admin = adminOpt.get();

            if (!Boolean.TRUE.equals(admin.getIsActive())) {
                log.warn("Admin login attempt on disabled account: {}", admin.getUsername());
                throw new DisabledException("This admin account has been disabled. Contact a super-admin.");
            }

            if (!passwordEncoder.matches(password, admin.getPasswordHash())) {
                log.warn("Admin login failed — wrong password for: {}", admin.getUsername());
                throw new BadCredentialsException("Invalid username or password.");
            }

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
                    .role("admin")
                    .build();
        }

        // ── 2. Try teacher table ─────────────────────────────────────────────
        var teacherOpt = teacherRepository.findByUsername(username);
        if (teacherOpt.isPresent()) {
            Teacher teacher = teacherOpt.get();

            if (!passwordEncoder.matches(password, teacher.getPasswordHash())) {
                log.warn("Teacher login failed — wrong password for: {}", teacher.getUsername());
                throw new BadCredentialsException("Invalid username or password.");
            }

            String token = jwtUtils.generateTeacherToken(teacher.getTeacherId(), teacher.getUsername());
            log.info("Teacher logged in successfully: {}", teacher.getUsername());

            return AdminAuthResponse.builder()
                    .token(token)
                    .adminId(teacher.getTeacherId())
                    .username(teacher.getUsername())
                    .email(teacher.getEmail())
                    .mustChangePassword(false)
                    .role("teacher")
                    .build();
        }

        // ── 3. Not found in either table ─────────────────────────────────────
        log.warn("Login failed — username not found in admin or teacher tables: {}", username);
        throw new BadCredentialsException("Invalid username or password.");
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
                .role("admin")
                .build();
    }
}
