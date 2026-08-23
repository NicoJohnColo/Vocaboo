package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "practice_results")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PracticeResult {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "result_id", updatable = false, nullable = false)
    private UUID resultId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id", nullable = false)
    private PracticeSession session;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "word_id", nullable = false)
    private VocabularyWord word;

    @Column(name = "is_correct", nullable = false)
    private Boolean isCorrect;

    @Column(name = "attempt_number", nullable = false)
    @Builder.Default
    private Integer attemptNumber = 1;

    @Column(name = "activity_type", length = 30)
    private String activityType;

    @Column(name = "points", nullable = false)
    @Builder.Default
    private Integer points = 0;

    @Column(name = "recorded_at", updatable = false)
    @Builder.Default
    private OffsetDateTime recordedAt = OffsetDateTime.now();

    public UUID getResultId() { return resultId; }
    public PracticeSession getSession() { return session; }
    public Boolean getIsCorrect() { return isCorrect; }
    public boolean isCorrect() { return Boolean.TRUE.equals(isCorrect); }
    public Integer getAttemptNumber() { return attemptNumber; }
    public Integer getPoints() { return points; }
    public VocabularyWord getWord() { return word; }
    public String getActivityType() { return activityType; }
    public OffsetDateTime getRecordedAt() { return recordedAt; }

    public static PracticeResultBuilder builder() { return new PracticeResultBuilder(); }

    public static class PracticeResultBuilder {
        private PracticeSession session;
        private VocabularyWord word;
        private Boolean isCorrect;
        private Integer attemptNumber = 1;
        private String activityType;
        private Integer points = 0;

        public PracticeResultBuilder session(PracticeSession session) { this.session = session; return this; }
        public PracticeResultBuilder word(VocabularyWord word) { this.word = word; return this; }
        public PracticeResultBuilder isCorrect(Boolean isCorrect) { this.isCorrect = isCorrect; return this; }
        public PracticeResultBuilder attemptNumber(Integer attemptNumber) { this.attemptNumber = attemptNumber; return this; }
        public PracticeResultBuilder activityType(String activityType) { this.activityType = activityType; return this; }
        public PracticeResultBuilder points(Integer points) { this.points = points; return this; }
        public PracticeResultBuilder recordedAt(OffsetDateTime recordedAt) { return this; }

        public PracticeResult build() {
            PracticeResult r = new PracticeResult();
            r.session = this.session;
            r.word = this.word;
            r.isCorrect = this.isCorrect;
            r.attemptNumber = this.attemptNumber;
            r.activityType = this.activityType;
            r.points = this.points;
            r.recordedAt = OffsetDateTime.now();
            return r;
        }
    }

    @PrePersist
    protected void onCreate() {
        recordedAt = OffsetDateTime.now();
    }
}
