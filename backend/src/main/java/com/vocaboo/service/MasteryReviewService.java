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
        // Compute and save reward badge
        badgeService.calculateAndSaveBadge(learnerId, lessonId);

        // Aggregate statistics and save session summary
        return summaryService.saveSessionSummary(learnerId, sessionId, lessonId);
    }
}
