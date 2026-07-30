package com.vocaboo.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.OffsetDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PracticeResultResponse {
    private UUID resultId;
    private UUID sessionId;
    private UUID wordId;
    private Boolean isCorrect;
    private Integer attemptNumber;
    private String activityType;
    private Integer points;
    private OffsetDateTime recordedAt;
}
