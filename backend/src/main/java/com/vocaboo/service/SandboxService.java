package com.vocaboo.service;

import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import com.vocaboo.dto.response.MatchingWordResponse;
import com.vocaboo.dto.response.SandboxLessonResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import org.springframework.http.HttpStatus;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;
import java.util.regex.Pattern;

@Service
@RequiredArgsConstructor
public class SandboxService {

    private final SandboxSessionRepository sandboxSessionRepository;
    private final SandboxWordRepository sandboxWordRepository;
    private final SandboxWordProgressRepository sandboxWordProgressRepository;
    private final SandboxModuleScoreRepository sandboxModuleScoreRepository;
    private final LearnerRepository learnerRepository;
    private final GeminiService geminiService;

    @Transactional
    public SandboxSessionGenerationResult createSession(UUID learnerId, String customWord) {
        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner not found"));

        String normalizedWord = normalizeSandboxWord(customWord);
        GeminiService.SandboxWordDto dto = geminiService.generateSandboxLesson(normalizedWord);

        if (dto == null) {
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Gemini returned no sandbox lesson.");
        }

        SandboxSession session = SandboxSession.builder()
                .learner(learner)
                .customWord(normalizedWord)
                .createdAt(OffsetDateTime.now())
                .updatedAt(OffsetDateTime.now())
                .build();

        session = sandboxSessionRepository.save(session);

        if (dto.getEnglishWord() == null || dto.getEnglishWord().trim().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Gemini returned an empty sandbox word.");
        }

        GeminiService.ConfusablePairDto confusablePair = dto.getConfusablePair();

        SandboxWord word = SandboxWord.builder()
                .session(session)
                .englishWord(dto.getEnglishWord())
                .cebuanoMeaning(dto.getCebuanoMeaning())
                .exampleSentenceEnglish(dto.getExampleSentenceEnglish())
                .exampleSentenceCebuano(dto.getExampleSentenceCebuano())
                .phonologicalTipKey(dto.getPhonologicalTip())
                .trueOrFalseStatement(dto.getTrueOrFalseStatement())
                .trueOrFalseAnswer(dto.getTrueOrFalseAnswer() != null ? dto.getTrueOrFalseAnswer() : Boolean.TRUE)
                .hintClue(dto.getHintClue())
                .confusablePartnerWord(confusablePair != null ? confusablePair.getPartnerWord() : null)
                .confusableCebuanoDistinction(confusablePair != null ? confusablePair.getCebuanoDistinction() : null)
                .confusableContrastSentenceA(confusablePair != null ? confusablePair.getContrastiveSentenceA() : null)
                .confusableContrastSentenceB(confusablePair != null ? confusablePair.getContrastiveSentenceB() : null)
                .wordOrder(1)
                .createdAt(OffsetDateTime.now())
                .build();

        word = sandboxWordRepository.save(word);

        // Seed progress rows for modules 1 to 3
        for (int moduleNum = 1; moduleNum <= 3; moduleNum++) {
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
            .sandboxWordId(word.getWordId())
            .englishWord(dto.getEnglishWord())
            .cebuanoMeaning(dto.getCebuanoMeaning())
            .englishExampleSentence(dto.getExampleSentenceEnglish())
            .exampleSentenceCebuano(dto.getExampleSentenceCebuano())
            .phonologicalTip(dto.getPhonologicalTip())
            .multipleChoiceDistractors(dto.getMultipleChoiceDistractors())
            .fillInTheBlankSentence(buildFillInTheBlankSentence(dto.getExampleSentenceEnglish(), dto.getEnglishWord()))
            .matchingSet(dto.getMatchingSet() == null ? List.of() : dto.getMatchingSet().stream()
                .map(entry -> MatchingWordResponse.builder()
                    .englishWord(entry.getEnglishWord())
                    .cebuanoMeaning(entry.getCebuanoMeaning())
                    .cebuanoTranslation(entry.getCebuanoTranslation())
                    .build())
                .toList())
            .sentenceArrangementTokens(buildSentenceArrangementTokens(dto.getExampleSentenceEnglish()))
            .sentenceCompletionBlank(buildFillInTheBlankSentence(dto.getExampleSentenceEnglish(), dto.getEnglishWord()))
            .sentenceCompletionOptions(buildSentenceCompletionOptions(dto.getEnglishWord(), dto.getMultipleChoiceDistractors()))
            .trueOrFalseStatement(word.getTrueOrFalseStatement())
            .trueOrFalseAnswer(word.getTrueOrFalseAnswer())
            .hintClue(word.getHintClue())
            .confusablePartnerWord(word.getConfusablePartnerWord())
            .confusableCebuanoDistinction(word.getConfusableCebuanoDistinction())
            .confusableContrastSentenceA(word.getConfusableContrastSentenceA())
            .confusableContrastSentenceB(word.getConfusableContrastSentenceB())
            .build();

        return SandboxSessionGenerationResult.builder()
            .session(session)
            .lesson(lessonResponse)
            .build();
    }

    @Transactional
    public SandboxModuleScore saveModuleScore(UUID sessionId, Integer moduleNumber, Integer correctCount, Integer totalCount, Double score) {
        // Accept null moduleNumber from clients and treat as unified module 1.
        if (moduleNumber == null) {
            moduleNumber = 1;
        }
        if (moduleNumber < 1) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Sandbox moduleNumber must be >= 1.");
        }

        final Integer finalModuleNumber = moduleNumber;

        SandboxSession session = sandboxSessionRepository.findById(sessionId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Sandbox session not found."));

        int safeCorrectCount = correctCount == null ? 0 : correctCount;
        int safeTotalCount = totalCount == null ? 0 : totalCount;
        double safeScore = score == null
                ? (safeTotalCount > 0 ? ((double) safeCorrectCount / safeTotalCount) * 100.0 : 0.0)
                : score;

        SandboxModuleScore moduleScore = sandboxModuleScoreRepository
            .findBySessionSessionIdAndModuleNumber(sessionId, finalModuleNumber)
            .orElseGet(() -> SandboxModuleScore.builder()
                .session(session)
                .moduleNumber(finalModuleNumber)
                .build());

        moduleScore.setCorrect(safeCorrectCount);
        moduleScore.setTotal(safeTotalCount);
        moduleScore.setScore(BigDecimal.valueOf(safeScore).setScale(2, java.math.RoundingMode.HALF_UP));

        try {
            return sandboxModuleScoreRepository.save(moduleScore);
        } catch (org.springframework.dao.DataIntegrityViolationException ex) {
            // Handle rare race where two inserts happen concurrently for same unique key.
            // Fall back to re-fetching the existing record and updating it.
            SandboxModuleScore existing = sandboxModuleScoreRepository
                .findBySessionSessionIdAndModuleNumber(sessionId, finalModuleNumber)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.CONFLICT, "Failed to persist module score and could not recover."));
            existing.setCorrect(safeCorrectCount);
            existing.setTotal(safeTotalCount);
            existing.setScore(BigDecimal.valueOf(safeScore).setScale(2, java.math.RoundingMode.HALF_UP));
            return sandboxModuleScoreRepository.save(existing);
        }
    }

    private List<String> buildSentenceArrangementTokens(String exampleSentence) {
        String sentence = exampleSentence == null ? "" : exampleSentence.trim();
        if (sentence.isEmpty()) {
            return List.of();
        }

        String normalized = sentence.replaceAll("[^\\p{L}\\p{N}' ]", " ");
        List<String> tokens = new ArrayList<>();
        for (String token : normalized.split("\\s+")) {
            String trimmed = token.trim();
            if (!trimmed.isEmpty()) {
                tokens.add(trimmed);
            }
        }
        return tokens;
    }

    private String buildFillInTheBlankSentence(String exampleSentence, String englishWord) {
        String sentence = exampleSentence == null ? "" : exampleSentence.trim();
        String word = englishWord == null ? "" : englishWord.trim();
        if (sentence.isEmpty() || word.isEmpty()) {
            return sentence;
        }

        String blanked = sentence.replaceFirst("(?i)\\b" + Pattern.quote(word) + "\\b", "___");
        return blanked.equals(sentence) ? sentence : blanked;
    }

    private List<String> buildSentenceCompletionOptions(String englishWord, List<String> distractors) {
        List<String> options = new ArrayList<>();
        addUniqueOption(options, englishWord);

        if (distractors != null) {
            for (String distractor : distractors) {
                addUniqueOption(options, distractor);
                if (options.size() >= 4) {
                    break;
                }
            }
        }

        for (String fallback : List.of("book", "school", "water", "friend", "house", "color")) {
            if (options.size() >= 4) {
                break;
            }
            addUniqueOption(options, fallback);
        }

        return options;
    }

    private void addUniqueOption(List<String> options, String candidate) {
        if (candidate == null) {
            return;
        }

        String trimmed = candidate.trim();
        if (trimmed.isEmpty()) {
            return;
        }

        for (String existing : options) {
            if (existing.equalsIgnoreCase(trimmed)) {
                return;
            }
        }

        options.add(trimmed);
    }

    @Transactional
    public com.vocaboo.dto.response.SandboxWordProgressDto updateProgress(UUID sessionId, UUID wordId, Integer moduleNumber, Integer stepCompleted, String statusStr) {
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

        SandboxWordProgress saved = sandboxWordProgressRepository.save(progress);

        // Build DTO while still in transaction to ensure related proxies are accessible
        com.vocaboo.dto.response.SandboxWordProgressDto dto = com.vocaboo.dto.response.SandboxWordProgressDto.builder()
                .progressId(saved.getProgressId())
                .sessionId(saved.getSession() != null ? saved.getSession().getSessionId() : null)
                .wordId(saved.getWord() != null ? saved.getWord().getWordId() : null)
                .moduleNumber(saved.getModuleNumber())
                .stepCompleted(saved.getStepCompleted())
                .status(saved.getStatus())
                .completedAt(saved.getCompletedAt())
                .createdAt(saved.getCreatedAt())
                .updatedAt(saved.getUpdatedAt())
                .build();

        return dto;
    }

    @Transactional
    public SandboxSession completeSession(UUID sessionId, Double score) {
        SandboxSession session = sandboxSessionRepository.findById(sessionId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Sandbox session not found."));

        if (score == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Sandbox finalScore is required.");
        }

        session.setMasteryScore(score);
        session.setCompletedAt(OffsetDateTime.now());
        session.setUpdatedAt(OffsetDateTime.now());

        return sandboxSessionRepository.save(session);
    }

    public List<SandboxModuleScore> getModuleScores(UUID sessionId) {
        return sandboxModuleScoreRepository.findBySessionSessionId(sessionId);
    }

    private String normalizeSandboxWord(String customWord) {
        if (customWord == null || customWord.trim().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "customWord is required.");
        }
        return customWord.trim().replaceAll("\\s+", " ");
    }

    public List<SandboxSession> getHistory(UUID learnerId) {
        return sandboxSessionRepository.findByLearnerLearnerIdOrderByCreatedAtDesc(learnerId);
    }

    public SandboxLessonResponse toLessonResponse(SandboxWord word) {
        if (word == null) return null;
        List<String> distractors = new ArrayList<>();
        if (word.getConfusablePartnerWord() != null && !word.getConfusablePartnerWord().isBlank()) {
            distractors.add(word.getConfusablePartnerWord());
        }
        return SandboxLessonResponse.builder()
                .sandboxWordId(word.getWordId())
                .englishWord(word.getEnglishWord())
                .cebuanoMeaning(word.getCebuanoMeaning())
                .englishExampleSentence(word.getExampleSentenceEnglish())
                .exampleSentenceCebuano(word.getExampleSentenceCebuano())
                .phonologicalTip(word.getPhonologicalTipKey())
                .multipleChoiceDistractors(distractors)
                .fillInTheBlankSentence(buildFillInTheBlankSentence(word.getExampleSentenceEnglish(), word.getEnglishWord()))
                .matchingSet(List.of())
                .sentenceArrangementTokens(buildSentenceArrangementTokens(word.getExampleSentenceEnglish()))
                .sentenceCompletionBlank(buildFillInTheBlankSentence(word.getExampleSentenceEnglish(), word.getEnglishWord()))
                .sentenceCompletionOptions(buildSentenceCompletionOptions(word.getEnglishWord(), distractors))
                .trueOrFalseStatement(word.getTrueOrFalseStatement())
                .trueOrFalseAnswer(word.getTrueOrFalseAnswer())
                .hintClue(word.getHintClue())
                .confusablePartnerWord(word.getConfusablePartnerWord())
                .confusableCebuanoDistinction(word.getConfusableCebuanoDistinction())
                .confusableContrastSentenceA(word.getConfusableContrastSentenceA())
                .confusableContrastSentenceB(word.getConfusableContrastSentenceB())
                .build();
    }

    @Transactional(readOnly = true)
    public SandboxSessionGenerationResult getSession(UUID sessionId) {
        SandboxSession session = sandboxSessionRepository.findById(sessionId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Session not found"));
        List<SandboxWord> words = sandboxWordRepository.findBySessionSessionIdOrderByWordOrderAsc(sessionId);
        SandboxLessonResponse lesson = words.isEmpty() ? null : toLessonResponse(words.get(0));
        return SandboxSessionGenerationResult.builder()
                .session(session)
                .lesson(lesson)
                .build();
    }
}

