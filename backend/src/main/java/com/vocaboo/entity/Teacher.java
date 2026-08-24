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

    public UUID getTeacherId() { return teacherId; }
    public String getUsername() { return username; }
    public String getPasswordHash() { return passwordHash; }
    public String getEmail() { return email; }
    public String getFirstname() { return firstname; }
    public String getMiddlename() { return middlename; }
    public String getLastname() { return lastname; }
    public String getGender() { return gender; }
    public String getSchool() { return school; }
    public OffsetDateTime getPasswordResetExpiry() { return passwordResetExpiry; }

    public void setPasswordHash(String passwordHash) { this.passwordHash = passwordHash; }
    public void setPasswordResetToken(String passwordResetToken) { this.passwordResetToken = passwordResetToken; }
    public void setPasswordResetExpiry(OffsetDateTime passwordResetExpiry) { this.passwordResetExpiry = passwordResetExpiry; }

    public static TeacherBuilder builder() { return new TeacherBuilder(); }

    public static class TeacherBuilder {
        private String username;
        private String email;
        private String passwordHash;
        private String firstname;
        private String middlename;
        private String lastname;
        private String gender;
        private String school;

        public TeacherBuilder username(String username) { this.username = username; return this; }
        public TeacherBuilder email(String email) { this.email = email; return this; }
        public TeacherBuilder passwordHash(String passwordHash) { this.passwordHash = passwordHash; return this; }
        public TeacherBuilder firstname(String firstname) { this.firstname = firstname; return this; }
        public TeacherBuilder middlename(String middlename) { this.middlename = middlename; return this; }
        public TeacherBuilder lastname(String lastname) { this.lastname = lastname; return this; }
        public TeacherBuilder gender(String gender) { this.gender = gender; return this; }
        public TeacherBuilder school(String school) { this.school = school; return this; }

        public Teacher build() {
            Teacher t = new Teacher();
            t.username = this.username;
            t.email = this.email;
            t.passwordHash = this.passwordHash;
            t.firstname = this.firstname;
            t.middlename = this.middlename;
            t.lastname = this.lastname;
            t.gender = this.gender;
            t.school = this.school;
            t.createdAt = OffsetDateTime.now();
            return t;
        }
    }

    @PrePersist
    protected void onCreate() {
        createdAt = OffsetDateTime.now();
    }
}
