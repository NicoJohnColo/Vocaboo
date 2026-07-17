package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(
    name = "rewards_data",
    uniqueConstraints = {
        @UniqueConstraint(columnNames = {"learner_id", "lesson_id", "badge_type"})
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RewardData {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "reward_id", updatable = false, nullable = false)
    private UUID rewardId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "learner_id", nullable = false)
    private Learner learner;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lesson_id", nullable = false)
    private Lesson lesson;

    @Column(name = "badge_type", nullable = false, length = 50)
    private String badgeType; // BRONZE, SILVER, GOLD, PERFECT_GOLD

    @Column(name = "earned_at", updatable = false)
    @Builder.Default
    private OffsetDateTime earnedAt = OffsetDateTime.now();

    @PrePersist
    protected void onCreate() {
        earnedAt = OffsetDateTime.now();
    }
}
