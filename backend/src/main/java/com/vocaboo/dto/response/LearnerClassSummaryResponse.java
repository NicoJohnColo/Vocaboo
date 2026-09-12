package com.vocaboo.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LearnerClassSummaryResponse {
    private UUID classId;
    private String name;
    private String classCode;
    private String teacherName;
    private String teacherSchool;
    private long studentCount;
    private OffsetDateTime enrolledAt;
    private com.vocaboo.entity.GradeLevel gradeLevel;
    private int totalLessons;
}
