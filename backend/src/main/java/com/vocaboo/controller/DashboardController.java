package com.vocaboo.controller;

import com.vocaboo.dto.response.DashboardResponse;
import com.vocaboo.service.DashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.security.Principal;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/dashboard")
@RequiredArgsConstructor
public class DashboardController {

    private final DashboardService dashboardService;

    @GetMapping("/progress")
    public ResponseEntity<DashboardResponse> getDashboardProgress(Principal principal) {
        UUID learnerId = UUID.fromString(principal.getName());
        DashboardResponse response = dashboardService.getDashboardData(learnerId);
        return ResponseEntity.ok(response);
    }
}
