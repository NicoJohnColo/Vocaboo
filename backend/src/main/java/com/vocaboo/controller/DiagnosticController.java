package com.vocaboo.controller;

import com.vocaboo.dto.request.DiagnosticRequest;
import com.vocaboo.dto.response.DiagnosticResponse;
import com.vocaboo.service.DiagnosticService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.security.Principal;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/diagnostic")
@RequiredArgsConstructor
public class DiagnosticController {

    private final DiagnosticService diagnosticService;

    @PostMapping
    public ResponseEntity<DiagnosticResponse> submitDiagnostic(
            @Valid @RequestBody DiagnosticRequest request,
            Principal principal) {
        UUID learnerId = UUID.fromString(principal.getName());
        return ResponseEntity.ok(diagnosticService.submitDiagnostic(learnerId, request));
    }
}
