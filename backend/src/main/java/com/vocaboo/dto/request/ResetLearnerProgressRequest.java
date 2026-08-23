package com.vocaboo.dto.request;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;

import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ResetLearnerProgressRequest {

    /**
     * Optional: If provided, only progress for this lesson is wiped.
     * If null, all progress for the learner is wiped.
     */
    @JsonProperty("lesson_id")
    private UUID lessonId;
}
