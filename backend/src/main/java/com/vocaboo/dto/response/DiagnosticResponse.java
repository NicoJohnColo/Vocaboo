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

    public static DiagnosticResponseBuilder builder() { return new DiagnosticResponseBuilder(); }

    public static class DiagnosticResponseBuilder {
        private UUID sessionId;
        private UUID lessonId;
        private List<UUID> knownWordIds;
        private List<UUID> unknownWordIds;

        public DiagnosticResponseBuilder sessionId(UUID sessionId) { this.sessionId = sessionId; return this; }
        public DiagnosticResponseBuilder lessonId(UUID lessonId) { this.lessonId = lessonId; return this; }
        public DiagnosticResponseBuilder knownWordIds(List<UUID> knownWordIds) { this.knownWordIds = knownWordIds; return this; }
        public DiagnosticResponseBuilder unknownWordIds(List<UUID> unknownWordIds) { this.unknownWordIds = unknownWordIds; return this; }

        public DiagnosticResponse build() {
            DiagnosticResponse r = new DiagnosticResponse();
            r.sessionId = this.sessionId;
            r.lessonId = this.lessonId;
            r.knownWordIds = this.knownWordIds;
            r.unknownWordIds = this.unknownWordIds;
            return r;
        }
    }
}
