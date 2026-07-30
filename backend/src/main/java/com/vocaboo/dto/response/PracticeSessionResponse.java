package com.vocaboo.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PracticeSessionResponse {
    private UUID sessionId;
    private UUID learnerId;
    private UUID lessonId;
    private Integer moduleNumber;
    private BigDecimal score;
    private Integer starsEarned;
    private OffsetDateTime completedAt;
    private OffsetDateTime createdAt;
}
