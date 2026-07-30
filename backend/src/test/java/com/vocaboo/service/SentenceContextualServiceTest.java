package com.vocaboo.service;

import com.vocaboo.entity.SentenceTemplate;
import com.vocaboo.repository.SentenceTemplateRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class SentenceContextualServiceTest {

    @Mock
    private SentenceTemplateRepository templateRepository;

    @InjectMocks
    private SentenceContextualService service;

    @Test
    void getTemplatesForWord_returnsListOfTemplates() {
        UUID wordId = UUID.randomUUID();
        SentenceTemplate template = SentenceTemplate.builder()
                .templateId(UUID.randomUUID())
                .templateText("The pencil is long.")
                .build();

        when(templateRepository.findByWordWordId(wordId)).thenReturn(List.of(template));

        List<SentenceTemplate> result = service.getTemplatesForWord(wordId);

        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals("The pencil is long.", result.get(0).getTemplateText());
    }

    @Test
    void evaluateSentence_returnsTrueOnMatchingText() {
        UUID templateId = UUID.randomUUID();
        SentenceTemplate template = SentenceTemplate.builder()
                .templateId(templateId)
                .templateText("The {pencil} is red.")
                .build();

        when(templateRepository.findById(templateId)).thenReturn(Optional.of(template));

        Map<String, Object> result = service.evaluateSentence(templateId, "The pencil is red.");

        assertTrue((Boolean) result.get("isCorrect"));
        assertEquals("The {pencil} is red.", result.get("expectedText"));
        assertEquals("The pencil is red.", result.get("actualText"));
    }

    @Test
    void evaluateSentence_returnsFalseOnMismatch() {
        UUID templateId = UUID.randomUUID();
        SentenceTemplate template = SentenceTemplate.builder()
                .templateId(templateId)
                .templateText("The {pencil} is red.")
                .build();

        when(templateRepository.findById(templateId)).thenReturn(Optional.of(template));

        Map<String, Object> result = service.evaluateSentence(templateId, "The bag is red.");

        assertFalse((Boolean) result.get("isCorrect"));
    }
}
