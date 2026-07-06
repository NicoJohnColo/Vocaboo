package com.vocaboo.controller;

import com.vocaboo.dto.request.AddVocabularyRequest;
import com.vocaboo.dto.request.UpdateVocabularyRequest;
import com.vocaboo.dto.response.AdminVocabularyResponse;
import com.vocaboo.service.BulkImportService;
import com.vocaboo.service.VocabularyManagementService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/admin/lessons/{lessonId}/vocabulary")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminVocabularyController {

    private final VocabularyManagementService vocabularyManagementService;
    private final BulkImportService bulkImportService;

    /**
     * GET /api/admin/lessons/{lessonId}/vocabulary — List words in lesson
     */
    @GetMapping
    public ResponseEntity<List<AdminVocabularyResponse>> getWords(@PathVariable UUID lessonId) {
        return ResponseEntity.ok(vocabularyManagementService.getWordsForLesson(lessonId));
    }

    /**
     * POST /api/admin/lessons/{lessonId}/vocabulary — Add word to lesson
     */
    @PostMapping
    public ResponseEntity<AdminVocabularyResponse> addWord(
            @PathVariable UUID lessonId,
            @Valid @RequestBody AddVocabularyRequest req) {
        AdminVocabularyResponse created = vocabularyManagementService.addWord(lessonId, req);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    /**
     * PUT /api/admin/lessons/{lessonId}/vocabulary/{wordId} — Update a word
     */
    @PutMapping("/{wordId}")
    public ResponseEntity<AdminVocabularyResponse> updateWord(
            @PathVariable UUID lessonId,
            @PathVariable UUID wordId,
            @Valid @RequestBody UpdateVocabularyRequest req) {
        return ResponseEntity.ok(vocabularyManagementService.updateWord(lessonId, wordId, req));
    }

    /**
     * DELETE /api/admin/lessons/{lessonId}/vocabulary/{wordId} — Soft-delete a word
     */
    @DeleteMapping("/{wordId}")
    public ResponseEntity<Void> deleteWord(
            @PathVariable UUID lessonId,
            @PathVariable UUID wordId) {
        vocabularyManagementService.deleteWord(lessonId, wordId);
        return ResponseEntity.noContent().build();
    }

    /**
     * POST /api/admin/lessons/{lessonId}/vocabulary/bulk-import — Upload CSV file
     */
    @PostMapping("/bulk-import")
    public ResponseEntity<Map<String, Object>> bulkImport(
            @PathVariable UUID lessonId,
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "dryRun", defaultValue = "false") boolean dryRun,
            Authentication auth) throws IOException {
        UUID adminId = UUID.fromString(auth.getName());
        Map<String, Object> result = bulkImportService.parseAndImportCSV(lessonId, file.getInputStream(), adminId, dryRun);
        return ResponseEntity.ok(result);
    }

    /**
     * GET /api/admin/lessons/{lessonId}/vocabulary/bulk-import/template — Download CSV template
     */
    @GetMapping("/bulk-import/template")
    public ResponseEntity<byte[]> downloadTemplate(@PathVariable UUID lessonId) {
        String csv = bulkImportService.getCsvTemplate();
        byte[] bytes = csv.getBytes();
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.parseMediaType("text/csv"));
        headers.setContentDispositionFormData("attachment", "vocabulary_import_template.csv");
        return ResponseEntity.ok().headers(headers).body(bytes);
    }
}
