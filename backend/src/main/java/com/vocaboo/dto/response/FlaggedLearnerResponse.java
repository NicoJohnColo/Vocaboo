package com.vocaboo.dto.response;

import lombok.*;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FlaggedLearnerResponse {
    private UUID progressId;
    private UUID learnerId;
    private String learnerName;
    private String username;
    private String sectionName;
    private String gradeLevel;
    private UUID wordId;
    private String englishWord;
    private String cebuanoMeaning;
    private String partOfSpeech;
    private UUID lessonId;
    private String lessonTitle;
    private Integer reintroductionCount;
    private Integer consecutiveIncorrect;
    private String currentLevel;
    private OffsetDateTime flaggedAt;
    private String flagReason;
    private Integer totalAttempts;
    private BigDecimal accuracy;
}