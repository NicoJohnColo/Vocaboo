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
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/admin/lessons/{lessonId}/vocabulary")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('ADMIN', 'TEACHER')")
public class AdminVocabularyController {

    private final VocabularyManagementService vocabularyManagementService;
    private final BulkImportService bulkImportService;
    private final com.vocaboo.repository.LessonRepository lessonRepository;

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
            @Valid @RequestBody AddVocabularyRequest req,
            Authentication auth) {
        checkLessonModifyPermission(lessonId, auth);
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
            @Valid @RequestBody UpdateVocabularyRequest req,
            Authentication auth) {
        checkLessonModifyPermission(lessonId, auth);
        return ResponseEntity.ok(vocabularyManagementService.updateWord(lessonId, wordId, req));
    }

    /**
     * DELETE /api/admin/lessons/{lessonId}/vocabulary/{wordId} — Soft-delete a word
     */
    @DeleteMapping("/{wordId}")
    public ResponseEntity<Void> deleteWord(
            @PathVariable UUID lessonId,
            @PathVariable UUID wordId,
            Authentication auth) {
        checkLessonModifyPermission(lessonId, auth);
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
        checkLessonModifyPermission(lessonId, auth);
        UUID adminId = UUID.fromString(auth.getName());
        Map<String, Object> result = bulkImportService.parseAndImportCSV(lessonId, file.getInputStream(), adminId, dryRun);
        return ResponseEntity.ok(result);
    }

    /**
     * GET /api/admin/lessons/{lessonId}/vocabulary/bulk-import/template — Download CSV template
     */
    @GetMapping("/bulk-import/template")
    @Transactional(readOnly = true)
    public ResponseEntity<byte[]> downloadTemplate(@PathVariable UUID lessonId) {
        String csv = bulkImportService.getCsvTemplate(lessonId);
        byte[] bytes = csv.getBytes(java.nio.charset.StandardCharsets.UTF_8);

        String filename = "vocabulary_import_template.csv";
        com.vocaboo.entity.Lesson lesson = lessonRepository.findById(lessonId).orElse(null);
        if (lesson != null && lesson.getLessonTitle() != null && !lesson.getLessonTitle().isBlank()) {
            String sanitized = lesson.getLessonTitle()
                    .toLowerCase()
                    .replaceAll("[^a-z0-9]+", "_")
                    .replaceAll("^_+|_+$", "");
            if (!sanitized.isBlank()) {
                filename = "lesson_" + sanitized + "_template.csv";
            }
        }

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.parseMediaType("text/csv; charset=UTF-8"));
        headers.setContentDisposition(org.springframework.http.ContentDisposition.attachment().filename(filename).build());
        return ResponseEntity.ok().headers(headers).body(bytes);
    }

    private void checkLessonModifyPermission(UUID lessonId, Authentication auth) {
        com.vocaboo.entity.Lesson lesson = lessonRepository.findById(lessonId)
                .orElseThrow(() -> new org.springframework.web.server.ResponseStatusException(HttpStatus.NOT_FOUND, "Lesson not found"));
        boolean isTeacherLesson = lesson.getClassroom() != null
                || (lesson.getCategory() != null && lesson.getCategory().getTeacher() != null);
        if (isTeacherLesson) {
            boolean isTeacher = auth != null && auth.getAuthorities().stream()
                    .anyMatch(a -> a.getAuthority().equals("ROLE_TEACHER"));
            if (!isTeacher) {
                throw new org.springframework.security.access.AccessDeniedException(
                        "Main admin cannot modify vocabulary words in teacher-authored classroom lessons.");
            }
            UUID teacherId = parseTeacherId(auth);
            UUID ownerTeacherId = lesson.getClassroom() != null && lesson.getClassroom().getTeacher() != null
                    ? lesson.getClassroom().getTeacher().getTeacherId()
                    : (lesson.getCategory() != null && lesson.getCategory().getTeacher() != null
                        ? lesson.getCategory().getTeacher().getTeacherId()
                        : null);
            if (teacherId == null || !teacherId.equals(ownerTeacherId)) {
                throw new org.springframework.security.access.AccessDeniedException(
                        "You do not have permission to modify vocabulary words in this lesson.");
            }
        }
    }

    private UUID parseTeacherId(Authentication auth) {
        if (auth == null || auth.getName() == null) return null;
        try {
            return UUID.fromString(auth.getName());
        } catch (Exception e) {
            return null;
        }
    }
}
