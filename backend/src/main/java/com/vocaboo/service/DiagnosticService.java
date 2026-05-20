package com.vocaboo.service;

import com.vocaboo.dto.request.DiagnosticRequest;
import com.vocaboo.dto.response.DiagnosticResponse;
import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class DiagnosticService {

    private final IntroductionSessionRepository sessionRepository;
    private final DiagnosticResultRepository diagnosticResultRepository;
    private final WordProgressRepository wordProgressRepository;
    private final LearnerRepository learnerRepository;
    private final LessonRepository lessonRepository;
    private final VocabularyWordRepository wordRepository;

    @Transactional
    public DiagnosticResponse submitDiagnostic(UUID learnerId, DiagnosticRequest request) {
        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner not found"));
        Lesson lesson = lessonRepository.findById(request.getLessonId())
                .orElseThrow(() -> new IllegalArgumentException("Lesson not found"));

        // Close any existing active session for this learner and lesson
        sessionRepository.findFirstByLearnerLearnerIdAndLessonLessonIdAndIsActiveTrue(learnerId, lesson.getLessonId())
                .ifPresent(existing -> {
                    existing.setIsActive(false);
                    existing.setCompletedAt(OffsetDateTime.now());
                    sessionRepository.save(existing);
                });

        // Create new introduction session
        IntroductionSession session = IntroductionSession.builder()
                .learner(learner)
                .lesson(lesson)
                .isActive(true)
                .build();
        session = sessionRepository.save(session);

        List<UUID> knownWordIds = new ArrayList<>();
        List<UUID> unknownWordIds = new ArrayList<>();

        for (Map.Entry<UUID, Boolean> entry : request.getResponses().entrySet()) {
            UUID wordId = entry.getKey();
            Boolean isKnown = entry.getValue();

            VocabularyWord word = wordRepository.findById(wordId)
                    .orElseThrow(() -> new IllegalArgumentException("Word not found with id: " + wordId));

            // Save diagnostic result
            DiagnosticResult result = DiagnosticResult.builder()
                    .learner(learner)
                    .lesson(lesson)
                    .word(word)
                    .session(session)
                    .isKnown(isKnown)
                    .build();
            diagnosticResultRepository.save(result);

            // Establish pathways and steps
            Pathway pathway = isKnown ? Pathway.ACCELERATED : Pathway.FULL;
            Integer initialStep = isKnown ? 2 : 0;

            WordProgress progress = WordProgress.builder()
                    .session(session)
                    .learner(learner)
                    .lesson(lesson)
                    .word(word)
                    .moduleNumber(1)
                    .pathway(pathway)
                    .stepCompleted(initialStep)
                    .status(WordStatus.INTRODUCED)
                    .build();
            wordProgressRepository.save(progress);

            if (isKnown) {
                knownWordIds.add(wordId);
            } else {
                unknownWordIds.add(wordId);
            }
        }

        return DiagnosticResponse.builder()
                .sessionId(session.getSessionId())
                .lessonId(lesson.getLessonId())
                .knownWordIds(knownWordIds)
                .unknownWordIds(unknownWordIds)
                .build();
    }
}
