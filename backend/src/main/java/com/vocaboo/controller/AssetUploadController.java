package com.vocaboo.controller;

import com.vocaboo.service.AssetUploadService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/admin/assets")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
public class AssetUploadController {

    private final AssetUploadService assetUploadService;

    /**
     * POST /api/admin/assets/upload
     * Params: file (multipart), asset_type (AUDIO|IMAGE), lesson_id (required), word_id (optional)
     */
    @PostMapping("/upload")
    public ResponseEntity<Map<String, Object>> uploadAsset(
            @RequestParam("file") MultipartFile file,
            @RequestParam("asset_type") String assetType,
            @RequestParam("lesson_id") UUID lessonId,
            @RequestParam(value = "word_id", required = false) UUID wordId,
            Authentication auth) throws IOException {

        UUID adminId = UUID.fromString(auth.getName());
        Map<String, Object> result;

        if ("AUDIO".equalsIgnoreCase(assetType)) {
            result = assetUploadService.uploadAudio(file, lessonId, wordId, adminId);
        } else if ("IMAGE".equalsIgnoreCase(assetType)) {
            result = assetUploadService.uploadImage(file, lessonId, wordId, adminId);
        } else {
            return ResponseEntity.badRequest().body(Map.of("error", "asset_type must be AUDIO or IMAGE"));
        }

        return ResponseEntity.ok(result);
    }

    /**
     * DELETE /api/admin/assets/{assetId} — Delete an uploaded asset
     */
    @DeleteMapping("/{assetId}")
    public ResponseEntity<Void> deleteAsset(@PathVariable UUID assetId) {
        assetUploadService.deleteAsset(assetId);
        return ResponseEntity.noContent().build();
    }

    /**
     * GET /api/admin/assets/verify?url=... — Verify a file URL is accessible
     */
    @GetMapping("/verify")
    public ResponseEntity<Map<String, Object>> verifyUrl(@RequestParam String url) {
        return ResponseEntity.ok(assetUploadService.verifyUrl(url));
    }
}
