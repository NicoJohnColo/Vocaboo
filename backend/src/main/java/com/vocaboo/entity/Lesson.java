package com.vocaboo.entity;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcType;
import org.hibernate.dialect.PostgreSQLEnumJdbcType;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Entity
@Table(
    name = "lessons",
    uniqueConstraints = {
        @UniqueConstraint(columnNames = {"category_id", "lesson_order"})
    }
)
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Lesson {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "lesson_id", updatable = false, nullable = false)
    private UUID lessonId;

    @JsonIgnoreProperties({"hibernateLazyInitializer", "handler", "teacher", "classroom"})
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id", nullable = false)
    private VocabularyCategory category;

    @Column(name = "lesson_title", nullable = false, length = 200)
    private String lessonTitle;

    @Column(name = "lesson_description", columnDefinition = "TEXT")
    private String lessonDescription;

    @Enumerated(EnumType.STRING)
    @JdbcType(PostgreSQLEnumJdbcType.class)
    @Column(name = "grade_level", nullable = false, columnDefinition = "grade_level_enum")
    private GradeLevel gradeLevel;

    @Column(name = "lesson_order", nullable = false)
    @Builder.Default
    private Integer lessonOrder = 1;

    @Column(name = "total_word_count", nullable = false)
    @Builder.Default
    private Integer totalWordCount = 0;

    @Enumerated(EnumType.STRING)
    @JdbcType(PostgreSQLEnumJdbcType.class)
    @Column(name = "lesson_type", columnDefinition = "lesson_type_enum")
    @Builder.Default
    private LessonType lessonType = LessonType.REGULAR;

    @Column(name = "source_lesson_ids", columnDefinition = "UUID[]")
    private List<UUID> sourceLessonIds;

    @Column(name = "context_paragraph", columnDefinition = "TEXT")
    private String contextParagraph;

    @Column(name = "composite_review_after_lesson_id")
    private UUID compositeReviewAfterLessonId;

    @JsonIgnoreProperties({"hibernateLazyInitializer", "handler", "teacher"})
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "class_id")
    private Classroom classroom;

    @Column(name = "created_at", updatable = false)
    @Builder.Default
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "updated_at")
    @Builder.Default
    private OffsetDateTime updatedAt = OffsetDateTime.now();

    // ── Admin Content Management Fields ──────────────────────────────────────

    @Column(name = "is_deleted", nullable = false)
    @Builder.Default
    private Boolean isDeleted = false;

    @Column(name = "content_status", length = 20)
    @Builder.Default
    private String contentStatus = "DRAFT";

    @Column(name = "published_date")
    private OffsetDateTime publishedDate;

    @Column(name = "published_by_admin_id")
    private UUID publishedByAdminId;

    @Column(name = "target_grades", columnDefinition = "TEXT")
    private String targetGrades;

    // ── Per-Lesson Activity & Mastery Configurations ─────────────────────────

    @Column(name = "module2_activities", columnDefinition = "TEXT")
    @Builder.Default
    private String module2Activities = "MULTIPLE_CHOICE;FILL_IN_BLANK;MATCHING;WORD_SCRAMBLE;IMAGE_LABELING;TRUE_OR_FALSE";

    @Column(name = "module3_activities", columnDefinition = "TEXT")
    @Builder.Default
    private String module3Activities = "SENTENCE_COMPLETION;SENTENCE_ARRANGEMENT;PRONUNCIATION_FEEDBACK";

    @Column(name = "module4_activities", columnDefinition = "TEXT")
    @Builder.Default
    private String module4Activities = "MULTIPLE_CHOICE;MATCHING;FILL_IN_BLANK;WORD_SCRAMBLE;SENTENCE_RECONSTRUCTION;TRUE_OR_FALSE";

    @Column(name = "upgrade_streak_required")
    @Builder.Default
    private Integer upgradeStreakRequired = 2;

    @Column(name = "demotion_threshold")
    @Builder.Default
    private Integer demotionThreshold = 2;

    @Column(name = "reintroduction_threshold")
    @Builder.Default
    private Integer reintroductionThreshold = 4;

    @Column(name = "module3_upgrade_streak_required")
    @Builder.Default
    private Integer module3UpgradeStreakRequired = 2;

    @Column(name = "module3_demotion_threshold")
    @Builder.Default
    private Integer module3DemotionThreshold = 1;

    @Column(name = "streak_celebration_threshold")
    @Builder.Default
    private Integer streakCelebrationThreshold = 3;

    public UUID getLessonId() {
        return lessonId;
    }

    public String getLessonTitle() {
        return lessonTitle;
    }

    public GradeLevel getGradeLevel() {
        return gradeLevel;
    }

    public Boolean getIsDeleted() {
        return isDeleted;
    }

    public VocabularyCategory getCategory() {
        return category;
    }

    public Integer getLessonOrder() {
        return lessonOrder;
    }

    public void setLessonOrder(Integer lessonOrder) {
        this.lessonOrder = lessonOrder;
    }

    public String getLessonDescription() {
        return lessonDescription;
    }

    public Integer getTotalWordCount() {
        return totalWordCount;
    }

    public LessonType getLessonType() {
        return lessonType;
    }

    public String getContentStatus() {
        return contentStatus;
    }

    public String getTargetGrades() {
        return targetGrades;
    }

    public OffsetDateTime getPublishedDate() {
        return publishedDate;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public OffsetDateTime getUpdatedAt() {
        return updatedAt;
    }

    public String getContextParagraph() {
        return contextParagraph;
    }

    public List<UUID> getSourceLessonIds() { return sourceLessonIds; }
    public UUID getCompositeReviewAfterLessonId() { return compositeReviewAfterLessonId; }

    public void setLessonTitle(String lessonTitle) {
        this.lessonTitle = lessonTitle;
    }

    public void setLessonDescription(String lessonDescription) {
        this.lessonDescription = lessonDescription;
    }

    public void setGradeLevel(GradeLevel gradeLevel) {
        this.gradeLevel = gradeLevel;
    }

    public void setTotalWordCount(Integer totalWordCount) {
        this.totalWordCount = totalWordCount;
    }

    public void setContextParagraph(String contextParagraph) {
        this.contextParagraph = contextParagraph;
    }

    public void setContentStatus(String contentStatus) {
        this.contentStatus = contentStatus;
    }

    public void setPublishedDate(OffsetDateTime publishedDate) {
        this.publishedDate = publishedDate;
    }

    public void setPublishedByAdminId(UUID publishedByAdminId) {
        this.publishedByAdminId = publishedByAdminId;
    }

    public void setLessonId(UUID lessonId) {
        this.lessonId = lessonId;
    }

    public void setTargetGrades(String targetGrades) {
        this.targetGrades = targetGrades;
    }

    public Classroom getClassroom() { return classroom; }
    public void setClassroom(Classroom classroom) { this.classroom = classroom; }

    public static LessonBuilder builder() {
        return new LessonBuilder();
    }

    public static class LessonBuilder {
        private UUID lessonId;
        private VocabularyCategory category;
        private Classroom classroom;
        private String lessonTitle;
        private String lessonDescription;
        private GradeLevel gradeLevel;
        private LessonType lessonType = LessonType.REGULAR;
        private Integer lessonOrder = 1;
        private Integer totalWordCount = 0;
        private List<UUID> sourceLessonIds;
        private String contextParagraph;
        private UUID compositeReviewAfterLessonId;
        private String contentStatus = "DRAFT";
        private Boolean isDeleted = false;
        private String module2Activities = "MULTIPLE_CHOICE;FILL_IN_BLANK;MATCHING;WORD_SCRAMBLE;IMAGE_LABELING;TRUE_OR_FALSE";
        private String module3Activities = "SENTENCE_COMPLETION;SENTENCE_ARRANGEMENT;PRONUNCIATION_FEEDBACK";
        private String module4Activities = "MULTIPLE_CHOICE;MATCHING;FILL_IN_BLANK;WORD_SCRAMBLE;SENTENCE_RECONSTRUCTION;TRUE_OR_FALSE";
        private Integer upgradeStreakRequired = 2;
        private Integer demotionThreshold = 2;
        private Integer reintroductionThreshold = 4;
        private Integer module3UpgradeStreakRequired = 2;
        private Integer module3DemotionThreshold = 1;
        private Integer streakCelebrationThreshold = 3;

        public LessonBuilder lessonId(UUID lessonId) { this.lessonId = lessonId; return this; }
        public LessonBuilder category(VocabularyCategory category) { this.category = category; return this; }
        public LessonBuilder classroom(Classroom classroom) { this.classroom = classroom; return this; }
        public LessonBuilder lessonTitle(String lessonTitle) { this.lessonTitle = lessonTitle; return this; }
        public LessonBuilder lessonDescription(String lessonDescription) { this.lessonDescription = lessonDescription; return this; }
        public LessonBuilder gradeLevel(GradeLevel gradeLevel) { this.gradeLevel = gradeLevel; return this; }
        public LessonBuilder lessonType(LessonType lessonType) { this.lessonType = lessonType; return this; }
        public LessonBuilder lessonOrder(Integer lessonOrder) { this.lessonOrder = lessonOrder; return this; }
        public LessonBuilder totalWordCount(Integer totalWordCount) { this.totalWordCount = totalWordCount; return this; }
        public LessonBuilder sourceLessonIds(List<UUID> sourceLessonIds) { this.sourceLessonIds = sourceLessonIds; return this; }
        public LessonBuilder contextParagraph(String contextParagraph) { this.contextParagraph = contextParagraph; return this; }
        public LessonBuilder compositeReviewAfterLessonId(UUID compositeReviewAfterLessonId) { this.compositeReviewAfterLessonId = compositeReviewAfterLessonId; return this; }
        public LessonBuilder contentStatus(String contentStatus) { this.contentStatus = contentStatus; return this; }
        public LessonBuilder isDeleted(Boolean isDeleted) { this.isDeleted = isDeleted; return this; }
        public LessonBuilder module2Activities(String module2Activities) { this.module2Activities = module2Activities; return this; }
        public LessonBuilder module3Activities(String module3Activities) { this.module3Activities = module3Activities; return this; }
        public LessonBuilder module4Activities(String module4Activities) { this.module4Activities = module4Activities; return this; }
        public LessonBuilder upgradeStreakRequired(Integer upgradeStreakRequired) { this.upgradeStreakRequired = upgradeStreakRequired; return this; }
        public LessonBuilder demotionThreshold(Integer demotionThreshold) { this.demotionThreshold = demotionThreshold; return this; }
        public LessonBuilder reintroductionThreshold(Integer reintroductionThreshold) { this.reintroductionThreshold = reintroductionThreshold; return this; }
        public LessonBuilder module3UpgradeStreakRequired(Integer module3UpgradeStreakRequired) { this.module3UpgradeStreakRequired = module3UpgradeStreakRequired; return this; }
        public LessonBuilder module3DemotionThreshold(Integer module3DemotionThreshold) { this.module3DemotionThreshold = module3DemotionThreshold; return this; }
        public LessonBuilder streakCelebrationThreshold(Integer streakCelebrationThreshold) { this.streakCelebrationThreshold = streakCelebrationThreshold; return this; }

        public Lesson build() {
            Lesson l = new Lesson();
            l.lessonId = this.lessonId;
            l.category = this.category;
            l.classroom = this.classroom;
            l.lessonTitle = this.lessonTitle;
            l.lessonDescription = this.lessonDescription;
            l.gradeLevel = this.gradeLevel;
            l.lessonType = this.lessonType;
            l.lessonOrder = this.lessonOrder;
            l.totalWordCount = this.totalWordCount;
            l.sourceLessonIds = this.sourceLessonIds;
            l.contextParagraph = this.contextParagraph;
            l.compositeReviewAfterLessonId = this.compositeReviewAfterLessonId;
            l.contentStatus = this.contentStatus;
            l.module2Activities = this.module2Activities != null ? this.module2Activities : "MULTIPLE_CHOICE;FILL_IN_BLANK;MATCHING;WORD_SCRAMBLE;IMAGE_LABELING;TRUE_OR_FALSE";
            l.module3Activities = this.module3Activities != null ? this.module3Activities : "SENTENCE_COMPLETION;SENTENCE_ARRANGEMENT;PRONUNCIATION_FEEDBACK";
            l.module4Activities = this.module4Activities != null ? this.module4Activities : "MULTIPLE_CHOICE;MATCHING;FILL_IN_BLANK;WORD_SCRAMBLE;SENTENCE_RECONSTRUCTION;TRUE_OR_FALSE";
            l.upgradeStreakRequired = this.upgradeStreakRequired != null ? this.upgradeStreakRequired : 2;
            l.demotionThreshold = this.demotionThreshold != null ? this.demotionThreshold : 2;
            l.reintroductionThreshold = this.reintroductionThreshold != null ? this.reintroductionThreshold : 4;
            l.module3UpgradeStreakRequired = this.module3UpgradeStreakRequired != null ? this.module3UpgradeStreakRequired : 2;
            l.module3DemotionThreshold = this.module3DemotionThreshold != null ? this.module3DemotionThreshold : 1;
            l.streakCelebrationThreshold = this.streakCelebrationThreshold != null ? this.streakCelebrationThreshold : 3;
            l.createdAt = OffsetDateTime.now();
            l.updatedAt = OffsetDateTime.now();
            return l;
        }
    }

    @PrePersist
    protected void onCreate() {
        createdAt = OffsetDateTime.now();
        updatedAt = OffsetDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = OffsetDateTime.now();
    }
}
