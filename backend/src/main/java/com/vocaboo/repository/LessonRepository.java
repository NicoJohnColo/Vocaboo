package com.vocaboo.repository;

import com.vocaboo.entity.Lesson;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface LessonRepository extends JpaRepository<Lesson, UUID> {

    @Override
    @EntityGraph(attributePaths = {"category", "classroom"})
    Optional<Lesson> findById(UUID id);

    @Override
    @EntityGraph(attributePaths = {"category", "classroom"})
    List<Lesson> findAll();

    // Learner-facing
    List<Lesson> findByCategoryCategoryIdOrderByLessonOrderAsc(UUID categoryId);

    @EntityGraph(attributePaths = {"category", "classroom"})
    List<Lesson> findByCategoryCategoryIdAndContentStatusAndIsDeletedFalseOrderByLessonOrderAsc(UUID categoryId, String contentStatus);

    @EntityGraph(attributePaths = {"category", "classroom"})
    List<Lesson> findByCategoryCategoryIdAndContentStatusAndIsDeletedFalseAndClassroomIsNullOrderByLessonOrderAsc(UUID categoryId, String contentStatus);

    Optional<Lesson> findByCategoryCategoryIdAndLessonOrder(UUID categoryId, Integer lessonOrder);

    // Class-scoped lessons
    @EntityGraph(attributePaths = {"category", "classroom"})
    List<Lesson> findByClassroomClassIdAndIsDeletedFalseOrderByLessonOrderAsc(UUID classId);

    @EntityGraph(attributePaths = {"category", "classroom"})
    List<Lesson> findByClassroomClassIdAndContentStatusAndIsDeletedFalseOrderByLessonOrderAsc(UUID classId, String contentStatus);

    // Admin-facing (soft-delete aware)
    @EntityGraph(attributePaths = {"category", "classroom"})
    List<Lesson> findByIsDeletedFalseOrderByLessonOrderAsc();

    @EntityGraph(attributePaths = {"category", "classroom"})
    List<Lesson> findByCategoryCategoryIdAndIsDeletedFalseOrderByLessonOrderAsc(UUID categoryId);

    @EntityGraph(attributePaths = {"category", "classroom"})
    List<Lesson> findByCategoryCategoryIdAndIsDeletedFalseAndClassroomIsNullOrderByLessonOrderAsc(UUID categoryId);

    @EntityGraph(attributePaths = {"category", "classroom"})
    List<Lesson> findByIsDeletedFalseAndClassroomIsNullOrderByLessonOrderAsc();

    @EntityGraph(attributePaths = {"category", "classroom"})
    List<Lesson> findByClassroomTeacherTeacherIdAndIsDeletedFalseOrderByLessonOrderAsc(UUID teacherId);

    @Query("SELECT DISTINCT l FROM Lesson l LEFT JOIN l.classroom c LEFT JOIN c.teacher ct WHERE l.isDeleted = false AND (ct.teacherId = :teacherId OR l.category.teacher.teacherId = :teacherId) ORDER BY l.lessonOrder ASC")
    List<Lesson> findVisibleLessonsForTeacher(@Param("teacherId") UUID teacherId);

    @Query("SELECT DISTINCT l FROM Lesson l LEFT JOIN l.classroom c LEFT JOIN c.teacher ct WHERE l.isDeleted = false AND l.category.categoryId = :categoryId AND (ct.teacherId = :teacherId OR l.category.teacher.teacherId = :teacherId) ORDER BY l.lessonOrder ASC")
    List<Lesson> findVisibleLessonsForTeacherByCategory(@Param("teacherId") UUID teacherId, @Param("categoryId") UUID categoryId);

    @Query("SELECT COALESCE(MAX(l.lessonOrder), 0) FROM Lesson l WHERE l.category.categoryId = :categoryId AND l.isDeleted = false")
    int findMaxLessonOrderByCategoryId(@Param("categoryId") UUID categoryId);

    @Query("SELECT l FROM Lesson l WHERE l.category.categoryId = :categoryId AND l.isDeleted = false AND l.lessonOrder >= :order ORDER BY l.lessonOrder ASC")
    List<Lesson> findByCategoryAndOrderGreaterEqual(@Param("categoryId") UUID categoryId, @Param("order") int order);
}

