package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(
    name = "word_performance",
    uniqueConstraints = {
        @UniqueConstraint(columnNames = {"learner_id", "word_id"})
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WordPerformance {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "performance_id", updatable = false, nullable = false)
    private UUID performanceId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "learner_id", nullable = false)
    private Learner learner;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "word_id", nullable = false)
    private VocabularyWord word;

    @Column(name = "correct_count", nullable = false)
    @Builder.Default
    private Integer correctCount = 0;

    @Column(name = "incorrect_count", nullable = false)
    @Builder.Default
    private Integer incorrectCount = 0;

    @Column(name = "demerit_points", nullable = false)
    @Builder.Default
    private Integer demeritPoints = 0;

    /**
     * Number of times this word's difficulty tier was downgraded (wrong answer at
     * FAMILIAR/PROFICIENT/MASTERED). Used with accuracy to compute Gold/Silver/Bronze
     * word-level performance rating on the score screen.
     */
    @Column(name = "tier_drop_count", nullable = false)
    @Builder.Default
    private Integer tierDropCount = 0;

    /**
     * Number of times this word experienced asset fallbacks in Module 4 practice.
     */
    @Column(name = "fallback_count", nullable = false)
    @Builder.Default
    private Integer fallbackCount = 0;

    @Column(name = "total_attempts", nullable = false)
    @Builder.Default
    private Integer totalAttempts = 0;

    @Column(name = "accuracy", nullable = false, precision = 5, scale = 2)
    @Builder.Default
    private BigDecimal accuracy = BigDecimal.ZERO;

    @Column(name = "last_practiced_at", nullable = false)
    @Builder.Default
    private OffsetDateTime lastPracticedAt = OffsetDateTime.now();

    @Column(name = "created_at", updatable = false)
    @Builder.Default
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "updated_at")
    @Builder.Default
    private OffsetDateTime updatedAt = OffsetDateTime.now();

    public Learner getLearner() {
        return learner;
    }

    public VocabularyWord getWord() {
        return word;
    }

    public OffsetDateTime getLastPracticedAt() {
        return lastPracticedAt;
    }

    public BigDecimal getAccuracy() {
        return accuracy;
    }

    public Integer getDemeritPoints() {
        return demeritPoints;
    }

    public Integer getTierDropCount() {
        return tierDropCount;
    }

    public Integer getFallbackCount() {
        return fallbackCount;
    }

    public Integer getTotalAttempts() {
        return totalAttempts;
    }

    public Integer getCorrectCount() {
        return correctCount;
    }

    public Integer getIncorrectCount() {
        return incorrectCount;
    }

    public void setTotalAttempts(Integer totalAttempts) { this.totalAttempts = totalAttempts; }
    public void setCorrectCount(Integer correctCount) { this.correctCount = correctCount; }
    public void setIncorrectCount(Integer incorrectCount) { this.incorrectCount = incorrectCount; }
    public void setAccuracy(BigDecimal accuracy) { this.accuracy = accuracy; }
    public void setDemeritPoints(Integer demeritPoints) { this.demeritPoints = demeritPoints; }
    public void setLastPracticedAt(OffsetDateTime lastPracticedAt) { this.lastPracticedAt = lastPracticedAt; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }

    public static WordPerformanceBuilder builder() { return new WordPerformanceBuilder(); }

    public static class WordPerformanceBuilder {
        private UUID performanceId;
        private Learner learner;
        private VocabularyWord word;
        private Integer correctCount = 0;
        private Integer incorrectCount = 0;
        private Integer demeritPoints = 0;
        private Integer tierDropCount = 0;
        private Integer fallbackCount = 0;
        private Integer totalAttempts = 0;
        private BigDecimal accuracy = BigDecimal.ZERO;
        private OffsetDateTime lastPracticedAt;
        private OffsetDateTime createdAt;
        private OffsetDateTime updatedAt;

        public WordPerformanceBuilder performanceId(UUID performanceId) { this.performanceId = performanceId; return this; }
        public WordPerformanceBuilder learner(Learner learner) { this.learner = learner; return this; }
        public WordPerformanceBuilder word(VocabularyWord word) { this.word = word; return this; }
        public WordPerformanceBuilder correctCount(Integer correctCount) { this.correctCount = correctCount; return this; }
        public WordPerformanceBuilder incorrectCount(Integer incorrectCount) { this.incorrectCount = incorrectCount; return this; }
        public WordPerformanceBuilder demeritPoints(Integer demeritPoints) { this.demeritPoints = demeritPoints; return this; }
        public WordPerformanceBuilder tierDropCount(Integer tierDropCount) { this.tierDropCount = tierDropCount; return this; }
        public WordPerformanceBuilder fallbackCount(Integer fallbackCount) { this.fallbackCount = fallbackCount; return this; }
        public WordPerformanceBuilder totalAttempts(Integer totalAttempts) { this.totalAttempts = totalAttempts; return this; }
        public WordPerformanceBuilder accuracy(BigDecimal accuracy) { this.accuracy = accuracy; return this; }
        public WordPerformanceBuilder lastPracticedAt(OffsetDateTime lastPracticedAt) { this.lastPracticedAt = lastPracticedAt; return this; }
        public WordPerformanceBuilder createdAt(OffsetDateTime createdAt) { this.createdAt = createdAt; return this; }
        public WordPerformanceBuilder updatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; return this; }

        public WordPerformance build() {
            WordPerformance w = new WordPerformance();
            w.performanceId = this.performanceId;
            w.learner = this.learner;
            w.word = this.word;
            w.correctCount = this.correctCount;
            w.incorrectCount = this.incorrectCount;
            w.demeritPoints = this.demeritPoints;
            w.tierDropCount = this.tierDropCount;
            w.fallbackCount = this.fallbackCount;
            w.totalAttempts = this.totalAttempts;
            w.accuracy = this.accuracy;
            w.lastPracticedAt = this.lastPracticedAt != null ? this.lastPracticedAt : OffsetDateTime.now();
            w.createdAt = this.createdAt != null ? this.createdAt : OffsetDateTime.now();
            w.updatedAt = this.updatedAt != null ? this.updatedAt : OffsetDateTime.now();
            return w;
        }
    }

    @PrePersist
    protected void onCreate() {
        createdAt = OffsetDateTime.now();
        updatedAt = OffsetDateTime.now();
        lastPracticedAt = OffsetDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = OffsetDateTime.now();
    }
}
