package com.vocaboo.repository;

import com.vocaboo.entity.Learner;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface LearnerRepository extends JpaRepository<Learner, UUID> {
    Optional<Learner> findByDisplayNameIgnoreCase(String displayName);
}
