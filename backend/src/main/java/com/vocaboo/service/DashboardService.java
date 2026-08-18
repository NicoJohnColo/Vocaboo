package com.vocaboo.service;

import com.vocaboo.dto.response.DashboardResponse;
import com.vocaboo.dto.response.DashboardStatsResponse;
import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
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
    private final LearnerRepository learnerRepository;
    private final AdminRepository adminRepository;
    private final ReviewSessionRepository reviewSessionRepository;
    private final CumulativeReviewSessionRepository cumulativeReviewSessionRepository;

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

        // Cumulative review stats & history
        List<CumulativeReviewSession> cumulativeSessions = cumulativeReviewSessionRepository.findByLearnerLearnerIdOrderByStartTimeDesc(learnerId);
        long cumulativeCompletedCount = cumulativeSessions.stream().filter(s -> "COMPLETED".equals(s.getSessionStatus())).count();

        String bestBadge = null;
        if (cumulativeSessions.stream().anyMatch(s -> "GOLD".equals(s.getBadgeAwarded()))) {
            bestBadge = "GOLD";
        } else if (cumulativeSessions.stream().anyMatch(s -> "SILVER".equals(s.getBadgeAwarded()))) {
            bestBadge = "SILVER";
        } else if (cumulativeSessions.stream().anyMatch(s -> "BRONZE".equals(s.getBadgeAwarded()))) {
            bestBadge = "BRONZE";
        }

        List<DashboardResponse.CumulativeSessionDetails> cumulativeHistory = cumulativeSessions.stream()
                .map(s -> DashboardResponse.CumulativeSessionDetails.builder()
                        .sessionId(s.getId())
                        .lessonPairId(s.getLessonPairId())
                        .sessionStatus(s.getSessionStatus())
                        .accuracyPercent(s.getAccuracyPercent() != null ? s.getAccuracyPercent().doubleValue() : null)
                        .badgeAwarded(s.getBadgeAwarded())
                        .pointsEarned(s.getPointsEarned())
                        .pointsBreakdown(s.getPointsBreakdown())
                        .startTime(s.getStartTime())
                        .endTime(s.getEndTime())
                        .build())
                .collect(Collectors.toList());

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
                .cumulativeReviewsCompleted((int) cumulativeCompletedCount)
                .bestCumulativeBadge(bestBadge)
                .cumulativeReviewHistory(cumulativeHistory)
                .build();
    }

    public DashboardStatsResponse getDashboardStats() {
        // Count total learners
        long totalLearners = learnerRepository.count();

        // Count total lessons
        long totalLessons = lessonRepository.count();

        // Count active sessions (incomplete review sessions)
        long activeSessions = reviewSessionRepository.countByCompletedAtIsNull();

        // Count total admin accounts
        long totalAdmins = adminRepository.count();

        return DashboardStatsResponse.builder()
                .totalLearners(totalLearners)
                .totalLessons(totalLessons)
                .activeSessions(activeSessions)
                .totalAdmins(totalAdmins)
                .build();
    }
}
