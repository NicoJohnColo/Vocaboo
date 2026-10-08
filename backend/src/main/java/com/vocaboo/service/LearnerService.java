package com.vocaboo.service;

import com.vocaboo.dto.request.ChangePinRequest;
import com.vocaboo.dto.request.LoginRequest;
import com.vocaboo.dto.request.RegisterRequest;
import com.vocaboo.dto.response.AuthResponse;
import com.vocaboo.dto.response.LearnerResponse;
import com.vocaboo.entity.*;
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
    private final LessonModuleScoreRepository lessonModuleScoreRepository;
    private final SandboxModuleScoreRepository sandboxModuleScoreRepository;
    private final ClassPerformanceRepository classPerformanceRepository;
    private final CumulativeReviewSessionRepository cumulativeReviewSessionRepository;
    private final CumulativeReviewResultRepository cumulativeReviewResultRepository;
    private final LessonWordAccuracyRepository lessonWordAccuracyRepository;
    private final ReinforcementQueueRepository reinforcementQueueRepository;
    private final WrongAnswerRecordRepository wrongAnswerRecordRepository;
    private final DifficultyAuditLogRepository difficultyAuditLogRepository;

    private static final String[] DEFAULT_AVATARS = {
            "prof1.jpg", "prof2.jpg", "prof3.jpg", "prof4.jpg", "prof5.jpg",
            "prof6.jpg", "prof7.jpg", "prof8.jpg", "prof9.jpg"
    };

    private String getRandomDefaultAvatar() {
        return DEFAULT_AVATARS[java.util.concurrent.ThreadLocalRandom.current().nextInt(DEFAULT_AVATARS.length)];
    }

    public String generateUniqueUserId() {
        int year = java.time.Year.now().getValue() % 100;
        String prefix = String.format("%02d", year);
        for (int i = 0; i < 100; i++) {
            int mid = java.util.concurrent.ThreadLocalRandom.current().nextInt(10000);
            int suffix = java.util.concurrent.ThreadLocalRandom.current().nextInt(1000);
            String candidate = String.format("%s-%04d-%03d", prefix, mid, suffix);
            if (!learnerRepository.existsByUserId(candidate)) {
                return candidate;
            }
        }
        throw new IllegalStateException("Unable to generate unique user ID after multiple attempts");
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (learnerRepository.findByDisplayNameIgnoreCase(request.getDisplayName().trim()).isPresent()) {
            throw new IllegalArgumentException("This name is already taken. Please choose another one.");
        }

        String hashedPin = passwordEncoder.encode(request.getPin());
        String avatar = (request.getAvatar() != null && !request.getAvatar().trim().isEmpty())
                ? request.getAvatar().trim()
                : getRandomDefaultAvatar();
        String generatedUserId = generateUniqueUserId();

        GradeLevel gradeLevel = request.getGradeLevel() != null ? request.getGradeLevel() : GradeLevel.GRADE_4;

        Learner learner = Learner.builder()
                .userId(generatedUserId)
                .displayName(request.getDisplayName())
                .age(request.getAge())
                .pinHash(hashedPin)
                .avatar(avatar)
                .languagePreference(request.getLanguagePreference())
                .gradeLevel(gradeLevel)
                .onboardingComplete(true)
                .build();

        learner = learnerRepository.save(learner);
        String token = jwtUtils.generateToken(learner.getLearnerId(), learner.getDisplayName());

        return AuthResponse.builder()
                .token(token)
                .learnerId(learner.getLearnerId())
                .userId(learner.getUserId())
                .displayName(learner.getDisplayName())
                .avatar(learner.getAvatar())
                .onboardingComplete(learner.getOnboardingComplete())
                .languagePreference(learner.getLanguagePreference())
                .gradeLevel(learner.getGradeLevel())
                .build();
    }

    public boolean isNameAvailable(String displayName) {
        return learnerRepository.findByDisplayNameIgnoreCase(displayName.trim()).isEmpty();
    }

    public AuthResponse login(LoginRequest request) {
        String identifier = request.getLearnerId().trim();
        Learner learner = null;

        // 1. Check if identifier matches structured User ID format XX-XXXX-XXX
        if (identifier.matches("^\\d{2}-\\d{4}-\\d{3}$")) {
            learner = learnerRepository.findByUserId(identifier).orElse(null);
        }

        // 2. Check if UUID
        if (learner == null) {
            try {
                UUID uuid = UUID.fromString(identifier);
                learner = learnerRepository.findById(uuid).orElse(null);
            } catch (IllegalArgumentException e) {
                // Not a UUID format, proceed to next check
            }
        }

        // 3. Fallback check for case-insensitive User ID lookup
        if (learner == null) {
            learner = learnerRepository.findByUserIdIgnoreCase(identifier).orElse(null);
        }

        // 4. Fallback to display name lookup
        if (learner == null) {
            learner = learnerRepository.findByDisplayNameIgnoreCase(identifier)
                    .orElseThrow(() -> new BadCredentialsException("Incorrect PIN, please try again."));
        }

        if (!passwordEncoder.matches(request.getPin(), learner.getPinHash())) {
            throw new BadCredentialsException("Incorrect PIN, please try again.");
        }

        // Ensure user_id is assigned if legacy account lacked one
        if (learner.getUserId() == null) {
            learner.setUserId(generateUniqueUserId());
            learner = learnerRepository.save(learner);
        }

        String token = jwtUtils.generateToken(learner.getLearnerId(), learner.getDisplayName());

        return AuthResponse.builder()
                .token(token)
                .learnerId(learner.getLearnerId())
                .userId(learner.getUserId())
                .displayName(learner.getDisplayName())
                .avatar(learner.getAvatar())
                .onboardingComplete(learner.getOnboardingComplete())
                .languagePreference(learner.getLanguagePreference())
                .build();
    }

    public LearnerResponse getProfile(UUID learnerId) {
        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner profile not found."));

        if (learner.getUserId() == null) {
            learner.setUserId(generateUniqueUserId());
            learner = learnerRepository.save(learner);
        }

        return LearnerResponse.builder()
                .learnerId(learner.getLearnerId())
                .userId(learner.getUserId())
                .displayName(learner.getDisplayName())
                .age(learner.getAge())
                .avatar(learner.getAvatar())
                .languagePreference(learner.getLanguagePreference())
                .gradeLevel(learner.getGradeLevel())
                .onboardingComplete(learner.getOnboardingComplete())
                .masteryApplyImmediately(learner.getMasteryApplyImmediately())
                .posFocus(learner.getPosFocus())
                .build();
    }

    @Transactional
    public LearnerResponse updatePreferences(UUID learnerId, String displayName, String languagePreferenceStr,
            Boolean masteryApplyImmediately, String posFocus, String avatar, String gradeLevelStr, Integer age) {
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

        if (posFocus != null && !posFocus.trim().isEmpty()) {
            learner.setPosFocus(posFocus.trim().toUpperCase());
        }

        if (avatar != null && !avatar.trim().isEmpty()) {
            learner.setAvatar(avatar.trim());
        }

        if (age != null && age >= 9 && age <= 12) {
            learner.setAge(age);
        }

        if (gradeLevelStr != null && !gradeLevelStr.trim().isEmpty()) {
            try {
                String cleanGrade = gradeLevelStr.trim().toUpperCase();
                if (!cleanGrade.startsWith("GRADE_")) {
                    cleanGrade = "GRADE_" + cleanGrade;
                }
                learner.setGradeLevel(GradeLevel.valueOf(cleanGrade));
            } catch (Exception e) {
                // Ignore invalid grade level
            }
        }

        learner = learnerRepository.save(learner);

        return LearnerResponse.builder()
                .learnerId(learner.getLearnerId())
                .userId(learner.getUserId())
                .displayName(learner.getDisplayName())
                .age(learner.getAge())
                .avatar(learner.getAvatar())
                .languagePreference(learner.getLanguagePreference())
                .gradeLevel(learner.getGradeLevel())
                .onboardingComplete(learner.getOnboardingComplete())
                .masteryApplyImmediately(learner.getMasteryApplyImmediately())
                .posFocus(learner.getPosFocus())
                .build();
    }

    @Transactional
    public LearnerResponse updatePreferences(UUID learnerId, String displayName, String languagePreferenceStr,
            Boolean masteryApplyImmediately, String posFocus, String avatar) {
        return updatePreferences(learnerId, displayName, languagePreferenceStr, masteryApplyImmediately, posFocus,
                avatar, null, null);
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

        // Delete sandbox module scores first
        for (SandboxSession sSession : sSessions) {
            sandboxModuleScoreRepository.deleteBySessionSessionId(sSession.getSessionId());
        }

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

        // Delete cumulative review sessions and results
        List<CumulativeReviewSession> crSessions = cumulativeReviewSessionRepository
                .findByLearnerLearnerIdOrderByStartTimeDesc(learnerId);
        for (CumulativeReviewSession cr : crSessions) {
            cumulativeReviewResultRepository.deleteBySessionId(cr.getId());
        }
        cumulativeReviewResultRepository.deleteBySessionLearnerLearnerId(learnerId);
        cumulativeReviewSessionRepository.deleteByLearnerLearnerId(learnerId);

        summaryRepository.deleteByLearnerLearnerId(learnerId);
        performanceRepository.deleteByLearnerLearnerId(learnerId);
        difficultyProgressRepository.deleteByLearnerLearnerId(learnerId);
        pointTransactionRepository.deleteByLearnerLearnerId(learnerId);
        rewardDataRepository.deleteByLearnerLearnerId(learnerId);

        pronunciationAttemptRepository.deleteByLearnerLearnerId(learnerId);
        wordProgressRepository.deleteByLearnerLearnerId(learnerId);
        diagnosticResultRepository.deleteByLearnerLearnerId(learnerId);
        introductionSessionRepository.deleteByLearnerLearnerId(learnerId);
        lessonStatusRepository.deleteByLearnerLearnerId(learnerId);

        // Delete lesson module scores, lesson word accuracies, and adaptive queues
        lessonModuleScoreRepository.deleteByLearnerLearnerId(learnerId);
        lessonWordAccuracyRepository.deleteByLearnerLearnerId(learnerId);
        reinforcementQueueRepository.deleteByLearnerLearnerId(learnerId);
        wrongAnswerRecordRepository.deleteByLearnerLearnerId(learnerId);
        difficultyAuditLogRepository.deleteByLearnerLearnerId(learnerId);

        // Reset all class-scoped performance records
        List<ClassPerformance> classPerformances = classPerformanceRepository.findByLearnerLearnerId(learnerId);
        for (ClassPerformance cp : classPerformances) {
            cp.setClassPoints(0);
            cp.setClassTotalQuestions(0);
            cp.setClassCorrectAnswers(0);
            cp.setClassSessionsPlayed(0);
            cp.setClassAccuracy(java.math.BigDecimal.ZERO);
            cp.setClassMasteryLevel("LEARNING");
            cp.setUpdatedAt(java.time.OffsetDateTime.now());
            classPerformanceRepository.save(cp);
        }

        // Reset LearnerMastery record in-place (or create if none exists) to prevent
        // unique constraint violation
        java.util.Optional<LearnerMastery> existingMastery = masteryRepository.findByLearnerLearnerId(learnerId);
        if (existingMastery.isPresent()) {
            LearnerMastery mastery = existingMastery.get();
            mastery.setTotalSessionsPlayed(0);
            mastery.setTotalCorrectAnswers(0);
            mastery.setTotalQuestionsAnswered(0);
            mastery.setOverallAccuracy(java.math.BigDecimal.ZERO);
            mastery.setWordsMasteredCount(0);
            mastery.setTotalPoints(0);
            mastery.setMasteryLevel("LEARNING");
            mastery.setUpdatedAt(java.time.OffsetDateTime.now());
            masteryRepository.save(mastery);
        } else {
            Learner learner = learnerRepository.findById(learnerId).orElse(null);
            if (learner != null) {
                LearnerMastery freshMastery = LearnerMastery.builder()
                        .learner(learner)
                        .totalSessionsPlayed(0)
                        .totalCorrectAnswers(0)
                        .totalQuestionsAnswered(0)
                        .overallAccuracy(java.math.BigDecimal.ZERO)
                        .wordsMasteredCount(0)
                        .totalPoints(0)
                        .masteryLevel("LEARNING")
                        .createdAt(java.time.OffsetDateTime.now())
                        .build();
                masteryRepository.save(freshMastery);
            }
        }
    }
}
