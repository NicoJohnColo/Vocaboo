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
public class PracticeResultResponse {
    private UUID resultId;
    private UUID sessionId;
    private UUID wordId;
    private Boolean isCorrect;
    private Integer attemptNumber;
    private String activityType;
    private Integer points;
    private OffsetDateTime recordedAt;

    public static PracticeResultResponseBuilder builder() { return new PracticeResultResponseBuilder(); }

    public static class PracticeResultResponseBuilder {
        private UUID resultId;
        private UUID sessionId;
        private UUID wordId;
        private Boolean isCorrect;
        private Integer attemptNumber;
        private String activityType;
        private Integer points;
        private OffsetDateTime recordedAt;

        public PracticeResultResponseBuilder resultId(UUID resultId) { this.resultId = resultId; return this; }
        public PracticeResultResponseBuilder sessionId(UUID sessionId) { this.sessionId = sessionId; return this; }
        public PracticeResultResponseBuilder wordId(UUID wordId) { this.wordId = wordId; return this; }
        public PracticeResultResponseBuilder isCorrect(Boolean isCorrect) { this.isCorrect = isCorrect; return this; }
        public PracticeResultResponseBuilder attemptNumber(Integer attemptNumber) { this.attemptNumber = attemptNumber; return this; }
        public PracticeResultResponseBuilder activityType(String activityType) { this.activityType = activityType; return this; }
        public PracticeResultResponseBuilder points(Integer points) { this.points = points; return this; }
        public PracticeResultResponseBuilder recordedAt(OffsetDateTime recordedAt) { this.recordedAt = recordedAt; return this; }

        public PracticeResultResponse build() {
            PracticeResultResponse r = new PracticeResultResponse();
            r.resultId = this.resultId;
            r.sessionId = this.sessionId;
            r.wordId = this.wordId;
            r.isCorrect = this.isCorrect;
            r.attemptNumber = this.attemptNumber;
            r.activityType = this.activityType;
            r.points = this.points;
            r.recordedAt = this.recordedAt;
            return r;
        }
    }
}
