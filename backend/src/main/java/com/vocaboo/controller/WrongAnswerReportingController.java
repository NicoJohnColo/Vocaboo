package com.vocaboo.controller;

import com.vocaboo.dto.response.LearnerWrongAnswersResponse;
import com.vocaboo.dto.response.WrongAnswerAnalysisResponse;
import com.vocaboo.service.WrongAnswerReportingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.security.Principal;
import java.util.UUID;

@RestController
@RequiredArgsConstructor
public class WrongAnswerReportingController {

    private final WrongAnswerReportingService wrongAnswerReportingService;

    /**
     * Learner endpoint — returns the calling learner's wrong answer history
     * and demerit point total.
     *
     * Authentication: ROLE_LEARNER (JWT).
     * Endpoint: GET /api/v1/learners/wrong-answers
     */
    @GetMapping("/api/v1/learners/wrong-answers")
    public ResponseEntity<LearnerWrongAnswersResponse> getLearnerWrongAnswers(Principal principal) {
        UUID learnerId = UUID.fromString(principal.getName());
        LearnerWrongAnswersResponse response =
                wrongAnswerReportingService.getLearnerWrongAnswers(learnerId);
        return ResponseEntity.ok(response);
    }

    /**
     * Admin endpoint — returns class-wide wrong answer patterns for teachers.
     *
     * Authentication: ROLE_ADMIN (JWT). Security is enforced by the wildcard
     * rule .requestMatchers("/api/admin/**").hasRole("ADMIN") in SecurityConfig.
     * Endpoint: GET /api/admin/reports/wrong-answers
     */
    @GetMapping("/api/admin/reports/wrong-answers")
    public ResponseEntity<WrongAnswerAnalysisResponse> getClassWrongAnswerAnalysis() {
        WrongAnswerAnalysisResponse response =
                wrongAnswerReportingService.getClassWideWrongAnswerAnalysis();
        return ResponseEntity.ok(response);
    }
}
