package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "wrong_answer_records")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WrongAnswerRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "record_id", updatable = false, nullable = false)
    private UUID recordId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "learner_id", nullable = false)
    private Learner learner;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "word_id", nullable = false)
    private VocabularyWord word;

    @Column(name = "wrong_answer", nullable = false)
    private String wrongAnswer;

    @Column(name = "activity_format", nullable = false)
    private String activityFormat;

    @Column(name = "recorded_at", updatable = false)
    @Builder.Default
    private OffsetDateTime recordedAt = OffsetDateTime.now();

    public static WrongAnswerRecordBuilder builder() { return new WrongAnswerRecordBuilder(); }

    public static class WrongAnswerRecordBuilder {
        private Learner learner;
        private VocabularyWord word;
        private String wrongAnswer;
        private String activityFormat;

        public WrongAnswerRecordBuilder learner(Learner learner) { this.learner = learner; return this; }
        public WrongAnswerRecordBuilder word(VocabularyWord word) { this.word = word; return this; }
        public WrongAnswerRecordBuilder wrongAnswer(String wrongAnswer) { this.wrongAnswer = wrongAnswer; return this; }
        public WrongAnswerRecordBuilder activityFormat(String activityFormat) { this.activityFormat = activityFormat; return this; }

        public WrongAnswerRecord build() {
            WrongAnswerRecord r = new WrongAnswerRecord();
            r.learner = this.learner;
            r.word = this.word;
            r.wrongAnswer = this.wrongAnswer;
            r.activityFormat = this.activityFormat;
            r.recordedAt = OffsetDateTime.now();
            return r;
        }
    }

    @PrePersist
    protected void onCreate() {
        recordedAt = OffsetDateTime.now();
    }
}
