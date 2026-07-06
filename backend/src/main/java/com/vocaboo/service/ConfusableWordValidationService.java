package com.vocaboo.service;

import com.vocaboo.entity.VocabularyWord;
import com.vocaboo.repository.ConfusableWordPairRepository;
import com.vocaboo.repository.VocabularyWordRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ConfusableWordValidationService {

    private final VocabularyWordRepository wordRepository;
    private final ConfusableWordPairRepository pairRepository;

    /**
     * Validate that both words exist in the lesson before creating a confusable pair.
     * Throws ResponseStatusException with a descriptive message if validation fails.
     */
    public void validateBothWordsExist(UUID wordAId, UUID wordBId, UUID lessonId) {
        VocabularyWord wordA = wordRepository.findById(wordAId)
                .filter(w -> !Boolean.TRUE.equals(w.getIsDeleted()))
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                        "Word A not found or has been deleted"));

        VocabularyWord wordB = wordRepository.findById(wordBId)
                .filter(w -> !Boolean.TRUE.equals(w.getIsDeleted()))
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                        "Word B not found or has been deleted"));

        if (!wordA.getLesson().getLessonId().equals(lessonId)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Word A '" + wordA.getEnglishWord() + "' does not belong to lesson " + lessonId
                    + ". Add it to this lesson first.");
        }
        if (!wordB.getLesson().getLessonId().equals(lessonId)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Word B '" + wordB.getEnglishWord() + "' does not belong to lesson " + lessonId
                    + ". Add it to this lesson first.");
        }
        if (wordAId.equals(wordBId)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Word A and Word B cannot be the same word");
        }

        // Check for duplicate pair (order-independent)
        boolean pairExists = pairRepository.existsByLessonAndWords(lessonId, wordAId, wordBId);
        if (pairExists) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "A confusable pair between '" + wordA.getEnglishWord() + "' and '"
                    + wordB.getEnglishWord() + "' already exists in this lesson");
        }
    }

    /**
     * Get all active words in a lesson for the confusable pair selector dropdown.
     */
    public List<Map<String, Object>> getWordsForPairSelector(UUID lessonId) {
        return wordRepository.findByLessonLessonIdAndIsDeletedFalseOrderByWordOrderAsc(lessonId)
                .stream()
                .map(w -> Map.<String, Object>of(
                        "word_id", w.getWordId(),
                        "english_word", w.getEnglishWord(),
                        "cebuano_meaning", w.getCebuanoMeaning(),
                        "word_order", w.getWordOrder(),
                        "is_confusable_pair_member", Boolean.TRUE.equals(w.getIsConfusablePairMember())
                ))
                .collect(Collectors.toList());
    }

    /**
     * Analyze lesson vocabulary and suggest commonly confused word pairs.
     * Uses heuristics: similar length, same POS, shared prefix, or similar vowel pattern.
     * Already-paired words are excluded from suggestions.
     */
    public List<Map<String, Object>> suggestConfusablePairs(UUID lessonId) {
        List<VocabularyWord> words = wordRepository
                .findByLessonLessonIdAndIsDeletedFalseOrderByWordOrderAsc(lessonId);

        if (words.size() < 2) {
            return Collections.emptyList();
        }

        // Collect all already-existing pair word ID combos
        Set<String> existingPairs = pairRepository.findByLessonLessonId(lessonId)
                .stream()
                .map(p -> normalizedPairKey(p.getWordA().getWordId(), p.getWordB().getWordId()))
                .collect(Collectors.toSet());

        List<Map<String, Object>> suggestions = new ArrayList<>();

        for (int i = 0; i < words.size(); i++) {
            for (int j = i + 1; j < words.size(); j++) {
                VocabularyWord a = words.get(i);
                VocabularyWord b = words.get(j);

                String pairKey = normalizedPairKey(a.getWordId(), b.getWordId());
                if (existingPairs.contains(pairKey)) {
                    continue; // already paired, skip
                }

                String reason = detectConfusabilityReason(a, b);
                if (reason != null) {
                    Map<String, Object> suggestion = new LinkedHashMap<>();
                    suggestion.put("word_a", Map.of(
                            "word_id", a.getWordId(),
                            "english_word", a.getEnglishWord(),
                            "cebuano_meaning", a.getCebuanoMeaning()
                    ));
                    suggestion.put("word_b", Map.of(
                            "word_id", b.getWordId(),
                            "english_word", b.getEnglishWord(),
                            "cebuano_meaning", b.getCebuanoMeaning()
                    ));
                    suggestion.put("reason", reason);
                    suggestions.add(suggestion);

                    if (suggestions.size() >= 10) {
                        return suggestions; // cap at 10 suggestions
                    }
                }
            }
        }

        return suggestions;
    }

    // ─── Private helpers ──────────────────────────────────────────────────────

    private String normalizedPairKey(UUID idA, UUID idB) {
        // Consistent order-independent key so (A,B) == (B,A)
        if (idA.compareTo(idB) < 0) {
            return idA + ":" + idB;
        }
        return idB + ":" + idA;
    }

    private String detectConfusabilityReason(VocabularyWord a, VocabularyWord b) {
        String wa = a.getEnglishWord().toLowerCase(Locale.ROOT);
        String wb = b.getEnglishWord().toLowerCase(Locale.ROOT);

        // Same POS + similar length (within 2 chars)
        boolean samePOS = a.getPartOfSpeech() != null
                && a.getPartOfSpeech().equals(b.getPartOfSpeech());
        boolean similarLength = Math.abs(wa.length() - wb.length()) <= 2;

        // Shared prefix (first 2 chars)
        boolean sharedPrefix = wa.length() >= 2 && wb.length() >= 2
                && wa.substring(0, 2).equals(wb.substring(0, 2));

        // Shared suffix (last 2 chars)
        boolean sharedSuffix = wa.length() >= 2 && wb.length() >= 2
                && wa.substring(wa.length() - 2).equals(wb.substring(wb.length() - 2));

        // Anagram-like: same sorted characters
        boolean anagram = wa.length() == wb.length()
                && sortedChars(wa).equals(sortedChars(wb));

        // Minimal edit distance (Levenshtein ≤ 2 for words shorter than 8 chars)
        boolean closeSpelling = wa.length() <= 8 && wb.length() <= 8
                && levenshtein(wa, wb) <= 2 && !wa.equals(wb);

        if (closeSpelling)   return "Very similar spelling";
        if (anagram)         return "Same letters, different order (anagram)";
        if (sharedPrefix && samePOS) return "Same start, same part of speech";
        if (sharedSuffix && samePOS) return "Same ending, same part of speech";
        if (samePOS && similarLength) return "Same part of speech, similar length";
        if (sharedPrefix && similarLength) return "Similar spelling (shared prefix)";
        if (sharedSuffix)    return "Same word ending";

        return null; // not confusable enough
    }

    private String sortedChars(String s) {
        char[] chars = s.toCharArray();
        Arrays.sort(chars);
        return new String(chars);
    }

    private int levenshtein(String a, String b) {
        int m = a.length(), n = b.length();
        int[][] dp = new int[m + 1][n + 1];
        for (int i = 0; i <= m; i++) dp[i][0] = i;
        for (int j = 0; j <= n; j++) dp[0][j] = j;
        for (int i = 1; i <= m; i++) {
            for (int j = 1; j <= n; j++) {
                if (a.charAt(i - 1) == b.charAt(j - 1)) {
                    dp[i][j] = dp[i - 1][j - 1];
                } else {
                    dp[i][j] = 1 + Math.min(dp[i - 1][j - 1],
                            Math.min(dp[i - 1][j], dp[i][j - 1]));
                }
            }
        }
        return dp[m][n];
    }
}
