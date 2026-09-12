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
    public SessionSummary completeSession(UUID learnerId, UUID sessionId, UUID lessonId, Double score,
                                          Boolean isPerfectFirstAttempt, UUID classroomContextId) {
        SessionSummary summary = summaryService.saveSessionSummary(
                learnerId, sessionId, lessonId, score, isPerfectFirstAttempt, classroomContextId);
        badgeService.calculateAndSaveBadge(learnerId, lessonId);
        return summary;
    }

    @Transactional
    public SessionSummary completeSession(UUID learnerId, UUID sessionId, UUID lessonId, Double score,
                                          Boolean isPerfectFirstAttempt) {
        return completeSession(learnerId, sessionId, lessonId, score, isPerfectFirstAttempt, null);
    }

    @Transactional
    public SessionSummary completeSession(UUID learnerId, UUID sessionId, UUID lessonId) {
        return completeSession(learnerId, sessionId, lessonId, null, null, null);
    }
}
