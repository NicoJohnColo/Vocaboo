package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "sandbox_words")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SandboxWord {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "word_id", updatable = false, nullable = false)
    private UUID wordId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id", nullable = false)
    private SandboxSession session;

    @Column(name = "english_word", nullable = false, length = 100)
    private String englishWord;

    @Column(name = "cebuano_meaning", nullable = false, columnDefinition = "TEXT")
    private String cebuanoMeaning;

    @Column(name = "example_sentence_english", nullable = false, columnDefinition = "TEXT")
    private String exampleSentenceEnglish;

    @Column(name = "example_sentence_cebuano", columnDefinition = "TEXT")
    private String exampleSentenceCebuano;

    @Column(name = "phonological_tip_key", length = 100)
    private String phonologicalTipKey;

    @Column(name = "word_order", nullable = false)
    private Integer wordOrder;

    @Column(name = "created_at", updatable = false)
    @Builder.Default
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @PrePersist
    protected void onCreate() {
        createdAt = OffsetDateTime.now();
    }
}
