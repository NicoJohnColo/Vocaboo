package com.vocaboo.service;

import com.vocaboo.dto.response.ClassResponse;
import com.vocaboo.entity.Classroom;
import com.vocaboo.entity.GradeLevel;
import com.vocaboo.entity.Teacher;
import com.vocaboo.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.OffsetDateTime;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ClassManagementServiceTest {

    @Mock private ClassroomRepository classroomRepository;
    @Mock private ClassEnrollmentRepository enrollmentRepository;
    @Mock private ClassInvitationRepository invitationRepository;
    @Mock private ClassJoinRequestRepository joinRequestRepository;
    @Mock private TeacherRepository teacherRepository;
    @Mock private LearnerRepository learnerRepository;
    @Mock private LessonRepository lessonRepository;
    @Mock private ClassPerformanceRepository classPerformanceRepository;

    @InjectMocks
    private ClassManagementService classManagementService;

    private UUID teacherId;
    private Teacher teacher;
    private Classroom classroom1;
    private Classroom classroom2;

    @BeforeEach
    void setUp() {
        teacherId = UUID.randomUUID();
        teacher = Teacher.builder()
                .teacherId(teacherId)
                .username("teacher_test")
                .email("teacher@school.edu")
                .firstname("Maria")
                .lastname("Santos")
                .school("Central Elementary")
                .build();

        classroom1 = Classroom.builder()
                .classId(UUID.randomUUID())
                .name("Grade 4 - Rizal")
                .classCode("VOC-ABCD")
                .teacher(teacher)
                .gradeLevel(GradeLevel.GRADE_4)
                .createdAt(OffsetDateTime.now())
                .build();

        classroom2 = Classroom.builder()
                .classId(UUID.randomUUID())
                .name("Grade 4 - Bonifacio")
                .classCode("VOC-WXYZ")
                .teacher(teacher)
                .gradeLevel(GradeLevel.GRADE_4)
                .createdAt(OffsetDateTime.now().minusDays(1))
                .build();
    }

    @Test
    void testGetClassesForTeacher_AdminView_ReturnsAllClassesWithBatchCounts() {
        when(classroomRepository.findAllByOrderByCreatedAtDesc()).thenReturn(List.of(classroom1, classroom2));
        when(enrollmentRepository.countActiveEnrollmentsGroupByClassId()).thenReturn(List.<Object[]>of(
                new Object[]{classroom1.getClassId(), 15L},
                new Object[]{classroom2.getClassId(), 20L}
        ));

        List<ClassResponse> result = classManagementService.getClassesForTeacher(null, true, "ALL");

        assertNotNull(result);
        assertEquals(2, result.size());
        assertEquals("Grade 4 - Rizal", result.get(0).getName());
        assertEquals("Maria Santos", result.get(0).getTeacherName());
        assertEquals("Central Elementary", result.get(0).getTeacherSchool());
        assertEquals(15L, result.get(0).getStudentCount());
        assertEquals(20L, result.get(1).getStudentCount());

        verify(classroomRepository).findAllByOrderByCreatedAtDesc();
        verify(enrollmentRepository).countActiveEnrollmentsGroupByClassId();
        verify(enrollmentRepository, never()).countByClassroomClassIdAndStatus(any(), any());
    }

    @Test
    void testGetClassesForTeacher_TeacherView_ReturnsTeacherClasses() {
        when(classroomRepository.findByTeacherTeacherIdOrderByCreatedAtDesc(teacherId)).thenReturn(List.of(classroom1));
        when(enrollmentRepository.countActiveEnrollmentsGroupByClassId()).thenReturn(List.<Object[]>of(
                new Object[]{classroom1.getClassId(), 8L}
        ));

        List<ClassResponse> result = classManagementService.getClassesForTeacher(teacherId, false, null);

        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals("Grade 4 - Rizal", result.get(0).getName());
        assertEquals(8L, result.get(0).getStudentCount());

        verify(classroomRepository).findByTeacherTeacherIdOrderByCreatedAtDesc(teacherId);
    }

    @Test
    void testGetClassesForTeacher_IndependentCohort_ReturnsEmptyList() {
        List<ClassResponse> result = classManagementService.getClassesForTeacher(teacherId, true, "INDEPENDENT");

        assertNotNull(result);
        assertTrue(result.isEmpty());
        verifyNoInteractions(classroomRepository);
    }

    @Test
    void testGetClassesForTeacher_NullTeacherReferenceHandledSafely() {
        Classroom classWithoutTeacher = Classroom.builder()
                .classId(UUID.randomUUID())
                .name("Unassigned Class")
                .classCode("VOC-NULL")
                .teacher(null)
                .gradeLevel(GradeLevel.GRADE_4)
                .build();

        when(classroomRepository.findAllByOrderByCreatedAtDesc()).thenReturn(List.of(classWithoutTeacher));
        when(enrollmentRepository.countActiveEnrollmentsGroupByClassId()).thenReturn(new ArrayList<Object[]>());
        when(enrollmentRepository.countByClassroomClassIdAndStatus(classWithoutTeacher.getClassId(), "ACTIVE")).thenReturn(0L);

        List<ClassResponse> result = classManagementService.getClassesForTeacher(null, true, null);

        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals("Vocaboo Teacher", result.get(0).getTeacherName());
        assertNull(result.get(0).getTeacherId());
        assertEquals(0L, result.get(0).getStudentCount());
    }
}
