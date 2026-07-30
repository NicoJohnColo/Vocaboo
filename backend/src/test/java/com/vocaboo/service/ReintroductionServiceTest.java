package com.vocaboo.service;

import com.vocaboo.dto.response.DifficultyProgressResponse;
import com.vocaboo.dto.response.ReintroductionResponse;
import com.vocaboo.entity.VocabularyWord;
import com.vocaboo.repository.VocabularyWordRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ReintroductionServiceTest {

    @Mock
    private VocabularyWordRepository wordRepository;

    @Mock
    private DifficultyAdjustmentService difficultyAdjustmentService;

    @InjectMocks
    private ReintroductionService service;

    @Test
    void buildPayload_returnsHighlightedSentenceAndPayload() {
        UUID learnerId = UUID.randomUUID();
        UUID wordId = UUID.randomUUID();

        VocabularyWord word = VocabularyWord.builder()
                .wordId(wordId)
                .englishWord("apple")
                .cebuanoMeaning("mansanas")
                .exampleSentenceEnglish("I eat an apple every day.")
                .exampleSentenceCebuano("Mokaon ko og mansanas kada adlaw.")
                .audioAssetPath("audio/apple.mp3")
                .build();

        when(wordRepository.findById(wordId)).thenReturn(Optional.of(word));

        ReintroductionResponse response = service.buildPayload(learnerId, wordId);

        assertNotNull(response);
        assertEquals(wordId, response.getWordId());
        assertEquals("apple", response.getEnglishWord());
        assertEquals("mansanas", response.getCebuanoMeaning());
        assertEquals("I eat an <b>apple</b> every day.", response.getHighlightedSentenceEnglish());
        assertEquals(70.0, response.getPronunciationThreshold());
    }

    @Test
    void acknowledgeUnderstanding_callsDifficultyServiceCompleteReintroduction() {
        UUID learnerId = UUID.randomUUID();
        UUID wordId = UUID.randomUUID();

        DifficultyProgressResponse mockResponse = DifficultyProgressResponse.builder()
                .currentLevel("LEARNING")
                .needsReintroduction(false)
                .build();

        when(difficultyAdjustmentService.completeReintroduction(learnerId, wordId)).thenReturn(mockResponse);

        DifficultyProgressResponse response = service.acknowledgeUnderstanding(learnerId, wordId);

        assertNotNull(response);
        assertFalse(response.getNeedsReintroduction());
        verify(difficultyAdjustmentService, times(1)).completeReintroduction(learnerId, wordId);
    }
}
