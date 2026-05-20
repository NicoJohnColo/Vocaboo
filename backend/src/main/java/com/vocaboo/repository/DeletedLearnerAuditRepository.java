package com.vocaboo.repository;

import com.vocaboo.entity.DeletedLearnerAudit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.UUID;

@Repository
public interface DeletedLearnerAuditRepository extends JpaRepository<DeletedLearnerAudit, UUID> {
}
