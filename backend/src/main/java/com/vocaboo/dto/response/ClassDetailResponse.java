package com.vocaboo.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ClassDetailResponse {

    private UUID classId;
    private String name;
    private String classCode;
    private UUID teacherId;
    private String teacherName;
    private String teacherSchool;
    private com.vocaboo.entity.GradeLevel gradeLevel;
    private OffsetDateTime createdAt;

    private List<EnrolledLearnerDto> enrolledLearners;
    private List<JoinRequestDto> pendingJoinRequests;
    private List<InvitationDto> pendingInvitations;
    private List<ClassLessonSummaryDto> lessons;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class EnrolledLearnerDto {
        private UUID enrollmentId;
        private UUID learnerId;
        @com.fasterxml.jackson.annotation.JsonProperty("user_id")
        private String userId;
        private String displayName;
        private Integer age;
        private String avatar;
        private com.vocaboo.entity.GradeLevel gradeLevel;
        private OffsetDateTime enrolledAt;
        private Integer classPoints;
        private java.math.BigDecimal classAccuracy;
        private Integer classSessionsPlayed;
        private String classMasteryLevel;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class JoinRequestDto {
        private UUID requestId;
        private UUID learnerId;
        @com.fasterxml.jackson.annotation.JsonProperty("user_id")
        private String userId;
        private String displayName;
        private Integer age;
        private String avatar;
        private String status;
        private OffsetDateTime createdAt;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class InvitationDto {
        private UUID invitationId;
        private UUID learnerId;
        @com.fasterxml.jackson.annotation.JsonProperty("user_id")
        private String userId;
        private String displayName;
        private String avatar;
        private String status;
        private OffsetDateTime createdAt;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ClassLessonSummaryDto {
        private UUID lessonId;
        private String lessonTitle;
        private String lessonDescription;
        private Integer lessonOrder;
        private Integer totalWordCount;
        private String contentStatus;
    }
}
