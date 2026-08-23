package com.vocaboo.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AdminLearnerDetailResponse {

    @JsonProperty("learner_id")
    private UUID learnerId;

    @JsonProperty("display_name")
    private String displayName;

    @JsonProperty("age")
    private Integer age;

    @JsonProperty("grade_level")
    private String gradeLevel;

    @JsonProperty("section_id")
    private UUID sectionId;

    @JsonProperty("section_name")
    private String sectionName;

    @JsonProperty("language_preference")
    private String languagePreference;

    @JsonProperty("pos_focus")
    private String posFocus;

    @JsonProperty("is_active")
    private Boolean isActive;

    @JsonProperty("created_at")
    private OffsetDateTime createdAt;

    @JsonProperty("updated_at")
    private OffsetDateTime updatedAt;

    @JsonProperty("last_active_at")
    private OffsetDateTime lastActiveAt;

    // ── Mastery & Stats ──
    @JsonProperty("mastery_level")
    private String masteryLevel;

    @JsonProperty("total_points")
    private Integer totalPoints;

    @JsonProperty("overall_accuracy")
    private BigDecimal overallAccuracy;

    @JsonProperty("words_mastered_count")
    private Integer wordsMasteredCount;

    @JsonProperty("total_sessions_played")
    private Integer totalSessionsPlayed;

    @JsonProperty("total_questions_answered")
    private Integer totalQuestionsAnswered;

    @JsonProperty("total_correct_answers")
    private Integer totalCorrectAnswers;

    @JsonProperty("is_struggling")
    private Boolean isStruggling;

    @JsonProperty("struggling_reasons")
    private List<String> strugglingReasons;

    // ── Detailed Lesson Breakdown ──
    @JsonProperty("lessons")
    private List<LearnerLessonProgressDetail> lessons;

    // ── Weak Words / Words Needing Attention ──
    @JsonProperty("weak_words")
    private List<LearnerWordPerformanceDetail> weakWords;

    // ── Cumulative Review Performance ──
    @JsonProperty("cumulative_reviews_completed")
    private Integer cumulativeReviewsCompleted;

    @JsonProperty("avg_cumulative_score")
    private BigDecimal avgCumulativeScore;

    @JsonProperty("best_cumulative_badge")
    private String bestCumulativeBadge;

    @JsonProperty("cumulative_reviews")
    private List<CumulativeReviewPerformanceDetail> cumulativeReviews;

    // ── Sub DTOs ──
    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class LearnerLessonProgressDetail {
        @JsonProperty("lesson_id")
        private UUID lessonId;

        @JsonProperty("lesson_title")
        private String lessonTitle;

        @JsonProperty("grade_level")
        private String gradeLevel;

        @JsonProperty("status")
        private String status;

        @JsonProperty("mastery_score")
        private BigDecimal masteryScore;

        @JsonProperty("module_1_score")
        private BigDecimal module1Score;

        @JsonProperty("module_2_score")
        private BigDecimal module2Score;

        @JsonProperty("module_3_score")
        private BigDecimal module3Score;

        @JsonProperty("module_4_score")
        private BigDecimal module4Score;

        @JsonProperty("stars_earned")
        private Integer starsEarned;

        @JsonProperty("mastery_bonus_awarded")
        private Boolean masteryBonusAwarded;

        @JsonProperty("module_scores")
        private List<ModuleScoreDetail> moduleScores;

        @JsonProperty("completed_at")
        private OffsetDateTime completedAt;

        @JsonProperty("last_practiced_at")
        private OffsetDateTime lastPracticedAt;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class ModuleScoreDetail {
        @JsonProperty("module_number")
        private Integer moduleNumber;

        @JsonProperty("score")
        private BigDecimal score;

        @JsonProperty("correct_count")
        private Integer correctCount;

        @JsonProperty("total_count")
        private Integer totalCount;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class LearnerWordPerformanceDetail {
        @JsonProperty("word_id")
        private UUID wordId;

        @JsonProperty("english_word")
        private String englishWord;

        @JsonProperty("cebuano_meaning")
        private String cebuanoMeaning;

        @JsonProperty("lesson_title")
        private String lessonTitle;

        @JsonProperty("accuracy")
        private BigDecimal accuracy;

        @JsonProperty("total_attempts")
        private Integer totalAttempts;

        @JsonProperty("correct_count")
        private Integer correctCount;

        @JsonProperty("incorrect_count")
        private Integer incorrectCount;

        @JsonProperty("demerit_points")
        private Integer demeritPoints;

        @JsonProperty("tier_drop_count")
        private Integer tierDropCount;

        @JsonProperty("fallback_count")
        private Integer fallbackCount;

        @JsonProperty("last_practiced_at")
        private OffsetDateTime lastPracticedAt;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class CumulativeReviewPerformanceDetail {
        @JsonProperty("session_id")
        private UUID sessionId;

        @JsonProperty("lesson_pair_id")
        private String lessonPairId;

        @JsonProperty("category_name")
        private String categoryName;

        @JsonProperty("accuracy_percent")
        private BigDecimal accuracyPercent;

        @JsonProperty("badge_awarded")
        private String badgeAwarded;

        @JsonProperty("points_earned")
        private Integer pointsEarned;

        @JsonProperty("correct_count")
        private Integer correctCount;

        @JsonProperty("total_attempts")
        private Integer totalAttempts;

        @JsonProperty("session_status")
        private String sessionStatus;

        @JsonProperty("completed_at")
        private OffsetDateTime completedAt;
    }
}
