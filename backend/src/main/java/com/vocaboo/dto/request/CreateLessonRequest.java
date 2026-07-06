package com.vocaboo.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateLessonRequest {

    @NotBlank(message = "Lesson title is required")
    @Size(min = 3, max = 200, message = "Lesson title must be between 3 and 200 characters")
    private String lessonTitle;

    @NotBlank(message = "Lesson description is required")
    @Size(min = 10, max = 5000, message = "Lesson description must be between 10 and 5000 characters")
    private String lessonDescription;

    @NotNull(message = "Category ID is required")
    private String categoryId; // Received as string, parsed to UUID in service

    @NotBlank(message = "Grade level is required")
    @Pattern(regexp = "GRADE_4|GRADE_5|GRADE_6", message = "Grade level must be GRADE_4, GRADE_5, or GRADE_6")
    private String gradeLevel;

    @Pattern(regexp = "REGULAR|COMPOSITE_REVIEW|", message = "Lesson type must be REGULAR or COMPOSITE_REVIEW")
    private String lessonType;
}
