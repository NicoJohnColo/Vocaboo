package com.vocaboo.dto.response;

import com.vocaboo.entity.GradeLevel;
import com.vocaboo.entity.LessonStatus;
import lombok.*;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LessonResponse {
    private UUID lessonId;
    private UUID categoryId;
    private String lessonTitle;
    private String lessonDescription;
    private GradeLevel gradeLevel;
    private Integer lessonOrder;
    private Integer totalWordCount;
    private Integer masteredWordCount;
    private Map<String, Integer> posTotalWordCounts;
    private Map<String, Integer> posMasteredWordCounts;
    private LessonStatus status;
    private BigDecimal masteryScore;
    private String lessonType;
    private List<UUID> sourceLessonIds;
    private UUID compositeReviewAfterLessonId;
    private String contextParagraph;

    public static LessonResponseBuilder builder() { return new LessonResponseBuilder(); }

    public static class LessonResponseBuilder {
        private UUID lessonId;
        private UUID categoryId;
        private String lessonTitle;
        private String lessonDescription;
        private GradeLevel gradeLevel;
        private Integer lessonOrder;
        private Integer totalWordCount;
        private Integer masteredWordCount;
        private Map<String, Integer> posTotalWordCounts;
        private Map<String, Integer> posMasteredWordCounts;
        private LessonStatus status;
        private BigDecimal masteryScore;
        private String lessonType;
        private List<UUID> sourceLessonIds;
        private UUID compositeReviewAfterLessonId;
        private String contextParagraph;

        public LessonResponseBuilder lessonId(UUID lessonId) { this.lessonId = lessonId; return this; }
        public LessonResponseBuilder categoryId(UUID categoryId) { this.categoryId = categoryId; return this; }
        public LessonResponseBuilder lessonTitle(String lessonTitle) { this.lessonTitle = lessonTitle; return this; }
        public LessonResponseBuilder lessonDescription(String lessonDescription) { this.lessonDescription = lessonDescription; return this; }
        public LessonResponseBuilder gradeLevel(GradeLevel gradeLevel) { this.gradeLevel = gradeLevel; return this; }
        public LessonResponseBuilder lessonOrder(Integer lessonOrder) { this.lessonOrder = lessonOrder; return this; }
        public LessonResponseBuilder totalWordCount(Integer totalWordCount) { this.totalWordCount = totalWordCount; return this; }
        public LessonResponseBuilder masteredWordCount(Integer masteredWordCount) { this.masteredWordCount = masteredWordCount; return this; }
        public LessonResponseBuilder posTotalWordCounts(Map<String, Integer> posTotalWordCounts) { this.posTotalWordCounts = posTotalWordCounts; return this; }
        public LessonResponseBuilder posMasteredWordCounts(Map<String, Integer> posMasteredWordCounts) { this.posMasteredWordCounts = posMasteredWordCounts; return this; }
        public LessonResponseBuilder status(LessonStatus status) { this.status = status; return this; }
        public LessonResponseBuilder masteryScore(BigDecimal masteryScore) { this.masteryScore = masteryScore; return this; }
        public LessonResponseBuilder lessonType(String lessonType) { this.lessonType = lessonType; return this; }
        public LessonResponseBuilder sourceLessonIds(List<UUID> sourceLessonIds) { this.sourceLessonIds = sourceLessonIds; return this; }
        public LessonResponseBuilder compositeReviewAfterLessonId(UUID compositeReviewAfterLessonId) { this.compositeReviewAfterLessonId = compositeReviewAfterLessonId; return this; }
        public LessonResponseBuilder contextParagraph(String contextParagraph) { this.contextParagraph = contextParagraph; return this; }

        public LessonResponse build() {
            LessonResponse r = new LessonResponse();
            r.lessonId = this.lessonId;
            r.categoryId = this.categoryId;
            r.lessonTitle = this.lessonTitle;
            r.lessonDescription = this.lessonDescription;
            r.gradeLevel = this.gradeLevel;
            r.lessonOrder = this.lessonOrder;
            r.totalWordCount = this.totalWordCount;
            r.masteredWordCount = this.masteredWordCount;
            r.posTotalWordCounts = this.posTotalWordCounts;
            r.posMasteredWordCounts = this.posMasteredWordCounts;
            r.status = this.status;
            r.masteryScore = this.masteryScore;
            r.lessonType = this.lessonType;
            r.sourceLessonIds = this.sourceLessonIds;
            r.compositeReviewAfterLessonId = this.compositeReviewAfterLessonId;
            r.contextParagraph = this.contextParagraph;
            return r;
        }
    }
}
