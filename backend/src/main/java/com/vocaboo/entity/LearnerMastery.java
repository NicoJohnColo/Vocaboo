package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "learner_mastery")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LearnerMastery {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "mastery_id", updatable = false, nullable = false)
    private UUID masteryId;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "learner_id", unique = true, nullable = false)
    private Learner learner;

    @Column(name = "total_sessions_played", nullable = false)
    @Builder.Default
    private Integer totalSessionsPlayed = 0;

    @Column(name = "total_correct_answers", nullable = false)
    @Builder.Default
    private Integer totalCorrectAnswers = 0;

    @Column(name = "total_questions_answered", nullable = false)
    @Builder.Default
    private Integer totalQuestionsAnswered = 0;

    @Column(name = "overall_accuracy", nullable = false, precision = 5, scale = 2)
    @Builder.Default
    private BigDecimal overallAccuracy = BigDecimal.ZERO;

    @Column(name = "words_mastered_count", nullable = false)
    @Builder.Default
    private Integer wordsMasteredCount = 0;

    @Column(name = "mastery_level", nullable = false, length = 20)
    @Builder.Default
    private String masteryLevel = "LEARNING";

    @Column(name = "total_points", nullable = false)
    @Builder.Default
    private Integer totalPoints = 0;

    @Column(name = "created_at", updatable = false)
    @Builder.Default
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "updated_at")
    @Builder.Default
    private OffsetDateTime updatedAt = OffsetDateTime.now();

    public String getMasteryLevel() {
        return masteryLevel;
    }

    public Learner getLearner() {
        return learner;
    }

    public Integer getTotalPoints() {
        return totalPoints;
    }

    public Integer getTotalSessionsPlayed() {
        return totalSessionsPlayed;
    }

    public Integer getWordsMasteredCount() {
        return wordsMasteredCount;
    }

    public BigDecimal getOverallAccuracy() {
        return overallAccuracy;
    }

    public Integer getTotalQuestionsAnswered() {
        return totalQuestionsAnswered;
    }

    public Integer getTotalCorrectAnswers() {
        return totalCorrectAnswers;
    }

    public void setTotalQuestionsAnswered(Integer totalQuestionsAnswered) {
        this.totalQuestionsAnswered = totalQuestionsAnswered;
    }

    public void setTotalCorrectAnswers(Integer totalCorrectAnswers) {
        this.totalCorrectAnswers = totalCorrectAnswers;
    }

    public void setOverallAccuracy(BigDecimal overallAccuracy) {
        this.overallAccuracy = overallAccuracy;
    }

    public void setWordsMasteredCount(Integer wordsMasteredCount) {
        this.wordsMasteredCount = wordsMasteredCount;
    }

    public void setTotalPoints(Integer totalPoints) {
        this.totalPoints = totalPoints;
    }

    public void setMasteryLevel(String masteryLevel) { this.masteryLevel = masteryLevel; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }
    public void setTotalSessionsPlayed(Integer totalSessionsPlayed) { this.totalSessionsPlayed = totalSessionsPlayed; }

    public static LearnerMasteryBuilder builder() {
        return new LearnerMasteryBuilder();
    }

    public static class LearnerMasteryBuilder {
        private Learner learner;
        private Integer totalPoints = 0;
        private Integer totalSessionsPlayed = 0;
        private Integer wordsMasteredCount = 0;
        private BigDecimal overallAccuracy = BigDecimal.ZERO;
        private Integer totalQuestionsAnswered = 0;
        private Integer totalCorrectAnswers = 0;
        private String masteryLevel = "NOVICE";

        public LearnerMasteryBuilder learner(Learner learner) { this.learner = learner; return this; }
        public LearnerMasteryBuilder totalPoints(Integer totalPoints) { this.totalPoints = totalPoints; return this; }
        public LearnerMasteryBuilder totalSessionsPlayed(Integer totalSessionsPlayed) { this.totalSessionsPlayed = totalSessionsPlayed; return this; }
        public LearnerMasteryBuilder wordsMasteredCount(Integer wordsMasteredCount) { this.wordsMasteredCount = wordsMasteredCount; return this; }
        public LearnerMasteryBuilder overallAccuracy(BigDecimal overallAccuracy) { this.overallAccuracy = overallAccuracy; return this; }
        public LearnerMasteryBuilder totalQuestionsAnswered(Integer totalQuestionsAnswered) { this.totalQuestionsAnswered = totalQuestionsAnswered; return this; }
        public LearnerMasteryBuilder totalCorrectAnswers(Integer totalCorrectAnswers) { this.totalCorrectAnswers = totalCorrectAnswers; return this; }
        public LearnerMasteryBuilder masteryLevel(String masteryLevel) { this.masteryLevel = masteryLevel; return this; }
        public LearnerMasteryBuilder createdAt(OffsetDateTime createdAt) { return this; }
        public LearnerMasteryBuilder updatedAt(OffsetDateTime updatedAt) { return this; }

        public LearnerMastery build() {
            LearnerMastery m = new LearnerMastery();
            m.learner = this.learner;
            m.totalPoints = this.totalPoints;
            m.totalSessionsPlayed = this.totalSessionsPlayed;
            m.wordsMasteredCount = this.wordsMasteredCount;
            m.overallAccuracy = this.overallAccuracy;
            m.totalQuestionsAnswered = this.totalQuestionsAnswered;
            m.totalCorrectAnswers = this.totalCorrectAnswers;
            m.masteryLevel = this.masteryLevel;
            m.createdAt = OffsetDateTime.now();
            m.updatedAt = OffsetDateTime.now();
            return m;
        }
    }

    @PrePersist
    protected void onCreate() {
        createdAt = OffsetDateTime.now();
        updatedAt = OffsetDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = OffsetDateTime.now();
    }
}
