package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "session_summaries")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SessionSummary {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "summary_id", updatable = false, nullable = false)
    private UUID summaryId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "learner_id", nullable = false)
    private Learner learner;

    @Column(name = "session_id", nullable = false)
    private UUID sessionId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lesson_id", nullable = false)
    private Lesson lesson;

    @Column(name = "total_words_reviewed", nullable = false)
    private Integer totalWordsReviewed;

    @Column(name = "correct_pronunciations", nullable = false)
    private Integer correctPronunciations;

    @Column(name = "incorrect_pronunciations", nullable = false)
    private Integer incorrectPronunciations;

    @Column(name = "total_attempts", nullable = false)
    private Integer totalAttempts;

    @Column(name = "accuracy_rate", nullable = false, precision = 5, scale = 2)
    private BigDecimal accuracyRate;

    @Column(name = "demerit_points", nullable = false)
    private Integer demeritPoints;

    @Column(name = "points_earned", nullable = false)
    @Builder.Default
    private Integer pointsEarned = 0;

    @Column(name = "stars_earned", nullable = false)
    @Builder.Default
    private Integer starsEarned = 0;

    @Column(name = "completed_at", updatable = false)
    @Builder.Default
    private OffsetDateTime completedAt = OffsetDateTime.now();

    public UUID getSummaryId() { return summaryId; }
    public UUID getSessionId() { return sessionId; }
    public Lesson getLesson() { return lesson; }
    public Integer getTotalWordsReviewed() { return totalWordsReviewed; }
    public Integer getCorrectPronunciations() { return correctPronunciations; }
    public Integer getIncorrectPronunciations() { return incorrectPronunciations; }
    public Integer getDemeritPoints() { return demeritPoints; }
    public Integer getPointsEarned() { return pointsEarned; }
    public OffsetDateTime getCompletedAt() { return completedAt; }
    public BigDecimal getAccuracyRate() { return accuracyRate; }
    public Integer getTotalAttempts() { return totalAttempts; }

    public void setTotalWordsReviewed(Integer totalWordsReviewed) { this.totalWordsReviewed = totalWordsReviewed; }
    public void setCorrectPronunciations(Integer correctPronunciations) { this.correctPronunciations = correctPronunciations; }
    public void setIncorrectPronunciations(Integer incorrectPronunciations) { this.incorrectPronunciations = incorrectPronunciations; }
    public void setTotalAttempts(Integer totalAttempts) { this.totalAttempts = totalAttempts; }
    public void setAccuracyRate(BigDecimal accuracyRate) { this.accuracyRate = accuracyRate; }
    public void setStarsEarned(Integer starsEarned) { this.starsEarned = starsEarned; }
    public void setPointsEarned(Integer pointsEarned) { this.pointsEarned = pointsEarned; }
    public void setDemeritPoints(Integer demeritPoints) { this.demeritPoints = demeritPoints; }
    public void setCompletedAt(OffsetDateTime completedAt) { this.completedAt = completedAt; }

    public static SessionSummaryBuilder builder() { return new SessionSummaryBuilder(); }

    public static class SessionSummaryBuilder {
        private Learner learner;
        private UUID sessionId;
        private Lesson lesson;
        private Integer totalWordsReviewed = 0;
        private Integer correctPronunciations = 0;
        private Integer incorrectPronunciations = 0;
        private Integer totalAttempts = 0;
        private BigDecimal accuracyRate = BigDecimal.ZERO;
        private Integer demeritPoints = 0;
        private Integer pointsEarned = 0;
        private Integer starsEarned = 0;

        public SessionSummaryBuilder learner(Learner learner) { this.learner = learner; return this; }
        public SessionSummaryBuilder sessionId(UUID sessionId) { this.sessionId = sessionId; return this; }
        public SessionSummaryBuilder lesson(Lesson lesson) { this.lesson = lesson; return this; }
        public SessionSummaryBuilder totalWordsReviewed(Integer totalWordsReviewed) { this.totalWordsReviewed = totalWordsReviewed; return this; }
        public SessionSummaryBuilder correctPronunciations(Integer correctPronunciations) { this.correctPronunciations = correctPronunciations; return this; }
        public SessionSummaryBuilder incorrectPronunciations(Integer incorrectPronunciations) { this.incorrectPronunciations = incorrectPronunciations; return this; }
        public SessionSummaryBuilder totalAttempts(Integer totalAttempts) { this.totalAttempts = totalAttempts; return this; }
        public SessionSummaryBuilder accuracyRate(BigDecimal accuracyRate) { this.accuracyRate = accuracyRate; return this; }
        public SessionSummaryBuilder demeritPoints(Integer demeritPoints) { this.demeritPoints = demeritPoints; return this; }
        public SessionSummaryBuilder pointsEarned(Integer pointsEarned) { this.pointsEarned = pointsEarned; return this; }
        public SessionSummaryBuilder starsEarned(Integer starsEarned) { this.starsEarned = starsEarned; return this; }

        public SessionSummary build() {
            SessionSummary s = new SessionSummary();
            s.learner = this.learner;
            s.sessionId = this.sessionId;
            s.lesson = this.lesson;
            s.totalWordsReviewed = this.totalWordsReviewed;
            s.correctPronunciations = this.correctPronunciations;
            s.incorrectPronunciations = this.incorrectPronunciations;
            s.totalAttempts = this.totalAttempts;
            s.accuracyRate = this.accuracyRate;
            s.demeritPoints = this.demeritPoints;
            s.pointsEarned = this.pointsEarned;
            s.starsEarned = this.starsEarned;
            s.completedAt = OffsetDateTime.now();
            return s;
        }
    }

    @PrePersist
    protected void onCreate() {
        completedAt = OffsetDateTime.now();
    }
}
