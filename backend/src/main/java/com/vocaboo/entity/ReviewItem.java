package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "review_items")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReviewItem {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "item_id", updatable = false, nullable = false)
    private UUID itemId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id", nullable = false)
    private ReviewSession session;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "word_id", nullable = false)
    private VocabularyWord word;

    @Column(name = "is_correct", nullable = false)
    private Boolean isCorrect;

    @Column(name = "created_at", updatable = false)
    @Builder.Default
    private OffsetDateTime createdAt = OffsetDateTime.now();

    public VocabularyWord getWord() { return word; }
    public Boolean getIsCorrect() { return isCorrect; }
    public OffsetDateTime getCreatedAt() { return createdAt; }
    public ReviewSession getSession() { return session; }

    public static ReviewItemBuilder builder() { return new ReviewItemBuilder(); }

    public static class ReviewItemBuilder {
        private ReviewSession session;
        private VocabularyWord word;
        private Boolean isCorrect;

        public ReviewItemBuilder session(ReviewSession session) { this.session = session; return this; }
        public ReviewItemBuilder word(VocabularyWord word) { this.word = word; return this; }
        public ReviewItemBuilder isCorrect(Boolean isCorrect) { this.isCorrect = isCorrect; return this; }
        public ReviewItemBuilder createdAt(OffsetDateTime createdAt) { return this; }

        public ReviewItem build() {
            ReviewItem item = new ReviewItem();
            item.session = this.session;
            item.word = this.word;
            item.isCorrect = this.isCorrect;
            item.createdAt = OffsetDateTime.now();
            return item;
        }
    }

    @PrePersist
    protected void onCreate() {
        createdAt = OffsetDateTime.now();
    }
}
