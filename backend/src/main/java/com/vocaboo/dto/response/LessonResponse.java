package com.vocaboo.dto.response;

import com.vocaboo.entity.GradeLevel;
import com.vocaboo.entity.LessonStatus;
import lombok.*;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LessonResponse {
    private UUID lessonId;
    private UUID categoryId;
    private String lessonTitle;
    private String lessonDescription;
    private GradeLevel gradeLevel;
    private Integer lessonOrder;
    private Integer totalWordCount;
    private Integer masteredWordCount;
    private Map<String, Integer> posTotalWordCounts;
    private Map<String, Integer> posMasteredWordCounts;
    private LessonStatus status;
    private BigDecimal masteryScore;
    private String lessonType;
    private List<UUID> sourceLessonIds;
    private UUID compositeReviewAfterLessonId;
    private String contextParagraph;
}
