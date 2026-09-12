package com.vocaboo.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UpdateLessonRequest {

    @NotBlank(message = "Lesson title is required")
    @Size(min = 3, max = 200, message = "Lesson title must be between 3 and 200 characters")
    private String lessonTitle;

    @Size(max = 5000, message = "Lesson description cannot exceed 5000 characters")
    private String lessonDescription;

    @Pattern(regexp = "GRADE_4|GRADE_5|GRADE_6|", message = "Grade level must be GRADE_4, GRADE_5, or GRADE_6")
    private String gradeLevel;

    private String module2Activities;
    private String module3Activities;
    private String module4Activities;

    @Min(value = 1, message = "Upgrade streak must be at least 1")
    @Max(value = 5, message = "Upgrade streak cannot exceed 5")
    private Integer upgradeStreakRequired;

    @Min(value = 1, message = "Demotion threshold must be at least 1")
    @Max(value = 5, message = "Demotion threshold cannot exceed 5")
    private Integer demotionThreshold;

    @Min(value = 2, message = "Reintroduction threshold must be at least 2")
    @Max(value = 10, message = "Reintroduction threshold cannot exceed 10")
    private Integer reintroductionThreshold;

    @Min(value = 1, message = "Module 3 upgrade streak must be at least 1")
    @Max(value = 5, message = "Module 3 upgrade streak cannot exceed 5")
    private Integer module3UpgradeStreakRequired;

    @Min(value = 1, message = "Module 3 demotion threshold must be at least 1")
    @Max(value = 5, message = "Module 3 demotion threshold cannot exceed 5")
    private Integer module3DemotionThreshold;

    @Min(value = 1, message = "Streak celebration threshold must be at least 1")
    @Max(value = 10, message = "Streak celebration threshold cannot exceed 10")
    private Integer streakCelebrationThreshold;

    private String classId;

    @Size(max = 5000, message = "Context paragraph cannot exceed 5000 characters")
    private String contextParagraph;

    public String getLessonTitle() {
        return lessonTitle;
    }

    public String getLessonDescription() {
        return lessonDescription;
    }

    public String getGradeLevel() {
        return gradeLevel;
    }

    public String getModule2Activities() {
        return module2Activities;
    }

    public String getModule3Activities() {
        return module3Activities;
    }

    public String getModule4Activities() {
        return module4Activities;
    }

    public Integer getUpgradeStreakRequired() {
        return upgradeStreakRequired;
    }

    public Integer getDemotionThreshold() {
        return demotionThreshold;
    }

    public Integer getReintroductionThreshold() {
        return reintroductionThreshold;
    }

    public Integer getModule3UpgradeStreakRequired() {
        return module3UpgradeStreakRequired;
    }

    public Integer getModule3DemotionThreshold() {
        return module3DemotionThreshold;
    }

    public Integer getStreakCelebrationThreshold() {
        return streakCelebrationThreshold;
    }

    public String getClassId() {
        return classId;
    }

    public void setClassId(String classId) {
        this.classId = classId;
    }
}
