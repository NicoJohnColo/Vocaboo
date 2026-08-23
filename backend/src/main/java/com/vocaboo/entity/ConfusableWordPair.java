package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(
    name = "confusable_word_pairs",
    uniqueConstraints = {
        @UniqueConstraint(columnNames = {"lesson_id", "word_a_id", "word_b_id"})
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ConfusableWordPair {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "pair_id", updatable = false, nullable = false)
    private UUID pairId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lesson_id", nullable = false)
    private Lesson lesson;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "word_a_id", nullable = false)
    private VocabularyWord wordA;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "word_b_id", nullable = false)
    private VocabularyWord wordB;

    @Column(name = "contrastive_sentence_a", nullable = false, columnDefinition = "TEXT")
    private String contrastiveSentenceA;

    @Column(name = "contrastive_sentence_b", nullable = false, columnDefinition = "TEXT")
    private String contrastiveSentenceB;

    @Column(name = "created_at", updatable = false)
    @Builder.Default
    private OffsetDateTime createdAt = OffsetDateTime.now();

    public UUID getPairId() { return pairId; }
    public Lesson getLesson() { return lesson; }
    public VocabularyWord getWordA() { return wordA; }
    public VocabularyWord getWordB() { return wordB; }
    public String getContrastiveSentenceA() { return contrastiveSentenceA; }
    public String getContrastiveSentenceB() { return contrastiveSentenceB; }
    public OffsetDateTime getCreatedAt() { return createdAt; }

    public static ConfusableWordPairBuilder builder() {
        return new ConfusableWordPairBuilder();
    }

    public static class ConfusableWordPairBuilder {
        private Lesson lesson;
        private VocabularyWord wordA;
        private VocabularyWord wordB;
        private String contrastiveSentenceA;
        private String contrastiveSentenceB;

        public ConfusableWordPairBuilder lesson(Lesson lesson) { this.lesson = lesson; return this; }
        public ConfusableWordPairBuilder wordA(VocabularyWord wordA) { this.wordA = wordA; return this; }
        public ConfusableWordPairBuilder wordB(VocabularyWord wordB) { this.wordB = wordB; return this; }
        public ConfusableWordPairBuilder contrastiveSentenceA(String contrastiveSentenceA) { this.contrastiveSentenceA = contrastiveSentenceA; return this; }
        public ConfusableWordPairBuilder contrastiveSentenceB(String contrastiveSentenceB) { this.contrastiveSentenceB = contrastiveSentenceB; return this; }

        public ConfusableWordPair build() {
            ConfusableWordPair p = new ConfusableWordPair();
            p.lesson = this.lesson;
            p.wordA = this.wordA;
            p.wordB = this.wordB;
            p.contrastiveSentenceA = this.contrastiveSentenceA;
            p.contrastiveSentenceB = this.contrastiveSentenceB;
            p.createdAt = OffsetDateTime.now();
            return p;
        }
    }

    @PrePersist
    protected void onCreate() {
        createdAt = OffsetDateTime.now();
    }
}
