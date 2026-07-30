package com.vocaboo.service;

import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class MasteryBadgeService {

    private final WordPerformanceRepository performanceRepository;
    private final DifficultyProgressRepository difficultyRepository;
    private final RewardDataRepository rewardRepository;
    private final LearnerRepository learnerRepository;
    private final LessonRepository lessonRepository;
    private final VocabularyWordRepository wordRepository;

    @Transactional
    public String calculateAndSaveBadge(UUID learnerId, UUID lessonId, double sessionAccuracy) {
        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner not found"));
        Lesson lesson = lessonRepository.findById(lessonId)
                .orElseThrow(() -> new IllegalArgumentException("Lesson not found"));

        String earnedBadge;
        if (sessionAccuracy >= 90.0) {
            earnedBadge = "GOLD";
        } else if (sessionAccuracy >= 80.0) {
            earnedBadge = "SILVER";
        } else {
            earnedBadge = "BRONZE";
        }

        // Save if it's the highest tier earned
        List<RewardData> existingRewards = rewardRepository.findByLearnerLearnerIdAndLessonLessonId(learnerId, lessonId);
        int maxExistingTier = 0;
        for (RewardData reward : existingRewards) {
            maxExistingTier = Math.max(maxExistingTier, getBadgeTier(reward.getBadgeType()));
        }

        int newTier = getBadgeTier(earnedBadge);
        if (newTier > maxExistingTier) {
            rewardRepository.save(
                RewardData.builder()
                    .learner(learner)
                    .lesson(lesson)
                    .badgeType(earnedBadge)
                    .build()
            );
        }

        return earnedBadge;
    }

    @Transactional
    public String calculateAndSaveBadge(UUID learnerId, UUID lessonId) {
        List<VocabularyWord> words = wordRepository.findByLessonLessonIdOrderByWordOrderAsc(lessonId);
        if (words == null || words.isEmpty()) {
            return calculateAndSaveBadge(learnerId, lessonId, 0.0);
        }

        int totalCorrect = 0;
        int totalAttempts = 0;
        for (VocabularyWord word : words) {
            WordPerformance perf = performanceRepository.findByLearnerLearnerIdAndWordWordId(learnerId, word.getWordId())
                    .orElse(null);
            if (perf != null) {
                totalCorrect += perf.getCorrectCount();
                totalAttempts += perf.getTotalAttempts();
            }
        }

        double accuracy = totalAttempts > 0 ? (totalCorrect * 100.0 / totalAttempts) : 0.0;
        return calculateAndSaveBadge(learnerId, lessonId, accuracy);
    }

    private int getBadgeTier(String badge) {
        if (badge == null) return 0;
        switch (badge) {
            case "PERFECT_GOLD":
            case "GOLD": return 3;
            case "SILVER": return 2;
            case "BRONZE": return 1;
            default: return 0;
        }
    }
}
