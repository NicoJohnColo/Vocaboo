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

    @Column(name = "true_or_false_statement", columnDefinition = "TEXT")
    private String trueOrFalseStatement;

    @Column(name = "true_or_false_answer")
    @Builder.Default
    private Boolean trueOrFalseAnswer = true;

    @Column(name = "hint_clue", columnDefinition = "TEXT")
    private String hintClue;

    @Column(name = "confusable_partner_word", length = 100)
    private String confusablePartnerWord;

    @Column(name = "confusable_cebuano_distinction", columnDefinition = "TEXT")
    private String confusableCebuanoDistinction;

    @Column(name = "confusable_contrast_sentence_a", columnDefinition = "TEXT")
    private String confusableContrastSentenceA;

    @Column(name = "confusable_contrast_sentence_b", columnDefinition = "TEXT")
    private String confusableContrastSentenceB;

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
        private String trueOrFalseStatement;
        private Boolean trueOrFalseAnswer = true;
        private String hintClue;
        private String confusablePartnerWord;
        private String confusableCebuanoDistinction;
        private String confusableContrastSentenceA;
        private String confusableContrastSentenceB;
        private Integer wordOrder;

        public SandboxWordBuilder session(SandboxSession session) { this.session = session; return this; }
        public SandboxWordBuilder englishWord(String englishWord) { this.englishWord = englishWord; return this; }
        public SandboxWordBuilder cebuanoMeaning(String cebuanoMeaning) { this.cebuanoMeaning = cebuanoMeaning; return this; }
        public SandboxWordBuilder exampleSentenceEnglish(String exampleSentenceEnglish) { this.exampleSentenceEnglish = exampleSentenceEnglish; return this; }
        public SandboxWordBuilder exampleSentenceCebuano(String exampleSentenceCebuano) { this.exampleSentenceCebuano = exampleSentenceCebuano; return this; }
        public SandboxWordBuilder phonologicalTipKey(String phonologicalTipKey) { this.phonologicalTipKey = phonologicalTipKey; return this; }
        public SandboxWordBuilder trueOrFalseStatement(String trueOrFalseStatement) { this.trueOrFalseStatement = trueOrFalseStatement; return this; }
        public SandboxWordBuilder trueOrFalseAnswer(Boolean trueOrFalseAnswer) { this.trueOrFalseAnswer = trueOrFalseAnswer; return this; }
        public SandboxWordBuilder hintClue(String hintClue) { this.hintClue = hintClue; return this; }
        public SandboxWordBuilder confusablePartnerWord(String confusablePartnerWord) { this.confusablePartnerWord = confusablePartnerWord; return this; }
        public SandboxWordBuilder confusableCebuanoDistinction(String confusableCebuanoDistinction) { this.confusableCebuanoDistinction = confusableCebuanoDistinction; return this; }
        public SandboxWordBuilder confusableContrastSentenceA(String confusableContrastSentenceA) { this.confusableContrastSentenceA = confusableContrastSentenceA; return this; }
        public SandboxWordBuilder confusableContrastSentenceB(String confusableContrastSentenceB) { this.confusableContrastSentenceB = confusableContrastSentenceB; return this; }
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
            w.trueOrFalseStatement = this.trueOrFalseStatement;
            w.trueOrFalseAnswer = this.trueOrFalseAnswer != null ? this.trueOrFalseAnswer : true;
            w.hintClue = this.hintClue;
            w.confusablePartnerWord = this.confusablePartnerWord;
            w.confusableCebuanoDistinction = this.confusableCebuanoDistinction;
            w.confusableContrastSentenceA = this.confusableContrastSentenceA;
            w.confusableContrastSentenceB = this.confusableContrastSentenceB;
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
