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

    @PrePersist
    protected void onCreate() {
        createdAt = OffsetDateTime.now();
    }
}
