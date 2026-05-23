package com.vocaboo.service;

import com.vocaboo.dto.request.LoginRequest;
import com.vocaboo.dto.request.RegisterRequest;
import com.vocaboo.dto.response.AuthResponse;
import com.vocaboo.dto.response.LearnerResponse;
import com.vocaboo.entity.Learner;
import com.vocaboo.repository.LearnerRepository;
import com.vocaboo.entity.LanguageMedium;
import com.vocaboo.entity.ReviewSession;
import com.vocaboo.entity.SandboxSession;
import com.vocaboo.repository.*;
import com.vocaboo.security.JwtUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class LearnerService {

    private final LearnerRepository learnerRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtils jwtUtils;
    private final LearnerLessonStatusRepository lessonStatusRepository;
    private final PronunciationAttemptRepository pronunciationAttemptRepository;
    private final WordProgressRepository wordProgressRepository;
    private final DiagnosticResultRepository diagnosticResultRepository;
    private final IntroductionSessionRepository introductionSessionRepository;
    private final ReviewSessionRepository reviewSessionRepository;
    private final ReviewItemRepository reviewItemRepository;
    private final SandboxSessionRepository sandboxSessionRepository;
    private final SandboxWordRepository sandboxWordRepository;
    private final SandboxWordProgressRepository sandboxWordProgressRepository;

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

    @Transactional
    public LearnerResponse updatePreferences(UUID learnerId, String displayName, String languagePreferenceStr) {
        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner profile not found."));

        if (displayName != null && !displayName.trim().isEmpty()) {
            learner.setDisplayName(displayName.trim());
        }

        if (languagePreferenceStr != null && !languagePreferenceStr.trim().isEmpty()) {
            try {
                LanguageMedium preference = LanguageMedium.valueOf(languagePreferenceStr.toUpperCase().trim());
                learner.setLanguagePreference(preference);
            } catch (Exception e) {
                // Ignore invalid preferences
            }
        }

        learner = learnerRepository.save(learner);

        return LearnerResponse.builder()
                .learnerId(learner.getLearnerId())
                .displayName(learner.getDisplayName())
                .age(learner.getAge())
                .languagePreference(learner.getLanguagePreference())
                .onboardingComplete(learner.getOnboardingComplete())
                .build();
    }

    @Transactional
    public void resetProgress(UUID learnerId) {
        // Fetch and purge sandbox session entities (sandbox_word_progress, sandbox_words, then sandbox_sessions)
        List<SandboxSession> sSessions = sandboxSessionRepository.findByLearnerLearnerIdOrderByCreatedAtDesc(learnerId);
        for (SandboxSession sSession : sSessions) {
            sandboxWordProgressRepository.deleteBySessionSessionId(sSession.getSessionId());
            sandboxWordRepository.deleteBySessionSessionId(sSession.getSessionId());
        }
        sandboxSessionRepository.deleteByLearnerLearnerId(learnerId);

        // Fetch and purge review sessions (review_items, then review_sessions)
        List<ReviewSession> rSessions = reviewSessionRepository.findByLearnerLearnerId(learnerId);
        for (ReviewSession rSession : rSessions) {
            reviewItemRepository.deleteBySessionSessionId(rSession.getSessionId());
        }
        reviewSessionRepository.deleteByLearnerLearnerId(learnerId);

        // Purge standard diagnostic, pronunciation, progress, and lesson stats
        pronunciationAttemptRepository.deleteByLearnerLearnerId(learnerId);
        wordProgressRepository.deleteByLearnerLearnerId(learnerId);
        diagnosticResultRepository.deleteByLearnerLearnerId(learnerId);
        introductionSessionRepository.deleteByLearnerLearnerId(learnerId);
        lessonStatusRepository.deleteByLearnerLearnerId(learnerId);
    }
}
