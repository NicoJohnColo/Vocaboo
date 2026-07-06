package com.vocaboo.service;

import com.vocaboo.entity.Lesson;
import com.vocaboo.repository.LessonRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class LessonReorderingService {

    private final LessonRepository lessonRepository;

    /**
     * Move a single lesson to a new position within its category.
     * Shifts siblings to maintain uniqueness.
     */
    @Transactional
    public void updateLessonOrder(UUID lessonId, int newOrder) {
        Lesson lesson = lessonRepository.findById(lessonId)
                .filter(l -> !Boolean.TRUE.equals(l.getIsDeleted()))
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Lesson not found"));

        UUID categoryId = lesson.getCategory().getCategoryId();
        int oldOrder = lesson.getLessonOrder();

        if (oldOrder == newOrder) return;

        // Shift siblings to make room
        List<Lesson> siblings = lessonRepository.findByCategoryCategoryIdAndIsDeletedFalseOrderByLessonOrderAsc(categoryId);

        if (newOrder < oldOrder) {
            // Moving up: shift lessons between newOrder and oldOrder-1 down by 1
            siblings.stream()
                    .filter(s -> !s.getLessonId().equals(lessonId)
                            && s.getLessonOrder() >= newOrder
                            && s.getLessonOrder() < oldOrder)
                    .forEach(s -> {
                        s.setLessonOrder(s.getLessonOrder() + 1);
                        lessonRepository.save(s);
                    });
        } else {
            // Moving down: shift lessons between oldOrder+1 and newOrder up by 1
            siblings.stream()
                    .filter(s -> !s.getLessonId().equals(lessonId)
                            && s.getLessonOrder() > oldOrder
                            && s.getLessonOrder() <= newOrder)
                    .forEach(s -> {
                        s.setLessonOrder(s.getLessonOrder() - 1);
                        lessonRepository.save(s);
                    });
        }

        lesson.setLessonOrder(newOrder);
        lessonRepository.save(lesson);
    }

    /**
     * Bulk reorder lessons in a category.
     * Request: { "lessonId1": 1, "lessonId2": 3, "lessonId3": 2 }
     */
    @Transactional
    public void reorderLessonsInCategory(Map<String, Integer> lessonOrders) {
        lessonOrders.forEach((idStr, order) -> {
            UUID id = UUID.fromString(idStr);
            lessonRepository.findById(id).ifPresent(lesson -> {
                lesson.setLessonOrder(order);
                lessonRepository.save(lesson);
            });
        });
    }
}
