package com.vocaboo.controller;

import com.vocaboo.dto.response.AdminTrustLayerStatsResponse;
import com.vocaboo.service.AdminTrustLayerService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/admin/trust-layer")
@RequiredArgsConstructor
public class AdminTrustLayerController {

    private final AdminTrustLayerService adminTrustLayerService;

    @GetMapping("/stats")
    public ResponseEntity<List<AdminTrustLayerStatsResponse>> getTrustLayerStats() {
        return ResponseEntity.ok(adminTrustLayerService.getTrustLayerStats());
    }
}
