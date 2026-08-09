package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "teachers")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Teacher {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "teacher_id", updatable = false, nullable = false)
    private UUID teacherId;

    @Column(name = "username", nullable = false, unique = true, length = 100)
    private String username;

    @Column(name = "email", nullable = false, unique = true, length = 200)
    private String email;

    @Column(name = "password_hash", nullable = false, columnDefinition = "TEXT")
    private String passwordHash;

    @Column(name = "firstname", length = 100)
    private String firstname;

    @Column(name = "middlename", length = 100)
    private String middlename;

    @Column(name = "lastname", length = 100)
    private String lastname;

    @Column(name = "gender", length = 50)
    private String gender;

    @Column(name = "school", length = 200)
    private String school;

    /** Short-lived token for password reset flow (expires in 1 hour). */
    @Column(name = "password_reset_token", columnDefinition = "TEXT")
    private String passwordResetToken;

    /** Expiry timestamp for the password reset token. */
    @Column(name = "password_reset_expiry")
    private OffsetDateTime passwordResetExpiry;

    @Column(name = "created_at", updatable = false)
    @Builder.Default
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @PrePersist
    protected void onCreate() {
        createdAt = OffsetDateTime.now();
    }
}
