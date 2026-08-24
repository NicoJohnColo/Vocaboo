package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "cumulative_review_results")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CumulativeReviewResult {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id", nullable = false)
    private CumulativeReviewSession session;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "word_id", nullable = false)
    private VocabularyWord word;

    @Column(name = "activity_type", nullable = false, length = 50)
    private String activityType;

    @Column(name = "correct", nullable = false)
    private boolean correct;

    @Column(name = "attempt_number", nullable = false)
    @Builder.Default
    private Integer attemptNumber = 1;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "cross_lesson_sentence_id")
    private CrossLessonSentence crossLessonSentence;

    @Column(name = "created_at", updatable = false)
    @Builder.Default
    private OffsetDateTime createdAt = OffsetDateTime.now();

    public boolean isCorrect() { return correct; }
    public String getActivityType() { return activityType; }
    public Integer getAttemptNumber() { return attemptNumber; }
    public OffsetDateTime getCreatedAt() { return createdAt; }

    public static CumulativeReviewResultBuilder builder() { return new CumulativeReviewResultBuilder(); }

    public static class CumulativeReviewResultBuilder {
        private CumulativeReviewSession session;
        private VocabularyWord word;
        private String activityType;
        private boolean correct;
        private Integer attemptNumber = 1;
        private CrossLessonSentence crossLessonSentence;

        public CumulativeReviewResultBuilder session(CumulativeReviewSession session) { this.session = session; return this; }
        public CumulativeReviewResultBuilder word(VocabularyWord word) { this.word = word; return this; }
        public CumulativeReviewResultBuilder activityType(String activityType) { this.activityType = activityType; return this; }
        public CumulativeReviewResultBuilder correct(boolean correct) { this.correct = correct; return this; }
        public CumulativeReviewResultBuilder attemptNumber(Integer attemptNumber) { this.attemptNumber = attemptNumber; return this; }
        public CumulativeReviewResultBuilder crossLessonSentence(CrossLessonSentence crossLessonSentence) { this.crossLessonSentence = crossLessonSentence; return this; }

        public CumulativeReviewResult build() {
            CumulativeReviewResult r = new CumulativeReviewResult();
            r.session = this.session;
            r.word = this.word;
            r.activityType = this.activityType;
            r.correct = this.correct;
            r.attemptNumber = this.attemptNumber;
            r.crossLessonSentence = this.crossLessonSentence;
            r.createdAt = OffsetDateTime.now();
            return r;
        }
    }
}
