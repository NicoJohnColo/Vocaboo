package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "class_invitations")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ClassInvitation {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "invitation_id", updatable = false, nullable = false)
    private UUID invitationId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "class_id", nullable = false)
    private Classroom classroom;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "learner_id", nullable = false)
    private Learner learner;

    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private String status = "PENDING";

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "sent_by_teacher_id", nullable = false)
    private Teacher sentByTeacher;

    @Column(name = "created_at", updatable = false)
    @Builder.Default
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "responded_at")
    private OffsetDateTime respondedAt;

    public UUID getInvitationId() { return invitationId; }
    public Classroom getClassroom() { return classroom; }
    public Learner getLearner() { return learner; }
    public String getStatus() { return status; }
    public Teacher getSentByTeacher() { return sentByTeacher; }
    public OffsetDateTime getCreatedAt() { return createdAt; }
    public OffsetDateTime getRespondedAt() { return respondedAt; }

    public void setStatus(String status) { this.status = status; }
    public void setRespondedAt(OffsetDateTime respondedAt) { this.respondedAt = respondedAt; }

    public static ClassInvitationBuilder builder() { return new ClassInvitationBuilder(); }

    public static class ClassInvitationBuilder {
        private UUID invitationId;
        private Classroom classroom;
        private Learner learner;
        private String status = "PENDING";
        private Teacher sentByTeacher;
        private OffsetDateTime createdAt;
        private OffsetDateTime respondedAt;

        public ClassInvitationBuilder invitationId(UUID invitationId) { this.invitationId = invitationId; return this; }
        public ClassInvitationBuilder classroom(Classroom classroom) { this.classroom = classroom; return this; }
        public ClassInvitationBuilder learner(Learner learner) { this.learner = learner; return this; }
        public ClassInvitationBuilder status(String status) { this.status = status; return this; }
        public ClassInvitationBuilder sentByTeacher(Teacher sentByTeacher) { this.sentByTeacher = sentByTeacher; return this; }
        public ClassInvitationBuilder createdAt(OffsetDateTime createdAt) { this.createdAt = createdAt; return this; }
        public ClassInvitationBuilder respondedAt(OffsetDateTime respondedAt) { this.respondedAt = respondedAt; return this; }

        public ClassInvitation build() {
            ClassInvitation ci = new ClassInvitation();
            ci.invitationId = this.invitationId;
            ci.classroom = this.classroom;
            ci.learner = this.learner;
            ci.status = this.status != null ? this.status : "PENDING";
            ci.sentByTeacher = this.sentByTeacher;
            ci.createdAt = this.createdAt != null ? this.createdAt : OffsetDateTime.now();
            ci.respondedAt = this.respondedAt;
            return ci;
        }
    }

    @PrePersist
    protected void onCreate() {
        if (status == null) status = "PENDING";
        if (createdAt == null) createdAt = OffsetDateTime.now();
    }
}
