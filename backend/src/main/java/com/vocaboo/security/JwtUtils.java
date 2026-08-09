package com.vocaboo.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;

@Component
public class JwtUtils {

    private final SecretKey key;
    private final long accessTokenExpirationMs;

    public JwtUtils(
            @Value("${app.jwt.secret}") String secret,
            @Value("${app.jwt.access-token-expiration-ms:900000}") long accessTokenExpirationMs) {
        // Ensure secret key is long enough (at least 256 bits / 32 bytes)
        byte[] secretBytes = secret.getBytes(StandardCharsets.UTF_8);
        if (secretBytes.length < 32) {
            byte[] paddedBytes = new byte[32];
            System.arraycopy(secretBytes, 0, paddedBytes, 0, Math.min(secretBytes.length, 32));
            this.key = Keys.hmacShaKeyFor(paddedBytes);
        } else {
            this.key = Keys.hmacShaKeyFor(secretBytes);
        }
        this.accessTokenExpirationMs = accessTokenExpirationMs;
    }

    /**
     * Generates an access token for a learner with ROLE_LEARNER claim.
     */
    public String generateToken(UUID learnerId, String displayName) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("displayName", displayName);
        claims.put("role", "ROLE_LEARNER");
        // Keep learner tokens valid for 30 days (2,592,000,000 ms) so they don't get kicked out or fail requests constantly.
        long learnerExpirationMs = 30L * 24 * 60 * 60 * 1000;
        return Jwts.builder()
                .subject(learnerId.toString())
                .claims(claims)
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + learnerExpirationMs))
                .signWith(key)
                .compact();
    }

    /**
     * Generates an access token for an admin with ROLE_ADMIN claim.
     */
    public String generateAdminToken(UUID adminId, String username) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("username", username);
        claims.put("role", "ROLE_ADMIN");
        return Jwts.builder()
                .subject(adminId.toString())
                .claims(claims)
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + accessTokenExpirationMs))
                .signWith(key)
                .compact();
    }

    /**
     * Generates an access token for a teacher with ROLE_TEACHER claim.
     */
    public String generateTeacherToken(UUID teacherId, String username) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("username", username);
        claims.put("role", "ROLE_TEACHER");
        return Jwts.builder()
                .subject(teacherId.toString())
                .claims(claims)
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + accessTokenExpirationMs))
                .signWith(key)
                .compact();
    }

    public String extractSubject(String token) {
        return extractClaim(token, Claims::getSubject);
    }

    public Date extractExpiration(String token) {
        return extractClaim(token, Claims::getExpiration);
    }

    /**
     * Extracts the role claim (e.g. "ROLE_ADMIN" or "ROLE_LEARNER") from a JWT.
     * Returns "ROLE_LEARNER" as a safe default if the claim is absent.
     */
    public String extractRole(String token) {
        try {
            Claims claims = extractAllClaims(token);
            Object role = claims.get("role");
            return role != null ? role.toString() : "ROLE_LEARNER";
        } catch (Exception e) {
            return "ROLE_LEARNER";
        }
    }

    public <T> T extractClaim(String token, Function<Claims, T> claimsResolver) {
        final Claims claims = extractAllClaims(token);
        return claimsResolver.apply(claims);
    }

    private Claims extractAllClaims(String token) {
        return Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    private Boolean isTokenExpired(String token) {
        return extractExpiration(token).before(new Date());
    }

    public Boolean validateToken(String token, String expectedSubject) {
        try {
            final String subject = extractSubject(token);
            return (subject.equals(expectedSubject) && !isTokenExpired(token));
        } catch (Exception e) {
            return false;
        }
    }

    public Boolean validateToken(String token) {
        try {
            Jwts.parser().verifyWith(key).build().parseSignedClaims(token);
            return !isTokenExpired(token);
        } catch (Exception e) {
            return false;
        }
    }
}
