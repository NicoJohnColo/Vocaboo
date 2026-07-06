package com.vocaboo.security;

import com.vocaboo.dto.request.AdminRegisterRequest;
import com.vocaboo.dto.response.AdminAuthResponse;
import com.vocaboo.entity.Admin;
import com.vocaboo.repository.AdminRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AdminAuthServiceTest {

    @Mock
    private AdminRepository adminRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtUtils jwtUtils;

    @InjectMocks
    private AdminAuthService adminAuthService;

    @Test
    void register_success() {
        // Arrange
        AdminRegisterRequest request = AdminRegisterRequest.builder()
                .username("newadmin")
                .email("new@vocaboo.com")
                .password("securepassword")
                .build();

        UUID expectedId = UUID.randomUUID();
        Admin savedAdmin = Admin.builder()
                .adminId(expectedId)
                .username("newadmin")
                .email("new@vocaboo.com")
                .passwordHash("hashedpassword")
                .isActive(true)
                .build();

        when(adminRepository.findByUsername("newadmin")).thenReturn(Optional.empty());
        when(adminRepository.findByEmail("new@vocaboo.com")).thenReturn(Optional.empty());
        when(passwordEncoder.encode("securepassword")).thenReturn("hashedpassword");
        when(adminRepository.save(any(Admin.class))).thenReturn(savedAdmin);
        when(jwtUtils.generateAdminToken(expectedId, "newadmin")).thenReturn("mock-jwt-token");

        // Act
        AdminAuthResponse response = adminAuthService.register(request);

        // Assert
        assertNotNull(response);
        assertEquals("mock-jwt-token", response.getToken());
        assertEquals(expectedId, response.getAdminId());
        assertEquals("newadmin", response.getUsername());
        assertEquals("new@vocaboo.com", response.getEmail());

        verify(adminRepository).save(any(Admin.class));
    }

    @Test
    void register_duplicateUsername_throwsException() {
        // Arrange
        AdminRegisterRequest request = AdminRegisterRequest.builder()
                .username("existingadmin")
                .email("new@vocaboo.com")
                .password("password")
                .build();

        when(adminRepository.findByUsername("existingadmin")).thenReturn(Optional.of(new Admin()));

        // Act & Assert
        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class, () -> {
            adminAuthService.register(request);
        });

        assertEquals("Username 'existingadmin' is already taken.", exception.getMessage());
        verify(adminRepository, never()).save(any(Admin.class));
    }

    @Test
    void register_duplicateEmail_throwsException() {
        // Arrange
        AdminRegisterRequest request = AdminRegisterRequest.builder()
                .username("newadmin")
                .email("existing@vocaboo.com")
                .password("password")
                .build();

        when(adminRepository.findByUsername("newadmin")).thenReturn(Optional.empty());
        when(adminRepository.findByEmail("existing@vocaboo.com")).thenReturn(Optional.of(new Admin()));

        // Act & Assert
        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class, () -> {
            adminAuthService.register(request);
        });

        assertEquals("An admin with email 'existing@vocaboo.com' already exists.", exception.getMessage());
        verify(adminRepository, never()).save(any(Admin.class));
    }
}
