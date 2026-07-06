package com.vocaboo.repository;

import com.vocaboo.entity.RefreshToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface RefreshTokenRepository extends JpaRepository<RefreshToken, UUID> {

    /** Find all active (non-revoked) tokens for a user. */
    List<RefreshToken> findByUserIdAndRevokedAtIsNull(UUID userId);

    /** Revoke all tokens for a user (force logout everywhere). */
    @Modifying
    @Query("UPDATE RefreshToken rt SET rt.revokedAt = :now WHERE rt.userId = :userId AND rt.revokedAt IS NULL")
    int revokeAllByUserId(@Param("userId") UUID userId, @Param("now") OffsetDateTime now);

    /** Clean up expired and revoked tokens older than a cutoff date. */
    @Modifying
    @Query("DELETE FROM RefreshToken rt WHERE rt.expiresAt < :cutoff OR rt.revokedAt IS NOT NULL")
    int deleteExpiredAndRevoked(@Param("cutoff") OffsetDateTime cutoff);
}
