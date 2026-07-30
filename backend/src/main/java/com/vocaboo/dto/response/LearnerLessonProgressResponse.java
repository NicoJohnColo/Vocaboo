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
public class LearnerLessonProgressResponse {
    private UUID lessonId;
    private String lessonTitle;
    private UUID categoryId;
    private String categoryName;
    private BigDecimal accuracyRate;
    private Integer starsEarned;
    private Integer totalAttempts;
    private OffsetDateTime completedAt;
    private String status; // 'COMPLETED', 'UNLOCKED', 'LOCKED'
}
