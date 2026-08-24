package com.vocaboo.dto.response;

import com.vocaboo.entity.Pathway;
import com.vocaboo.entity.WordStatus;
import lombok.*;
import java.time.OffsetDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProgressResponse {
    private UUID progressId;
    private UUID sessionId;
    private UUID wordId;
    private Pathway pathway;
    private Integer stepCompleted;
    private WordStatus status;
    private OffsetDateTime completedAt;

    public static ProgressResponseBuilder builder() { return new ProgressResponseBuilder(); }

    public static class ProgressResponseBuilder {
        private UUID progressId;
        private UUID sessionId;
        private UUID wordId;
        private Pathway pathway;
        private Integer stepCompleted;
        private WordStatus status;
        private OffsetDateTime completedAt;

        public ProgressResponseBuilder progressId(UUID progressId) { this.progressId = progressId; return this; }
        public ProgressResponseBuilder sessionId(UUID sessionId) { this.sessionId = sessionId; return this; }
        public ProgressResponseBuilder wordId(UUID wordId) { this.wordId = wordId; return this; }
        public ProgressResponseBuilder pathway(Pathway pathway) { this.pathway = pathway; return this; }
        public ProgressResponseBuilder stepCompleted(Integer stepCompleted) { this.stepCompleted = stepCompleted; return this; }
        public ProgressResponseBuilder status(WordStatus status) { this.status = status; return this; }
        public ProgressResponseBuilder completedAt(OffsetDateTime completedAt) { this.completedAt = completedAt; return this; }

        public ProgressResponse build() {
            ProgressResponse r = new ProgressResponse();
            r.progressId = this.progressId;
            r.sessionId = this.sessionId;
            r.wordId = this.wordId;
            r.pathway = this.pathway;
            r.stepCompleted = this.stepCompleted;
            r.status = this.status;
            r.completedAt = this.completedAt;
            return r;
        }
    }
}
