package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(
    name = "class_enrollments",
    uniqueConstraints = {
        @UniqueConstraint(columnNames = {"class_id", "learner_id"})
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ClassEnrollment {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "enrollment_id", updatable = false, nullable = false)
    private UUID enrollmentId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "class_id", nullable = false)
    private Classroom classroom;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "learner_id", nullable = false)
    private Learner learner;

    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private String status = "ACTIVE";

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "invited_by_teacher_id")
    private Teacher invitedByTeacher;

    @Column(name = "enrolled_at", updatable = false)
    @Builder.Default
    private OffsetDateTime enrolledAt = OffsetDateTime.now();

    public UUID getEnrollmentId() { return enrollmentId; }
    public Classroom getClassroom() { return classroom; }
    public Learner getLearner() { return learner; }
    public String getStatus() { return status; }
    public Teacher getInvitedByTeacher() { return invitedByTeacher; }
    public OffsetDateTime getEnrolledAt() { return enrolledAt; }

    public void setStatus(String status) { this.status = status; }
    public void setClassroom(Classroom classroom) { this.classroom = classroom; }
    public void setLearner(Learner learner) { this.learner = learner; }
    public void setInvitedByTeacher(Teacher invitedByTeacher) { this.invitedByTeacher = invitedByTeacher; }

    public static ClassEnrollmentBuilder builder() { return new ClassEnrollmentBuilder(); }

    public static class ClassEnrollmentBuilder {
        private UUID enrollmentId;
        private Classroom classroom;
        private Learner learner;
        private String status = "ACTIVE";
        private Teacher invitedByTeacher;
        private OffsetDateTime enrolledAt;

        public ClassEnrollmentBuilder enrollmentId(UUID enrollmentId) { this.enrollmentId = enrollmentId; return this; }
        public ClassEnrollmentBuilder classroom(Classroom classroom) { this.classroom = classroom; return this; }
        public ClassEnrollmentBuilder learner(Learner learner) { this.learner = learner; return this; }
        public ClassEnrollmentBuilder status(String status) { this.status = status; return this; }
        public ClassEnrollmentBuilder invitedByTeacher(Teacher invitedByTeacher) { this.invitedByTeacher = invitedByTeacher; return this; }
        public ClassEnrollmentBuilder enrolledAt(OffsetDateTime enrolledAt) { this.enrolledAt = enrolledAt; return this; }

        public ClassEnrollment build() {
            ClassEnrollment ce = new ClassEnrollment();
            ce.enrollmentId = this.enrollmentId;
            ce.classroom = this.classroom;
            ce.learner = this.learner;
            ce.status = this.status != null ? this.status : "ACTIVE";
            ce.invitedByTeacher = this.invitedByTeacher;
            ce.enrolledAt = this.enrolledAt != null ? this.enrolledAt : OffsetDateTime.now();
            return ce;
        }
    }

    @PrePersist
    protected void onCreate() {
        if (status == null) status = "ACTIVE";
        if (enrolledAt == null) enrolledAt = OffsetDateTime.now();
    }
}
