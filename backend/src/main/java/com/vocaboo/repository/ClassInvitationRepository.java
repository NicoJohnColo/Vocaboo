package com.vocaboo.repository;

import com.vocaboo.entity.ClassInvitation;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ClassInvitationRepository extends JpaRepository<ClassInvitation, UUID> {

    @EntityGraph(attributePaths = {"learner"})
    List<ClassInvitation> findByClassroomClassIdAndStatusOrderByCreatedAtDesc(UUID classId, String status);

    @EntityGraph(attributePaths = {"classroom", "sentByTeacher"})
    List<ClassInvitation> findByLearnerLearnerIdAndStatusOrderByCreatedAtDesc(UUID learnerId, String status);

    Optional<ClassInvitation> findByClassroomClassIdAndLearnerLearnerIdAndStatus(UUID classId, UUID learnerId, String status);

    boolean existsByClassroomClassIdAndLearnerLearnerIdAndStatus(UUID classId, UUID learnerId, String status);

    List<ClassInvitation> findByClassroomClassId(UUID classId);
}
