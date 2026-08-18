package com.vocaboo.service;

import com.vocaboo.entity.VocabularyWord;
import com.vocaboo.repository.VocabularyWordRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import java.util.List;

@SpringBootTest
public class QueryWordsTest {

    @Autowired
    private VocabularyWordRepository wordRepository;

    @Test
    public void printWords() {
        List<VocabularyWord> words = wordRepository.findAll();
        System.out.println("=== PRINTING DB WORDS ===");
        for (VocabularyWord w : words) {
            System.out.println("Word: " + w.getEnglishWord());
            System.out.println("  Meaning: " + w.getCebuanoMeaning());
            System.out.println("  Example En: " + w.getExampleSentenceEnglish());
            System.out.println("  Fill Blank En: " + w.getFillBlankSentence());
            System.out.println("  Tile Sentence En: " + w.getTileSentence());
            System.out.println("  Eligible Activities: " + w.getEligibleActivityTypes());
            System.out.println("  Distractor Pool: " + w.getDistractorPool());
            System.out.println("-------------------------------------");
        }
    }
}
