package com.vocaboo.service;

import com.vocaboo.dto.request.PronunciationEvaluationRequest;
import com.vocaboo.dto.response.PronunciationAttemptResponse;
import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Base64;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class PronunciationService {

    private static final Logger log = LoggerFactory.getLogger(PronunciationService.class);

    private final PronunciationAttemptRepository attemptRepository;
    private final IntroductionSessionRepository sessionRepository;
    private final VocabularyWordRepository wordRepository;
    private final LearnerRepository learnerRepository;

    private final DeepgramSpeechService deepgramSpeechService;
    private final PronunciationEvaluationService pronunciationEvaluationService;
    private final PhoneticFeedbackService phoneticFeedbackService;

    String detectContentType(String audioBase64) {
        if (audioBase64 == null) {
            return null;
        }
        String normalized = audioBase64.trim();
        if (!normalized.startsWith("data:")) {
            return null;
        }
        int semicolonIndex = normalized.indexOf(';');
        if (semicolonIndex <= 5) {
            return null;
        }
        return normalized.substring(5, semicolonIndex);
    }

    String normalizeAudioBase64(String audioBase64) {
        if (audioBase64 == null) {
            return null;
        }
        String normalized = audioBase64.trim();
        int commaIndex = normalized.indexOf(',');
        if (normalized.startsWith("data:") && commaIndex > -1) {
            return normalized.substring(commaIndex + 1).trim();
        }
        return normalized;
    }

    private static final Map<String, String> PHONETIC_MAP = new HashMap<>();
    static {
        PHONETIC_MAP.put("pencil", "/ˈpɛn.səl/");
        PHONETIC_MAP.put("notebook", "/ˈnoʊt.bʊk/");
        PHONETIC_MAP.put("eraser", "/ɪˈreɪ.sər/");
        PHONETIC_MAP.put("bag", "/bæɡ/");
        PHONETIC_MAP.put("ruler", "/ˈruː.lər/");
        PHONETIC_MAP.put("mother", "/ˈmʌð.ər/");
        PHONETIC_MAP.put("father", "/ˈfɑː.ðər/");
        PHONETIC_MAP.put("sister", "/ˈsɪs.tər/");
        PHONETIC_MAP.put("brother", "/ˈbrʌð.ər/");
        PHONETIC_MAP.put("grandmother", "/ˈɡrændˌmʌð.ər/");
        PHONETIC_MAP.put("dog", "/dɔːɡ/");
        PHONETIC_MAP.put("cat", "/kæt/");
        PHONETIC_MAP.put("bird", "/bɜːrd/");
        PHONETIC_MAP.put("fish", "/fɪʃ/");
        PHONETIC_MAP.put("horse", "/hɔːrs/");
        PHONETIC_MAP.put("rice", "/raɪs/");
        PHONETIC_MAP.put("water", "/ˈwɔː.tər/");
        PHONETIC_MAP.put("bread", "/brɛd/");
        PHONETIC_MAP.put("milk", "/mɪlk/");
        PHONETIC_MAP.put("apple", "/ˈæp.əl/");
        PHONETIC_MAP.put("school", "/skuːl/");
        PHONETIC_MAP.put("hospital", "/ˈhɒs.pɪ.təl/");
        PHONETIC_MAP.put("market", "/ˈmɑːr.kɪt/");
        PHONETIC_MAP.put("church", "/tʃɜːrtʃ/");
        PHONETIC_MAP.put("park", "/pɑːrk/");
    }

    private static final Map<String, Map<LanguageMedium, String>> TIPS_MAP = new HashMap<>();
    static {
        // v_sound tips
        Map<LanguageMedium, String> vSound = new HashMap<>();
        vSound.put(LanguageMedium.CEBUANO_TO_ENGLISH, "Tip: The letter V makes a sound by touching your top teeth to your lower lip. Example: 'very' sounds like 'bery' but with teeth touching lip.");
        vSound.put(LanguageMedium.FULL_ENGLISH, "Tip: For the V sound, touch your upper teeth to your lower lip and push air out.");
        vSound.put(LanguageMedium.CEBUANO_ENGLISH_MIXED, "Tip (V): I-touch ang imong ngipon sa ubos nga ngabil. Example: 'very' dili 'bery'.");
        TIPS_MAP.put("v_sound", vSound);

        // f_sound tips
        Map<LanguageMedium, String> fSound = new HashMap<>();
        fSound.put(LanguageMedium.CEBUANO_TO_ENGLISH, "Tip: Ang F sound — i-touch ang imong ngipon sa ubos nga ngabil ug hanginon. Dili sama sa P.");
        fSound.put(LanguageMedium.FULL_ENGLISH, "Tip: For the F sound, bite your lower lip gently and push air out. It is different from P.");
        fSound.put(LanguageMedium.CEBUANO_ENGLISH_MIXED, "Tip (F): Touch upper teeth to lower lip — mas lain kay sa P.");
        TIPS_MAP.put("f_sound", fSound);

        // th_sound tips
        Map<LanguageMedium, String> thSound = new HashMap<>();
        thSound.put(LanguageMedium.CEBUANO_TO_ENGLISH, "Tip: Ang TH sound — ibutang ang imong dila tali sa imong mga ngipon ug hanginon. Example: 'the' dili 'da'.");
        thSound.put(LanguageMedium.FULL_ENGLISH, "Tip: For the TH sound, place your tongue between your teeth and push air out.");
        thSound.put(LanguageMedium.CEBUANO_ENGLISH_MIXED, "Tip (TH): Ibutang ang dila tali sa mga ngipon. 'The' dili 'da'.");
        TIPS_MAP.put("th_sound", thSound);
    }

    @Transactional
    public PronunciationAttemptResponse evaluate(UUID learnerId, PronunciationEvaluationRequest request) {
        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner not found"));
        IntroductionSession session = sessionRepository.findById(request.getSessionId())
                .orElseThrow(() -> new IllegalArgumentException("Session not found"));
        VocabularyWord word = wordRepository.findById(request.getWordId())
                .orElseThrow(() -> new IllegalArgumentException("Word not found"));

        // Validate audio base64 is not empty
        if (request.getAudioBase64() == null || request.getAudioBase64().trim().isEmpty()) {
            return PronunciationAttemptResponse.builder()
                    .isCorrect(false)
                    .phoneticTarget(PHONETIC_MAP.getOrDefault(request.getTargetWord().toLowerCase(), ""))
                    .attemptNumber(request.getAttemptNumber())
                    .isInconclusive(true)
                    .build();
        }

        // Simulate STT decoding
        String detectedContentType = detectContentType(request.getAudioBase64());
        String normalizedAudioBase64 = normalizeAudioBase64(request.getAudioBase64());

        byte[] decodedAudio;
        try {
            decodedAudio = Base64.getDecoder().decode(normalizedAudioBase64);
        } catch (Exception e) {
            return PronunciationAttemptResponse.builder()
                    .isCorrect(false)
                    .phoneticTarget(PHONETIC_MAP.getOrDefault(request.getTargetWord().toLowerCase(), ""))
                    .attemptNumber(request.getAttemptNumber())
                    .isInconclusive(true)
                    .build();
        }

        // Deepgram Speech-to-Text Integration
        boolean isCorrect = false;
        double similarityScore = 0.0;
        String transcript = null;
        Double confidence = null;
        String apiError = null;
        boolean isInconclusive = false;
        long startTime = System.currentTimeMillis();

        try {
            DeepgramSpeechService.DeepgramResult deepgramResult = deepgramSpeechService.uploadAudioToDeepgram(decodedAudio, detectedContentType);
            if (deepgramResult != null) {
                transcript = deepgramResult.getTranscript();
                confidence = deepgramResult.getConfidence();

                PronunciationEvaluationService.EvaluationResult evalResult = pronunciationEvaluationService.evaluatePronunciation(
                        request.getTargetWord(), transcript, request.getAttemptNumber());
                isCorrect = evalResult.isCorrect();
                similarityScore = evalResult.getSimilarityScore();
                System.out.println("Deepgram evaluation completed for target: '" + request.getTargetWord() + "' -> clean transcript: '" + transcript + "', isCorrect=" + isCorrect);
            } else {
                isInconclusive = true;
            }
        } catch (Exception e) {
            apiError = e.getClass().getSimpleName() + ": " + e.getMessage();
            isInconclusive = true;
            log.warn("Deepgram Speech-to-Text ASR failed gracefully: {}", apiError);
        } finally {
            long responseTimeMs = System.currentTimeMillis() - startTime;
            logAttempt(learner.getLearnerId(), request.getTargetWord(), transcript, confidence, similarityScore, isCorrect, responseTimeMs, apiError);
        }

        String phoneticTarget = PHONETIC_MAP.getOrDefault(request.getTargetWord().toLowerCase(), "");
        String phonologicalTip = null;

        if (!isCorrect && word.getPhonologicalTipKey() != null) {
            // First check the dynamic tip service
            if (phoneticFeedbackService != null) {
                phonologicalTip = phoneticFeedbackService.getTip(word.getPhonologicalTipKey(), learner.getLanguagePreference());
            }
            // Fall back to static map if tip is not found in DB
            if (phonologicalTip == null) {
                Map<LanguageMedium, String> tipsByLang = TIPS_MAP.get(word.getPhonologicalTipKey());
                if (tipsByLang != null) {
                    phonologicalTip = tipsByLang.getOrDefault(learner.getLanguagePreference(), tipsByLang.get(LanguageMedium.FULL_ENGLISH));
                }
            }
        }

        // Save pronunciation attempt record
        PronunciationAttempt attempt = PronunciationAttempt.builder()
                .learner(learner)
                .session(session)
                .word(word)
                .lesson(session.getLesson())
                .moduleNumber(request.getModuleNumber())
                .transcribedText(transcript)
                .targetWord(request.getTargetWord())
                .isCorrect(isCorrect)
                .attemptNumber(request.getAttemptNumber())
                .isInconclusive(isInconclusive)
                .build();

        // Adjust column mapping for standard targetWord if JPA generated it
        attempt.setTargetWord(request.getTargetWord());
        attemptRepository.save(attempt);

        boolean manualTeacherFallback = !isCorrect && (request.getAttemptNumber() >= 3);

        return PronunciationAttemptResponse.builder()
                .attemptId(attempt.getAttemptId())
                .isCorrect(isCorrect)
                .transcribedText(transcript)
                .phoneticTarget(phoneticTarget)
                .phonologicalTip(phonologicalTip)
                .attemptNumber(request.getAttemptNumber())
                .isInconclusive(isInconclusive)
                .similarityScore(similarityScore)
                .manualTeacherFallback(manualTeacherFallback)
                .build();
    }

    private void logAttempt(UUID learnerId, String targetWord, String transcript, Double confidence, double similarityScore, boolean isCorrect, long responseTimeMs, String apiError) {
        String timestamp = java.time.Instant.now().toString();
        String safeTranscript = transcript != null ? transcript.replace("\"", "\\\"") : "";
        String safeApiError = apiError != null ? apiError.replace("\"", "\\\"").replace("\n", " ").replace("\r", " ") : "";

        log.info("[DIAGNOSTIC] {\"timestamp\":\"{}\", \"learnerId\":\"{}\", \"targetWord\":\"{}\", \"transcript\":\"{}\", \"confidenceScore\":{}, \"similarityScore\":{}, \"pronunciationResult\":{}, \"responseTimeMs\":{}, \"apiError\":\"{}\"}",
                timestamp,
                learnerId != null ? learnerId.toString() : "",
                targetWord != null ? targetWord.replace("\"", "\\\"") : "",
                safeTranscript,
                confidence != null ? String.format(java.util.Locale.US, "%.4f", confidence) : "null",
                String.format(java.util.Locale.US, "%.4f", similarityScore),
                isCorrect,
                responseTimeMs,
                safeApiError
        );
    }


}
