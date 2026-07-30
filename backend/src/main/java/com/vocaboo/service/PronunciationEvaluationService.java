package com.vocaboo.service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class PronunciationEvaluationService {

    private final PhoneticComparisonService phoneticComparisonService;

    private static final double ACCEPTANCE_THRESHOLD = 0.80; // 80%
    private static final int MAX_ATTEMPT_LIMIT = 3;

    public static class EvaluationResult {
        private final boolean isCorrect;
        private final double similarityScore;

        public EvaluationResult(boolean isCorrect, double similarityScore) {
            this.isCorrect = isCorrect;
            this.similarityScore = similarityScore;
        }

        public boolean isCorrect() { return isCorrect; }
        public double getSimilarityScore() { return similarityScore; }
    }

    public EvaluationResult evaluatePronunciation(String targetWord, String transcript, int attemptNumber) {
        // Enforce attempt limit
        if (attemptNumber < 1 || attemptNumber > MAX_ATTEMPT_LIMIT) {
            throw new IllegalArgumentException("Attempt number must be between 1 and " + MAX_ATTEMPT_LIMIT);
        }

        if (targetWord == null || transcript == null) {
            return new EvaluationResult(false, 0.0);
        }

        String cleanTarget = cleanWord(targetWord);
        String cleanTranscript = cleanWord(transcript);

        if (cleanTarget.isEmpty() || cleanTranscript.isEmpty()) {
            return new EvaluationResult(false, 0.0);
        }

        // 1. Exact string match
        if (cleanTranscript.equals(cleanTarget)) {
            return new EvaluationResult(true, 1.0);
        }

        // 2. Phonetic exact match on full string
        String phoneTarget = phoneticComparisonService.normalizePhonetically(cleanTarget);
        String phoneTranscript = phoneticComparisonService.normalizePhonetically(cleanTranscript);

        if (phoneTranscript.equals(phoneTarget)) {
            return new EvaluationResult(true, 1.0);
        }

        // 3. Phonetic similarity match on full string
        double maxSimilarity = 0.0;
        double fullSim = normalizedSimilarity(phoneTranscript, phoneTarget);
        maxSimilarity = Math.max(maxSimilarity, fullSim);

        if (fullSim >= ACCEPTANCE_THRESHOLD) {
            System.out.println("[EVAL] Full phonetic similarity match: sim=" + fullSim + " for phoneTarget='" + phoneTarget + "', phoneTranscript='" + phoneTranscript + "'");
            return new EvaluationResult(true, fullSim);
        }

        // 4. Token comparison (no substring match - checks each token completely)
        String[] tokens = cleanTranscript.split("\\s+");
        for (String token : tokens) {
            if (token.equals(cleanTarget)) {
                return new EvaluationResult(true, 1.0);
            }
            String phoneToken = phoneticComparisonService.normalizePhonetically(token);
            if (phoneToken.equals(phoneTarget)) {
                return new EvaluationResult(true, 1.0);
            }
            double tokenSim = normalizedSimilarity(phoneToken, phoneTarget);
            maxSimilarity = Math.max(maxSimilarity, tokenSim);
            if (tokenSim >= ACCEPTANCE_THRESHOLD) {
                System.out.println("[EVAL] Token phonetic similarity match: token='" + token + "', sim=" + tokenSim + " for phoneTarget='" + phoneTarget + "', phoneToken='" + phoneToken + "'");
                return new EvaluationResult(true, tokenSim);
            }
        }

        return new EvaluationResult(false, maxSimilarity);
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
