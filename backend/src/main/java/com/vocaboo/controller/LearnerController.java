package com.vocaboo.controller;

import com.vocaboo.dto.request.ChangePinRequest;
import com.vocaboo.dto.request.LoginRequest;
import com.vocaboo.dto.request.RegisterRequest;
import com.vocaboo.dto.response.AuthResponse;
import com.vocaboo.dto.response.LearnerResponse;
import com.vocaboo.service.LearnerService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/learners")
@RequiredArgsConstructor
public class LearnerController {

    private final LearnerService learnerService;

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.ok(learnerService.register(request));
    }

    @GetMapping("/check-name")
    public ResponseEntity<Map<String, Boolean>> checkName(@RequestParam String displayName) {
        boolean available = learnerService.isNameAvailable(displayName);
        return ResponseEntity.ok(Map.of("available", available));
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(learnerService.login(request));
    }

    @GetMapping("/me")
    public ResponseEntity<LearnerResponse> getProfile(Principal principal) {
        UUID learnerId = UUID.fromString(principal.getName());
        return ResponseEntity.ok(learnerService.getProfile(learnerId));
    }

    @lombok.Data
    public static class PreferencesRequest {
        private String displayName;
        private String languagePreference;
        private Boolean masteryApplyImmediately;
        private String posFocus;
        private String avatar;
        private String gradeLevel;
        private Integer age;

        public String getDisplayName() { return displayName; }
        public String getLanguagePreference() { return languagePreference; }
        public Boolean getMasteryApplyImmediately() { return masteryApplyImmediately; }
        public String getPosFocus() { return posFocus; }
        public String getAvatar() { return avatar; }
        public String getGradeLevel() { return gradeLevel; }
        public Integer getAge() { return age; }
    }

    @PatchMapping("/preferences")
    public ResponseEntity<LearnerResponse> updatePreferences(@RequestBody PreferencesRequest request, Principal principal) {
        UUID learnerId = UUID.fromString(principal.getName());
        LearnerResponse response = learnerService.updatePreferences(
                learnerId, 
                request.getDisplayName(), 
                request.getLanguagePreference(), 
                request.getMasteryApplyImmediately(),
                request.getPosFocus(),
                request.getAvatar(),
                request.getGradeLevel(),
                request.getAge()
        );
        return ResponseEntity.ok(response);
    }

    @PatchMapping("/change-pin")
    public ResponseEntity<Void> changePin(@Valid @RequestBody ChangePinRequest request, Principal principal) {
        UUID learnerId = UUID.fromString(principal.getName());
        learnerService.changePin(learnerId, request);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/reset-progress")
    public ResponseEntity<Void> resetProgress(Principal principal) {
        UUID learnerId = UUID.fromString(principal.getName());
        learnerService.resetProgress(learnerId);
        return ResponseEntity.noContent().build();
    }
}
