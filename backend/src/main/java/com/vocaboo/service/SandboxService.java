package com.vocaboo.service;

import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import com.vocaboo.dto.response.MatchingWordResponse;
import com.vocaboo.dto.response.SandboxLessonResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class SandboxService {

    private final SandboxSessionRepository sandboxSessionRepository;
    private final SandboxWordRepository sandboxWordRepository;
    private final SandboxWordProgressRepository sandboxWordProgressRepository;
    private final LearnerRepository learnerRepository;
    private final GeminiService geminiService;

    @Transactional
    public SandboxSessionGenerationResult createSession(UUID learnerId, String topic, String customWord) {
        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner not found"));

        SandboxSession session = SandboxSession.builder()
                .learner(learner)
                .topic(topic != null && !topic.trim().isEmpty() ? topic.trim() : null)
                .customWord(customWord != null && !customWord.trim().isEmpty() ? customWord.trim() : null)
                .createdAt(OffsetDateTime.now())
                .updatedAt(OffsetDateTime.now())
                .build();

        session = sandboxSessionRepository.save(session);

        GeminiService.SandboxWordDto dto = geminiService.generateSandboxLesson(
                session.getCustomWord() != null ? session.getCustomWord() : session.getTopic());

        if (dto == null || dto.getEnglishWord() == null || dto.getEnglishWord().trim().isEmpty()) {
            throw new IllegalStateException("Failed to generate vocabulary word for sandbox session.");
        }

        SandboxWord word = SandboxWord.builder()
                .session(session)
                .englishWord(dto.getEnglishWord())
                .cebuanoMeaning(dto.getCebuanoMeaning())
                .exampleSentenceEnglish(dto.getExampleSentenceEnglish())
                .exampleSentenceCebuano(dto.getExampleSentenceCebuano())
                .phonologicalTipKey(dto.getPhonologicalTipKey())
                .wordOrder(1)
                .createdAt(OffsetDateTime.now())
                .build();

        word = sandboxWordRepository.save(word);

        // Seed progress rows for modules 1 to 4
        for (int moduleNum = 1; moduleNum <= 4; moduleNum++) {
            SandboxWordProgress progress = SandboxWordProgress.builder()
                    .session(session)
                    .word(word)
                    .moduleNumber(moduleNum)
                    .stepCompleted(0)
                    .status(WordStatus.INTRODUCED)
                    .createdAt(OffsetDateTime.now())
                    .updatedAt(OffsetDateTime.now())
                    .build();
            sandboxWordProgressRepository.save(progress);
        }

        SandboxLessonResponse lessonResponse = SandboxLessonResponse.builder()
            .englishWord(dto.getEnglishWord())
            .cebuanoMeaning(dto.getCebuanoMeaning())
            .englishExampleSentence(dto.getExampleSentenceEnglish())
            .phonologicalTip(dto.getPhonologicalTipKey())
            .isConfusable(dto.getIsConfusable() != null && dto.getIsConfusable())
            .confusablePairWord(dto.getConfusablePairWord())
            .confusableSentenceA(dto.getConfusableSentenceA())
            .confusableSentenceB(dto.getConfusableSentenceB())
            .multipleChoiceDistractors(dto.getMultipleChoiceDistractors())
            .fillInTheBlankSentence(dto.getFillInTheBlankSentence())
            .matchingSet(dto.getMatchingSet() == null ? List.of() : dto.getMatchingSet().stream()
                .map(entry -> MatchingWordResponse.builder()
                    .englishWord(entry.get("english_word"))
                    .cebuanoMeaning(entry.get("cebuano_meaning"))
                    .build())
                .toList())
            .sentenceArrangementTokens(dto.getSentenceArrangementTokens())
            .sentenceCompletionBlank(dto.getSentenceCompletionBlank())
            .sentenceCompletionOptions(dto.getSentenceCompletionOptions())
            .build();

        return SandboxSessionGenerationResult.builder()
            .session(session)
            .lesson(lessonResponse)
            .build();
    }

    @Transactional
    public SandboxWordProgress updateProgress(UUID sessionId, UUID wordId, Integer moduleNumber, Integer stepCompleted, String statusStr) {
        WordStatus status;
        try {
            status = WordStatus.valueOf(statusStr.toUpperCase());
        } catch (Exception e) {
            status = WordStatus.INTRODUCED;
        }

        SandboxWordProgress progress = sandboxWordProgressRepository
                .findBySessionSessionIdAndWordWordIdAndModuleNumber(sessionId, wordId, moduleNumber)
                .orElseThrow(() -> new IllegalArgumentException("Sandbox progress record not found"));

        progress.setStepCompleted(stepCompleted);
        progress.setStatus(status);
        progress.setUpdatedAt(OffsetDateTime.now());

        if (stepCompleted >= 4 || status == WordStatus.MASTERED) {
            progress.setCompletedAt(OffsetDateTime.now());
        }

        return sandboxWordProgressRepository.save(progress);
    }

    @Transactional
    public SandboxSession completeSession(UUID sessionId, Double score) {
        SandboxSession session = sandboxSessionRepository.findById(sessionId)
                .orElseThrow(() -> new IllegalArgumentException("Sandbox session not found"));

        session.setMasteryScore(score);
        session.setCompletedAt(OffsetDateTime.now());
        session.setUpdatedAt(OffsetDateTime.now());

        return sandboxSessionRepository.save(session);
    }

    public List<SandboxSession> getHistory(UUID learnerId) {
        return sandboxSessionRepository.findByLearnerLearnerIdOrderByCreatedAtDesc(learnerId);
    }
}
