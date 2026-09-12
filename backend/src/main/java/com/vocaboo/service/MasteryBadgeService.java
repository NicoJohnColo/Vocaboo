package com.vocaboo.service;

import com.vocaboo.entity.*;
import com.vocaboo.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
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
        } else if (sessionAccuracy >= 75.0) {
            earnedBadge = "SILVER";
        } else {
            earnedBadge = "BRONZE";
        }

        List<RewardData> existingRewards = rewardRepository.findByLearnerLearnerIdAndLessonLessonId(learnerId, lessonId);
        int newTier = getBadgeTier(earnedBadge);
        int existingTier = existingRewards.stream()
                .map(r -> getBadgeTier(r.getBadgeType()))
                .max(Integer::compareTo)
                .orElse(0);

        if (existingRewards.isEmpty() || newTier >= existingTier) {
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
            return earnedBadge;
        }

        return existingRewards.get(0).getBadgeType();
    }

    @Transactional
    public String calculateAndSaveBadge(UUID learnerId, UUID lessonId) {
        LearnerLessonStatus lls = lessonStatusRepository.findByLearnerLearnerIdAndLessonLessonId(learnerId, lessonId).orElse(null);
        List<VocabularyWord> allLessonWords = wordRepository.findByLessonLessonIdOrderByWordOrderAsc(lessonId);

        int totalCorrect = 0;
        int totalAttempts = 0;
        double wordAccSum = 0.0;
        int wordsWithAcc = 0;
        if (allLessonWords != null) {
            for (VocabularyWord word : allLessonWords) {
                WordPerformance perf = performanceRepository.findByLearnerLearnerIdAndWordWordId(learnerId, word.getWordId())
                        .orElse(null);
                if (perf != null && perf.getTotalAttempts() > 0) {
                    totalCorrect += perf.getCorrectCount();
                    totalAttempts += perf.getTotalAttempts();
                    if (perf.getAccuracy() != null && perf.getAccuracy().doubleValue() > 0) {
                        wordAccSum += perf.getAccuracy().doubleValue();
                        wordsWithAcc++;
                    } else if (perf.getTotalAttempts() > 0) {
                        wordAccSum += ((double) perf.getCorrectCount() / perf.getTotalAttempts() * 100.0);
                        wordsWithAcc++;
                    }
                }
            }
        }

        boolean hasAttempted = totalAttempts > 0 || wordsWithAcc > 0;
        double cumulativeAccuracy = wordsWithAcc > 0
                ? (wordAccSum / wordsWithAcc)
                : (hasAttempted ? (totalCorrect * 100.0 / totalAttempts) : 0.0);
        if (!hasAttempted && lls != null && lls.getMasteryScore() != null) {
            cumulativeAccuracy = lls.getMasteryScore().doubleValue();
            hasAttempted = true;
        }

        if (!hasAttempted) {
            List<RewardData> unearnedRewards = rewardRepository.findByLearnerLearnerIdAndLessonLessonId(learnerId, lessonId);
            if (!unearnedRewards.isEmpty()) {
                rewardRepository.deleteAll(unearnedRewards);
                rewardRepository.flush();
            }
            return null;
        }

        double bestScore = (lls != null && lls.getMasteryScore() != null) ? lls.getMasteryScore().doubleValue() : 0.0;
        BigDecimal targetScore = java.math.BigDecimal.valueOf(cumulativeAccuracy).setScale(2, java.math.RoundingMode.HALF_UP);
        if (lls != null) {
            // High-score rule: only override if new cumulative accuracy is higher than existing mastery score
            if (lls.getMasteryScore() == null || targetScore.compareTo(lls.getMasteryScore()) > 0) {
                lls.setMasteryScore(targetScore);
                lessonStatusRepository.save(lls);
                bestScore = targetScore.doubleValue();
            }
        }

        double effectiveAccuracy = Math.max(cumulativeAccuracy, bestScore);
        return calculateAndSaveBadge(learnerId, lessonId, effectiveAccuracy);
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
