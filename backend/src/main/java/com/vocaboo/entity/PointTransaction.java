package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "point_transactions")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PointTransaction {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "transaction_id", updatable = false, nullable = false)
    private UUID transactionId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "learner_id", nullable = false)
    private Learner learner;

    @Enumerated(EnumType.STRING)
    @Column(name = "action_type", nullable = false)
    private PointActionType actionType;

    @Column(name = "points_awarded", nullable = false)
    private Integer pointsAwarded;

    @Column(name = "related_session_id")
    private UUID relatedSessionId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "related_word_id")
    private VocabularyWord relatedWord;

    /**
     * Context in which the points were earned:
     * "GLOBAL" — free/personal app usage (default).
     * "CLASS"  — launched from within a class context; classroom_id will be set.
     */
    @Column(name = "context_type", nullable = false, length = 10)
    @Builder.Default
    private String contextType = "GLOBAL";

    /**
     * The classroom associated with this transaction when context_type = "CLASS".
     * Null for GLOBAL transactions.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "classroom_id")
    private Classroom classroom;

    @Column(name = "created_at", updatable = false)
    @Builder.Default
    private OffsetDateTime createdAt = OffsetDateTime.now();

    public Classroom getClassroom() { return classroom; }
    public String getContextType() { return contextType; }
    public void setContextType(String contextType) { this.contextType = contextType; }
    public void setClassroom(Classroom classroom) { this.classroom = classroom; }

    public static PointTransactionBuilder builder() { return new PointTransactionBuilder(); }

    public static class PointTransactionBuilder {
        private Learner learner;
        private PointActionType actionType;
        private Integer pointsAwarded;
        private UUID relatedSessionId;
        private VocabularyWord relatedWord;
        private String contextType = "GLOBAL";
        private Classroom classroom;

        public PointTransactionBuilder learner(Learner learner) { this.learner = learner; return this; }
        public PointTransactionBuilder actionType(PointActionType actionType) { this.actionType = actionType; return this; }
        public PointTransactionBuilder pointsAwarded(Integer pointsAwarded) { this.pointsAwarded = pointsAwarded; return this; }
        public PointTransactionBuilder relatedSessionId(UUID relatedSessionId) { this.relatedSessionId = relatedSessionId; return this; }
        public PointTransactionBuilder relatedWord(VocabularyWord relatedWord) { this.relatedWord = relatedWord; return this; }
        public PointTransactionBuilder contextType(String contextType) { this.contextType = contextType; return this; }
        public PointTransactionBuilder classroom(Classroom classroom) { this.classroom = classroom; return this; }
        public PointTransactionBuilder createdAt(OffsetDateTime createdAt) { return this; }

        public PointTransaction build() {
            PointTransaction p = new PointTransaction();
            p.learner = this.learner;
            p.actionType = this.actionType;
            p.pointsAwarded = this.pointsAwarded;
            p.relatedSessionId = this.relatedSessionId;
            p.relatedWord = this.relatedWord;
            p.contextType = this.contextType != null ? this.contextType : "GLOBAL";
            p.classroom = this.classroom;
            p.createdAt = OffsetDateTime.now();
            return p;
        }
    }

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = OffsetDateTime.now();
        }
    }
}
