package com.vocaboo.service;

import com.vocaboo.dto.response.DashboardResponse;
import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DashboardService {

    private final LearnerLessonStatusRepository lessonStatusRepository;
    private final LessonRepository lessonRepository;
    private final PronunciationAttemptRepository pronunciationAttemptRepository;
    private final SandboxSessionRepository sandboxSessionRepository;
    private final SandboxWordRepository sandboxWordRepository;

    public DashboardResponse getDashboardData(UUID learnerId) {
        // Core lesson stats
        List<LearnerLessonStatus> statuses = lessonStatusRepository.findByLearnerLearnerId(learnerId);
        long completedCount = statuses.stream()
                .filter(s -> s.getStatus() == LessonStatus.COMPLETED)
                .count();

        long totalLessons = lessonRepository.count();

        double averageScore = 0.0;
        List<LearnerLessonStatus> completedWithScores = statuses.stream()
                .filter(s -> s.getStatus() == LessonStatus.COMPLETED && s.getMasteryScore() != null)
                .collect(Collectors.toList());

        if (!completedWithScores.isEmpty()) {
            double sum = completedWithScores.stream()
                    .mapToDouble(s -> s.getMasteryScore().doubleValue())
                    .sum();
            averageScore = sum / completedWithScores.size();
        }

        // Pronunciation stats
        int totalPronunciations = (int) pronunciationAttemptRepository.countByLearnerLearnerId(learnerId);
        int correctPronunciations = (int) pronunciationAttemptRepository.countByLearnerLearnerIdAndIsCorrect(learnerId, true);

        // Sandbox history
        List<SandboxSession> sandboxSessions = sandboxSessionRepository.findByLearnerLearnerIdOrderByCreatedAtDesc(learnerId);
        List<DashboardResponse.SandboxSessionDetails> sandboxHistory = new ArrayList<>();

        for (SandboxSession session : sandboxSessions) {
            List<SandboxWord> words = sandboxWordRepository.findBySessionSessionIdOrderByWordOrderAsc(session.getSessionId());
            List<String> englishWords = words.stream()
                    .map(SandboxWord::getEnglishWord)
                    .collect(Collectors.toList());

            sandboxHistory.add(DashboardResponse.SandboxSessionDetails.builder()
                    .sessionId(session.getSessionId())
                    .topic(session.getTopic())
                    .customWord(session.getCustomWord())
                    .masteryScore(session.getMasteryScore())
                    .completedAt(session.getCompletedAt())
                    .words(englishWords)
                    .build());
        }

        return DashboardResponse.builder()
                .completedLessons((int) completedCount)
                .totalLessons((int) totalLessons)
                .averageMasteryScore(averageScore)
                .totalPronunciationAttempts(totalPronunciations)
                .correctPronunciationAttempts(correctPronunciations)
                .sandboxHistory(sandboxHistory)
                .build();
    }
}
