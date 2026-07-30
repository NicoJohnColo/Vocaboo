package com.vocaboo.service;

import com.vocaboo.dto.request.ChangePinRequest;
import com.vocaboo.dto.request.LoginRequest;
import com.vocaboo.dto.request.RegisterRequest;
import com.vocaboo.dto.response.AuthResponse;
import com.vocaboo.dto.response.LearnerResponse;
import com.vocaboo.entity.LanguageMedium;
import com.vocaboo.entity.Learner;
import com.vocaboo.entity.PracticeSession;
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
    private final SessionSummaryRepository summaryRepository;
    private final PracticeResultRepository practiceResultRepository;
    private final PracticeSessionRepository practiceSessionRepository;
    private final WordPerformanceRepository performanceRepository;
    private final LearnerMasteryRepository masteryRepository;
    private final DifficultyProgressRepository difficultyProgressRepository;
    private final PointTransactionRepository pointTransactionRepository;
    private final RewardDataRepository rewardDataRepository;

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (learnerRepository.findByDisplayNameIgnoreCase(request.getDisplayName().trim()).isPresent()) {
            throw new IllegalArgumentException("This name is already taken. Please choose another one.");
        }

        String hashedPin = passwordEncoder.encode(request.getPin());

        Learner learner = Learner.builder()
                .displayName(request.getDisplayName())
                .age(request.getAge())
                .pinHash(hashedPin)
                .languagePreference(request.getLanguagePreference())
                .onboardingComplete(true)
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

    public boolean isNameAvailable(String displayName) {
        return learnerRepository.findByDisplayNameIgnoreCase(displayName.trim()).isEmpty();
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
                .masteryApplyImmediately(learner.getMasteryApplyImmediately())
                .build();
    }

    @Transactional
    public LearnerResponse updatePreferences(UUID learnerId, String displayName, String languagePreferenceStr, Boolean masteryApplyImmediately) {
        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner profile not found."));

        if (displayName != null && !displayName.trim().isEmpty()) {
            String newName = displayName.trim();
            if (!newName.equalsIgnoreCase(learner.getDisplayName())) {
                if (learnerRepository.findByDisplayNameIgnoreCase(newName).isPresent()) {
                    throw new IllegalArgumentException("This name is already taken. Please choose another one.");
                }
            }
            learner.setDisplayName(newName);
        }

        if (languagePreferenceStr != null && !languagePreferenceStr.trim().isEmpty()) {
            try {
                LanguageMedium preference = LanguageMedium.valueOf(languagePreferenceStr.toUpperCase().trim());
                learner.setLanguagePreference(preference);
            } catch (Exception e) {
                // Ignore invalid preferences
            }
        }

        if (masteryApplyImmediately != null) {
            learner.setMasteryApplyImmediately(masteryApplyImmediately);
        }

        learner = learnerRepository.save(learner);

        return LearnerResponse.builder()
                .learnerId(learner.getLearnerId())
                .displayName(learner.getDisplayName())
                .age(learner.getAge())
                .languagePreference(learner.getLanguagePreference())
                .onboardingComplete(learner.getOnboardingComplete())
                .masteryApplyImmediately(learner.getMasteryApplyImmediately())
                .build();
    }

    @Transactional
    public void changePin(UUID learnerId, ChangePinRequest request) {
        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner profile not found."));

        if (!passwordEncoder.matches(request.getCurrentPin(), learner.getPinHash())) {
            throw new BadCredentialsException("Current PIN is incorrect.");
        }

        learner.setPinHash(passwordEncoder.encode(request.getNewPin()));
        learnerRepository.save(learner);
    }

    @Transactional
    public void resetProgress(UUID learnerId) {
        List<SandboxSession> sSessions = sandboxSessionRepository.findByLearnerLearnerIdOrderByCreatedAtDesc(learnerId);
        for (SandboxSession sSession : sSessions) {
            sandboxWordProgressRepository.deleteBySessionSessionId(sSession.getSessionId());
            sandboxWordRepository.deleteBySessionSessionId(sSession.getSessionId());
        }
        sandboxSessionRepository.deleteByLearnerLearnerId(learnerId);

        List<ReviewSession> rSessions = reviewSessionRepository.findByLearnerLearnerId(learnerId);
        for (ReviewSession rSession : rSessions) {
            reviewItemRepository.deleteBySessionSessionId(rSession.getSessionId());
        }
        reviewSessionRepository.deleteByLearnerLearnerId(learnerId);

        List<PracticeSession> pSessions = practiceSessionRepository.findByLearnerLearnerId(learnerId);
        for (PracticeSession pSession : pSessions) {
            practiceResultRepository.deleteBySessionSessionId(pSession.getSessionId());
        }
        practiceSessionRepository.deleteByLearnerLearnerId(learnerId);

        summaryRepository.deleteByLearnerLearnerId(learnerId);
        performanceRepository.deleteByLearnerLearnerId(learnerId);
        masteryRepository.deleteByLearnerLearnerId(learnerId);
        difficultyProgressRepository.deleteByLearnerLearnerId(learnerId);
        pointTransactionRepository.deleteByLearnerLearnerId(learnerId);
        rewardDataRepository.deleteByLearnerLearnerId(learnerId);

        pronunciationAttemptRepository.deleteByLearnerLearnerId(learnerId);
        wordProgressRepository.deleteByLearnerLearnerId(learnerId);
        diagnosticResultRepository.deleteByLearnerLearnerId(learnerId);
        introductionSessionRepository.deleteByLearnerLearnerId(learnerId);
        lessonStatusRepository.deleteByLearnerLearnerId(learnerId);
    }
}
