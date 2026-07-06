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
}
