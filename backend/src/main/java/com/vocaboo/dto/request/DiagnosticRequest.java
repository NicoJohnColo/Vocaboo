package com.vocaboo.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.*;
import java.util.Map;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DiagnosticRequest {

    @NotNull(message = "Lesson ID is required")
    private UUID lessonId;

    @NotNull(message = "Responses map is required")
    private Map<UUID, Boolean> responses;

    public UUID getLessonId() { return lessonId; }
    public Map<UUID, Boolean> getResponses() { return responses; }
}
