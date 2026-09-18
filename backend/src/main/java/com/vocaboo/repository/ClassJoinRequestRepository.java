package com.vocaboo.repository;

import com.vocaboo.entity.ClassJoinRequest;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ClassJoinRequestRepository extends JpaRepository<ClassJoinRequest, UUID> {

    @EntityGraph(attributePaths = {"learner"})
    List<ClassJoinRequest> findByClassroomClassIdAndStatusOrderByCreatedAtDesc(UUID classId, String status);

    List<ClassJoinRequest> findByLearnerLearnerIdOrderByCreatedAtDesc(UUID learnerId);

    Optional<ClassJoinRequest> findByClassroomClassIdAndLearnerLearnerIdAndStatus(UUID classId, UUID learnerId, String status);

    boolean existsByClassroomClassIdAndLearnerLearnerIdAndStatus(UUID classId, UUID learnerId, String status);
}
