package com.vocaboo.service;

import com.vocaboo.dto.response.LeaderboardEntryResponse;
import com.vocaboo.entity.LearnerMastery;
import com.vocaboo.repository.LearnerMasteryRepository;
import com.vocaboo.repository.PointTransactionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class LeaderboardService {

    private final LearnerMasteryRepository masteryRepository;
    private final PointTransactionRepository pointTransactionRepository;

    @Transactional(readOnly = true)
    public List<LeaderboardEntryResponse> getLeaderboard(String range) {
        List<LeaderboardEntryResponse> leaderboard = new ArrayList<>();
        
        if ("weekly".equalsIgnoreCase(range)) {
            List<LearnerMastery> masteries = masteryRepository.findAll();
            OffsetDateTime oneWeekAgo = OffsetDateTime.now().minusDays(7);
            
            for (LearnerMastery mastery : masteries) {
                int weeklyPoints = pointTransactionRepository.sumPointsByLearnerAndDateAfter(
                        mastery.getLearner().getLearnerId(), oneWeekAgo);
                
                if (weeklyPoints > 0) {
                    leaderboard.add(LeaderboardEntryResponse.builder()
                            .learnerId(mastery.getLearner().getLearnerId())
                            .displayName(mastery.getLearner().getDisplayName())
                            .avatar(mastery.getLearner().getAvatar())
                            .points(weeklyPoints)
                            .tier(resolveLeagueTier(weeklyPoints, mastery.getMasteryLevel()))
                            .build());
                }
            }
        } else {
            List<LearnerMastery> masteries = masteryRepository.findAll();
            for (LearnerMastery mastery : masteries) {
                if (mastery.getTotalPoints() > 0) {
                    leaderboard.add(LeaderboardEntryResponse.builder()
                            .learnerId(mastery.getLearner().getLearnerId())
                            .displayName(mastery.getLearner().getDisplayName())
                            .avatar(mastery.getLearner().getAvatar())
                            .points(mastery.getTotalPoints())
                            .tier(resolveLeagueTier(mastery.getTotalPoints(), mastery.getMasteryLevel()))
                            .build());
                }
            }
        }
        
        leaderboard.sort((a, b) -> Integer.compare(b.getPoints(), a.getPoints()));
        
        int rank = 1;
        for (LeaderboardEntryResponse entry : leaderboard) {
            entry.setRank(rank++);
        }
        
        if (leaderboard.size() > 50) {
            leaderboard = leaderboard.subList(0, 50);
        }
        
        return leaderboard;
    }

    private String resolveLeagueTier(int points, String masteryLevel) {
        if (points >= 3500 || "MASTERED".equalsIgnoreCase(masteryLevel)) {
            return "DIAMOND";
        } else if (points >= 2500 || "PROFICIENT".equalsIgnoreCase(masteryLevel)) {
            return "GOLD";
        } else if (points >= 1000 || "FAMILIAR".equalsIgnoreCase(masteryLevel)) {
            return "SILVER";
        } else {
            return "BRONZE";
        }
    }
}
