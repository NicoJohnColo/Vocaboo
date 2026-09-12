package com.vocaboo.dto.response;

import lombok.*;
import java.math.BigDecimal;
import java.util.UUID;

/**
 * Response DTO representing a learner's performance within a single classroom.
 * Returned alongside global (LearnerMastery) stats so the mobile app can display
 * both scores independently.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ClassPerformanceResponse {

    private UUID classId;
    private String className;
    private String classCode;

    /** Total points earned in class context. */
    private Integer classPoints;

    /** Overall accuracy (0–100) within class context. */
    private BigDecimal classAccuracy;

    /** Derived mastery level: LEARNING / FAMILIAR / PROFICIENT / MASTERED */
    private String classMasteryLevel;

    /** Number of sessions completed in this class context. */
    private Integer classSessionsPlayed;

    /** Total questions answered in class context. */
    private Integer classTotalQuestions;

    /** Total correct answers in class context. */
    private Integer classCorrectAnswers;

    /**
     * Optional: the learner's rank within this class leaderboard.
     * Populated by the leaderboard endpoint, null when fetched directly.
     */
    private Integer classRank;

    public static ClassPerformanceResponseBuilder builder() { return new ClassPerformanceResponseBuilder(); }

    public static class ClassPerformanceResponseBuilder {
        private UUID classId;
        private String className;
        private String classCode;
        private Integer classPoints;
        private BigDecimal classAccuracy;
        private String classMasteryLevel;
        private Integer classSessionsPlayed;
        private Integer classTotalQuestions;
        private Integer classCorrectAnswers;
        private Integer classRank;

        public ClassPerformanceResponseBuilder classId(UUID classId) { this.classId = classId; return this; }
        public ClassPerformanceResponseBuilder className(String className) { this.className = className; return this; }
        public ClassPerformanceResponseBuilder classCode(String classCode) { this.classCode = classCode; return this; }
        public ClassPerformanceResponseBuilder classPoints(Integer classPoints) { this.classPoints = classPoints; return this; }
        public ClassPerformanceResponseBuilder classAccuracy(BigDecimal classAccuracy) { this.classAccuracy = classAccuracy; return this; }
        public ClassPerformanceResponseBuilder classMasteryLevel(String classMasteryLevel) { this.classMasteryLevel = classMasteryLevel; return this; }
        public ClassPerformanceResponseBuilder classSessionsPlayed(Integer classSessionsPlayed) { this.classSessionsPlayed = classSessionsPlayed; return this; }
        public ClassPerformanceResponseBuilder classTotalQuestions(Integer classTotalQuestions) { this.classTotalQuestions = classTotalQuestions; return this; }
        public ClassPerformanceResponseBuilder classCorrectAnswers(Integer classCorrectAnswers) { this.classCorrectAnswers = classCorrectAnswers; return this; }
        public ClassPerformanceResponseBuilder classRank(Integer classRank) { this.classRank = classRank; return this; }

        public ClassPerformanceResponse build() {
            ClassPerformanceResponse r = new ClassPerformanceResponse();
            r.classId = this.classId;
            r.className = this.className;
            r.classCode = this.classCode;
            r.classPoints = this.classPoints != null ? this.classPoints : 0;
            r.classAccuracy = this.classAccuracy != null ? this.classAccuracy : BigDecimal.ZERO;
            r.classMasteryLevel = this.classMasteryLevel != null ? this.classMasteryLevel : "LEARNING";
            r.classSessionsPlayed = this.classSessionsPlayed != null ? this.classSessionsPlayed : 0;
            r.classTotalQuestions = this.classTotalQuestions != null ? this.classTotalQuestions : 0;
            r.classCorrectAnswers = this.classCorrectAnswers != null ? this.classCorrectAnswers : 0;
            r.classRank = this.classRank;
            return r;
        }
    }
}
