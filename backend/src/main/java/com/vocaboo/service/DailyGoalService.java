package com.vocaboo.service;

import com.vocaboo.entity.DailyGoal;
import com.vocaboo.entity.Learner;
import com.vocaboo.repository.DailyGoalRepository;
import com.vocaboo.repository.LearnerMasteryRepository;
import com.vocaboo.repository.LearnerRepository;
import com.vocaboo.entity.LearnerMastery;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.ZoneId;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class DailyGoalService {

    private final DailyGoalRepository dailyGoalRepository;
    private final LearnerRepository learnerRepository;
    private final LearnerMasteryRepository learnerMasteryRepository;

    @Transactional
    public DailyGoal getOrCreateGoal(UUID learnerId, LocalDate date) {
        return dailyGoalRepository.findByLearnerLearnerIdAndGoalDate(learnerId, date)
                .orElseGet(() -> {
                    Learner learner = learnerRepository.findById(learnerId)
                            .orElseThrow(() -> new EntityNotFoundException("Learner not found"));
                    DailyGoal newGoal = DailyGoal.builder()
                            .learner(learner)
                            .goalDate(date)
                            .targetCount(10)
                            .currentProgress(0)
                            .isCompleted(false)
                            .pointsAwarded(false)
                            .build();
                    return dailyGoalRepository.save(newGoal);
                });
    }

    @Transactional
    public DailyGoal incrementGoal(UUID learnerId, int amount) {
        LocalDate today = LocalDate.now(ZoneId.systemDefault());
        DailyGoal goal = getOrCreateGoal(learnerId, today);

        if (goal.getIsCompleted()) {
            return goal; // Already completed today
        }

        goal.setCurrentProgress(goal.getCurrentProgress() + amount);

        if (goal.getCurrentProgress() >= goal.getTargetCount()) {
            goal.setIsCompleted(true);
            
            // Award points
            if (!goal.getPointsAwarded()) {
                LearnerMastery mastery = learnerMasteryRepository.findByLearnerLearnerId(learnerId)
                        .orElseGet(() -> LearnerMastery.builder()
                                .learner(learnerRepository.getReferenceById(learnerId))
                                .overallAccuracy(0.0)
                                .masteryLevel("BEGINNER")
                                .totalPoints(0)
                                .build());

                mastery.setTotalPoints(mastery.getTotalPoints() + 50);
                learnerMasteryRepository.save(mastery);
                
                goal.setPointsAwarded(true);
            }
        }

        return dailyGoalRepository.save(goal);
    }
}
