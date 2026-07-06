package com.vocaboo.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;

import com.fasterxml.jackson.annotation.JsonProperty;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdateCategoryRequest {

    @Size(min = 2, max = 100, message = "Category name must be between 2 and 100 characters")
    @JsonProperty("category_name")
    private String categoryName;

    @Size(max = 1000, message = "Description cannot exceed 1000 characters")
    private String description;

    @JsonProperty("sort_order")
    private Integer sortOrder;
}
