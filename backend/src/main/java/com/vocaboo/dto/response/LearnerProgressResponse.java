package com.vocaboo.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LearnerProgressResponse {
    private UUID learnerId;
    private Integer totalSessionsPlayed;
    private Integer totalCorrectAnswers;
    private Integer totalQuestionsAnswered;
    private BigDecimal overallAccuracy;
    private Integer wordsMasteredCount;
    private Integer totalPoints;
    private Integer pointsThisWeek;
    private String masteryLevel;

    public static LearnerProgressResponseBuilder builder() { return new LearnerProgressResponseBuilder(); }

    public static class LearnerProgressResponseBuilder {
        private UUID learnerId;
        private Integer totalSessionsPlayed;
        private Integer totalCorrectAnswers;
        private Integer totalQuestionsAnswered;
        private BigDecimal overallAccuracy;
        private Integer wordsMasteredCount;
        private Integer totalPoints;
        private Integer pointsThisWeek;
        private String masteryLevel;

        public LearnerProgressResponseBuilder learnerId(UUID learnerId) { this.learnerId = learnerId; return this; }
        public LearnerProgressResponseBuilder totalSessionsPlayed(Integer totalSessionsPlayed) { this.totalSessionsPlayed = totalSessionsPlayed; return this; }
        public LearnerProgressResponseBuilder totalCorrectAnswers(Integer totalCorrectAnswers) { this.totalCorrectAnswers = totalCorrectAnswers; return this; }
        public LearnerProgressResponseBuilder totalQuestionsAnswered(Integer totalQuestionsAnswered) { this.totalQuestionsAnswered = totalQuestionsAnswered; return this; }
        public LearnerProgressResponseBuilder overallAccuracy(BigDecimal overallAccuracy) { this.overallAccuracy = overallAccuracy; return this; }
        public LearnerProgressResponseBuilder wordsMasteredCount(Integer wordsMasteredCount) { this.wordsMasteredCount = wordsMasteredCount; return this; }
        public LearnerProgressResponseBuilder totalPoints(Integer totalPoints) { this.totalPoints = totalPoints; return this; }
        public LearnerProgressResponseBuilder pointsThisWeek(Integer pointsThisWeek) { this.pointsThisWeek = pointsThisWeek; return this; }
        public LearnerProgressResponseBuilder masteryLevel(String masteryLevel) { this.masteryLevel = masteryLevel; return this; }

        public LearnerProgressResponse build() {
            LearnerProgressResponse r = new LearnerProgressResponse();
            r.learnerId = this.learnerId;
            r.totalSessionsPlayed = this.totalSessionsPlayed;
            r.totalCorrectAnswers = this.totalCorrectAnswers;
            r.totalQuestionsAnswered = this.totalQuestionsAnswered;
            r.overallAccuracy = this.overallAccuracy;
            r.wordsMasteredCount = this.wordsMasteredCount;
            r.totalPoints = this.totalPoints;
            r.pointsThisWeek = this.pointsThisWeek;
            r.masteryLevel = this.masteryLevel;
            return r;
        }
    }
}
