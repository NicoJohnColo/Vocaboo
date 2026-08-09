package com.vocaboo.entity;

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
