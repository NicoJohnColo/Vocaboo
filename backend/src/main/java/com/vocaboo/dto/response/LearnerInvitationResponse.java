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
public class LearnerInvitationResponse {
    private UUID invitationId;
    private UUID classId;
    private String className;
    private String classCode;
    private String teacherName;
    private String teacherSchool;
    private OffsetDateTime sentAt;
    private String status;
}
