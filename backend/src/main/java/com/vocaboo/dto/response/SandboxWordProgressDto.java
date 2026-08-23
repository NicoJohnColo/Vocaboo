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

    public static SandboxWordProgressDtoBuilder builder() { return new SandboxWordProgressDtoBuilder(); }

    public static class SandboxWordProgressDtoBuilder {
        private UUID progressId;
        private UUID sessionId;
        private UUID wordId;
        private Integer moduleNumber;
        private Integer stepCompleted;
        private WordStatus status;
        private OffsetDateTime completedAt;
        private OffsetDateTime createdAt;
        private OffsetDateTime updatedAt;

        public SandboxWordProgressDtoBuilder progressId(UUID progressId) { this.progressId = progressId; return this; }
        public SandboxWordProgressDtoBuilder sessionId(UUID sessionId) { this.sessionId = sessionId; return this; }
        public SandboxWordProgressDtoBuilder wordId(UUID wordId) { this.wordId = wordId; return this; }
        public SandboxWordProgressDtoBuilder moduleNumber(Integer moduleNumber) { this.moduleNumber = moduleNumber; return this; }
        public SandboxWordProgressDtoBuilder stepCompleted(Integer stepCompleted) { this.stepCompleted = stepCompleted; return this; }
        public SandboxWordProgressDtoBuilder status(WordStatus status) { this.status = status; return this; }
        public SandboxWordProgressDtoBuilder completedAt(OffsetDateTime completedAt) { this.completedAt = completedAt; return this; }
        public SandboxWordProgressDtoBuilder createdAt(OffsetDateTime createdAt) { this.createdAt = createdAt; return this; }
        public SandboxWordProgressDtoBuilder updatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; return this; }

        public SandboxWordProgressDto build() {
            SandboxWordProgressDto dto = new SandboxWordProgressDto();
            dto.progressId = this.progressId;
            dto.sessionId = this.sessionId;
            dto.wordId = this.wordId;
            dto.moduleNumber = this.moduleNumber;
            dto.stepCompleted = this.stepCompleted;
            dto.status = this.status;
            dto.completedAt = this.completedAt;
            dto.createdAt = this.createdAt;
            dto.updatedAt = this.updatedAt;
            return dto;
        }
    }
}
