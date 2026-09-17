package com.vocaboo.repository;

import com.vocaboo.entity.DailyGoal;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DailyGoalRepository extends JpaRepository<DailyGoal, UUID> {
    Optional<DailyGoal> findByLearnerLearnerIdAndGoalDate(UUID learnerId, LocalDate goalDate);
}
