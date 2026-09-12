package com.vocaboo.repository;

import com.vocaboo.entity.Classroom;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ClassroomRepository extends JpaRepository<Classroom, UUID> {

    Optional<Classroom> findByClassCode(String classCode);

    boolean existsByClassCode(String classCode);

    List<Classroom> findByTeacherTeacherId(UUID teacherId);

    List<Classroom> findByTeacherTeacherIdOrderByCreatedAtDesc(UUID teacherId);

    List<Classroom> findByTeacherTeacherIdOrderByNameAsc(UUID teacherId);

    List<Classroom> findAllByOrderByCreatedAtDesc();

    List<Classroom> findAllByOrderByNameAsc();
}
