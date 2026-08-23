package com.vocaboo.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MasteryResponse {
    private boolean success;
    private String message;
    private double finalScore;
    private boolean passed;
    private int totalItems;
    private int masteredCount;
    private List<String> missedWordIds;

    public static MasteryResponseBuilder builder() { return new MasteryResponseBuilder(); }

    public static class MasteryResponseBuilder {
        private boolean success;
        private String message;
        private double finalScore;
        private boolean passed;
        private int totalItems;
        private int masteredCount;
        private List<String> missedWordIds;

        public MasteryResponseBuilder success(boolean success) { this.success = success; return this; }
        public MasteryResponseBuilder message(String message) { this.message = message; return this; }
        public MasteryResponseBuilder finalScore(double finalScore) { this.finalScore = finalScore; return this; }
        public MasteryResponseBuilder passed(boolean passed) { this.passed = passed; return this; }
        public MasteryResponseBuilder totalItems(int totalItems) { this.totalItems = totalItems; return this; }
        public MasteryResponseBuilder masteredCount(int masteredCount) { this.masteredCount = masteredCount; return this; }
        public MasteryResponseBuilder missedWordIds(List<String> missedWordIds) { this.missedWordIds = missedWordIds; return this; }

        public MasteryResponse build() {
            MasteryResponse r = new MasteryResponse();
            r.success = this.success;
            r.message = this.message;
            r.finalScore = this.finalScore;
            r.passed = this.passed;
            r.totalItems = this.totalItems;
            r.masteredCount = this.masteredCount;
            r.missedWordIds = this.missedWordIds;
            return r;
        }
    }
}
