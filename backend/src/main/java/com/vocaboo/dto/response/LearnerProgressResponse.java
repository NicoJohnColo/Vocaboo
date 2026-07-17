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
}
