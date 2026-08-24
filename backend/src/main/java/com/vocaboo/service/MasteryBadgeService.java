package com.vocaboo.service;

import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class MasteryBadgeService {

    private final WordPerformanceRepository performanceRepository;
    private final DifficultyProgressRepository difficultyRepository;
    private final RewardDataRepository rewardRepository;
    private final LearnerRepository learnerRepository;
    private final LessonRepository lessonRepository;
    private final VocabularyWordRepository wordRepository;
    private final LearnerLessonStatusRepository lessonStatusRepository;

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
        if (newTier > maxExistingTier || existingRewards.isEmpty()) {
            if (!existingRewards.isEmpty()) {
                rewardRepository.deleteAll(existingRewards);
                rewardRepository.flush();
            }
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
        LearnerLessonStatus lls = lessonStatusRepository.findByLearnerLearnerIdAndLessonLessonId(learnerId, lessonId).orElse(null);
        List<VocabularyWord> allLessonWords = wordRepository.findByLessonLessonIdOrderByWordOrderAsc(lessonId);

        int totalCorrect = 0;
        int totalAttempts = 0;
        if (allLessonWords != null) {
            for (VocabularyWord word : allLessonWords) {
                WordPerformance perf = performanceRepository.findByLearnerLearnerIdAndWordWordId(learnerId, word.getWordId())
                        .orElse(null);
                if (perf != null) {
                    totalCorrect += perf.getCorrectCount();
                    totalAttempts += perf.getTotalAttempts();
                }
            }
        }

        boolean hasAttempted = totalAttempts > 0 || (lls != null && lls.getMasteryScore() != null);
        if (!hasAttempted) {
            List<RewardData> unearnedRewards = rewardRepository.findByLearnerLearnerIdAndLessonLessonId(learnerId, lessonId);
            if (!unearnedRewards.isEmpty()) {
                rewardRepository.deleteAll(unearnedRewards);
                rewardRepository.flush();
            }
            return null;
        }

        double accuracy = 0.0;
        if (totalAttempts > 0) {
            accuracy = (totalCorrect * 100.0 / totalAttempts);
        }

        if (lls != null && lls.getMasteryScore() != null && lls.getMasteryScore().doubleValue() > accuracy) {
            accuracy = lls.getMasteryScore().doubleValue();
        }

        if (allLessonWords != null && !allLessonWords.isEmpty()) {
            long masteredCount = difficultyRepository.countMasteredWordsByLearnerAndLesson(learnerId, lessonId);
            if (masteredCount >= allLessonWords.size() && accuracy < 90.0) {
                accuracy = 97.5;
            }
        }

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
