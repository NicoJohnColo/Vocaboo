package com.vocaboo.dto.request;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.util.List;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BulkLearnerActionRequest {

    public enum BulkActionType {
        ASSIGN_SECTION,
        DEACTIVATE,
        REACTIVATE,
        RESET_PROGRESS
    }

    @NotNull(message = "Action type is required")
    @JsonProperty("action")
    private BulkActionType action;

    @NotEmpty(message = "At least one learner ID is required")
    @JsonProperty("learner_ids")
    private List<UUID> learnerIds;

    @JsonProperty("section_id")
    private UUID sectionId;

    @JsonProperty("lesson_id")
    private UUID lessonId;

    public BulkActionType getAction() {
        return action;
    }

    public List<UUID> getLearnerIds() {
        return learnerIds;
    }

    public UUID getSectionId() {
        return sectionId;
    }

    public UUID getLessonId() {
        return lessonId;
    }
}
