package com.vocaboo.controller;

import com.vocaboo.dto.response.AdminAnalyticsDashboardResponse;
import com.vocaboo.dto.response.AdminDemographicsResponse;
import com.vocaboo.dto.response.AdminLeaderboardStatsResponse;
import com.vocaboo.entity.GradeLevel;
import com.vocaboo.service.AdminAnalyticsService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/admin/analytics")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
@org.springframework.transaction.annotation.Transactional(readOnly = true)
public class AdminAnalyticsController {

    private final AdminAnalyticsService adminAnalyticsService;

    /**
     * GET /api/admin/analytics/dashboard
     * Returns comprehensive school-level, independent cohort, or class-level analytics payload.
     */
    @GetMapping("/dashboard")
    public ResponseEntity<AdminAnalyticsDashboardResponse> getDashboardAnalytics(
            @RequestParam(required = false) UUID sectionId,
            @RequestParam(required = false) GradeLevel gradeLevel,
            @RequestParam(defaultValue = "7d") String timeRange,
            @RequestParam(required = false) String cohortType,
            org.springframework.security.core.Authentication auth) {

        UUID teacherId = isTeacher(auth) ? parseUserId(auth) : null;
        AdminAnalyticsDashboardResponse response = adminAnalyticsService.getDashboardAnalytics(
                sectionId, gradeLevel, timeRange, cohortType, teacherId);
        return ResponseEntity.ok(response);
    }

    /**
     * GET /api/admin/analytics/demographics
     * Returns platform-wide demographics (Independent vs Enrolled, language preferences, grade distributions).
     */
    @GetMapping("/demographics")
    public ResponseEntity<AdminDemographicsResponse> getDemographics(
            org.springframework.security.core.Authentication auth) {
        UUID teacherId = isTeacher(auth) ? parseUserId(auth) : null;
        return ResponseEntity.ok(adminAnalyticsService.getGlobalDemographics(teacherId));
    }

    private final com.vocaboo.repository.ClassroomRepository classroomRepository;

    /**
     * GET /api/admin/analytics/leaderboard-stats
     * Returns gamification KPIs and live ranking table for weekly or all-time points.
     */
    @GetMapping("/leaderboard-stats")
    public ResponseEntity<AdminLeaderboardStatsResponse> getLeaderboardStats(
            @RequestParam(defaultValue = "weekly") String range,
            @RequestParam(required = false) String cohortType,
            @RequestParam(required = false) UUID sectionId,
            org.springframework.security.core.Authentication auth) {

        final UUID teacherId = isTeacher(auth) ? parseUserId(auth) : null;
        if (teacherId != null && sectionId != null) {
            boolean ownsClass = classroomRepository.findById(sectionId)
                    .map(c -> c.getTeacher() != null && teacherId.equals(c.getTeacher().getTeacherId()))
                    .orElse(false);
            if (!ownsClass) {
                return ResponseEntity.status(org.springframework.http.HttpStatus.FORBIDDEN).build();
            }
        }

        return ResponseEntity.ok(adminAnalyticsService.getLeaderboardStats(range, cohortType, sectionId, teacherId));
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
