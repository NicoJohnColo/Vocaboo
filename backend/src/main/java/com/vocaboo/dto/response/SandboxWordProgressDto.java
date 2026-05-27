package com.vocaboo.dto.response;

import com.vocaboo.entity.WordStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SandboxWordProgressDto {
    private UUID progressId;
    private UUID sessionId;
    private UUID wordId;
    private Integer moduleNumber;
    private Integer stepCompleted;
    private WordStatus status;
    private OffsetDateTime completedAt;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;
}
