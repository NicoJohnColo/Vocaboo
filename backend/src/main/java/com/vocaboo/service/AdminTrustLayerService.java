package com.vocaboo.service;

import com.vocaboo.dto.response.AdminTrustLayerStatsResponse;
import com.vocaboo.entity.DifficultyProgress;
import com.vocaboo.entity.Learner;
import com.vocaboo.entity.WordPerformance;
import com.vocaboo.repository.DifficultyProgressRepository;
import com.vocaboo.repository.LearnerRepository;
import com.vocaboo.repository.LessonModuleScoreRepository;
import com.vocaboo.repository.PronunciationAttemptRepository;
import com.vocaboo.repository.WordPerformanceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AdminTrustLayerService {

    private final LearnerRepository learnerRepository;
    private final WordPerformanceRepository wordPerformanceRepository;
    private final PronunciationAttemptRepository pronunciationAttemptRepository;
    private final DifficultyProgressRepository difficultyProgressRepository;
    private final LessonModuleScoreRepository lessonModuleScoreRepository;

    @Transactional(readOnly = true)
    public List<AdminTrustLayerStatsResponse> getTrustLayerStats() {
        List<Learner> learners = learnerRepository.findAll();
        List<AdminTrustLayerStatsResponse> statsList = new ArrayList<>();

        for (Learner learner : learners) {
            // Get total word attempts from performances
            List<WordPerformance> performances = wordPerformanceRepository.findByLearnerLearnerId(learner.getLearnerId());
            int totalWordAttempts = performances.stream().mapToInt(WordPerformance::getTotalAttempts).sum();

            // Get pronunciation accuracy
            int totalPronunciations = (int) pronunciationAttemptRepository.countByLearnerLearnerId(learner.getLearnerId());
            int correctPronunciations = (int) pronunciationAttemptRepository.countByLearnerLearnerIdAndIsCorrect(learner.getLearnerId(), true);
            double pronunciationAccuracy = totalPronunciations > 0 
                    ? (correctPronunciations * 100.0) / totalPronunciations 
                    : 0.0;

            // Get tier drops / reintroductions and total mastered words
            List<DifficultyProgress> progresses = difficultyProgressRepository.findByLearnerLearnerIdAndModuleNumber(learner.getLearnerId(), 2);
            int tierDrops = progresses.stream().mapToInt(DifficultyProgress::getReintroductionCount).sum();
            
            int totalMastered = (int) difficultyProgressRepository.countTotalMasteredWordsByLearner(learner.getLearnerId());

            // Module-level active time tracking
            int m2Time = lessonModuleScoreRepository.findByLearnerLearnerIdAndModuleNumber(learner.getLearnerId(), 2)
                    .stream().mapToInt(s -> s.getTimeSeconds() != null ? s.getTimeSeconds() : 0).sum();
            int m3Time = lessonModuleScoreRepository.findByLearnerLearnerIdAndModuleNumber(learner.getLearnerId(), 3)
                    .stream().mapToInt(s -> s.getTimeSeconds() != null ? s.getTimeSeconds() : 0).sum();
            int m4Time = lessonModuleScoreRepository.findByLearnerLearnerIdAndModuleNumber(learner.getLearnerId(), 4)
                    .stream().mapToInt(s -> s.getTimeSeconds() != null ? s.getTimeSeconds() : 0).sum();
            int totalTime = m2Time + m3Time + m4Time;

            statsList.add(AdminTrustLayerStatsResponse.builder()
                    .learnerId(learner.getLearnerId())
                    .displayName(learner.getDisplayName())
                    .totalWordAttempts(totalWordAttempts)
                    .totalPronunciationAttempts(totalPronunciations)
                    .pronunciationAccuracyPercent(pronunciationAccuracy)
                    .tierDrops(tierDrops)
                    .totalWordsMastered(totalMastered)
                    .module2TimeSeconds(m2Time)
                    .module3TimeSeconds(m3Time)
                    .module4TimeSeconds(m4Time)
                    .totalLessonTimeSeconds(totalTime)
                    .build());
        }

        return statsList;
    }
}
