package com.vocaboo.dto.response;

import lombok.*;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CategoryResponse {
    private UUID categoryId;
    private String categoryName;
    private String description;
    private Integer sortOrder;

    public static CategoryResponseBuilder builder() { return new CategoryResponseBuilder(); }

    public static class CategoryResponseBuilder {
        private UUID categoryId;
        private String categoryName;
        private String description;
        private Integer sortOrder;

        public CategoryResponseBuilder categoryId(UUID categoryId) { this.categoryId = categoryId; return this; }
        public CategoryResponseBuilder categoryName(String categoryName) { this.categoryName = categoryName; return this; }
        public CategoryResponseBuilder description(String description) { this.description = description; return this; }
        public CategoryResponseBuilder sortOrder(Integer sortOrder) { this.sortOrder = sortOrder; return this; }

        public CategoryResponse build() {
            CategoryResponse c = new CategoryResponse();
            c.categoryId = this.categoryId;
            c.categoryName = this.categoryName;
            c.description = this.description;
            c.sortOrder = this.sortOrder;
            return c;
        }
    }
}
