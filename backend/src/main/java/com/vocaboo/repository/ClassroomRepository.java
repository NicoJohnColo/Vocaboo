package com.vocaboo.repository;

import com.vocaboo.entity.Classroom;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ClassroomRepository extends JpaRepository<Classroom, UUID> {

    @Override
    @EntityGraph(attributePaths = {"teacher"})
    Optional<Classroom> findById(UUID id);

    @EntityGraph(attributePaths = {"teacher"})
    Optional<Classroom> findByClassCode(String classCode);

    boolean existsByClassCode(String classCode);

    @Query("SELECT c FROM Classroom c LEFT JOIN FETCH c.teacher WHERE c.teacher.teacherId = :teacherId")
    List<Classroom> findByTeacherTeacherId(@Param("teacherId") UUID teacherId);

    @Query("SELECT c FROM Classroom c LEFT JOIN FETCH c.teacher WHERE c.teacher.teacherId = :teacherId ORDER BY c.createdAt DESC")
    List<Classroom> findByTeacherTeacherIdOrderByCreatedAtDesc(@Param("teacherId") UUID teacherId);

    @Query("SELECT c FROM Classroom c LEFT JOIN FETCH c.teacher WHERE c.teacher.teacherId = :teacherId ORDER BY c.name ASC")
    List<Classroom> findByTeacherTeacherIdOrderByNameAsc(@Param("teacherId") UUID teacherId);

    @Query("SELECT c FROM Classroom c LEFT JOIN FETCH c.teacher ORDER BY c.createdAt DESC")
    List<Classroom> findAllByOrderByCreatedAtDesc();

    @Query("SELECT c FROM Classroom c LEFT JOIN FETCH c.teacher ORDER BY c.name ASC")
    List<Classroom> findAllByOrderByNameAsc();

    @org.springframework.data.jpa.repository.Modifying
    @Query("UPDATE VocabularyCategory v SET v.classroom = null WHERE v.classroom.classId = :classId")
    void unlinkCategories(@Param("classId") UUID classId);

    @org.springframework.data.jpa.repository.Modifying
    @Query("UPDATE SessionSummary s SET s.classroom = null WHERE s.classroom.classId = :classId")
    void unlinkSessionSummaries(@Param("classId") UUID classId);

    @org.springframework.data.jpa.repository.Modifying
    @Query("UPDATE PointTransaction p SET p.classroom = null WHERE p.classroom.classId = :classId")
    void unlinkPointTransactions(@Param("classId") UUID classId);

    @org.springframework.data.jpa.repository.Modifying
    @Query("UPDATE LessonModuleScore l SET l.classroom = null WHERE l.classroom.classId = :classId")
    void unlinkLessonModuleScores(@Param("classId") UUID classId);

    @org.springframework.data.jpa.repository.Modifying
    @Query("UPDATE Lesson l SET l.classroom = null, l.isDeleted = true WHERE l.classroom.classId = :classId")
    void unlinkAndSoftDeleteLessons(@Param("classId") UUID classId);
}

