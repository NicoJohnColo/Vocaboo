package com.vocaboo.repository;

import com.vocaboo.entity.Lesson;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface LessonRepository extends JpaRepository<Lesson, UUID> {

    // Learner-facing
    List<Lesson> findByCategoryCategoryIdOrderByLessonOrderAsc(UUID categoryId);
    List<Lesson> findByCategoryCategoryIdAndContentStatusAndIsDeletedFalseOrderByLessonOrderAsc(UUID categoryId, String contentStatus);
    Optional<Lesson> findByCategoryCategoryIdAndLessonOrder(UUID categoryId, Integer lessonOrder);

    // Admin-facing (soft-delete aware)
    List<Lesson> findByIsDeletedFalseOrderByLessonOrderAsc();
    List<Lesson> findByCategoryCategoryIdAndIsDeletedFalseOrderByLessonOrderAsc(UUID categoryId);

    @Query("SELECT COALESCE(MAX(l.lessonOrder), 0) FROM Lesson l WHERE l.category.categoryId = :categoryId AND l.isDeleted = false")
    int findMaxLessonOrderByCategoryId(@Param("categoryId") UUID categoryId);

    @Query("SELECT l FROM Lesson l WHERE l.category.categoryId = :categoryId AND l.isDeleted = false AND l.lessonOrder >= :order ORDER BY l.lessonOrder ASC")
    List<Lesson> findByCategoryAndOrderGreaterEqual(@Param("categoryId") UUID categoryId, @Param("order") int order);
}

