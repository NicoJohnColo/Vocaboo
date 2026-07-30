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

    @PrePersist
    protected void onCreate() {
        completedAt = OffsetDateTime.now();
    }
}
