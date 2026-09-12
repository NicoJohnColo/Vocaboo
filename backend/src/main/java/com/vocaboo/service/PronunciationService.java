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
        PHONETIC_MAP.put("spoon", "/spuːn/");
        PHONETIC_MAP.put("fork", "/fɔːrk/");
        PHONETIC_MAP.put("knife", "/naɪf/");
        PHONETIC_MAP.put("plate", "/pleɪt/");
        PHONETIC_MAP.put("cup", "/kʌp/");
        PHONETIC_MAP.put("stove", "/stoʊv/");
        PHONETIC_MAP.put("pot", "/pɒt/");
        PHONETIC_MAP.put("pan", "/pæn/");
        PHONETIC_MAP.put("refrigerator", "/rɪˈfrɪdʒ.ə.reɪ.tər/");
        PHONETIC_MAP.put("head", "/hɛd/");
        PHONETIC_MAP.put("mouth", "/maʊθ/");
        PHONETIC_MAP.put("teeth", "/tiːθ/");
        PHONETIC_MAP.put("tooth", "/tuːθ/");
        PHONETIC_MAP.put("throat", "/θroʊt/");
        PHONETIC_MAP.put("vegetable", "/ˈvɛdʒ.tə.bəl/");
        PHONETIC_MAP.put("vegetables", "/ˈvɛdʒ.tə.bəlz/");
    }

    private static final Map<String, Map<LanguageMedium, String>> TIPS_MAP = new HashMap<>();
    static {
        // v_sound tips
        Map<LanguageMedium, String> vSound = new HashMap<>();
        vSound.put(LanguageMedium.CEBUANO_TO_ENGLISH, "Tip: Ang /v/ sound — i-touch ang ibabaw nga ngipon sa ubos nga ngabil ug pag-hum aron mag-vibrate. Ehemplo: 'stove' (dili 'stob'), 'vegetable'.");
        vSound.put(LanguageMedium.FULL_ENGLISH, "Tip: For the /v/ sound, touch your upper teeth to your lower lip and push air out while vibrating your voice.");
        vSound.put(LanguageMedium.CEBUANO_ENGLISH_MIXED, "Tip (V): Ang /v/ sound kay wala sa Cebuano (often masaypan og /b/). I-touch lang imong upper teeth sa lower lip unya i-vibrate imong voice. Like 'stove' dili 'stob'.");
        TIPS_MAP.put("v_sound", vSound);

        // f_sound tips
        Map<LanguageMedium, String> fSound = new HashMap<>();
        fSound.put(LanguageMedium.CEBUANO_TO_ENGLISH, "Tip: Ang /f/ sound — i-touch ang imong ngipon sa ubos nga ngabil ug hanginon nga walay tingog. Dili sama sa P. Ehemplo: 'fork' (dili 'pork'), 'knife'.");
        fSound.put(LanguageMedium.FULL_ENGLISH, "Tip: For the /f/ sound, bite your lower lip gently and push air out without vocal vibration. It is different from P.");
        fSound.put(LanguageMedium.CEBUANO_ENGLISH_MIXED, "Tip (F): Ang /f/ sound kay dili /p/. I-rest lang imong upper teeth sa lower lip unya blow og air without voice. Example: 'fork' dili 'pork'.");
        TIPS_MAP.put("f_sound", fSound);

        // th_sound tips
        Map<LanguageMedium, String> thSound = new HashMap<>();
        thSound.put(LanguageMedium.CEBUANO_TO_ENGLISH, "Tip: Ang /θ/ (TH) sound — ibutang ang imong dila tali sa imong mga ngipon ug hanginon. Dili sama sa /t/. Ehemplo: 'teeth', 'mouth', 'think'.");
        thSound.put(LanguageMedium.FULL_ENGLISH, "Tip: For the /θ/ (TH) sound, place the tip of your tongue between your teeth and push air out smoothly.");
        thSound.put(LanguageMedium.CEBUANO_ENGLISH_MIXED, "Tip (TH): Ang /θ/ sound kay dili /t/. Ibutang gamay ang tip sa imong tongue between sa upper ug lower teeth unya blow og air smoothly. Example: 'teeth' dili 'tit'.");
        TIPS_MAP.put("th_sound", thSound);
    }

    private String inferTipKey(String targetWord) {
        if (targetWord == null) return null;
        String lower = targetWord.toLowerCase().trim();
        if (lower.contains("th")) return "th_sound";
        if (lower.contains("v")) return "v_sound";
        if (lower.contains("f") || lower.contains("ph")) return "f_sound";
        if (lower.contains("sh")) return "sh_sound";
        if (lower.contains("ch")) return "ch_sound";
        return null;
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
                    .phoneticTarget(PHONETIC_MAP.getOrDefault(request.getTargetWord().toLowerCase(), "/" + request.getTargetWord().toLowerCase() + "/"))
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
                    .phoneticTarget(PHONETIC_MAP.getOrDefault(request.getTargetWord().toLowerCase(), "/" + request.getTargetWord().toLowerCase() + "/"))
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

        String phoneticTarget = PHONETIC_MAP.getOrDefault(request.getTargetWord().toLowerCase(), "/" + request.getTargetWord().toLowerCase() + "/");
        String phonologicalTip = null;

        String tipKey = word.getPhonologicalTipKey();
        if (tipKey == null || tipKey.trim().isEmpty()) {
            tipKey = inferTipKey(request.getTargetWord());
        }

        if (!isCorrect && tipKey != null) {
            // First check the dynamic tip service
            if (phoneticFeedbackService != null) {
                phonologicalTip = phoneticFeedbackService.getTip(tipKey, learner.getLanguagePreference());
            }
            // Fall back to static map if tip is not found in DB
            if (phonologicalTip == null) {
                Map<LanguageMedium, String> tipsByLang = TIPS_MAP.get(tipKey);
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
        int pointsEarned = (request.getModuleNumber() != null && request.getModuleNumber() == 1)
                ? 0
                : (isCorrect ? 15 : 0);

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
                .pointsEarned(pointsEarned)
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
