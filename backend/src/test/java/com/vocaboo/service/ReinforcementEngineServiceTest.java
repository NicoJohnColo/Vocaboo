package com.vocaboo.service;

import com.vocaboo.entity.PracticeResult;
import com.vocaboo.repository.LearnerRepository;
import com.vocaboo.repository.PracticeResultRepository;
import com.vocaboo.repository.ReinforcementQueueRepository;
import com.vocaboo.repository.VocabularyWordRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Collections;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ReinforcementEngineServiceTest {

    @Mock
    private ReinforcementQueueRepository queueRepository;
    @Mock
    private LearnerRepository learnerRepository;
    @Mock
    private VocabularyWordRepository wordRepository;
    @Mock
    private PracticeResultRepository practiceResultRepository;

    @InjectMocks
    private ReinforcementEngineService reinforcementEngine;

    private UUID learnerId;
    private UUID wordId;

    @BeforeEach
    void setUp() {
        learnerId = UUID.randomUUID();
        wordId = UUID.randomUUID();
    }

    @Test
    @DisplayName("isWordWeak returns true when recent accuracy is below 70% (2 correct out of 5 = 40%)")
    void testIsWordWeak_Below70Percent() {
        List<PracticeResult> mockAttempts = List.of(
                PracticeResult.builder().isCorrect(true).build(),
                PracticeResult.builder().isCorrect(false).build(),
                PracticeResult.builder().isCorrect(false).build(),
                PracticeResult.builder().isCorrect(true).build(),
                PracticeResult.builder().isCorrect(false).build()
        );
        when(practiceResultRepository.findTop5BySessionLearnerLearnerIdAndWordWordIdOrderByRecordedAtDesc(eq(learnerId), eq(wordId)))
                .thenReturn(mockAttempts);

        boolean isWeak = reinforcementEngine.isWordWeak(learnerId, wordId);

        assertTrue(isWeak, "Word with 2/5 (40%) accuracy should be flagged as weak (< 70%)");
    }

    @Test
    @DisplayName("isWordWeak returns false when recent accuracy is 70% or higher (4 correct out of 5 = 80%)")
    void testIsWordWeak_70PercentOrHigher() {
        List<PracticeResult> mockAttempts = List.of(
                PracticeResult.builder().isCorrect(true).build(),
                PracticeResult.builder().isCorrect(true).build(),
                PracticeResult.builder().isCorrect(true).build(),
                PracticeResult.builder().isCorrect(true).build(),
                PracticeResult.builder().isCorrect(false).build()
        );
        when(practiceResultRepository.findTop5BySessionLearnerLearnerIdAndWordWordIdOrderByRecordedAtDesc(eq(learnerId), eq(wordId)))
                .thenReturn(mockAttempts);

        boolean isWeak = reinforcementEngine.isWordWeak(learnerId, wordId);

        assertFalse(isWeak, "Word with 4/5 (80%) accuracy should NOT be flagged as weak (>= 70%)");
    }

    @Test
    @DisplayName("isWordWeak considers only top 5 recent attempts (poor start, strong recent streak = NOT weak)")
    void testIsWordWeak_StrongRecentStreakOvercomesPoorStart() {
        List<PracticeResult> recentAttempts = List.of(
                PracticeResult.builder().isCorrect(true).build(),
                PracticeResult.builder().isCorrect(true).build(),
                PracticeResult.builder().isCorrect(true).build(),
                PracticeResult.builder().isCorrect(true).build(),
                PracticeResult.builder().isCorrect(true).build()
        );
        when(practiceResultRepository.findTop5BySessionLearnerLearnerIdAndWordWordIdOrderByRecordedAtDesc(eq(learnerId), eq(wordId)))
                .thenReturn(recentAttempts);

        boolean isWeak = reinforcementEngine.isWordWeak(learnerId, wordId);

        assertFalse(isWeak, "Word with 5/5 recent correct attempts should NOT be flagged as weak regardless of lifetime history");
    }

    @Test
    @DisplayName("isWordWeak returns false when no attempt history exists")
    void testIsWordWeak_NoAttempts() {
        when(practiceResultRepository.findTop5BySessionLearnerLearnerIdAndWordWordIdOrderByRecordedAtDesc(eq(learnerId), eq(wordId)))
                .thenReturn(Collections.emptyList());

        boolean isWeak = reinforcementEngine.isWordWeak(learnerId, wordId);

        assertFalse(isWeak, "Word with zero attempts should return false (not weak)");
    }

    @Test
    @DisplayName("isWordWeak returns true when fewer than 5 attempts exist and accuracy < 70% (2 correct out of 3 = 66.7%)")
    void testIsWordWeak_PartialHistoryBelow70() {
        List<PracticeResult> mockAttempts = List.of(
                PracticeResult.builder().isCorrect(true).build(),
                PracticeResult.builder().isCorrect(false).build(),
                PracticeResult.builder().isCorrect(true).build()
        );
        when(practiceResultRepository.findTop5BySessionLearnerLearnerIdAndWordWordIdOrderByRecordedAtDesc(eq(learnerId), eq(wordId)))
                .thenReturn(mockAttempts);

        boolean isWeak = reinforcementEngine.isWordWeak(learnerId, wordId);

        assertTrue(isWeak, "Word with 2/3 (66.7%) accuracy should be flagged as weak (< 70%)");
    }
}
