package com.vocaboo.service;

import com.vocaboo.entity.SessionSummary;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class MasteryReviewService {

    private final SessionSummaryService summaryService;
    private final MasteryBadgeService badgeService;

    @Transactional
    public SessionSummary completeSession(UUID learnerId, UUID sessionId, UUID lessonId) {
        // Aggregate statistics and save session summary
        SessionSummary summary = summaryService.saveSessionSummary(learnerId, sessionId, lessonId);

        // Compute and save reward badge based on session accuracy rate
        double accuracy = summary.getAccuracyRate() != null ? summary.getAccuracyRate().doubleValue() : 0.0;
        badgeService.calculateAndSaveBadge(learnerId, lessonId, accuracy);

        return summary;
    }
}
