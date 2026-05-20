package com.vocaboo.service;

import com.vocaboo.dto.request.PronunciationEvaluationRequest;
import com.vocaboo.dto.response.PronunciationAttemptResponse;
import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class PronunciationService {

    private final PronunciationAttemptRepository attemptRepository;
    private final IntroductionSessionRepository sessionRepository;
    private final VocabularyWordRepository wordRepository;
    private final LearnerRepository learnerRepository;

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
                    .transcribedText("")
                    .phoneticTarget(PHONETIC_MAP.getOrDefault(request.getTargetWord().toLowerCase(), ""))
                    .attemptNumber(request.getAttemptNumber())
                    .isInconclusive(true)
                    .build();
        }

        // Simulate STT decoding
        byte[] decodedAudio;
        try {
            decodedAudio = Base64.getDecoder().decode(request.getAudioBase64());
        } catch (Exception e) {
            return PronunciationAttemptResponse.builder()
                    .isCorrect(false)
                    .transcribedText("")
                    .phoneticTarget(PHONETIC_MAP.getOrDefault(request.getTargetWord().toLowerCase(), ""))
                    .attemptNumber(request.getAttemptNumber())
                    .isInconclusive(true)
                    .build();
        }

        // Simulating the evaluation logic:
        // First attempt has a 30% chance of failing to show the retry UI.
        // Subsequent attempts succeed if the audio was decoded successfully.
        boolean isCorrect = true;
        String transcribedText = request.getTargetWord();

        if (request.getAttemptNumber() == 1 && Math.random() < 0.3) {
            isCorrect = false;
            // Generate an incorrect transcribed text
            transcribedText = mutateWord(request.getTargetWord());
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
                .transcribedText(transcribedText)
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
                .transcribedText(transcribedText)
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
}
