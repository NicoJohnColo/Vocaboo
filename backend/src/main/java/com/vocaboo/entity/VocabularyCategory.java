package com.vocaboo.entity;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "vocabulary_categories")
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VocabularyCategory {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "category_id", updatable = false, nullable = false)
    private UUID categoryId;

    @Column(name = "category_name", nullable = false, length = 100)
    private String categoryName;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "sort_order", nullable = false)
    @Builder.Default
    private Integer sortOrder = 0;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "teacher_id")
    private Teacher teacher;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "classroom_id")
    private Classroom classroom;

    @Column(name = "created_at", updatable = false)
    @Builder.Default
    private OffsetDateTime createdAt = OffsetDateTime.now();

    public UUID getCategoryId() {
        return categoryId;
    }

    public String getCategoryName() {
        return categoryName;
    }

    public void setCategoryName(String categoryName) {
        this.categoryName = categoryName;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public Integer getSortOrder() {
        return sortOrder;
    }

    public void setSortOrder(Integer sortOrder) {
        this.sortOrder = sortOrder;
    }

    public Teacher getTeacher() {
        return teacher;
    }

    public void setTeacher(Teacher teacher) {
        this.teacher = teacher;
    }

    public Classroom getClassroom() {
        return classroom;
    }

    public void setClassroom(Classroom classroom) {
        this.classroom = classroom;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public static VocabularyCategoryBuilder builder() { return new VocabularyCategoryBuilder(); }

    public static class VocabularyCategoryBuilder {
        private UUID categoryId;
        private String categoryName;
        private String description;
        private Integer sortOrder = 0;
        private Teacher teacher;
        private Classroom classroom;

        public VocabularyCategoryBuilder categoryId(UUID categoryId) { this.categoryId = categoryId; return this; }
        public VocabularyCategoryBuilder categoryName(String categoryName) { this.categoryName = categoryName; return this; }
        public VocabularyCategoryBuilder description(String description) { this.description = description; return this; }
        public VocabularyCategoryBuilder sortOrder(Integer sortOrder) { this.sortOrder = sortOrder; return this; }
        public VocabularyCategoryBuilder teacher(Teacher teacher) { this.teacher = teacher; return this; }
        public VocabularyCategoryBuilder classroom(Classroom classroom) { this.classroom = classroom; return this; }

        public VocabularyCategory build() {
            VocabularyCategory c = new VocabularyCategory();
            c.categoryId = this.categoryId;
            c.categoryName = this.categoryName;
            c.description = this.description;
            c.sortOrder = this.sortOrder;
            c.teacher = this.teacher;
            c.classroom = this.classroom;
            c.createdAt = OffsetDateTime.now();
            return c;
        }
    }

    @PrePersist
    protected void onCreate() {
        createdAt = OffsetDateTime.now();
    }
}
