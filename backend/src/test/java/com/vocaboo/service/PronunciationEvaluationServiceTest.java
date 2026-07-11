package com.vocaboo.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class PronunciationEvaluationServiceTest {

    private PronunciationEvaluationService evaluationService;

    @BeforeEach
    void setUp() {
        PhoneticComparisonService phoneticService = new PhoneticComparisonService();
        evaluationService = new PronunciationEvaluationService(phoneticService);
    }

    @Test
    void testDirectMatching() {
        assertTrue(evaluationService.evaluatePronunciation("very", "very", 1).isCorrect());
        assertTrue(evaluationService.evaluatePronunciation("pencil", "pencil", 1).isCorrect());
    }

    @Test
    void testCebuanoAccentVariations() {
        // fish -> pish
        assertTrue(evaluationService.evaluatePronunciation("fish", "pish", 1).isCorrect());
        // father -> pader / pater
        assertTrue(evaluationService.evaluatePronunciation("father", "pader", 1).isCorrect());
        // very -> bery
        assertTrue(evaluationService.evaluatePronunciation("very", "bery", 1).isCorrect());
        // brother -> brader
        assertTrue(evaluationService.evaluatePronunciation("brother", "brader", 1).isCorrect());
        // mother -> mader
        assertTrue(evaluationService.evaluatePronunciation("mother", "mader", 1).isCorrect());
        // pencil -> pensil
        assertTrue(evaluationService.evaluatePronunciation("pencil", "pensil", 1).isCorrect());
        // church -> tsarts
        assertTrue(evaluationService.evaluatePronunciation("church", "tsarts", 1).isCorrect());
        // water -> wader
        assertTrue(evaluationService.evaluatePronunciation("water", "wader", 1).isCorrect());
    }

    @Test
    void testSubstringBugsAreFixed() {
        // "pencil" must not match target "pen"
        assertFalse(evaluationService.evaluatePronunciation("pen", "pencil", 1).isCorrect());
        // "pen" must not match target "pencil"
        assertFalse(evaluationService.evaluatePronunciation("pencil", "pen", 1).isCorrect());
    }

    @Test
    void testTokenAndMultiwordMatching() {
        // Target in multi-word sentence
        assertTrue(evaluationService.evaluatePronunciation("pencil", "a pencil", 1).isCorrect());
        assertTrue(evaluationService.evaluatePronunciation("pencil", "this is a pensil", 1).isCorrect());
        assertTrue(evaluationService.evaluatePronunciation("fish", "i want a pish", 1).isCorrect());
    }

    @Test
    void testAttemptLimits() {
        // 1 to 3 should succeed
        assertTrue(evaluationService.evaluatePronunciation("very", "very", 1).isCorrect());
        assertTrue(evaluationService.evaluatePronunciation("very", "very", 3).isCorrect());

        // 0 or >3 should fail with IllegalArgumentException
        assertThrows(IllegalArgumentException.class, () -> 
            evaluationService.evaluatePronunciation("very", "very", 0)
        );
        assertThrows(IllegalArgumentException.class, () -> 
            evaluationService.evaluatePronunciation("very", "very", 4)
        );
    }

    @Test
    void testEvaluationResultSimilarityScores() {
        // Exact matches must return 1.0 similarity score
        assertEquals(1.0, evaluationService.evaluatePronunciation("very", "very", 1).getSimilarityScore());
        
        // Exact phonetic matches on targets must return 1.0 similarity score
        assertEquals(1.0, evaluationService.evaluatePronunciation("fish", "phish", 1).getSimilarityScore());

        // Accent similarity variations should return scores matching normalized similarity
        // pensil (phone token) vs pincil (phone target) -> edit distance 1 over length 6 = 5/6 = 0.8333...
        double pensilSim = evaluationService.evaluatePronunciation("pencil", "pensil", 1).getSimilarityScore();
        assertTrue(pensilSim >= 0.80 && pensilSim < 1.0);

        // Incorrect matches should return the calculated maximum similarity score
        double penPencilSim = evaluationService.evaluatePronunciation("pen", "pencil", 1).getSimilarityScore();
        assertTrue(penPencilSim < 0.80);
    }
}
