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
public class ClassResponse {
    private UUID classId;
    private String name;
    private String classCode;
    private UUID teacherId;
    private String teacherName;
    private String teacherSchool;
    private long studentCount;
    private com.vocaboo.entity.GradeLevel gradeLevel;
    private OffsetDateTime createdAt;
}
