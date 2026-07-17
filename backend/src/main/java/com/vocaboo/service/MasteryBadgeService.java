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
    public String calculateAndSaveBadge(UUID learnerId, UUID lessonId) {
        Learner learner = learnerRepository.findById(learnerId)
                .orElseThrow(() -> new IllegalArgumentException("Learner not found"));
        Lesson lesson = lessonRepository.findById(lessonId)
                .orElseThrow(() -> new IllegalArgumentException("Lesson not found"));

        List<VocabularyWord> words = wordRepository.findByLessonLessonIdOrderByWordOrderAsc(lessonId);
        if (words == null || words.isEmpty()) {
            return "BRONZE";
        }

        int totalDemerits = 0;
        boolean allMastered = true;
        boolean allProficientOrMastered = true;
        boolean allFamiliarOrAbove = true;

        for (VocabularyWord word : words) {
            WordPerformance perf = performanceRepository.findByLearnerLearnerIdAndWordWordId(learnerId, word.getWordId())
                    .orElse(null);
            int incorrect = perf != null ? perf.getIncorrectCount() : 0;
            totalDemerits += incorrect * 2;

            DifficultyProgress diff = difficultyRepository.findByLearnerLearnerIdAndWordWordId(learnerId, word.getWordId())
                    .orElse(null);
            DifficultyLevel level = diff != null ? diff.getCurrentLevel() : DifficultyLevel.LEARNING;

            if (level != DifficultyLevel.MASTERED) {
                allMastered = false;
            }
            if (level != DifficultyLevel.PROFICIENT && level != DifficultyLevel.MASTERED) {
                allProficientOrMastered = false;
            }
            if (level == DifficultyLevel.LEARNING) {
                allFamiliarOrAbove = false;
            }
        }

        String earnedBadge = "BRONZE";
        if (totalDemerits == 0 && allMastered) {
            earnedBadge = "PERFECT_GOLD";
        } else if (totalDemerits <= 4 && allProficientOrMastered) {
            earnedBadge = "GOLD";
        } else if (totalDemerits <= 10 && allFamiliarOrAbove) {
            earnedBadge = "SILVER";
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

    private int getBadgeTier(String badge) {
        if (badge == null) return 0;
        switch (badge) {
            case "PERFECT_GOLD": return 4;
            case "GOLD": return 3;
            case "SILVER": return 2;
            case "BRONZE": return 1;
            default: return 0;
        }
    }
}
