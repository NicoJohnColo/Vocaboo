package com.vocaboo.controller;

import com.vocaboo.dto.request.CreateCategoryRequest;
import com.vocaboo.dto.request.UpdateCategoryRequest;
import com.vocaboo.entity.VocabularyCategory;
import com.vocaboo.service.CategoryManagementService;
import com.vocaboo.service.LessonReorderingService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;


import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admin/categories")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminCategoryController {

    private final CategoryManagementService categoryManagementService;
    private final LessonReorderingService lessonReorderingService;

    /** GET /api/admin/categories — List all categories */
    @GetMapping
    public ResponseEntity<List<Map<String, Object>>> getAllCategories() {
        List<Map<String, Object>> result = categoryManagementService.getAllCategories().stream()
                .map(this::toMap)
                .collect(Collectors.toList());
        return ResponseEntity.ok(result);
    }

    /** POST /api/admin/categories — Create new category */
    @PostMapping
    public ResponseEntity<Map<String, Object>> createCategory(
            @Valid @RequestBody CreateCategoryRequest req) {
        VocabularyCategory created = categoryManagementService.createCategory(req);
        return ResponseEntity.status(HttpStatus.CREATED).body(toMap(created));
    }

    /** PUT /api/admin/categories/{id} — Update category */
    @PutMapping("/{id}")
    public ResponseEntity<Map<String, Object>> updateCategory(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateCategoryRequest req) {
        VocabularyCategory updated = categoryManagementService.updateCategory(id, req);
        return ResponseEntity.ok(toMap(updated));
    }

    /** DELETE /api/admin/categories/{id} — Delete category (fails if lessons exist) */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteCategory(@PathVariable UUID id) {
        categoryManagementService.deleteCategory(id);
        return ResponseEntity.noContent().build();
    }

    /** POST /api/admin/categories/reorder — Bulk reorder */
    @PostMapping("/reorder")
    public ResponseEntity<Map<String, String>> reorder(
            @RequestBody Map<String, Integer> reorderMap) {
        categoryManagementService.reorderCategories(reorderMap);
        return ResponseEntity.ok(Map.of("status", "reordered"));
    }

    /** POST /api/admin/categories/{id}/reorder-lessons — Bulk reorder lessons in a category */
    @PostMapping("/{id}/reorder-lessons")
    public ResponseEntity<Map<String, String>> reorderLessons(
            @PathVariable UUID id,
            @RequestBody Map<String, Integer> lessonOrders) {
        lessonReorderingService.reorderLessonsInCategory(lessonOrders);
        return ResponseEntity.ok(Map.of("status", "reordered"));
    }

    private Map<String, Object> toMap(VocabularyCategory c) {
        java.util.Map<String, Object> map = new java.util.HashMap<>();
        map.put("category_id", c.getCategoryId());
        map.put("category_name", c.getCategoryName());
        map.put("description", c.getDescription() != null ? c.getDescription() : "");
        map.put("sort_order", c.getSortOrder() != null ? c.getSortOrder() : 0);
        map.put("created_at", c.getCreatedAt());
        return map;
    }
}
