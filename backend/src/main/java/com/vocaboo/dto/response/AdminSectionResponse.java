package com.vocaboo.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;

import java.time.OffsetDateTime;
import java.util.Map;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AdminSectionResponse {

    @JsonProperty("section_id")
    private UUID sectionId;

    @JsonProperty("section_name")
    private String sectionName;

    @JsonProperty("total_learners")
    private long totalLearners;

    @JsonProperty("active_learners")
    private long activeLearners;

    @JsonProperty("grade_distribution")
    private Map<String, Long> gradeDistribution;

    @JsonProperty("created_at")
    private OffsetDateTime createdAt;

    @JsonProperty("updated_at")
    private OffsetDateTime updatedAt;
}
