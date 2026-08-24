package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "reinforcement_queue")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReinforcementQueueItem {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "queue_id", updatable = false, nullable = false)
    private UUID queueId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "learner_id", nullable = false)
    private Learner learner;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "word_id", nullable = false)
    private VocabularyWord word;

    @Column(name = "scheduled_at", nullable = false)
    @Builder.Default
    private OffsetDateTime scheduledAt = OffsetDateTime.now();

    @Column(name = "attempts_count", nullable = false)
    @Builder.Default
    private Integer attemptsCount = 0;

    @Column(name = "is_resolved", nullable = false)
    @Builder.Default
    private Boolean isResolved = false;

    @Column(name = "created_at", updatable = false)
    @Builder.Default
    private OffsetDateTime createdAt = OffsetDateTime.now();

    public VocabularyWord getWord() { return word; }
    public Boolean getIsResolved() { return isResolved; }
    public Integer getAttemptsCount() { return attemptsCount; }
    public void setIsResolved(Boolean isResolved) { this.isResolved = isResolved; }
    public void setScheduledAt(OffsetDateTime scheduledAt) { this.scheduledAt = scheduledAt; }
    public void setAttemptsCount(Integer attemptsCount) { this.attemptsCount = attemptsCount; }

    public static ReinforcementQueueItemBuilder builder() { return new ReinforcementQueueItemBuilder(); }

    public static class ReinforcementQueueItemBuilder {
        private Learner learner;
        private VocabularyWord word;
        private OffsetDateTime scheduledAt;
        private Integer attemptsCount = 0;
        private Boolean isResolved = false;

        public ReinforcementQueueItemBuilder learner(Learner learner) { this.learner = learner; return this; }
        public ReinforcementQueueItemBuilder word(VocabularyWord word) { this.word = word; return this; }
        public ReinforcementQueueItemBuilder scheduledAt(OffsetDateTime scheduledAt) { this.scheduledAt = scheduledAt; return this; }
        public ReinforcementQueueItemBuilder attemptsCount(Integer attemptsCount) { this.attemptsCount = attemptsCount; return this; }
        public ReinforcementQueueItemBuilder isResolved(Boolean isResolved) { this.isResolved = isResolved; return this; }

        public ReinforcementQueueItem build() {
            ReinforcementQueueItem item = new ReinforcementQueueItem();
            item.learner = this.learner;
            item.word = this.word;
            item.scheduledAt = this.scheduledAt != null ? this.scheduledAt : OffsetDateTime.now();
            item.attemptsCount = this.attemptsCount != null ? this.attemptsCount : 0;
            item.isResolved = this.isResolved != null ? this.isResolved : false;
            item.createdAt = OffsetDateTime.now();
            return item;
        }
    }

    @PrePersist
    protected void onCreate() {
        createdAt = OffsetDateTime.now();
        if (scheduledAt == null) {
            scheduledAt = OffsetDateTime.now();
        }
    }
}
