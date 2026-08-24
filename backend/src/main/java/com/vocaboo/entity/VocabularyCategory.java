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

    @Column(name = "category_name", nullable = false, unique = true, length = 100)
    private String categoryName;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "sort_order", nullable = false)
    @Builder.Default
    private Integer sortOrder = 0;

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

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public static VocabularyCategoryBuilder builder() { return new VocabularyCategoryBuilder(); }

    public static class VocabularyCategoryBuilder {
        private String categoryName;
        private String description;
        private Integer sortOrder = 0;

        public VocabularyCategoryBuilder categoryName(String categoryName) { this.categoryName = categoryName; return this; }
        public VocabularyCategoryBuilder description(String description) { this.description = description; return this; }
        public VocabularyCategoryBuilder sortOrder(Integer sortOrder) { this.sortOrder = sortOrder; return this; }

        public VocabularyCategory build() {
            VocabularyCategory c = new VocabularyCategory();
            c.categoryName = this.categoryName;
            c.description = this.description;
            c.sortOrder = this.sortOrder;
            c.createdAt = OffsetDateTime.now();
            return c;
        }
    }

    @PrePersist
    protected void onCreate() {
        createdAt = OffsetDateTime.now();
    }
}
