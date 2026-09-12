package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * Tracks a learner's performance within a specific classroom context.
 * This is a per-class aggregate — one row per (learner, classroom) pair.
 *
 * Design decision: class activity ALSO always updates LearnerMastery (global).
 * This table tracks the ADDITIONAL class-scoped view of the same work.
 */
@Entity
@Table(
    name = "class_performance",
    uniqueConstraints = {
        @UniqueConstraint(columnNames = {"learner_id", "classroom_id"})
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ClassPerformance {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "class_performance_id", updatable = false, nullable = false)
    private UUID classPerformanceId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "learner_id", nullable = false)
    private Learner learner;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "classroom_id", nullable = false)
    private Classroom classroom;

    /** Total points earned while in the class context. */
    @Column(name = "class_points", nullable = false)
    @Builder.Default
    private Integer classPoints = 0;

    /** Aggregated correct answers from class-context sessions. */
    @Column(name = "class_correct_answers", nullable = false)
    @Builder.Default
    private Integer classCorrectAnswers = 0;

    /** Aggregated total questions answered in class context. */
    @Column(name = "class_total_questions", nullable = false)
    @Builder.Default
    private Integer classTotalQuestions = 0;

    /** Computed overall accuracy within class context (0–100). */
    @Column(name = "class_accuracy", nullable = false, precision = 5, scale = 2)
    @Builder.Default
    private BigDecimal classAccuracy = BigDecimal.ZERO;

    /** Number of sessions completed in this class context. */
    @Column(name = "class_sessions_played", nullable = false)
    @Builder.Default
    private Integer classSessionsPlayed = 0;

    /**
     * Derived mastery level based on class_accuracy, mirroring global mastery levels:
     * LEARNING / FAMILIAR / PROFICIENT / MASTERED
     */
    @Column(name = "class_mastery_level", nullable = false, length = 20)
    @Builder.Default
    private String classMasteryLevel = "LEARNING";

    @Column(name = "created_at", updatable = false)
    @Builder.Default
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "updated_at")
    @Builder.Default
    private OffsetDateTime updatedAt = OffsetDateTime.now();

    // --- Getters ---
    public UUID getClassPerformanceId() { return classPerformanceId; }
    public Learner getLearner() { return learner; }
    public Classroom getClassroom() { return classroom; }
    public Integer getClassPoints() { return classPoints; }
    public Integer getClassCorrectAnswers() { return classCorrectAnswers; }
    public Integer getClassTotalQuestions() { return classTotalQuestions; }
    public BigDecimal getClassAccuracy() { return classAccuracy; }
    public Integer getClassSessionsPlayed() { return classSessionsPlayed; }
    public String getClassMasteryLevel() { return classMasteryLevel; }
    public OffsetDateTime getCreatedAt() { return createdAt; }
    public OffsetDateTime getUpdatedAt() { return updatedAt; }

    // --- Setters ---
    public void setClassPoints(Integer classPoints) { this.classPoints = classPoints; }
    public void setClassCorrectAnswers(Integer classCorrectAnswers) { this.classCorrectAnswers = classCorrectAnswers; }
    public void setClassTotalQuestions(Integer classTotalQuestions) { this.classTotalQuestions = classTotalQuestions; }
    public void setClassAccuracy(BigDecimal classAccuracy) { this.classAccuracy = classAccuracy; }
    public void setClassSessionsPlayed(Integer classSessionsPlayed) { this.classSessionsPlayed = classSessionsPlayed; }
    public void setClassMasteryLevel(String classMasteryLevel) { this.classMasteryLevel = classMasteryLevel; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }

    public static ClassPerformanceBuilder builder() { return new ClassPerformanceBuilder(); }

    public static class ClassPerformanceBuilder {
        private UUID classPerformanceId;
        private Learner learner;
        private Classroom classroom;
        private Integer classPoints = 0;
        private Integer classCorrectAnswers = 0;
        private Integer classTotalQuestions = 0;
        private BigDecimal classAccuracy = BigDecimal.ZERO;
        private Integer classSessionsPlayed = 0;
        private String classMasteryLevel = "LEARNING";
        private OffsetDateTime createdAt;
        private OffsetDateTime updatedAt;

        public ClassPerformanceBuilder classPerformanceId(UUID classPerformanceId) { this.classPerformanceId = classPerformanceId; return this; }
        public ClassPerformanceBuilder learner(Learner learner) { this.learner = learner; return this; }
        public ClassPerformanceBuilder classroom(Classroom classroom) { this.classroom = classroom; return this; }
        public ClassPerformanceBuilder classPoints(Integer classPoints) { this.classPoints = classPoints; return this; }
        public ClassPerformanceBuilder classCorrectAnswers(Integer classCorrectAnswers) { this.classCorrectAnswers = classCorrectAnswers; return this; }
        public ClassPerformanceBuilder classTotalQuestions(Integer classTotalQuestions) { this.classTotalQuestions = classTotalQuestions; return this; }
        public ClassPerformanceBuilder classAccuracy(BigDecimal classAccuracy) { this.classAccuracy = classAccuracy; return this; }
        public ClassPerformanceBuilder classSessionsPlayed(Integer classSessionsPlayed) { this.classSessionsPlayed = classSessionsPlayed; return this; }
        public ClassPerformanceBuilder classMasteryLevel(String classMasteryLevel) { this.classMasteryLevel = classMasteryLevel; return this; }
        public ClassPerformanceBuilder createdAt(OffsetDateTime createdAt) { this.createdAt = createdAt; return this; }
        public ClassPerformanceBuilder updatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; return this; }

        public ClassPerformance build() {
            ClassPerformance cp = new ClassPerformance();
            cp.classPerformanceId = this.classPerformanceId;
            cp.learner = this.learner;
            cp.classroom = this.classroom;
            cp.classPoints = this.classPoints != null ? this.classPoints : 0;
            cp.classCorrectAnswers = this.classCorrectAnswers != null ? this.classCorrectAnswers : 0;
            cp.classTotalQuestions = this.classTotalQuestions != null ? this.classTotalQuestions : 0;
            cp.classAccuracy = this.classAccuracy != null ? this.classAccuracy : BigDecimal.ZERO;
            cp.classSessionsPlayed = this.classSessionsPlayed != null ? this.classSessionsPlayed : 0;
            cp.classMasteryLevel = this.classMasteryLevel != null ? this.classMasteryLevel : "LEARNING";
            cp.createdAt = this.createdAt != null ? this.createdAt : OffsetDateTime.now();
            cp.updatedAt = this.updatedAt != null ? this.updatedAt : OffsetDateTime.now();
            return cp;
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
