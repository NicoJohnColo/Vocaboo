package com.vocaboo.service;

import com.vocaboo.entity.SentenceTemplate;
import com.vocaboo.repository.SentenceTemplateRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class SentenceContextualService {

    private final SentenceTemplateRepository templateRepository;

    public List<SentenceTemplate> getTemplatesForWord(UUID wordId) {
        return templateRepository.findByWordWordId(wordId);
    }

    @Transactional(readOnly = true)
    public Map<String, Object> evaluateSentence(UUID templateId, String assembledSentence) {
        SentenceTemplate template = templateRepository.findById(templateId)
                .orElseThrow(() -> new IllegalArgumentException("Template not found"));

        // Clean the template text and the assembled sentence to compare
        String cleanExpected = cleanSentence(template.getTemplateText());
        String cleanActual = cleanSentence(assembledSentence);

        boolean isCorrect = cleanExpected.equalsIgnoreCase(cleanActual);

        Map<String, Object> response = new HashMap<>();
        response.put("templateId", templateId.toString());
        response.put("isCorrect", isCorrect);
        response.put("expectedText", template.getTemplateText());
        response.put("actualText", assembledSentence);
        return response;
    }

    private String cleanSentence(String sentence) {
        if (sentence == null) return "";
        // Strip braces (e.g. {word}), lower case, clean spaces and punctuation
        return sentence.toLowerCase()
                .replaceAll("[\\{\\}]", "")
                .replaceAll("[^a-zA-Z0-9\\s]", "")
                .replaceAll("\\s+", " ")
                .trim();
    }
}
