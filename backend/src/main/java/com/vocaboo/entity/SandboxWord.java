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

    public UUID getWordId() { return wordId; }
    public String getEnglishWord() {
        return englishWord;
    }

    public static SandboxWordBuilder builder() { return new SandboxWordBuilder(); }

    public static class SandboxWordBuilder {
        private SandboxSession session;
        private String englishWord;
        private String cebuanoMeaning;
        private String exampleSentenceEnglish;
        private String exampleSentenceCebuano;
        private String phonologicalTipKey;
        private Integer wordOrder;

        public SandboxWordBuilder session(SandboxSession session) { this.session = session; return this; }
        public SandboxWordBuilder englishWord(String englishWord) { this.englishWord = englishWord; return this; }
        public SandboxWordBuilder cebuanoMeaning(String cebuanoMeaning) { this.cebuanoMeaning = cebuanoMeaning; return this; }
        public SandboxWordBuilder exampleSentenceEnglish(String exampleSentenceEnglish) { this.exampleSentenceEnglish = exampleSentenceEnglish; return this; }
        public SandboxWordBuilder exampleSentenceCebuano(String exampleSentenceCebuano) { this.exampleSentenceCebuano = exampleSentenceCebuano; return this; }
        public SandboxWordBuilder phonologicalTipKey(String phonologicalTipKey) { this.phonologicalTipKey = phonologicalTipKey; return this; }
        public SandboxWordBuilder wordOrder(Integer wordOrder) { this.wordOrder = wordOrder; return this; }
        public SandboxWordBuilder createdAt(OffsetDateTime createdAt) { return this; }

        public SandboxWord build() {
            SandboxWord w = new SandboxWord();
            w.session = this.session;
            w.englishWord = this.englishWord;
            w.cebuanoMeaning = this.cebuanoMeaning;
            w.exampleSentenceEnglish = this.exampleSentenceEnglish;
            w.exampleSentenceCebuano = this.exampleSentenceCebuano;
            w.phonologicalTipKey = this.phonologicalTipKey;
            w.wordOrder = this.wordOrder;
            w.createdAt = OffsetDateTime.now();
            return w;
        }
    }

    @PrePersist
    protected void onCreate() {
        createdAt = OffsetDateTime.now();
    }
}
