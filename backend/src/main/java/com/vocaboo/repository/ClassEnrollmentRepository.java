package com.vocaboo.repository;

import com.vocaboo.entity.ClassEnrollment;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ClassEnrollmentRepository extends JpaRepository<ClassEnrollment, UUID> {

    @EntityGraph(attributePaths = {"learner"})
    List<ClassEnrollment> findByClassroomClassIdAndStatus(UUID classId, String status);

    @EntityGraph(attributePaths = {"classroom", "classroom.teacher"})
    List<ClassEnrollment> findByLearnerLearnerIdAndStatus(UUID learnerId, String status);

    Optional<ClassEnrollment> findByClassroomClassIdAndLearnerLearnerId(UUID classId, UUID learnerId);

    boolean existsByClassroomClassIdAndLearnerLearnerIdAndStatus(UUID classId, UUID learnerId, String status);

    long countByClassroomClassIdAndStatus(UUID classId, String status);

    @org.springframework.data.jpa.repository.Query("SELECT DISTINCT e.learner.learnerId FROM ClassEnrollment e WHERE e.classroom.teacher.teacherId = :teacherId AND e.status = 'ACTIVE'")
    List<UUID> findEnrolledLearnerIdsByTeacherId(@org.springframework.data.repository.query.Param("teacherId") UUID teacherId);

    @org.springframework.data.jpa.repository.Query("SELECT DISTINCT e.learner.learnerId FROM ClassEnrollment e WHERE e.classroom.classId = :classId AND e.status = 'ACTIVE'")
    List<UUID> findEnrolledLearnerIdsByClassId(@org.springframework.data.repository.query.Param("classId") UUID classId);
}
