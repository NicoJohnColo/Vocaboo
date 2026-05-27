package com.vocaboo.dto.response;

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
public class SandboxSessionDto {
    private UUID sessionId;
    private String customWord;
    private Double masteryScore;
    private OffsetDateTime createdAt;
    private OffsetDateTime completedAt;
}
