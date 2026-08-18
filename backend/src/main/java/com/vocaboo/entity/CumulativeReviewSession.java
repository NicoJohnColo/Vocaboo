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
}
