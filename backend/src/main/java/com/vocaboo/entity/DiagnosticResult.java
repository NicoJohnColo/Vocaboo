package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(
    name = "diagnostic_results",
    uniqueConstraints = {
        @UniqueConstraint(columnNames = {"learner_id", "lesson_id", "word_id", "session_id"})
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DiagnosticResult {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "result_id", updatable = false, nullable = false)
    private UUID resultId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "learner_id", nullable = false)
    private Learner learner;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lesson_id", nullable = false)
    private Lesson lesson;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "word_id", nullable = false)
    private VocabularyWord word;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id", nullable = false)
    private IntroductionSession session;

    @Column(name = "is_known", nullable = false)
    private Boolean isKnown;

    @Column(name = "recorded_at", updatable = false)
    @Builder.Default
    private OffsetDateTime recordedAt = OffsetDateTime.now();

    public static DiagnosticResultBuilder builder() { return new DiagnosticResultBuilder(); }

    public static class DiagnosticResultBuilder {
        private Learner learner;
        private Lesson lesson;
        private VocabularyWord word;
        private IntroductionSession session;
        private Boolean isKnown;

        public DiagnosticResultBuilder learner(Learner learner) { this.learner = learner; return this; }
        public DiagnosticResultBuilder lesson(Lesson lesson) { this.lesson = lesson; return this; }
        public DiagnosticResultBuilder word(VocabularyWord word) { this.word = word; return this; }
        public DiagnosticResultBuilder session(IntroductionSession session) { this.session = session; return this; }
        public DiagnosticResultBuilder isKnown(Boolean isKnown) { this.isKnown = isKnown; return this; }

        public DiagnosticResult build() {
            DiagnosticResult r = new DiagnosticResult();
            r.learner = this.learner;
            r.lesson = this.lesson;
            r.word = this.word;
            r.session = this.session;
            r.isKnown = this.isKnown;
            r.recordedAt = OffsetDateTime.now();
            return r;
        }
    }

    @PrePersist
    protected void onCreate() {
        recordedAt = OffsetDateTime.now();
    }
}
