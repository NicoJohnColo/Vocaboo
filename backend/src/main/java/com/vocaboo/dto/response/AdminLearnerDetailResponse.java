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

    @JsonProperty("user_id")
    private String userId;

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

    @JsonProperty("avatar")
    private String avatar;

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

    // ── Class Performance Scope (When viewed within a class/section context) ──
    @JsonProperty("class_id")
    private UUID classId;

    @JsonProperty("class_name")
    private String className;

    @JsonProperty("class_code")
    private String classCode;

    @JsonProperty("class_points")
    private Integer classPoints;

    @JsonProperty("class_accuracy")
    private BigDecimal classAccuracy;

    @JsonProperty("class_mastery_level")
    private String classMasteryLevel;

    @JsonProperty("class_sessions_played")
    private Integer classSessionsPlayed;

    // ── Part of Speech (POS) Mastery Breakdown ──
    @JsonProperty("pos_breakdown")
    private List<PosAccuracyDetail> posBreakdown;

    // ── Full Word Diagnostic List (All words practiced with POS and accuracy) ──
    @JsonProperty("all_words")
    private List<LearnerWordPerformanceDetail> allWords;

    // ── All Enrolled Classes for this Learner ──
    @JsonProperty("enrolled_classes")
    private List<EnrolledClassDetail> enrolledClasses;

    // Explicit Getters for AdminLearnerDetailResponse
    public UUID getLearnerId() { return learnerId; }
    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }
    public String getDisplayName() { return displayName; }
    public Integer getAge() { return age; }
    public String getGradeLevel() { return gradeLevel; }
    public UUID getSectionId() { return sectionId; }
    public String getSectionName() { return sectionName; }
    public String getLanguagePreference() { return languagePreference; }
    public String getPosFocus() { return posFocus; }
    public String getAvatar() { return avatar != null ? avatar : "prof1.jpg"; }
    public Boolean getIsActive() { return isActive; }
    public OffsetDateTime getCreatedAt() { return createdAt; }
    public OffsetDateTime getUpdatedAt() { return updatedAt; }
    public OffsetDateTime getLastActiveAt() { return lastActiveAt; }
    public String getMasteryLevel() { return masteryLevel; }
    public Integer getTotalPoints() { return totalPoints; }
    public BigDecimal getOverallAccuracy() { return overallAccuracy; }
    public Integer getWordsMasteredCount() { return wordsMasteredCount; }
    public Integer getTotalSessionsPlayed() { return totalSessionsPlayed; }
    public Integer getTotalQuestionsAnswered() { return totalQuestionsAnswered; }
    public Integer getTotalCorrectAnswers() { return totalCorrectAnswers; }
    public Boolean getIsStruggling() { return isStruggling; }
    public List<String> getStrugglingReasons() { return strugglingReasons; }
    public List<LearnerLessonProgressDetail> getLessons() { return lessons; }
    public List<LearnerWordPerformanceDetail> getWeakWords() { return weakWords; }
    public Integer getCumulativeReviewsCompleted() { return cumulativeReviewsCompleted; }
    public BigDecimal getAvgCumulativeScore() { return avgCumulativeScore; }
    public String getBestCumulativeBadge() { return bestCumulativeBadge; }
    public List<CumulativeReviewPerformanceDetail> getCumulativeReviews() { return cumulativeReviews; }
    public UUID getClassId() { return classId; }
    public String getClassName() { return className; }
    public String getClassCode() { return classCode; }
    public Integer getClassPoints() { return classPoints; }
    public BigDecimal getClassAccuracy() { return classAccuracy; }
    public String getClassMasteryLevel() { return classMasteryLevel; }
    public Integer getClassSessionsPlayed() { return classSessionsPlayed; }
    public List<PosAccuracyDetail> getPosBreakdown() { return posBreakdown; }
    public List<LearnerWordPerformanceDetail> getAllWords() { return allWords; }
    public List<EnrolledClassDetail> getEnrolledClasses() { return enrolledClasses; }

    public static AdminLearnerDetailResponseBuilder builder() {
        return new AdminLearnerDetailResponseBuilder();
    }

    public static class AdminLearnerDetailResponseBuilder {
        private UUID learnerId;
        private String userId;
        private String displayName;
        private Integer age;
        private String gradeLevel;
        private UUID sectionId;
        private String sectionName;
        private String languagePreference;
        private String posFocus;
        private String avatar;
        private Boolean isActive;
        private OffsetDateTime createdAt;
        private OffsetDateTime updatedAt;
        private OffsetDateTime lastActiveAt;
        private String masteryLevel;
        private Integer totalPoints;
        private BigDecimal overallAccuracy;
        private Integer wordsMasteredCount;
        private Integer totalSessionsPlayed;
        private Integer totalQuestionsAnswered;
        private Integer totalCorrectAnswers;
        private Boolean isStruggling;
        private List<String> strugglingReasons;
        private List<LearnerLessonProgressDetail> lessons;
        private List<LearnerWordPerformanceDetail> weakWords;
        private Integer cumulativeReviewsCompleted;
        private BigDecimal avgCumulativeScore;
        private String bestCumulativeBadge;
        private List<CumulativeReviewPerformanceDetail> cumulativeReviews;
        private UUID classId;
        private String className;
        private String classCode;
        private Integer classPoints;
        private BigDecimal classAccuracy;
        private String classMasteryLevel;
        private Integer classSessionsPlayed;
        private List<PosAccuracyDetail> posBreakdown;
        private List<LearnerWordPerformanceDetail> allWords;
        private List<EnrolledClassDetail> enrolledClasses;

        public AdminLearnerDetailResponseBuilder classId(UUID classId) { this.classId = classId; return this; }
        public AdminLearnerDetailResponseBuilder className(String className) { this.className = className; return this; }
        public AdminLearnerDetailResponseBuilder classCode(String classCode) { this.classCode = classCode; return this; }

        public AdminLearnerDetailResponseBuilder learnerId(UUID learnerId) { this.learnerId = learnerId; return this; }
        public AdminLearnerDetailResponseBuilder userId(String userId) { this.userId = userId; return this; }
        public AdminLearnerDetailResponseBuilder displayName(String displayName) { this.displayName = displayName; return this; }
        public AdminLearnerDetailResponseBuilder age(Integer age) { this.age = age; return this; }
        public AdminLearnerDetailResponseBuilder gradeLevel(String gradeLevel) { this.gradeLevel = gradeLevel; return this; }
        public AdminLearnerDetailResponseBuilder sectionId(UUID sectionId) { this.sectionId = sectionId; return this; }
        public AdminLearnerDetailResponseBuilder sectionName(String sectionName) { this.sectionName = sectionName; return this; }
        public AdminLearnerDetailResponseBuilder languagePreference(String languagePreference) { this.languagePreference = languagePreference; return this; }
        public AdminLearnerDetailResponseBuilder posFocus(String posFocus) { this.posFocus = posFocus; return this; }
        public AdminLearnerDetailResponseBuilder avatar(String avatar) { this.avatar = avatar; return this; }
        public AdminLearnerDetailResponseBuilder isActive(Boolean isActive) { this.isActive = isActive; return this; }
        public AdminLearnerDetailResponseBuilder createdAt(OffsetDateTime createdAt) { this.createdAt = createdAt; return this; }
        public AdminLearnerDetailResponseBuilder updatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; return this; }
        public AdminLearnerDetailResponseBuilder lastActiveAt(OffsetDateTime lastActiveAt) { this.lastActiveAt = lastActiveAt; return this; }
        public AdminLearnerDetailResponseBuilder masteryLevel(String masteryLevel) { this.masteryLevel = masteryLevel; return this; }
        public AdminLearnerDetailResponseBuilder totalPoints(Integer totalPoints) { this.totalPoints = totalPoints; return this; }
        public AdminLearnerDetailResponseBuilder overallAccuracy(BigDecimal overallAccuracy) { this.overallAccuracy = overallAccuracy; return this; }
        public AdminLearnerDetailResponseBuilder wordsMasteredCount(Integer wordsMasteredCount) { this.wordsMasteredCount = wordsMasteredCount; return this; }
        public AdminLearnerDetailResponseBuilder totalSessionsPlayed(Integer totalSessionsPlayed) { this.totalSessionsPlayed = totalSessionsPlayed; return this; }
        public AdminLearnerDetailResponseBuilder totalQuestionsAnswered(Integer totalQuestionsAnswered) { this.totalQuestionsAnswered = totalQuestionsAnswered; return this; }
        public AdminLearnerDetailResponseBuilder totalCorrectAnswers(Integer totalCorrectAnswers) { this.totalCorrectAnswers = totalCorrectAnswers; return this; }
        public AdminLearnerDetailResponseBuilder isStruggling(Boolean isStruggling) { this.isStruggling = isStruggling; return this; }
        public AdminLearnerDetailResponseBuilder strugglingReasons(List<String> strugglingReasons) { this.strugglingReasons = strugglingReasons; return this; }
        public AdminLearnerDetailResponseBuilder lessons(List<LearnerLessonProgressDetail> lessons) { this.lessons = lessons; return this; }
        public AdminLearnerDetailResponseBuilder weakWords(List<LearnerWordPerformanceDetail> weakWords) { this.weakWords = weakWords; return this; }
        public AdminLearnerDetailResponseBuilder cumulativeReviewsCompleted(Integer cumulativeReviewsCompleted) { this.cumulativeReviewsCompleted = cumulativeReviewsCompleted; return this; }
        public AdminLearnerDetailResponseBuilder avgCumulativeScore(BigDecimal avgCumulativeScore) { this.avgCumulativeScore = avgCumulativeScore; return this; }
        public AdminLearnerDetailResponseBuilder bestCumulativeBadge(String bestCumulativeBadge) { this.bestCumulativeBadge = bestCumulativeBadge; return this; }
        public AdminLearnerDetailResponseBuilder cumulativeReviews(List<CumulativeReviewPerformanceDetail> cumulativeReviews) { this.cumulativeReviews = cumulativeReviews; return this; }
        public AdminLearnerDetailResponseBuilder classPoints(Integer classPoints) { this.classPoints = classPoints; return this; }
        public AdminLearnerDetailResponseBuilder classAccuracy(BigDecimal classAccuracy) { this.classAccuracy = classAccuracy; return this; }
        public AdminLearnerDetailResponseBuilder classMasteryLevel(String classMasteryLevel) { this.classMasteryLevel = classMasteryLevel; return this; }
        public AdminLearnerDetailResponseBuilder classSessionsPlayed(Integer classSessionsPlayed) { this.classSessionsPlayed = classSessionsPlayed; return this; }
        public AdminLearnerDetailResponseBuilder posBreakdown(List<PosAccuracyDetail> posBreakdown) { this.posBreakdown = posBreakdown; return this; }
        public AdminLearnerDetailResponseBuilder allWords(List<LearnerWordPerformanceDetail> allWords) { this.allWords = allWords; return this; }
        public AdminLearnerDetailResponseBuilder enrolledClasses(List<EnrolledClassDetail> enrolledClasses) { this.enrolledClasses = enrolledClasses; return this; }

        public AdminLearnerDetailResponse build() {
            AdminLearnerDetailResponse r = new AdminLearnerDetailResponse();
            r.learnerId = this.learnerId;
            r.userId = this.userId;
            r.displayName = this.displayName;
            r.age = this.age;
            r.gradeLevel = this.gradeLevel;
            r.sectionId = this.sectionId;
            r.sectionName = this.sectionName;
            r.languagePreference = this.languagePreference;
            r.posFocus = this.posFocus;
            r.avatar = this.avatar != null ? this.avatar : "prof1.jpg";
            r.isActive = this.isActive;
            r.createdAt = this.createdAt;
            r.updatedAt = this.updatedAt;
            r.lastActiveAt = this.lastActiveAt;
            r.masteryLevel = this.masteryLevel;
            r.totalPoints = this.totalPoints;
            r.overallAccuracy = this.overallAccuracy;
            r.wordsMasteredCount = this.wordsMasteredCount;
            r.totalSessionsPlayed = this.totalSessionsPlayed;
            r.totalQuestionsAnswered = this.totalQuestionsAnswered;
            r.totalCorrectAnswers = this.totalCorrectAnswers;
            r.isStruggling = this.isStruggling;
            r.strugglingReasons = this.strugglingReasons;
            r.lessons = this.lessons;
            r.weakWords = this.weakWords;
            r.cumulativeReviewsCompleted = this.cumulativeReviewsCompleted;
            r.avgCumulativeScore = this.avgCumulativeScore;
            r.bestCumulativeBadge = this.bestCumulativeBadge;
            r.cumulativeReviews = this.cumulativeReviews;
            r.classId = this.classId;
            r.className = this.className;
            r.classCode = this.classCode;
            r.classPoints = this.classPoints;
            r.classAccuracy = this.classAccuracy;
            r.classMasteryLevel = this.classMasteryLevel;
            r.classSessionsPlayed = this.classSessionsPlayed;
            r.posBreakdown = this.posBreakdown;
            r.allWords = this.allWords;
            r.enrolledClasses = this.enrolledClasses;
            return r;
        }
    }

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

        public String getLessonTitle() { return lessonTitle; }
        public String getGradeLevel() { return gradeLevel; }
        public String getStatus() { return status; }
        public BigDecimal getMasteryScore() { return masteryScore; }
        public BigDecimal getModule1Score() { return module1Score; }
        public BigDecimal getModule2Score() { return module2Score; }
        public BigDecimal getModule3Score() { return module3Score; }
        public BigDecimal getModule4Score() { return module4Score; }
        public OffsetDateTime getCompletedAt() { return completedAt; }

        public static LearnerLessonProgressDetailBuilder builder() {
            return new LearnerLessonProgressDetailBuilder();
        }

        public static class LearnerLessonProgressDetailBuilder {
            private UUID lessonId;
            private String lessonTitle;
            private String gradeLevel;
            private String status;
            private BigDecimal masteryScore;
            private BigDecimal module1Score;
            private BigDecimal module2Score;
            private BigDecimal module3Score;
            private BigDecimal module4Score;
            private Integer starsEarned;
            private Boolean masteryBonusAwarded;
            private List<ModuleScoreDetail> moduleScores;
            private OffsetDateTime completedAt;
            private OffsetDateTime lastPracticedAt;

            public LearnerLessonProgressDetailBuilder lessonId(UUID lessonId) { this.lessonId = lessonId; return this; }
            public LearnerLessonProgressDetailBuilder lessonTitle(String lessonTitle) { this.lessonTitle = lessonTitle; return this; }
            public LearnerLessonProgressDetailBuilder gradeLevel(String gradeLevel) { this.gradeLevel = gradeLevel; return this; }
            public LearnerLessonProgressDetailBuilder status(String status) { this.status = status; return this; }
            public LearnerLessonProgressDetailBuilder masteryScore(BigDecimal masteryScore) { this.masteryScore = masteryScore; return this; }
            public LearnerLessonProgressDetailBuilder module1Score(BigDecimal module1Score) { this.module1Score = module1Score; return this; }
            public LearnerLessonProgressDetailBuilder module2Score(BigDecimal module2Score) { this.module2Score = module2Score; return this; }
            public LearnerLessonProgressDetailBuilder module3Score(BigDecimal module3Score) { this.module3Score = module3Score; return this; }
            public LearnerLessonProgressDetailBuilder module4Score(BigDecimal module4Score) { this.module4Score = module4Score; return this; }
            public LearnerLessonProgressDetailBuilder starsEarned(Integer starsEarned) { this.starsEarned = starsEarned; return this; }
            public LearnerLessonProgressDetailBuilder masteryBonusAwarded(Boolean masteryBonusAwarded) { this.masteryBonusAwarded = masteryBonusAwarded; return this; }
            public LearnerLessonProgressDetailBuilder moduleScores(List<ModuleScoreDetail> moduleScores) { this.moduleScores = moduleScores; return this; }
            public LearnerLessonProgressDetailBuilder completedAt(OffsetDateTime completedAt) { this.completedAt = completedAt; return this; }
            public LearnerLessonProgressDetailBuilder lastPracticedAt(OffsetDateTime lastPracticedAt) { this.lastPracticedAt = lastPracticedAt; return this; }

            public LearnerLessonProgressDetail build() {
                LearnerLessonProgressDetail d = new LearnerLessonProgressDetail();
                d.lessonId = this.lessonId;
                d.lessonTitle = this.lessonTitle;
                d.gradeLevel = this.gradeLevel;
                d.status = this.status;
                d.masteryScore = this.masteryScore;
                d.module1Score = this.module1Score;
                d.module2Score = this.module2Score;
                d.module3Score = this.module3Score;
                d.module4Score = this.module4Score;
                d.starsEarned = this.starsEarned;
                d.masteryBonusAwarded = this.masteryBonusAwarded;
                d.moduleScores = this.moduleScores;
                d.completedAt = this.completedAt;
                d.lastPracticedAt = this.lastPracticedAt;
                return d;
            }
        }
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

        public Integer getModuleNumber() { return moduleNumber; }
        public BigDecimal getScore() { return score; }
        public Integer getCorrectCount() { return correctCount; }
        public Integer getTotalCount() { return totalCount; }

        public static ModuleScoreDetailBuilder builder() { return new ModuleScoreDetailBuilder(); }

        public static class ModuleScoreDetailBuilder {
            private Integer moduleNumber;
            private BigDecimal score;
            private Integer correctCount;
            private Integer totalCount;

            public ModuleScoreDetailBuilder moduleNumber(Integer moduleNumber) { this.moduleNumber = moduleNumber; return this; }
            public ModuleScoreDetailBuilder score(BigDecimal score) { this.score = score; return this; }
            public ModuleScoreDetailBuilder correctCount(Integer correctCount) { this.correctCount = correctCount; return this; }
            public ModuleScoreDetailBuilder totalCount(Integer totalCount) { this.totalCount = totalCount; return this; }

            public ModuleScoreDetail build() {
                ModuleScoreDetail m = new ModuleScoreDetail();
                m.moduleNumber = this.moduleNumber;
                m.score = this.score;
                m.correctCount = this.correctCount;
                m.totalCount = this.totalCount;
                return m;
            }
        }
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

        @JsonProperty("part_of_speech")
        private String partOfSpeech;

        @JsonProperty("lesson_title")
        private String lessonTitle;

        @JsonProperty("accuracy")
        private BigDecimal accuracy;

        @JsonProperty("lesson_accuracy")
        private BigDecimal lessonAccuracy;

        @JsonProperty("lifetime_accuracy")
        private BigDecimal lifetimeAccuracy;

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

        public String getEnglishWord() { return englishWord; }
        public String getCebuanoMeaning() { return cebuanoMeaning; }
        public String getLessonTitle() { return lessonTitle; }
        public BigDecimal getAccuracy() { return accuracy; }
        public BigDecimal getLessonAccuracy() { return lessonAccuracy != null ? lessonAccuracy : accuracy; }
        public BigDecimal getLifetimeAccuracy() { return lifetimeAccuracy != null ? lifetimeAccuracy : accuracy; }
        public Integer getCorrectCount() { return correctCount; }
        public Integer getIncorrectCount() { return incorrectCount; }
        public Integer getDemeritPoints() { return demeritPoints; }
        public Integer getFallbackCount() { return fallbackCount; }

        public static LearnerWordPerformanceDetailBuilder builder() { return new LearnerWordPerformanceDetailBuilder(); }

        public static class LearnerWordPerformanceDetailBuilder {
            private UUID wordId;
            private String englishWord;
            private String cebuanoMeaning;
            private String partOfSpeech;
            private String lessonTitle;
            private BigDecimal accuracy;
            private BigDecimal lessonAccuracy;
            private BigDecimal lifetimeAccuracy;
            private Integer totalAttempts;
            private Integer correctCount;
            private Integer incorrectCount;
            private Integer demeritPoints;
            private Integer tierDropCount;
            private Integer fallbackCount;
            private OffsetDateTime lastPracticedAt;

            public LearnerWordPerformanceDetailBuilder wordId(UUID wordId) { this.wordId = wordId; return this; }
            public LearnerWordPerformanceDetailBuilder englishWord(String englishWord) { this.englishWord = englishWord; return this; }
            public LearnerWordPerformanceDetailBuilder cebuanoMeaning(String cebuanoMeaning) { this.cebuanoMeaning = cebuanoMeaning; return this; }
            public LearnerWordPerformanceDetailBuilder partOfSpeech(String partOfSpeech) { this.partOfSpeech = partOfSpeech; return this; }
            public LearnerWordPerformanceDetailBuilder lessonTitle(String lessonTitle) { this.lessonTitle = lessonTitle; return this; }
            public LearnerWordPerformanceDetailBuilder accuracy(BigDecimal accuracy) { this.accuracy = accuracy; return this; }
            public LearnerWordPerformanceDetailBuilder lessonAccuracy(BigDecimal lessonAccuracy) { this.lessonAccuracy = lessonAccuracy; return this; }
            public LearnerWordPerformanceDetailBuilder lifetimeAccuracy(BigDecimal lifetimeAccuracy) { this.lifetimeAccuracy = lifetimeAccuracy; return this; }
            public LearnerWordPerformanceDetailBuilder totalAttempts(Integer totalAttempts) { this.totalAttempts = totalAttempts; return this; }
            public LearnerWordPerformanceDetailBuilder correctCount(Integer correctCount) { this.correctCount = correctCount; return this; }
            public LearnerWordPerformanceDetailBuilder incorrectCount(Integer incorrectCount) { this.incorrectCount = incorrectCount; return this; }
            public LearnerWordPerformanceDetailBuilder demeritPoints(Integer demeritPoints) { this.demeritPoints = demeritPoints; return this; }
            public LearnerWordPerformanceDetailBuilder tierDropCount(Integer tierDropCount) { this.tierDropCount = tierDropCount; return this; }
            public LearnerWordPerformanceDetailBuilder fallbackCount(Integer fallbackCount) { this.fallbackCount = fallbackCount; return this; }
            public LearnerWordPerformanceDetailBuilder lastPracticedAt(OffsetDateTime lastPracticedAt) { this.lastPracticedAt = lastPracticedAt; return this; }

            public LearnerWordPerformanceDetail build() {
                LearnerWordPerformanceDetail d = new LearnerWordPerformanceDetail();
                d.wordId = this.wordId;
                d.englishWord = this.englishWord;
                d.cebuanoMeaning = this.cebuanoMeaning;
                d.partOfSpeech = this.partOfSpeech;
                d.lessonTitle = this.lessonTitle;
                d.accuracy = this.accuracy;
                d.lessonAccuracy = this.lessonAccuracy != null ? this.lessonAccuracy : this.accuracy;
                d.lifetimeAccuracy = this.lifetimeAccuracy != null ? this.lifetimeAccuracy : this.accuracy;
                d.totalAttempts = this.totalAttempts;
                d.correctCount = this.correctCount;
                d.incorrectCount = this.incorrectCount;
                d.demeritPoints = this.demeritPoints;
                d.tierDropCount = this.tierDropCount;
                d.fallbackCount = this.fallbackCount;
                d.lastPracticedAt = this.lastPracticedAt;
                return d;
            }
        }
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

        public String getLessonPairId() { return lessonPairId; }
        public BigDecimal getAccuracyPercent() { return accuracyPercent; }
        public String getBadgeAwarded() { return badgeAwarded; }
        public Integer getPointsEarned() { return pointsEarned; }
        public Integer getCorrectCount() { return correctCount; }
        public Integer getTotalAttempts() { return totalAttempts; }
        public OffsetDateTime getCompletedAt() { return completedAt; }

        public static CumulativeReviewPerformanceDetailBuilder builder() { return new CumulativeReviewPerformanceDetailBuilder(); }

        public static class CumulativeReviewPerformanceDetailBuilder {
            private UUID sessionId;
            private String lessonPairId;
            private String categoryName;
            private BigDecimal accuracyPercent;
            private String badgeAwarded;
            private Integer pointsEarned;
            private Integer correctCount;
            private Integer totalAttempts;
            private String sessionStatus;
            private OffsetDateTime completedAt;

            public CumulativeReviewPerformanceDetailBuilder sessionId(UUID sessionId) { this.sessionId = sessionId; return this; }
            public CumulativeReviewPerformanceDetailBuilder lessonPairId(String lessonPairId) { this.lessonPairId = lessonPairId; return this; }
            public CumulativeReviewPerformanceDetailBuilder categoryName(String categoryName) { this.categoryName = categoryName; return this; }
            public CumulativeReviewPerformanceDetailBuilder accuracyPercent(BigDecimal accuracyPercent) { this.accuracyPercent = accuracyPercent; return this; }
            public CumulativeReviewPerformanceDetailBuilder badgeAwarded(String badgeAwarded) { this.badgeAwarded = badgeAwarded; return this; }
            public CumulativeReviewPerformanceDetailBuilder pointsEarned(Integer pointsEarned) { this.pointsEarned = pointsEarned; return this; }
            public CumulativeReviewPerformanceDetailBuilder correctCount(Integer correctCount) { this.correctCount = correctCount; return this; }
            public CumulativeReviewPerformanceDetailBuilder totalAttempts(Integer totalAttempts) { this.totalAttempts = totalAttempts; return this; }
            public CumulativeReviewPerformanceDetailBuilder sessionStatus(String sessionStatus) { this.sessionStatus = sessionStatus; return this; }
            public CumulativeReviewPerformanceDetailBuilder completedAt(OffsetDateTime completedAt) { this.completedAt = completedAt; return this; }

            public CumulativeReviewPerformanceDetail build() {
                CumulativeReviewPerformanceDetail d = new CumulativeReviewPerformanceDetail();
                d.sessionId = this.sessionId;
                d.lessonPairId = this.lessonPairId;
                d.categoryName = this.categoryName;
                d.accuracyPercent = this.accuracyPercent;
                d.badgeAwarded = this.badgeAwarded;
                d.pointsEarned = this.pointsEarned;
                d.correctCount = this.correctCount;
                d.totalAttempts = this.totalAttempts;
                d.sessionStatus = this.sessionStatus;
                d.completedAt = this.completedAt;
                return d;
            }
        }
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class PosAccuracyDetail {
        @JsonProperty("part_of_speech")
        private String partOfSpeech;

        @JsonProperty("total_words")
        private Integer totalWords;

        @JsonProperty("total_attempts")
        private Integer totalAttempts;

        @JsonProperty("correct_count")
        private Integer correctCount;

        @JsonProperty("accuracy")
        private BigDecimal accuracy;

        public String getPartOfSpeech() { return partOfSpeech; }
        public Integer getTotalWords() { return totalWords; }
        public Integer getTotalAttempts() { return totalAttempts; }
        public Integer getCorrectCount() { return correctCount; }
        public BigDecimal getAccuracy() { return accuracy; }

        public void setPartOfSpeech(String partOfSpeech) { this.partOfSpeech = partOfSpeech; }
        public void setTotalWords(Integer totalWords) { this.totalWords = totalWords; }
        public void setTotalAttempts(Integer totalAttempts) { this.totalAttempts = totalAttempts; }
        public void setCorrectCount(Integer correctCount) { this.correctCount = correctCount; }
        public void setAccuracy(BigDecimal accuracy) { this.accuracy = accuracy; }

        public static PosAccuracyDetailBuilder builder() { return new PosAccuracyDetailBuilder(); }

        public static class PosAccuracyDetailBuilder {
            private String partOfSpeech;
            private Integer totalWords;
            private Integer totalAttempts;
            private Integer correctCount;
            private BigDecimal accuracy;

            public PosAccuracyDetailBuilder partOfSpeech(String partOfSpeech) { this.partOfSpeech = partOfSpeech; return this; }
            public PosAccuracyDetailBuilder totalWords(Integer totalWords) { this.totalWords = totalWords; return this; }
            public PosAccuracyDetailBuilder totalAttempts(Integer totalAttempts) { this.totalAttempts = totalAttempts; return this; }
            public PosAccuracyDetailBuilder correctCount(Integer correctCount) { this.correctCount = correctCount; return this; }
            public PosAccuracyDetailBuilder accuracy(BigDecimal accuracy) { this.accuracy = accuracy; return this; }

            public PosAccuracyDetail build() {
                PosAccuracyDetail p = new PosAccuracyDetail();
                p.partOfSpeech = this.partOfSpeech;
                p.totalWords = this.totalWords != null ? this.totalWords : 0;
                p.totalAttempts = this.totalAttempts != null ? this.totalAttempts : 0;
                p.correctCount = this.correctCount != null ? this.correctCount : 0;
                p.accuracy = this.accuracy != null ? this.accuracy : BigDecimal.ZERO;
                return p;
            }
        }
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class EnrolledClassDetail {
        @JsonProperty("class_id")
        private UUID classId;

        @JsonProperty("class_name")
        private String className;

        @JsonProperty("class_code")
        private String classCode;

        @JsonProperty("teacher_name")
        private String teacherName;

        @JsonProperty("class_points")
        private Integer classPoints;

        @JsonProperty("class_accuracy")
        private BigDecimal classAccuracy;

        @JsonProperty("class_mastery_level")
        private String classMasteryLevel;

        @JsonProperty("class_sessions_played")
        private Integer classSessionsPlayed;

        public UUID getClassId() { return classId; }
        public String getClassName() { return className; }
        public String getClassCode() { return classCode; }
        public String getTeacherName() { return teacherName; }
        public Integer getClassPoints() { return classPoints; }
        public BigDecimal getClassAccuracy() { return classAccuracy; }
        public String getClassMasteryLevel() { return classMasteryLevel; }
        public Integer getClassSessionsPlayed() { return classSessionsPlayed; }

        public void setClassId(UUID classId) { this.classId = classId; }
        public void setClassName(String className) { this.className = className; }
        public void setClassCode(String classCode) { this.classCode = classCode; }
        public void setTeacherName(String teacherName) { this.teacherName = teacherName; }
        public void setClassPoints(Integer classPoints) { this.classPoints = classPoints; }
        public void setClassAccuracy(BigDecimal classAccuracy) { this.classAccuracy = classAccuracy; }
        public void setClassMasteryLevel(String classMasteryLevel) { this.classMasteryLevel = classMasteryLevel; }
        public void setClassSessionsPlayed(Integer classSessionsPlayed) { this.classSessionsPlayed = classSessionsPlayed; }

        public static EnrolledClassDetailBuilder builder() { return new EnrolledClassDetailBuilder(); }

        public static class EnrolledClassDetailBuilder {
            private UUID classId;
            private String className;
            private String classCode;
            private String teacherName;
            private Integer classPoints;
            private BigDecimal classAccuracy;
            private String classMasteryLevel;
            private Integer classSessionsPlayed;

            public EnrolledClassDetailBuilder classId(UUID classId) { this.classId = classId; return this; }
            public EnrolledClassDetailBuilder className(String className) { this.className = className; return this; }
            public EnrolledClassDetailBuilder classCode(String classCode) { this.classCode = classCode; return this; }
            public EnrolledClassDetailBuilder teacherName(String teacherName) { this.teacherName = teacherName; return this; }
            public EnrolledClassDetailBuilder classPoints(Integer classPoints) { this.classPoints = classPoints; return this; }
            public EnrolledClassDetailBuilder classAccuracy(BigDecimal classAccuracy) { this.classAccuracy = classAccuracy; return this; }
            public EnrolledClassDetailBuilder classMasteryLevel(String classMasteryLevel) { this.classMasteryLevel = classMasteryLevel; return this; }
            public EnrolledClassDetailBuilder classSessionsPlayed(Integer classSessionsPlayed) { this.classSessionsPlayed = classSessionsPlayed; return this; }

            public EnrolledClassDetail build() {
                EnrolledClassDetail d = new EnrolledClassDetail();
                d.classId = this.classId;
                d.className = this.className;
                d.classCode = this.classCode;
                d.teacherName = this.teacherName;
                d.classPoints = this.classPoints != null ? this.classPoints : 0;
                d.classAccuracy = this.classAccuracy != null ? this.classAccuracy : BigDecimal.ZERO;
                d.classMasteryLevel = this.classMasteryLevel != null ? this.classMasteryLevel : "LEARNING";
                d.classSessionsPlayed = this.classSessionsPlayed != null ? this.classSessionsPlayed : 0;
                return d;
            }
        }
    }
}
