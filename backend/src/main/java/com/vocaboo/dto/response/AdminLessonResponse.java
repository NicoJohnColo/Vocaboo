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

    @JsonProperty("module2_activities")
    private String module2Activities;

    @JsonProperty("module3_activities")
    private String module3Activities;

    @JsonProperty("module4_activities")
    private String module4Activities;

    @JsonProperty("upgrade_streak_required")
    private Integer upgradeStreakRequired;

    @JsonProperty("demotion_threshold")
    private Integer demotionThreshold;

    @JsonProperty("reintroduction_threshold")
    private Integer reintroductionThreshold;

    @JsonProperty("module3_upgrade_streak_required")
    private Integer module3UpgradeStreakRequired;

    @JsonProperty("module3_demotion_threshold")
    private Integer module3DemotionThreshold;

    @JsonProperty("streak_celebration_threshold")
    private Integer streakCelebrationThreshold;

    @JsonProperty("class_id")
    private UUID classId;

    @JsonProperty("class_name")
    private String className;

    @JsonProperty("class_code")
    private String classCode;

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
        private String module2Activities;
        private String module3Activities;
        private String module4Activities;
        private Integer upgradeStreakRequired;
        private Integer demotionThreshold;
        private Integer reintroductionThreshold;
        private Integer module3UpgradeStreakRequired;
        private Integer module3DemotionThreshold;
        private Integer streakCelebrationThreshold;
        private UUID classId;
        private String className;
        private String classCode;

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
        public AdminLessonResponseBuilder module2Activities(String module2Activities) { this.module2Activities = module2Activities; return this; }
        public AdminLessonResponseBuilder module3Activities(String module3Activities) { this.module3Activities = module3Activities; return this; }
        public AdminLessonResponseBuilder module4Activities(String module4Activities) { this.module4Activities = module4Activities; return this; }
        public AdminLessonResponseBuilder upgradeStreakRequired(Integer upgradeStreakRequired) { this.upgradeStreakRequired = upgradeStreakRequired; return this; }
        public AdminLessonResponseBuilder demotionThreshold(Integer demotionThreshold) { this.demotionThreshold = demotionThreshold; return this; }
        public AdminLessonResponseBuilder reintroductionThreshold(Integer reintroductionThreshold) { this.reintroductionThreshold = reintroductionThreshold; return this; }
        public AdminLessonResponseBuilder module3UpgradeStreakRequired(Integer module3UpgradeStreakRequired) { this.module3UpgradeStreakRequired = module3UpgradeStreakRequired; return this; }
        public AdminLessonResponseBuilder module3DemotionThreshold(Integer module3DemotionThreshold) { this.module3DemotionThreshold = module3DemotionThreshold; return this; }
        public AdminLessonResponseBuilder streakCelebrationThreshold(Integer streakCelebrationThreshold) { this.streakCelebrationThreshold = streakCelebrationThreshold; return this; }
        public AdminLessonResponseBuilder classId(UUID classId) { this.classId = classId; return this; }
        public AdminLessonResponseBuilder className(String className) { this.className = className; return this; }
        public AdminLessonResponseBuilder classCode(String classCode) { this.classCode = classCode; return this; }

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
            r.module2Activities = this.module2Activities;
            r.module3Activities = this.module3Activities;
            r.module4Activities = this.module4Activities;
            r.upgradeStreakRequired = this.upgradeStreakRequired;
            r.demotionThreshold = this.demotionThreshold;
            r.reintroductionThreshold = this.reintroductionThreshold;
            r.module3UpgradeStreakRequired = this.module3UpgradeStreakRequired;
            r.module3DemotionThreshold = this.module3DemotionThreshold;
            r.streakCelebrationThreshold = this.streakCelebrationThreshold;
            r.classId = this.classId;
            r.className = this.className;
            r.classCode = this.classCode;
            return r;
        }
    }
}
