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

    public Learner getLearner() {
        return learner;
    }

    public Lesson getLesson() {
        return lesson;
    }

    public String getBadgeType() {
        return badgeType;
    }

    public OffsetDateTime getEarnedAt() {
        return earnedAt;
    }

    public static RewardDataBuilder builder() { return new RewardDataBuilder(); }

    public static class RewardDataBuilder {
        private UUID rewardId;
        private Learner learner;
        private Lesson lesson;
        private String badgeType;
        private OffsetDateTime earnedAt;

        public RewardDataBuilder rewardId(UUID rewardId) { this.rewardId = rewardId; return this; }
        public RewardDataBuilder learner(Learner learner) { this.learner = learner; return this; }
        public RewardDataBuilder lesson(Lesson lesson) { this.lesson = lesson; return this; }
        public RewardDataBuilder badgeType(String badgeType) { this.badgeType = badgeType; return this; }
        public RewardDataBuilder earnedAt(OffsetDateTime earnedAt) { this.earnedAt = earnedAt; return this; }

        public RewardData build() {
            RewardData r = new RewardData();
            r.rewardId = this.rewardId;
            r.learner = this.learner;
            r.lesson = this.lesson;
            r.badgeType = this.badgeType;
            r.earnedAt = this.earnedAt != null ? this.earnedAt : OffsetDateTime.now();
            return r;
        }
    }

    @PrePersist
    protected void onCreate() {
        earnedAt = OffsetDateTime.now();
    }
}
