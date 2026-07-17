package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(
    name = "lesson_module_scores",
    uniqueConstraints = {
        @UniqueConstraint(columnNames = {"learner_id", "lesson_id", "module_number"})
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LessonModuleScore {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "score_id", updatable = false, nullable = false)
    private UUID scoreId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "learner_id", nullable = false)
    private Learner learner;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lesson_id", nullable = false)
    private Lesson lesson;

    @Column(name = "module_number", nullable = false)
    private Integer moduleNumber;

    @Column(name = "correct_count", nullable = false)
    @Builder.Default
    private Integer correctCount = 0;

    @Column(name = "total_count", nullable = false)
    @Builder.Default
    private Integer totalCount = 0;

    @Column(name = "score", precision = 5, scale = 2, nullable = false)
    @Builder.Default
    private BigDecimal score = BigDecimal.ZERO;

    @Column(name = "stars_earned", nullable = false)
    @Builder.Default
    private Integer starsEarned = 0;

    @Column(name = "recorded_at", updatable = false)
    @Builder.Default
    private OffsetDateTime recordedAt = OffsetDateTime.now();

    @Column(name = "updated_at")
    @Builder.Default
    private OffsetDateTime updatedAt = OffsetDateTime.now();

    @PrePersist
    protected void onCreate() {
        recordedAt = OffsetDateTime.now();
        updatedAt = OffsetDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = OffsetDateTime.now();
    }
}