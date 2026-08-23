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

    public static SandboxModuleScoreResponseBuilder builder() { return new SandboxModuleScoreResponseBuilder(); }

    public static class SandboxModuleScoreResponseBuilder {
        private UUID scoreId;
        private Integer moduleNumber;
        private Integer correct;
        private Integer total;
        private BigDecimal score;
        private OffsetDateTime recordedAt;
        private OffsetDateTime updatedAt;

        public SandboxModuleScoreResponseBuilder scoreId(UUID scoreId) { this.scoreId = scoreId; return this; }
        public SandboxModuleScoreResponseBuilder moduleNumber(Integer moduleNumber) { this.moduleNumber = moduleNumber; return this; }
        public SandboxModuleScoreResponseBuilder correct(Integer correct) { this.correct = correct; return this; }
        public SandboxModuleScoreResponseBuilder total(Integer total) { this.total = total; return this; }
        public SandboxModuleScoreResponseBuilder score(BigDecimal score) { this.score = score; return this; }
        public SandboxModuleScoreResponseBuilder recordedAt(OffsetDateTime recordedAt) { this.recordedAt = recordedAt; return this; }
        public SandboxModuleScoreResponseBuilder updatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; return this; }

        public SandboxModuleScoreResponse build() {
            SandboxModuleScoreResponse r = new SandboxModuleScoreResponse();
            r.scoreId = this.scoreId;
            r.moduleNumber = this.moduleNumber;
            r.correct = this.correct;
            r.total = this.total;
            r.score = this.score;
            r.recordedAt = this.recordedAt;
            r.updatedAt = this.updatedAt;
            return r;
        }
    }
}
