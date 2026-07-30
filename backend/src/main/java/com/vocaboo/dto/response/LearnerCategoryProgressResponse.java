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
public class LearnerCategoryProgressResponse {
    private UUID categoryId;
    private String categoryName;
    private Integer totalLessons;
    private Integer completedLessons;
    private BigDecimal categoryAccuracy;
}
