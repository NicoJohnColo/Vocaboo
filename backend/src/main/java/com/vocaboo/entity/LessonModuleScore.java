package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(
    name = "lesson_module_scores",
    uniqueConstraints = {
        @UniqueConstraint(columnNames = {"learner_id", "lesson_id", "module_number"})
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LessonModuleScore {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "score_id", updatable = false, nullable = false)
    private UUID scoreId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "learner_id", nullable = false)
    private Learner learner;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lesson_id", nullable = false)
    private Lesson lesson;

    @Column(name = "module_number", nullable = false)
    private Integer moduleNumber;

    @Column(name = "correct_count", nullable = false)
    @Builder.Default
    private Integer correctCount = 0;

    @Column(name = "total_count", nullable = false)
    @Builder.Default
    private Integer totalCount = 0;

    @Column(name = "score", precision = 5, scale = 2, nullable = false)
    @Builder.Default
    private BigDecimal score = BigDecimal.ZERO;

    @Column(name = "stars_earned", nullable = false)
    @Builder.Default
    private Integer starsEarned = 0;

    @Column(name = "time_seconds")
    private Integer timeSeconds;

    @Column(name = "recorded_at", updatable = false)
    @Builder.Default
    private OffsetDateTime recordedAt = OffsetDateTime.now();

    @Column(name = "updated_at")
    @Builder.Default
    private OffsetDateTime updatedAt = OffsetDateTime.now();

    /**
     * Context in which this module score was achieved:
     * "GLOBAL" — free/personal app usage (default).
     * "CLASS"  — launched from within a class context.
     */
    @Column(name = "context_type", nullable = false, length = 10)
    @Builder.Default
    private String contextType = "GLOBAL";

    /** Linked classroom when context_type = "CLASS". Null for GLOBAL. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "classroom_id")
    private Classroom classroom;

    public Lesson getLesson() {
        return lesson;
    }

    public Integer getModuleNumber() {
        return moduleNumber;
    }

    public BigDecimal getScore() {
        return score;
    }

    public Integer getCorrectCount() {
        return correctCount;
    }

    public Integer getTotalCount() {
        return totalCount;
    }

    public Integer getTimeSeconds() {
        return timeSeconds;
    }

    public void setCorrectCount(Integer correctCount) { this.correctCount = correctCount; }
    public void setTotalCount(Integer totalCount) { this.totalCount = totalCount; }
    public void setScore(BigDecimal score) { this.score = score; }
    public void setStarsEarned(Integer starsEarned) { this.starsEarned = starsEarned; }
    public void setTimeSeconds(Integer timeSeconds) { this.timeSeconds = timeSeconds; }
    public String getContextType() { return contextType; }
    public Classroom getClassroom() { return classroom; }
    public void setContextType(String contextType) { this.contextType = contextType; }
    public void setClassroom(Classroom classroom) { this.classroom = classroom; }

    public static LessonModuleScoreBuilder builder() { return new LessonModuleScoreBuilder(); }

    public static class LessonModuleScoreBuilder {
        private Learner learner;
        private Lesson lesson;
        private Integer moduleNumber;
        private Integer correctCount = 0;
        private Integer totalCount = 0;
        private BigDecimal score = BigDecimal.ZERO;
        private Integer starsEarned = 0;
        private Integer timeSeconds;
        private String contextType = "GLOBAL";
        private Classroom classroom;

        public LessonModuleScoreBuilder learner(Learner learner) { this.learner = learner; return this; }
        public LessonModuleScoreBuilder lesson(Lesson lesson) { this.lesson = lesson; return this; }
        public LessonModuleScoreBuilder moduleNumber(Integer moduleNumber) { this.moduleNumber = moduleNumber; return this; }
        public LessonModuleScoreBuilder correctCount(Integer correctCount) { this.correctCount = correctCount; return this; }
        public LessonModuleScoreBuilder totalCount(Integer totalCount) { this.totalCount = totalCount; return this; }
        public LessonModuleScoreBuilder score(BigDecimal score) { this.score = score; return this; }
        public LessonModuleScoreBuilder starsEarned(Integer starsEarned) { this.starsEarned = starsEarned; return this; }
        public LessonModuleScoreBuilder timeSeconds(Integer timeSeconds) { this.timeSeconds = timeSeconds; return this; }
        public LessonModuleScoreBuilder contextType(String contextType) { this.contextType = contextType; return this; }
        public LessonModuleScoreBuilder classroom(Classroom classroom) { this.classroom = classroom; return this; }

        public LessonModuleScore build() {
            LessonModuleScore s = new LessonModuleScore();
            s.learner = this.learner;
            s.lesson = this.lesson;
            s.moduleNumber = this.moduleNumber;
            s.correctCount = this.correctCount;
            s.totalCount = this.totalCount;
            s.score = this.score;
            s.starsEarned = this.starsEarned;
            s.timeSeconds = this.timeSeconds;
            s.contextType = this.contextType != null ? this.contextType : "GLOBAL";
            s.classroom = this.classroom;
            s.recordedAt = OffsetDateTime.now();
            s.updatedAt = OffsetDateTime.now();
            return s;
        }
    }

    @PrePersist
    protected void onCreate() {
        recordedAt = OffsetDateTime.now();
        updatedAt = OffsetDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = OffsetDateTime.now();
    }
}