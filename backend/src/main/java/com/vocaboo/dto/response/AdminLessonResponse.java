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

    public static AdminLessonResponseBuilder builder() {
        return new AdminLessonResponseBuilder();
    }

    public static class AdminLessonResponseBuilder {
        private UUID lessonId;
        private String lessonTitle;
        private String lessonDescription;
        private UUID categoryId;
        private String categoryName;
        private String gradeLevel;
        private Integer lessonOrder;
        private Integer totalWordCount;
        private String lessonType;
        private String contentStatus;
        private String targetGrades;
        private OffsetDateTime publishedDate;
        private OffsetDateTime createdAt;
        private OffsetDateTime updatedAt;
        private String contextParagraph;

        public AdminLessonResponseBuilder lessonId(UUID lessonId) { this.lessonId = lessonId; return this; }
        public AdminLessonResponseBuilder lessonTitle(String lessonTitle) { this.lessonTitle = lessonTitle; return this; }
        public AdminLessonResponseBuilder lessonDescription(String lessonDescription) { this.lessonDescription = lessonDescription; return this; }
        public AdminLessonResponseBuilder categoryId(UUID categoryId) { this.categoryId = categoryId; return this; }
        public AdminLessonResponseBuilder categoryName(String categoryName) { this.categoryName = categoryName; return this; }
        public AdminLessonResponseBuilder gradeLevel(String gradeLevel) { this.gradeLevel = gradeLevel; return this; }
        public AdminLessonResponseBuilder lessonOrder(Integer lessonOrder) { this.lessonOrder = lessonOrder; return this; }
        public AdminLessonResponseBuilder totalWordCount(Integer totalWordCount) { this.totalWordCount = totalWordCount; return this; }
        public AdminLessonResponseBuilder lessonType(String lessonType) { this.lessonType = lessonType; return this; }
        public AdminLessonResponseBuilder contentStatus(String contentStatus) { this.contentStatus = contentStatus; return this; }
        public AdminLessonResponseBuilder targetGrades(String targetGrades) { this.targetGrades = targetGrades; return this; }
        public AdminLessonResponseBuilder publishedDate(OffsetDateTime publishedDate) { this.publishedDate = publishedDate; return this; }
        public AdminLessonResponseBuilder createdAt(OffsetDateTime createdAt) { this.createdAt = createdAt; return this; }
        public AdminLessonResponseBuilder updatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; return this; }
        public AdminLessonResponseBuilder contextParagraph(String contextParagraph) { this.contextParagraph = contextParagraph; return this; }

        public AdminLessonResponse build() {
            AdminLessonResponse r = new AdminLessonResponse();
            r.lessonId = this.lessonId;
            r.lessonTitle = this.lessonTitle;
            r.lessonDescription = this.lessonDescription;
            r.categoryId = this.categoryId;
            r.categoryName = this.categoryName;
            r.gradeLevel = this.gradeLevel;
            r.lessonOrder = this.lessonOrder;
            r.totalWordCount = this.totalWordCount;
            r.lessonType = this.lessonType;
            r.contentStatus = this.contentStatus;
            r.targetGrades = this.targetGrades;
            r.publishedDate = this.publishedDate;
            r.createdAt = this.createdAt;
            r.updatedAt = this.updatedAt;
            r.contextParagraph = this.contextParagraph;
            return r;
        }
    }
}
