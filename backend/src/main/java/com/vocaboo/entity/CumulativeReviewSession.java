package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;
import java.util.Map;

@Entity
@Table(name = "cumulative_review_sessions")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CumulativeReviewSession {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "learner_id", nullable = false)
    private Learner learner;

    @Column(name = "lesson_pair_id", nullable = false, length = 100)
    private String lessonPairId;

    @Column(name = "session_status", nullable = false, length = 20)
    @Builder.Default
    private String sessionStatus = "IN_PROGRESS";

    @Column(name = "start_time", updatable = false)
    @Builder.Default
    private OffsetDateTime startTime = OffsetDateTime.now();

    @Column(name = "end_time")
    private OffsetDateTime endTime;

    @Column(name = "total_attempts", nullable = false)
    @Builder.Default
    private Integer totalAttempts = 0;

    @Column(name = "correct_count", nullable = false)
    @Builder.Default
    private Integer correctCount = 0;

    @Column(name = "accuracy_percent", precision = 5, scale = 2)
    private BigDecimal accuracyPercent;

    @Column(name = "badge_awarded", length = 20)
    private String badgeAwarded;

    @Column(name = "points_earned", nullable = false)
    @Builder.Default
    private Integer pointsEarned = 0;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "points_breakdown", columnDefinition = "jsonb")
    private Map<String, Object> pointsBreakdown;

    public Learner getLearner() {
        return learner;
    }

    public String getSessionStatus() {
        return sessionStatus;
    }

    public BigDecimal getAccuracyPercent() {
        return accuracyPercent;
    }

    public String getBadgeAwarded() {
        return badgeAwarded;
    }

    public UUID getId() {
        return id;
    }

    public String getLessonPairId() {
        return lessonPairId;
    }

    public Integer getPointsEarned() {
        return pointsEarned;
    }

    public Integer getCorrectCount() {
        return correctCount;
    }

    public Integer getTotalAttempts() {
        return totalAttempts;
    }

    public OffsetDateTime getEndTime() {
        return endTime;
    }

    public OffsetDateTime getStartTime() {
        return startTime;
    }

    public void setSessionStatus(String sessionStatus) { this.sessionStatus = sessionStatus; }
    public void setEndTime(OffsetDateTime endTime) { this.endTime = endTime; }
    public void setBadgeAwarded(String badgeAwarded) { this.badgeAwarded = badgeAwarded; }
    public void setAccuracyPercent(BigDecimal accuracyPercent) { this.accuracyPercent = accuracyPercent; }
    public void setTotalAttempts(Integer totalAttempts) { this.totalAttempts = totalAttempts; }
    public void setCorrectCount(Integer correctCount) { this.correctCount = correctCount; }
    public void setPointsEarned(Integer pointsEarned) { this.pointsEarned = pointsEarned; }
    public void setPointsBreakdown(Map<String, Object> pointsBreakdown) { this.pointsBreakdown = pointsBreakdown; }
    public Map<String, Object> getPointsBreakdown() { return pointsBreakdown; }

    public static CumulativeReviewSessionBuilder builder() {
        return new CumulativeReviewSessionBuilder();
    }

    public static class CumulativeReviewSessionBuilder {
        private UUID id;
        private Learner learner;
        private String lessonPairId;
        private String sessionStatus = "IN_PROGRESS";
        private OffsetDateTime startTime = OffsetDateTime.now();
        private OffsetDateTime endTime;
        private Integer totalAttempts = 0;
        private Integer correctCount = 0;
        private BigDecimal accuracyPercent;
        private String badgeAwarded;
        private Integer pointsEarned = 0;
        private Map<String, Object> pointsBreakdown;

        public CumulativeReviewSessionBuilder id(UUID id) { this.id = id; return this; }
        public CumulativeReviewSessionBuilder learner(Learner learner) { this.learner = learner; return this; }
        public CumulativeReviewSessionBuilder lessonPairId(String lessonPairId) { this.lessonPairId = lessonPairId; return this; }
        public CumulativeReviewSessionBuilder sessionStatus(String sessionStatus) { this.sessionStatus = sessionStatus; return this; }
        public CumulativeReviewSessionBuilder startTime(OffsetDateTime startTime) { this.startTime = startTime; return this; }
        public CumulativeReviewSessionBuilder endTime(OffsetDateTime endTime) { this.endTime = endTime; return this; }
        public CumulativeReviewSessionBuilder totalAttempts(Integer totalAttempts) { this.totalAttempts = totalAttempts; return this; }
        public CumulativeReviewSessionBuilder correctCount(Integer correctCount) { this.correctCount = correctCount; return this; }
        public CumulativeReviewSessionBuilder accuracyPercent(BigDecimal accuracyPercent) { this.accuracyPercent = accuracyPercent; return this; }
        public CumulativeReviewSessionBuilder badgeAwarded(String badgeAwarded) { this.badgeAwarded = badgeAwarded; return this; }
        public CumulativeReviewSessionBuilder pointsEarned(Integer pointsEarned) { this.pointsEarned = pointsEarned; return this; }
        public CumulativeReviewSessionBuilder pointsBreakdown(Map<String, Object> pointsBreakdown) { this.pointsBreakdown = pointsBreakdown; return this; }

        public CumulativeReviewSession build() {
            CumulativeReviewSession s = new CumulativeReviewSession();
            s.id = this.id;
            s.learner = this.learner;
            s.lessonPairId = this.lessonPairId;
            s.sessionStatus = this.sessionStatus;
            s.startTime = this.startTime;
            s.endTime = this.endTime;
            s.totalAttempts = this.totalAttempts;
            s.correctCount = this.correctCount;
            s.accuracyPercent = this.accuracyPercent;
            s.badgeAwarded = this.badgeAwarded;
            s.pointsEarned = this.pointsEarned;
            s.pointsBreakdown = this.pointsBreakdown;
            return s;
        }
    }
}
