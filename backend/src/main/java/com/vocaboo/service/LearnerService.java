package com.vocaboo.service;

import com.vocaboo.dto.request.LoginRequest;
import com.vocaboo.dto.request.RegisterRequest;
import com.vocaboo.dto.response.AuthResponse;
import com.vocaboo.dto.response.LearnerResponse;
import com.vocaboo.entity.Learner;
import com.vocaboo.repository.LearnerRepository;
import com.vocaboo.security.JwtUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class LearnerService {

    private final LearnerRepository learnerRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtils jwtUtils;

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (learnerRepository.findByDisplayNameIgnoreCase(request.getDisplayName().trim()).isPresent()) {
            throw new IllegalArgumentException("This name is already taken. Please choose another one.");
        }

        // Enforce 12 strength BCrypt (done in SecurityConfig passwordEncoder bean config)
        String hashedPin = passwordEncoder.encode(request.getPin());

        Learner learner = Learner.builder()
                .displayName(request.getDisplayName())
                .age(request.getAge())
                .pinHash(hashedPin)
                .languagePreference(request.getLanguagePreference())
                .onboardingComplete(true) // complete upon registration
                .build();

        learner = learnerRepository.save(learner);
        String token = jwtUtils.generateToken(learner.getLearnerId(), learner.getDisplayName());

        return AuthResponse.builder()
                .token(token)
                .learnerId(learner.getLearnerId())
                .displayName(learner.getDisplayName())
                .onboardingComplete(learner.getOnboardingComplete())
                .languagePreference(learner.getLanguagePreference())
                .build();
    }

    public AuthResponse login(LoginRequest request) {
        String identifier = request.getLearnerId().trim();
        Learner learner = null;

        try {
            UUID uuid = UUID.fromString(identifier);
            learner = learnerRepository.findById(uuid).orElse(null);
        } catch (IllegalArgumentException e) {
            // Not a UUID format, proceed to display name lookup
        }

        if (learner == null) {
            learner = learnerRepository.findByDisplayNameIgnoreCase(identifier)
                    .orElseThrow(() -> new BadCredentialsException("Incorrect PIN, please try again."));
        }

        if (!passwordEncoder.matches(request.getPin(), learner.getPinHash())) {
            throw new BadCredentialsException("Incorrect PIN, please try again.");
        }

        String token = jwtUtils.generateToken(learner.getLearnerId(), learner.getDisplayName());

        return AuthResponse.builder()
                .token(token)
                .learnerId(learner.getLearnerId())
                .displayName(learner.getDisplayName())
                .onboardingComplete(learner.getOnboardingComplete())
                .languagePreference(learner.getLanguagePreference())
                .build();
    }

    public LearnerResponse getProfile(UUID learnerId) {
        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner profile not found."));

        return LearnerResponse.builder()
                .learnerId(learner.getLearnerId())
                .displayName(learner.getDisplayName())
                .age(learner.getAge())
                .languagePreference(learner.getLanguagePreference())
                .onboardingComplete(learner.getOnboardingComplete())
                .build();
    }
}
