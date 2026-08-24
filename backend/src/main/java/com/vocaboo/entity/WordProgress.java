package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcType;
import org.hibernate.dialect.PostgreSQLEnumJdbcType;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(
    name = "word_progress",
    uniqueConstraints = {
        @UniqueConstraint(columnNames = {"session_id", "word_id", "module_number"})
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WordProgress {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "progress_id", updatable = false, nullable = false)
    private UUID progressId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id", nullable = false)
    private IntroductionSession session;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "learner_id", nullable = false)
    private Learner learner;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lesson_id", nullable = false)
    private Lesson lesson;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "word_id", nullable = false)
    private VocabularyWord word;

    @Column(name = "module_number", nullable = false)
    @Builder.Default
    private Integer moduleNumber = 1;

    @Enumerated(EnumType.STRING)
    @JdbcType(PostgreSQLEnumJdbcType.class)
    @Column(name = "pathway", nullable = false, columnDefinition = "pathway_enum")
    private Pathway pathway;

    @Column(name = "step_completed", nullable = false)
    @Builder.Default
    private Integer stepCompleted = 0;

    @Enumerated(EnumType.STRING)
    @JdbcType(PostgreSQLEnumJdbcType.class)
    @Column(name = "status", nullable = false, columnDefinition = "word_status_enum")
    @Builder.Default
    private WordStatus status = WordStatus.INTRODUCED;

    @Column(name = "completed_at")
    private OffsetDateTime completedAt;

    @Column(name = "created_at", updatable = false)
    @Builder.Default
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "updated_at")
    @Builder.Default
    private OffsetDateTime updatedAt = OffsetDateTime.now();

    public UUID getProgressId() { return progressId; }
    public VocabularyWord getWord() { return word; }
    public Pathway getPathway() { return pathway; }
    public Integer getStepCompleted() { return stepCompleted; }
    public WordStatus getStatus() { return status; }
    public OffsetDateTime getCompletedAt() { return completedAt; }
    public void setCompletedAt(OffsetDateTime completedAt) { this.completedAt = completedAt; }
    public void setPathway(Pathway pathway) { this.pathway = pathway; }
    public void setStepCompleted(Integer stepCompleted) { this.stepCompleted = stepCompleted; }
    public void setStatus(WordStatus status) { this.status = status; }

    public static WordProgressBuilder builder() { return new WordProgressBuilder(); }

    public static class WordProgressBuilder {
        private IntroductionSession session;
        private Learner learner;
        private Lesson lesson;
        private VocabularyWord word;
        private Integer moduleNumber = 1;
        private Pathway pathway;
        private Integer stepCompleted = 0;
        private WordStatus status = WordStatus.INTRODUCED;

        public WordProgressBuilder session(IntroductionSession session) { this.session = session; return this; }
        public WordProgressBuilder learner(Learner learner) { this.learner = learner; return this; }
        public WordProgressBuilder lesson(Lesson lesson) { this.lesson = lesson; return this; }
        public WordProgressBuilder word(VocabularyWord word) { this.word = word; return this; }
        public WordProgressBuilder moduleNumber(Integer moduleNumber) { this.moduleNumber = moduleNumber; return this; }
        public WordProgressBuilder pathway(Pathway pathway) { this.pathway = pathway; return this; }
        public WordProgressBuilder stepCompleted(Integer stepCompleted) { this.stepCompleted = stepCompleted; return this; }
        public WordProgressBuilder status(WordStatus status) { this.status = status; return this; }

        public WordProgress build() {
            WordProgress p = new WordProgress();
            p.session = this.session;
            p.learner = this.learner;
            p.lesson = this.lesson;
            p.word = this.word;
            p.moduleNumber = this.moduleNumber;
            p.pathway = this.pathway;
            p.stepCompleted = this.stepCompleted;
            p.status = this.status;
            p.createdAt = OffsetDateTime.now();
            p.updatedAt = OffsetDateTime.now();
            return p;
        }
    }

    @PrePersist
    protected void onCreate() {
        createdAt = OffsetDateTime.now();
        updatedAt = OffsetDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = OffsetDateTime.now();
    }
}
