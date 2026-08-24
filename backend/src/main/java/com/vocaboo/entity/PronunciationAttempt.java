package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "pronunciation_attempts")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PronunciationAttempt {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "attempt_id", updatable = false, nullable = false)
    private UUID attemptId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "learner_id", nullable = false)
    private Learner learner;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id", nullable = false)
    private IntroductionSession session;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "word_id", nullable = false)
    private VocabularyWord word;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lesson_id", nullable = false)
    private Lesson lesson;

    @Column(name = "module_number", nullable = false)
    private Integer moduleNumber;

    @Column(name = "transcribed_text", columnDefinition = "TEXT")
    private String transcribedText;

    @Column(name = "target_word", nullable = false)
    private String targetWord;

    @Column(name = "is_correct")
    private Boolean isCorrect;

    @Column(name = "attempt_number", nullable = false)
    private Integer attemptNumber;

    @Column(name = "is_inconclusive", nullable = false)
    @Builder.Default
    private Boolean isInconclusive = false;

    @Column(name = "recorded_at", updatable = false)
    @Builder.Default
    private OffsetDateTime recordedAt = OffsetDateTime.now();

    public UUID getAttemptId() { return attemptId; }
    public Boolean getIsCorrect() { return isCorrect; }
    public Boolean getIsInconclusive() { return isInconclusive; }
    public VocabularyWord getWord() { return word; }
    public OffsetDateTime getRecordedAt() { return recordedAt; }
    public Learner getLearner() { return learner; }
    public void setTargetWord(String targetWord) { this.targetWord = targetWord; }

    public static PronunciationAttemptBuilder builder() { return new PronunciationAttemptBuilder(); }

    public static class PronunciationAttemptBuilder {
        private Learner learner;
        private IntroductionSession session;
        private VocabularyWord word;
        private Lesson lesson;
        private Integer moduleNumber;
        private String transcribedText;
        private String targetWord;
        private Boolean isCorrect;
        private Integer attemptNumber;
        private Boolean isInconclusive = false;

        public PronunciationAttemptBuilder learner(Learner learner) { this.learner = learner; return this; }
        public PronunciationAttemptBuilder session(IntroductionSession session) { this.session = session; return this; }
        public PronunciationAttemptBuilder word(VocabularyWord word) { this.word = word; return this; }
        public PronunciationAttemptBuilder lesson(Lesson lesson) { this.lesson = lesson; return this; }
        public PronunciationAttemptBuilder moduleNumber(Integer moduleNumber) { this.moduleNumber = moduleNumber; return this; }
        public PronunciationAttemptBuilder transcribedText(String transcribedText) { this.transcribedText = transcribedText; return this; }
        public PronunciationAttemptBuilder targetWord(String targetWord) { this.targetWord = targetWord; return this; }
        public PronunciationAttemptBuilder isCorrect(Boolean isCorrect) { this.isCorrect = isCorrect; return this; }
        public PronunciationAttemptBuilder attemptNumber(Integer attemptNumber) { this.attemptNumber = attemptNumber; return this; }
        public PronunciationAttemptBuilder isInconclusive(Boolean isInconclusive) { this.isInconclusive = isInconclusive; return this; }

        public PronunciationAttempt build() {
            PronunciationAttempt p = new PronunciationAttempt();
            p.learner = this.learner;
            p.session = this.session;
            p.word = this.word;
            p.lesson = this.lesson;
            p.moduleNumber = this.moduleNumber;
            p.transcribedText = this.transcribedText;
            p.targetWord = this.targetWord;
            p.isCorrect = this.isCorrect;
            p.attemptNumber = this.attemptNumber;
            p.isInconclusive = this.isInconclusive;
            p.recordedAt = OffsetDateTime.now();
            return p;
        }
    }

    @PrePersist
    protected void onCreate() {
        recordedAt = OffsetDateTime.now();
    }
}
