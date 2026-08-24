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

    public static AdminSectionResponseBuilder builder() {
        return new AdminSectionResponseBuilder();
    }

    public static class AdminSectionResponseBuilder {
        private UUID sectionId;
        private String sectionName;
        private long totalLearners;
        private long activeLearners;
        private Map<String, Long> gradeDistribution;
        private OffsetDateTime createdAt;
        private OffsetDateTime updatedAt;

        public AdminSectionResponseBuilder sectionId(UUID sectionId) { this.sectionId = sectionId; return this; }
        public AdminSectionResponseBuilder sectionName(String sectionName) { this.sectionName = sectionName; return this; }
        public AdminSectionResponseBuilder totalLearners(long totalLearners) { this.totalLearners = totalLearners; return this; }
        public AdminSectionResponseBuilder activeLearners(long activeLearners) { this.activeLearners = activeLearners; return this; }
        public AdminSectionResponseBuilder gradeDistribution(Map<String, Long> gradeDistribution) { this.gradeDistribution = gradeDistribution; return this; }
        public AdminSectionResponseBuilder createdAt(OffsetDateTime createdAt) { this.createdAt = createdAt; return this; }
        public AdminSectionResponseBuilder updatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; return this; }

        public AdminSectionResponse build() {
            AdminSectionResponse r = new AdminSectionResponse();
            r.sectionId = this.sectionId;
            r.sectionName = this.sectionName;
            r.totalLearners = this.totalLearners;
            r.activeLearners = this.activeLearners;
            r.gradeDistribution = this.gradeDistribution;
            r.createdAt = this.createdAt;
            r.updatedAt = this.updatedAt;
            return r;
        }
    }
}
