package com.vocaboo.repository;

import com.vocaboo.entity.Admin;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface AdminRepository extends JpaRepository<Admin, UUID> {

    Optional<Admin> findByUsername(String username);

    Optional<Admin> findByEmail(String email);

    Optional<Admin> findByPasswordResetToken(String passwordResetToken);

    List<Admin> findBySchoolId(UUID schoolId);

    List<Admin> findBySchoolIdAndIsActive(UUID schoolId, Boolean isActive);
}
