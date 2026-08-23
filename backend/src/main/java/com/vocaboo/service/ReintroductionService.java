package com.vocaboo.service;

import com.vocaboo.dto.response.DifficultyProgressResponse;
import com.vocaboo.dto.response.ReintroductionResponse;
import com.vocaboo.entity.VocabularyWord;
import com.vocaboo.repository.VocabularyWordRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;
import java.util.regex.Pattern;

@Service
@RequiredArgsConstructor
public class ReintroductionService {

    public static final double PRONUNCIATION_THRESHOLD = 70.0;

    private final VocabularyWordRepository wordRepository;
    private final DifficultyAdjustmentService difficultyAdjustmentService;

    @Transactional(readOnly = true)
    public ReintroductionResponse buildPayload(UUID learnerId, UUID wordId) {
        VocabularyWord word = wordRepository.findById(wordId)
                .orElseThrow(() -> new IllegalArgumentException("Word not found"));

        String englishSentence = word.getExampleSentenceEnglish();
        String targetWord = word.getEnglishWord();
        String highlightedSentence = highlightTargetWord(englishSentence, targetWord);

        return ReintroductionResponse.builder()
                .wordId(word.getWordId())
                .englishWord(word.getEnglishWord())
                .cebuanoMeaning(word.getCebuanoMeaning())
                .exampleSentenceEnglish(word.getExampleSentenceEnglish())
                .exampleSentenceCebuano(word.getExampleSentenceCebuano())
                .highlightedSentenceEnglish(highlightedSentence)
                .audioAssetPath(word.getAudioAssetPath())
                .pronunciationThreshold(PRONUNCIATION_THRESHOLD)
                .build();
    }

    @Transactional
    public DifficultyProgressResponse acknowledgeUnderstanding(UUID learnerId, UUID wordId) {
        return acknowledgeUnderstanding(learnerId, wordId, 2);
    }

    @Transactional
    public DifficultyProgressResponse acknowledgeUnderstanding(UUID learnerId, UUID wordId, Integer moduleNumber) {
        return difficultyAdjustmentService.completeReintroduction(learnerId, wordId, moduleNumber);
    }

    private String highlightTargetWord(String sentence, String word) {
        if (sentence == null || word == null || sentence.isBlank() || word.isBlank()) {
            return sentence;
        }
        return sentence.replaceAll("(?i)\\b" + Pattern.quote(word) + "\\b", "<b>" + word + "</b>");
    }
}
