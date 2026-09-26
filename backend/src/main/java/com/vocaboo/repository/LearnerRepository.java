package com.vocaboo.repository;

import com.vocaboo.entity.GradeLevel;
import com.vocaboo.entity.Learner;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface LearnerRepository extends JpaRepository<Learner, UUID>, JpaSpecificationExecutor<Learner> {
    Optional<Learner> findByDisplayNameIgnoreCase(String displayName);

    @org.springframework.data.jpa.repository.Query("SELECT l FROM Learner l WHERE l.isActive = true AND (LOWER(l.displayName) LIKE LOWER(CONCAT('%', :query, '%')) OR LOWER(l.userId) LIKE LOWER(CONCAT('%', :query, '%')))")
    List<Learner> searchActiveLearnersByDisplayNameOrUserId(@org.springframework.data.repository.query.Param("query") String query);

    boolean existsByDisplayNameIgnoreCase(String displayName);

    boolean existsByDisplayNameIgnoreCaseAndLearnerIdNot(String displayName, UUID learnerId);

    Optional<Learner> findByUserId(String userId);

    Optional<Learner> findByUserIdIgnoreCase(String userId);

    boolean existsByUserId(String userId);

    List<Learner> findBySectionSectionId(UUID sectionId);

    List<Learner> findBySectionSectionIdAndIsActiveTrue(UUID sectionId);

    List<Learner> findBySectionIsNullAndIsActiveTrue();

    List<Learner> findBySectionIsNotNullAndIsActiveTrue();

    List<Learner> findByGradeLevelAndIsActiveTrue(GradeLevel gradeLevel);

    List<Learner> findByIsActiveTrue();

    long countByIsActiveTrue();

    long countBySectionSectionId(UUID sectionId);

    long countBySectionSectionIdAndIsActiveTrue(UUID sectionId);

    long countBySectionIsNullAndIsActiveTrue();

    long countBySectionIsNotNullAndIsActiveTrue();

    long countByGradeLevelAndIsActiveTrue(GradeLevel gradeLevel);
}
