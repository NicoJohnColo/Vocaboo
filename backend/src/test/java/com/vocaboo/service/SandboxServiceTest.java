package com.vocaboo.service;

import com.vocaboo.dto.response.SandboxLessonResponse;
import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.server.ResponseStatusException;

import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class SandboxServiceTest {

    @Mock
    private SandboxSessionRepository sandboxSessionRepository;
    @Mock
    private SandboxWordRepository sandboxWordRepository;
    @Mock
    private SandboxWordProgressRepository sandboxWordProgressRepository;
    @Mock
    private SandboxModuleScoreRepository sandboxModuleScoreRepository;
    @Mock
    private LearnerRepository learnerRepository;
    @Mock
    private GeminiService geminiService;

    @InjectMocks
    private SandboxService sandboxService;

    @Test
    void createSession_withValidMultiWordTopic_succeeds() {
        UUID learnerId = UUID.randomUUID();
        String customWord = "  rainy   weather  "; // extra spaces to check collapsing

        Learner learner = Learner.builder().learnerId(learnerId).build();
        when(learnerRepository.findById(learnerId)).thenReturn(Optional.of(learner));

        GeminiService.SandboxWordDto mockDto = GeminiService.SandboxWordDto.builder()
                .englishWord("rain")
                .cebuanoMeaning("ulan")
                .exampleSentenceEnglish("The rain is heavy.")
                .exampleSentenceCebuano("Kusog ang ulan.")
                .phonologicalTip("rain-tip")
                .multipleChoiceDistractors(List.of("sun", "wind", "snow"))
                .matchingSet(List.of())
                .sentenceArrangementTokens(List.of("The", "rain", "is", "heavy"))
                .sentenceCompletionBlank("The ___ is heavy.")
                .sentenceCompletionOptions(List.of("rain", "sun", "wind", "snow"))
                .build();
        
        when(geminiService.generateSandboxLesson("rainy weather")).thenReturn(mockDto);

        when(sandboxSessionRepository.save(any(SandboxSession.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
        when(sandboxWordRepository.save(any(SandboxWord.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        SandboxSessionGenerationResult result = sandboxService.createSession(learnerId, customWord);

        assertNotNull(result);
        assertEquals("rainy weather", result.getSession().getCustomWord());
        assertEquals("rain", result.getLesson().getEnglishWord());
        assertEquals("ulan", result.getLesson().getCebuanoMeaning());

        verify(sandboxSessionRepository).save(any(SandboxSession.class));
        verify(sandboxWordRepository).save(any(SandboxWord.class));
        verify(sandboxWordProgressRepository, times(3)).save(any(SandboxWordProgress.class));
    }

    @Test
    void createSession_withNullOrEmptyInput_throwsBadRequest() {
        UUID learnerId = UUID.randomUUID();
        Learner learner = Learner.builder().learnerId(learnerId).build();
        when(learnerRepository.findById(learnerId)).thenReturn(Optional.of(learner));

        assertThrows(ResponseStatusException.class, () -> sandboxService.createSession(learnerId, ""));
        assertThrows(ResponseStatusException.class, () -> sandboxService.createSession(learnerId, "   "));
        assertThrows(ResponseStatusException.class, () -> sandboxService.createSession(learnerId, null));
    }

    @Test
    void createSession_withInvalidCharacters_throwsBadRequest() {
        UUID learnerId = UUID.randomUUID();
        Learner learner = Learner.builder().learnerId(learnerId).build();
        when(learnerRepository.findById(learnerId)).thenReturn(Optional.of(learner));

        // When validateSandboxInput runs in GeminiService, it should throw BAD_REQUEST for special chars.
        when(geminiService.generateSandboxLesson("beach@vacation"))
                .thenThrow(new ResponseStatusException(org.springframework.http.HttpStatus.BAD_REQUEST, "Sandbox input contains invalid characters."));

        ResponseStatusException ex = assertThrows(ResponseStatusException.class, () -> {
            sandboxService.createSession(learnerId, "beach@vacation");
        });
        assertEquals(org.springframework.http.HttpStatus.BAD_REQUEST, ex.getStatusCode());
    }
}
