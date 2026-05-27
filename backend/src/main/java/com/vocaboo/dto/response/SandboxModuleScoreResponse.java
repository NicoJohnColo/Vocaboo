package com.vocaboo.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SandboxModuleScoreResponse {
    private UUID scoreId;
    private Integer moduleNumber;
    private Integer correct;
    private Integer total;
    private BigDecimal score;
    private OffsetDateTime recordedAt;
    private OffsetDateTime updatedAt;
}
