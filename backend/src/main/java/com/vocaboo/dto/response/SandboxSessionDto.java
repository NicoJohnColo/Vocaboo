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

    public static SandboxSessionDtoBuilder builder() { return new SandboxSessionDtoBuilder(); }

    public static class SandboxSessionDtoBuilder {
        private UUID sessionId;
        private String customWord;
        private Double masteryScore;
        private OffsetDateTime createdAt;
        private OffsetDateTime completedAt;

        public SandboxSessionDtoBuilder sessionId(UUID sessionId) { this.sessionId = sessionId; return this; }
        public SandboxSessionDtoBuilder customWord(String customWord) { this.customWord = customWord; return this; }
        public SandboxSessionDtoBuilder masteryScore(Double masteryScore) { this.masteryScore = masteryScore; return this; }
        public SandboxSessionDtoBuilder createdAt(OffsetDateTime createdAt) { this.createdAt = createdAt; return this; }
        public SandboxSessionDtoBuilder completedAt(OffsetDateTime completedAt) { this.completedAt = completedAt; return this; }

        public SandboxSessionDto build() {
            SandboxSessionDto dto = new SandboxSessionDto();
            dto.sessionId = this.sessionId;
            dto.customWord = this.customWord;
            dto.masteryScore = this.masteryScore;
            dto.createdAt = this.createdAt;
            dto.completedAt = this.completedAt;
            return dto;
        }
    }
}
