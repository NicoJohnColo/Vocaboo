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
            @RequestParam(required = false) String cohortType) {

        AdminAnalyticsDashboardResponse response = adminAnalyticsService.getDashboardAnalytics(
                sectionId, gradeLevel, timeRange, cohortType);
        return ResponseEntity.ok(response);
    }

    /**
     * GET /api/admin/analytics/demographics
     * Returns platform-wide demographics (Independent vs Enrolled, language preferences, grade distributions).
     */
    @GetMapping("/demographics")
    public ResponseEntity<AdminDemographicsResponse> getDemographics() {
        return ResponseEntity.ok(adminAnalyticsService.getGlobalDemographics());
    }

    /**
     * GET /api/admin/analytics/leaderboard-stats
     * Returns gamification KPIs and live ranking table for weekly or all-time points.
     */
    @GetMapping("/leaderboard-stats")
    public ResponseEntity<AdminLeaderboardStatsResponse> getLeaderboardStats(
            @RequestParam(defaultValue = "weekly") String range,
            @RequestParam(required = false) String cohortType,
            @RequestParam(required = false) UUID sectionId) {

        return ResponseEntity.ok(adminAnalyticsService.getLeaderboardStats(range, cohortType, sectionId));
    }
}
