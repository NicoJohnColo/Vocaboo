package com.vocaboo.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AdminLessonResponse {
    @JsonProperty("lesson_id")
    private UUID lessonId;
    
    @JsonProperty("lesson_title")
    private String lessonTitle;
    
    @JsonProperty("lesson_description")
    private String lessonDescription;
    
    @JsonProperty("category_id")
    private UUID categoryId;
    
    @JsonProperty("category_name")
    private String categoryName;
    
    @JsonProperty("grade_level")
    private String gradeLevel;
    
    @JsonProperty("lesson_order")
    private Integer lessonOrder;
    
    @JsonProperty("total_word_count")
    private Integer totalWordCount;
    
    @JsonProperty("lesson_type")
    private String lessonType;
    
    @JsonProperty("content_status")
    private String contentStatus; // DRAFT, PUBLISHED, ARCHIVED
    
    @JsonProperty("target_grades")
    private String targetGrades;
    
    @JsonProperty("published_date")
    private OffsetDateTime publishedDate;
    
    @JsonProperty("created_at")
    private OffsetDateTime createdAt;
    
    @JsonProperty("updated_at")
    private OffsetDateTime updatedAt;
    
    @JsonProperty("context_paragraph")
    private String contextParagraph;
}
