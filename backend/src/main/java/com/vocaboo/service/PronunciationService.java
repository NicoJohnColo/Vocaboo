package com.vocaboo.service;

import com.vocaboo.dto.request.PronunciationEvaluationRequest;
import com.vocaboo.dto.response.PronunciationAttemptResponse;
import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.IOException;
import java.time.Duration;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.List;
import java.util.Base64;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class PronunciationService {

    private final PronunciationAttemptRepository attemptRepository;
    private final IntroductionSessionRepository sessionRepository;
    private final VocabularyWordRepository wordRepository;
    private final LearnerRepository learnerRepository;

    @Value("${huggingface.api.token:}")
    private String hfToken;

    @Value("${huggingface.api.url:https://api-inference.huggingface.co/models/openai/whisper-small}")
    private String hfApiUrl;

    private final ObjectMapper objectMapper = new ObjectMapper();

    private String transcribeAudioWithHuggingFace(byte[] audioBytes, String detectedContentType) {
        try {
            if (hfToken == null || hfToken.trim().isEmpty()) {
                System.err.println("Hugging Face API Token is not configured. Fallback to simulation.");
                return null;
            }

            HttpClient client = HttpClient.newBuilder()
                    .connectTimeout(Duration.ofSeconds(10))
                    .build();

            Set<String> contentTypes = new LinkedHashSet<>();
            if (detectedContentType != null && !detectedContentType.isBlank()) {
                contentTypes.add(detectedContentType);
            }
            contentTypes.add("audio/mp4");
            contentTypes.add("audio/m4a");
            contentTypes.add("audio/wav");
            contentTypes.add("application/octet-stream");

            for (String contentType : contentTypes) {
                URI requestUri = URI.create(hfApiUrl + (hfApiUrl.contains("?") ? "&" : "?") + "wait_for_model=true");

                HttpRequest request = HttpRequest.newBuilder()
                    .uri(requestUri)
                        .timeout(Duration.ofSeconds(30))
                        .header("Authorization", "Bearer " + hfToken)
                        .header("Content-Type", contentType)
                        .POST(HttpRequest.BodyPublishers.ofByteArray(audioBytes))
                        .build();

                HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
                int status = response.statusCode();
                String body = response.body();

                if (status == 200) {
                    String transcript = parseTranscript(body);
                    if (transcript != null && !transcript.isBlank()) {
                        return transcript;
                    }
                    System.err.println("Hugging Face response had no transcript. contentType=" + contentType + " body=" + body);
                } else {
                    System.err.println("Hugging Face API returned error status=" + status + " contentType=" + contentType + " body=" + body);
                }
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            System.err.println("Error calling Hugging Face API: InterruptedException: " + e.getMessage());
        } catch (IOException e) {
            System.err.println("Error calling Hugging Face API: IOException: " + e.getMessage());
        } catch (Exception e) {
            System.err.println("Error calling Hugging Face API: " + e.getClass().getSimpleName() + ": " + e.getMessage());
        }
        return null;
    }

    private String parseTranscript(String body) {
        try {
            if (body == null || body.isBlank()) {
                return null;
            }
            JsonNode root = objectMapper.readTree(body);
            if (root.hasNonNull("text")) {
                return root.get("text").asText();
            }
            if (root.isArray() && !root.isEmpty() && root.get(0).hasNonNull("text")) {
                return root.get(0).get("text").asText();
            }
            if (root.has("results") && root.get("results").isArray() && !root.get("results").isEmpty()) {
                JsonNode first = root.get("results").get(0);
                if (first.hasNonNull("text")) {
                    return first.get("text").asText();
                }
            }
        } catch (Exception ex) {
            System.err.println("Failed to parse Hugging Face response JSON: " + ex.getClass().getSimpleName() + ": " + ex.getMessage());
        }
        return null;
    }

    private String detectContentType(String audioBase64) {
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

    private String normalizeAudioBase64(String audioBase64) {
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

        // Hugging Face Speech-to-Text Integration
        boolean isCorrect = false;
        boolean isUsingHuggingFace = false;

        String transcript = transcribeAudioWithHuggingFace(decodedAudio, detectedContentType);
        if (transcript != null) {
            isUsingHuggingFace = true;
            
            if (!transcript.isEmpty()) {
                String cleanTarget = cleanWord(request.getTargetWord());
                String cleanTranscript = cleanWord(transcript);
                System.out.println("Hugging Face evaluation completed for target: '" + request.getTargetWord() + "' -> clean: '" + cleanTarget + "'");
                System.out.println("Target: '" + request.getTargetWord() + "' -> clean: '" + cleanTarget + "'");

                // Direct contains checks
                if (cleanTranscript.contains(cleanTarget) || cleanTarget.contains(cleanTranscript)) {
                    isCorrect = true;
                } else {
                    // Token-level checks: if any token in transcript is similar enough to target
                    String[] tokens = cleanTranscript.split("\\s+");
                    boolean tokenMatch = false;
                    for (String t : tokens) {
                        double sim = normalizedSimilarity(t, cleanTarget);
                        if (sim >= 0.75) {
                            tokenMatch = true;
                            System.out.println("Token similarity match: token='" + t + "' sim=" + sim);
                            break;
                        }
                    }
                    if (tokenMatch) {
                        isCorrect = true;
                    } else {
                        // Overall similarity (Levenshtein-based)
                        double sim = normalizedSimilarity(cleanTranscript, cleanTarget);
                        System.out.println("Overall similarity: " + sim);
                        if (sim >= 0.6) {
                            isCorrect = true;
                        } else {
                            isCorrect = false;
                        }
                    }
                }
                System.out.println("isCorrect decision: " + isCorrect);
            } else {
                isCorrect = false;
            }
        }

        // Fallback to strict error reporting if Hugging Face is not configured or failed
        if (!isUsingHuggingFace) {
            System.err.println("Evaluation failed: Hugging Face API was not used or failed.");
            return PronunciationAttemptResponse.builder()
                    .isCorrect(false)
                    .phoneticTarget(PHONETIC_MAP.getOrDefault(request.getTargetWord().toLowerCase(), ""))
                    .attemptNumber(request.getAttemptNumber())
                    .isInconclusive(true) // Marks the attempt as inconclusive rather than incorrect
                    .build();
        }

        String phoneticTarget = PHONETIC_MAP.getOrDefault(request.getTargetWord().toLowerCase(), "");
        String phonologicalTip = null;

        if (!isCorrect && word.getPhonologicalTipKey() != null) {
            Map<LanguageMedium, String> tipsByLang = TIPS_MAP.get(word.getPhonologicalTipKey());
            if (tipsByLang != null) {
                phonologicalTip = tipsByLang.getOrDefault(learner.getLanguagePreference(), tipsByLang.get(LanguageMedium.FULL_ENGLISH));
            }
        }

        // Save pronunciation attempt record
        PronunciationAttempt attempt = PronunciationAttempt.builder()
                .learner(learner)
                .session(session)
                .word(word)
                .lesson(session.getLesson())
                .moduleNumber(request.getModuleNumber())
                .transcribedText(null)
                .targetWord(request.getTargetWord())
                .isCorrect(isCorrect)
                .attemptNumber(request.getAttemptNumber())
                .isInconclusive(false)
                .build();

        // Adjust column mapping for standard targetWord if JPA generated it
        attempt.setTargetWord(request.getTargetWord());
        attemptRepository.save(attempt);

        return PronunciationAttemptResponse.builder()
                .attemptId(attempt.getAttemptId())
                .isCorrect(isCorrect)
                .transcribedText(null)
                .phoneticTarget(phoneticTarget)
                .phonologicalTip(phonologicalTip)
                .attemptNumber(request.getAttemptNumber())
                .isInconclusive(false)
                .build();
    }

    private String mutateWord(String word) {
        String lower = word.toLowerCase();
        if (lower.equals("father")) return "pader";
        if (lower.equals("brother")) return "brader";
        if (lower.equals("pencil")) return "pensil";
        if (lower.equals("mother")) return "mader";
        if (lower.equals("fish")) return "pish";
        if (lower.equals("church")) return "tsarts";
        if (lower.equals("water")) return "wader";
        if (lower.equals("apple")) return "apel";
        return lower + "h"; // default fallback mutation
    }

    private String cleanWord(String word) {
        if (word == null) return "";
        return word.toLowerCase()
                .replaceAll("[^a-zA-Z0-9\\s]", "")
                .trim();
    }

    private double normalizedSimilarity(String a, String b) {
        if (a == null || b == null) return 0.0;
        a = a.trim();
        b = b.trim();
        if (a.isEmpty() || b.isEmpty()) return 0.0;
        int longest = Math.max(a.length(), b.length());
        if (longest == 0) return 0.0;
        int distance = levenshteinDistance(a, b);
        return 1.0 - ((double) distance / (double) longest);
    }

    private int levenshteinDistance(String a, String b) {
        int la = a.length();
        int lb = b.length();
        int[][] dp = new int[la + 1][lb + 1];
        for (int i = 0; i <= la; i++) dp[i][0] = i;
        for (int j = 0; j <= lb; j++) dp[0][j] = j;
        for (int i = 1; i <= la; i++) {
            for (int j = 1; j <= lb; j++) {
                int cost = a.charAt(i - 1) == b.charAt(j - 1) ? 0 : 1;
                dp[i][j] = Math.min(Math.min(dp[i - 1][j] + 1, dp[i][j - 1] + 1), dp[i - 1][j - 1] + cost);
            }
        }
        return dp[la][lb];
    }
}
