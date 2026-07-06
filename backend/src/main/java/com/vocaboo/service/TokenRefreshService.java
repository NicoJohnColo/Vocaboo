package com.vocaboo.service;

import com.vocaboo.entity.RefreshToken;
import com.vocaboo.repository.LearnerRepository;
import com.vocaboo.repository.RefreshTokenRepository;
import com.vocaboo.security.JwtUtils;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.bcrypt.BCrypt;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class TokenRefreshService {

    private static final Logger log = LoggerFactory.getLogger(TokenRefreshService.class);

    private final RefreshTokenRepository refreshTokenRepository;
    private final LearnerRepository learnerRepository;
    private final JwtUtils jwtUtils;

    @Value("${app.jwt.refresh-token-expiration-days:7}")
    private int refreshTokenExpirationDays;

    /**
     * Generates and persists a new refresh token for a learner.
     * Revokes any previously active tokens for that user first (one active token per user).
     *
     * @param learnerId the learner's UUID
     * @return the raw (unhashed) refresh token string — return this to the client once only
     */
    @Transactional
    public String generateRefreshToken(UUID learnerId) {
        // Revoke existing active tokens for this user before issuing a new one
        refreshTokenRepository.revokeAllByUserId(learnerId, OffsetDateTime.now());

        String rawToken = UUID.randomUUID().toString() + "-" + UUID.randomUUID().toString();
        String hashed = BCrypt.hashpw(rawToken, BCrypt.gensalt(10));

        RefreshToken entity = RefreshToken.builder()
                .userId(learnerId)
                .tokenHash(hashed)
                .createdAt(OffsetDateTime.now())
                .expiresAt(OffsetDateTime.now().plusDays(refreshTokenExpirationDays))
                .build();

        refreshTokenRepository.save(entity);
        log.info("Refresh token issued for learner: {}", learnerId);
        return rawToken;
    }

    /**
     * Validates a raw refresh token string against the stored hash.
     * Returns the matching RefreshToken entity if valid.
     */
    @Transactional(readOnly = true)
    public RefreshToken validateRefreshToken(String rawToken) {
        // We must scan active tokens for this user; since we can't reverse the hash,
        // we find all active tokens and bcrypt-check each (max 1 per user in practice)
        String[] parts = rawToken.split("-", 2);
        if (parts.length < 2) {
            throw new BadCredentialsException("Invalid refresh token format.");
        }

        // Brute-force approach is safe here because max 1 active token per user
        // For scale: add a deterministic token_id prefix in the raw token
        List<RefreshToken> candidates = refreshTokenRepository.findAll().stream()
                .filter(RefreshToken::isValid)
                .toList();

        for (RefreshToken candidate : candidates) {
            if (BCrypt.checkpw(rawToken, candidate.getTokenHash())) {
                return candidate;
            }
        }
        throw new BadCredentialsException("Refresh token is invalid, expired, or has been revoked.");
    }

    /**
     * Issues a new access token in exchange for a valid refresh token.
     * The old refresh token is NOT rotated (token rotation can be added later).
     */
    @Transactional
    public String exchangeRefreshTokenForAccessToken(String rawRefreshToken) {
        RefreshToken token = validateRefreshToken(rawRefreshToken);

        UUID userId = token.getUserId();

        // Determine if the user is a learner and build the correct token type
        var learnerOpt = learnerRepository.findById(userId);
        if (learnerOpt.isPresent()) {
            var learner = learnerOpt.get();
            log.info("Access token refreshed for learner: {}", userId);
            return jwtUtils.generateToken(userId, learner.getDisplayName());
        }

        // Fallback — subject-only token (admin refresh not handled here)
        throw new BadCredentialsException("User not found for refresh token.");
    }

    /**
     * Revokes a specific refresh token (logout from current device).
     */
    @Transactional
    public void revokeRefreshToken(String rawRefreshToken) {
        RefreshToken token = validateRefreshToken(rawRefreshToken);
        token.setRevokedAt(OffsetDateTime.now());
        refreshTokenRepository.save(token);
        log.info("Refresh token revoked for user: {}", token.getUserId());
    }

    /**
     * Revokes all refresh tokens for a user (force logout from all devices).
     */
    @Transactional
    public void revokeAllTokensForUser(UUID userId) {
        int count = refreshTokenRepository.revokeAllByUserId(userId, OffsetDateTime.now());
        log.info("Revoked {} refresh token(s) for user: {}", count, userId);
    }
}
