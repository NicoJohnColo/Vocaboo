package com.vocaboo.dto.response;

import lombok.*;
import java.util.List;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DiagnosticResponse {
    private UUID sessionId;
    private UUID lessonId;
    private List<UUID> knownWordIds;
    private List<UUID> unknownWordIds;
}
