package com.vocaboo.backend.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.vocaboo.backend.model.Learner;

@Repository
public interface LearnerRepository extends JpaRepository<Learner, Long> {
    Optional<Learner> findByName(String name);
}
