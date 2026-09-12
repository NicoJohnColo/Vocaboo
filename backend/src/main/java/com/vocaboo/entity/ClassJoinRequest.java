package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "class_join_requests")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ClassJoinRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "request_id", updatable = false, nullable = false)
    private UUID requestId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "class_id", nullable = false)
    private Classroom classroom;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "learner_id", nullable = false)
    private Learner learner;

    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private String status = "PENDING";

    @Column(name = "created_at", updatable = false)
    @Builder.Default
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "reviewed_at")
    private OffsetDateTime reviewedAt;

    public UUID getRequestId() { return requestId; }
    public Classroom getClassroom() { return classroom; }
    public Learner getLearner() { return learner; }
    public String getStatus() { return status; }
    public OffsetDateTime getCreatedAt() { return createdAt; }
    public OffsetDateTime getReviewedAt() { return reviewedAt; }

    public void setStatus(String status) { this.status = status; }
    public void setReviewedAt(OffsetDateTime reviewedAt) { this.reviewedAt = reviewedAt; }

    public static ClassJoinRequestBuilder builder() { return new ClassJoinRequestBuilder(); }

    public static class ClassJoinRequestBuilder {
        private UUID requestId;
        private Classroom classroom;
        private Learner learner;
        private String status = "PENDING";
        private OffsetDateTime createdAt;
        private OffsetDateTime reviewedAt;

        public ClassJoinRequestBuilder requestId(UUID requestId) { this.requestId = requestId; return this; }
        public ClassJoinRequestBuilder classroom(Classroom classroom) { this.classroom = classroom; return this; }
        public ClassJoinRequestBuilder learner(Learner learner) { this.learner = learner; return this; }
        public ClassJoinRequestBuilder status(String status) { this.status = status; return this; }
        public ClassJoinRequestBuilder createdAt(OffsetDateTime createdAt) { this.createdAt = createdAt; return this; }
        public ClassJoinRequestBuilder reviewedAt(OffsetDateTime reviewedAt) { this.reviewedAt = reviewedAt; return this; }

        public ClassJoinRequest build() {
            ClassJoinRequest cjr = new ClassJoinRequest();
            cjr.requestId = this.requestId;
            cjr.classroom = this.classroom;
            cjr.learner = this.learner;
            cjr.status = this.status != null ? this.status : "PENDING";
            cjr.createdAt = this.createdAt != null ? this.createdAt : OffsetDateTime.now();
            cjr.reviewedAt = this.reviewedAt;
            return cjr;
        }
    }

    @PrePersist
    protected void onCreate() {
        if (status == null) status = "PENDING";
        if (createdAt == null) createdAt = OffsetDateTime.now();
    }
}
