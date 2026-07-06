package com.vocaboo.repository;

import com.vocaboo.entity.AdminAuditLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface AdminAuditLogRepository extends JpaRepository<AdminAuditLog, UUID> {

    /** All audit entries performed by a given admin, newest first. */
    List<AdminAuditLog> findByAdminIdOrderByTimestampDesc(UUID adminId);

    /** All audit entries targeting a specific entity (e.g. viewing a specific admin's history). */
    List<AdminAuditLog> findByTargetIdOrderByTimestampDesc(UUID targetId);
}
