package com.vocaboo.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LessonMasteryStatusResponse {
    private boolean allMastered;
    private long totalWords;
    private long masteredWords;

    public static LessonMasteryStatusResponseBuilder builder() { return new LessonMasteryStatusResponseBuilder(); }

    public static class LessonMasteryStatusResponseBuilder {
        private boolean allMastered;
        private long totalWords;
        private long masteredWords;

        public LessonMasteryStatusResponseBuilder allMastered(boolean allMastered) { this.allMastered = allMastered; return this; }
        public LessonMasteryStatusResponseBuilder totalWords(long totalWords) { this.totalWords = totalWords; return this; }
        public LessonMasteryStatusResponseBuilder masteredWords(long masteredWords) { this.masteredWords = masteredWords; return this; }

        public LessonMasteryStatusResponse build() {
            LessonMasteryStatusResponse r = new LessonMasteryStatusResponse();
            r.allMastered = this.allMastered;
            r.totalWords = this.totalWords;
            r.masteredWords = this.masteredWords;
            return r;
        }
    }
}
