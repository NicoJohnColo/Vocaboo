package com.vocaboo.repository;

import com.vocaboo.entity.Classroom;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
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

    @EntityGraph(attributePaths = {"teacher"})
    List<Classroom> findByTeacherTeacherId(UUID teacherId);

    @EntityGraph(attributePaths = {"teacher"})
    List<Classroom> findByTeacherTeacherIdOrderByCreatedAtDesc(UUID teacherId);

    @EntityGraph(attributePaths = {"teacher"})
    List<Classroom> findByTeacherTeacherIdOrderByNameAsc(UUID teacherId);

    @EntityGraph(attributePaths = {"teacher"})
    List<Classroom> findAllByOrderByCreatedAtDesc();

    @EntityGraph(attributePaths = {"teacher"})
    List<Classroom> findAllByOrderByNameAsc();
}

