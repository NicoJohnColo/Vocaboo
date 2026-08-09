package com.vocaboo.repository;

import com.vocaboo.entity.Teacher;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface TeacherRepository extends JpaRepository<Teacher, UUID> {

    Optional<Teacher> findByEmail(String email);

    boolean existsByEmail(String email);

    Optional<Teacher> findByUsername(String username);

    boolean existsByUsername(String username);

    Optional<Teacher> findByPasswordResetToken(String token);
}
