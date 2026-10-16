package com.vocaboo.controller;

import com.vocaboo.dto.response.LearnerWrongAnswersResponse;
import com.vocaboo.dto.response.WrongAnswerAnalysisResponse;
import com.vocaboo.service.WrongAnswerReportingService;
import com.vocaboo.service.WrongAnswerTrackingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.security.Principal;
import java.util.Map;
import java.util.UUID;

@RestController
@RequiredArgsConstructor
public class WrongAnswerReportingController {

    private final WrongAnswerReportingService wrongAnswerReportingService;
    private final WrongAnswerTrackingService wrongAnswerTrackingService;

    @PostMapping("/api/v1/learners/wrong-answers/record")
    public ResponseEntity<Map<String, Object>> recordWrongAnswer(
            @RequestBody Map<String, Object> body,
            Principal principal) {
        UUID learnerId = body.get("learnerId") != null
                ? UUID.fromString(body.get("learnerId").toString())
                : (principal != null ? UUID.fromString(principal.getName()) : null);
        UUID wordId = body.get("wordId") != null ? UUID.fromString(body.get("wordId").toString()) : null;
        String wrongAnswer = body.get("wrongAnswer") != null ? body.get("wrongAnswer").toString() : "";
        String activityFormat = body.get("activityFormat") != null ? body.get("activityFormat").toString() : "MULTIPLE_CHOICE";
        String errorType = body.get("errorType") != null ? body.get("errorType").toString() : null;

        if (learnerId != null && wordId != null) {
            wrongAnswerTrackingService.trackWrongAnswer(learnerId, wordId, wrongAnswer, activityFormat, errorType);
        }
        return ResponseEntity.ok(Map.of("recorded", true));
    }

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
    public ResponseEntity<WrongAnswerAnalysisResponse> getClassWrongAnswerAnalysis(
            @org.springframework.web.bind.annotation.RequestParam(required = false) UUID sectionId,
            @org.springframework.web.bind.annotation.RequestParam(required = false) com.vocaboo.entity.GradeLevel gradeLevel,
            @org.springframework.web.bind.annotation.RequestParam(required = false) String cohortType,
            org.springframework.security.core.Authentication auth) {

        UUID teacherId = isTeacher(auth) ? parseUserId(auth) : null;
        WrongAnswerAnalysisResponse response =
                wrongAnswerReportingService.getClassWideWrongAnswerAnalysis(sectionId, gradeLevel, cohortType, teacherId);
        return ResponseEntity.ok(response);
    }

    private UUID parseUserId(org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getName() == null) return null;
        try {
            return UUID.fromString(auth.getName());
        } catch (Exception e) {
            return null;
        }
    }

    private boolean isTeacher(org.springframework.security.core.Authentication auth) {
        if (auth == null) return false;
        return auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_TEACHER"));
    }
}
