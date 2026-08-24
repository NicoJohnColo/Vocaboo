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
public class PracticeSessionResponse {
    private UUID sessionId;
    private UUID learnerId;
    private UUID lessonId;
    private Integer moduleNumber;
    private BigDecimal score;
    private Integer starsEarned;
    private OffsetDateTime completedAt;
    private OffsetDateTime createdAt;

    public static PracticeSessionResponseBuilder builder() { return new PracticeSessionResponseBuilder(); }

    public static class PracticeSessionResponseBuilder {
        private UUID sessionId;
        private UUID learnerId;
        private UUID lessonId;
        private Integer moduleNumber;
        private BigDecimal score;
        private Integer starsEarned;
        private OffsetDateTime completedAt;
        private OffsetDateTime createdAt;

        public PracticeSessionResponseBuilder sessionId(UUID sessionId) { this.sessionId = sessionId; return this; }
        public PracticeSessionResponseBuilder learnerId(UUID learnerId) { this.learnerId = learnerId; return this; }
        public PracticeSessionResponseBuilder lessonId(UUID lessonId) { this.lessonId = lessonId; return this; }
        public PracticeSessionResponseBuilder moduleNumber(Integer moduleNumber) { this.moduleNumber = moduleNumber; return this; }
        public PracticeSessionResponseBuilder score(BigDecimal score) { this.score = score; return this; }
        public PracticeSessionResponseBuilder starsEarned(Integer starsEarned) { this.starsEarned = starsEarned; return this; }
        public PracticeSessionResponseBuilder completedAt(OffsetDateTime completedAt) { this.completedAt = completedAt; return this; }
        public PracticeSessionResponseBuilder createdAt(OffsetDateTime createdAt) { this.createdAt = createdAt; return this; }

        public PracticeSessionResponse build() {
            PracticeSessionResponse r = new PracticeSessionResponse();
            r.sessionId = this.sessionId;
            r.learnerId = this.learnerId;
            r.lessonId = this.lessonId;
            r.moduleNumber = this.moduleNumber;
            r.score = this.score;
            r.starsEarned = this.starsEarned;
            r.completedAt = this.completedAt;
            r.createdAt = this.createdAt;
            return r;
        }
    }
}
