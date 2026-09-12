package com.vocaboo.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "classes")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Classroom {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "class_id", updatable = false, nullable = false)
    private UUID classId;

    @Column(name = "name", nullable = false, length = 100)
    private String name;

    @Column(name = "class_code", nullable = false, unique = true, length = 10)
    private String classCode;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "teacher_id", nullable = false)
    private Teacher teacher;

    @Enumerated(EnumType.STRING)
    @org.hibernate.annotations.JdbcType(org.hibernate.dialect.PostgreSQLEnumJdbcType.class)
    @Column(name = "grade_level", columnDefinition = "grade_level_enum")
    private GradeLevel gradeLevel;

    @Column(name = "created_at", updatable = false)
    @Builder.Default
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "updated_at")
    @Builder.Default
    private OffsetDateTime updatedAt = OffsetDateTime.now();

    public UUID getClassId() { return classId; }
    public String getName() { return name; }
    public String getClassCode() { return classCode; }
    public Teacher getTeacher() { return teacher; }
    public GradeLevel getGradeLevel() { return gradeLevel; }
    public OffsetDateTime getCreatedAt() { return createdAt; }
    public OffsetDateTime getUpdatedAt() { return updatedAt; }

    public void setName(String name) { this.name = name; }
    public void setClassCode(String classCode) { this.classCode = classCode; }
    public void setTeacher(Teacher teacher) { this.teacher = teacher; }
    public void setGradeLevel(GradeLevel gradeLevel) { this.gradeLevel = gradeLevel; }

    public static ClassroomBuilder builder() { return new ClassroomBuilder(); }

    public static class ClassroomBuilder {
        private UUID classId;
        private String name;
        private String classCode;
        private Teacher teacher;
        private GradeLevel gradeLevel;
        private OffsetDateTime createdAt;
        private OffsetDateTime updatedAt;

        public ClassroomBuilder classId(UUID classId) { this.classId = classId; return this; }
        public ClassroomBuilder name(String name) { this.name = name; return this; }
        public ClassroomBuilder classCode(String classCode) { this.classCode = classCode; return this; }
        public ClassroomBuilder teacher(Teacher teacher) { this.teacher = teacher; return this; }
        public ClassroomBuilder gradeLevel(GradeLevel gradeLevel) { this.gradeLevel = gradeLevel; return this; }
        public ClassroomBuilder createdAt(OffsetDateTime createdAt) { this.createdAt = createdAt; return this; }
        public ClassroomBuilder updatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; return this; }

        public Classroom build() {
            Classroom c = new Classroom();
            c.classId = this.classId;
            c.name = this.name;
            c.classCode = this.classCode;
            c.teacher = this.teacher;
            c.gradeLevel = this.gradeLevel;
            c.createdAt = this.createdAt != null ? this.createdAt : OffsetDateTime.now();
            c.updatedAt = this.updatedAt != null ? this.updatedAt : OffsetDateTime.now();
            return c;
        }
    }

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) createdAt = OffsetDateTime.now();
        if (updatedAt == null) updatedAt = OffsetDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = OffsetDateTime.now();
    }
}
