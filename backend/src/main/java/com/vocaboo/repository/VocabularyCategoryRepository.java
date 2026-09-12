package com.vocaboo.repository;

import com.vocaboo.entity.VocabularyCategory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface VocabularyCategoryRepository extends JpaRepository<VocabularyCategory, UUID> {
    List<VocabularyCategory> findAllByOrderBySortOrderAsc();

    // Global categories (Admin managed)
    List<VocabularyCategory> findByTeacherIsNullOrderBySortOrderAsc();
    List<VocabularyCategory> findByTeacherIsNullAndClassroomIsNullOrderBySortOrderAsc();
    boolean existsByCategoryNameIgnoreCaseAndTeacherIsNull(String categoryName);
    boolean existsByCategoryNameIgnoreCaseAndTeacherIsNullAndClassroomIsNull(String categoryName);

    @Query("SELECT COALESCE(MAX(c.sortOrder), 0) FROM VocabularyCategory c WHERE c.teacher IS NULL AND c.classroom IS NULL")
    int findMaxSortOrderGlobal();

    // Teacher-scoped categories
    List<VocabularyCategory> findByTeacherTeacherIdOrderBySortOrderAsc(UUID teacherId);
    List<VocabularyCategory> findByTeacherTeacherIdAndClassroomClassIdOrderBySortOrderAsc(UUID teacherId, UUID classId);
    boolean existsByCategoryNameIgnoreCaseAndTeacherTeacherId(String categoryName, UUID teacherId);
    boolean existsByCategoryNameIgnoreCaseAndClassroomClassId(String categoryName, UUID classId);

    // Classroom-scoped categories
    List<VocabularyCategory> findByClassroomClassIdOrderBySortOrderAsc(UUID classId);

    @Query("SELECT COALESCE(MAX(c.sortOrder), 0) FROM VocabularyCategory c WHERE c.classroom.classId = :classId")
    int findMaxSortOrderByClassroomId(@Param("classId") UUID classId);

    @Query("SELECT COALESCE(MAX(c.sortOrder), 0) FROM VocabularyCategory c WHERE c.teacher.teacherId = :teacherId")
    int findMaxSortOrderByTeacherId(@Param("teacherId") UUID teacherId);

    boolean existsByCategoryNameIgnoreCase(String categoryName);

    @Query("SELECT COALESCE(MAX(c.sortOrder), 0) FROM VocabularyCategory c")
    int findMaxSortOrder();
}

