package com.vocaboo.controller;

import com.vocaboo.dto.request.CreateSectionRequest;
import com.vocaboo.dto.request.UpdateSectionRequest;
import com.vocaboo.dto.response.AdminSectionResponse;
import com.vocaboo.service.AdminSectionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/admin/classes")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
public class AdminSectionController {

    private final AdminSectionService adminSectionService;

    @GetMapping
    public ResponseEntity<List<AdminSectionResponse>> getAllClasses() {
        return ResponseEntity.ok(adminSectionService.getAllSections());
    }

    @GetMapping("/{id}")
    public ResponseEntity<AdminSectionResponse> getClassById(@PathVariable UUID id) {
        return ResponseEntity.ok(adminSectionService.getSectionById(id));
    }

    @PostMapping
    public ResponseEntity<AdminSectionResponse> createClass(
            @Valid @RequestBody CreateSectionRequest req,
            Authentication auth) {
        UUID adminId = parseAdminId(auth);
        AdminSectionResponse response = adminSectionService.createSection(req, adminId);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PatchMapping("/{id}")
    public ResponseEntity<AdminSectionResponse> patchClass(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateSectionRequest req,
            Authentication auth) {
        UUID adminId = parseAdminId(auth);
        return ResponseEntity.ok(adminSectionService.updateSection(id, req, adminId));
    }

    @PutMapping("/{id}")
    public ResponseEntity<AdminSectionResponse> updateClass(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateSectionRequest req,
            Authentication auth) {
        UUID adminId = parseAdminId(auth);
        return ResponseEntity.ok(adminSectionService.updateSection(id, req, adminId));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Map<String, String>> deleteClass(
            @PathVariable UUID id,
            Authentication auth) {
        UUID adminId = parseAdminId(auth);
        adminSectionService.deleteSection(id, adminId);
        return ResponseEntity.ok(Map.of("status", "deleted", "message", "Class/section deleted successfully"));
    }

    private UUID parseAdminId(Authentication auth) {
        if (auth == null || auth.getName() == null) return null;
        try {
            return UUID.fromString(auth.getName());
        } catch (Exception e) {
            return null;
        }
    }
}
