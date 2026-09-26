import { apiFetch } from './AuthService';

export const TeacherClassService = {
  async getClasses() {
    const res = await apiFetch('/api/teacher/classes');
    if (!res.ok) throw new Error('Failed to load classes');
    return res.json();
  },

  async getClassDetail(classId) {
    const res = await apiFetch(`/api/teacher/classes/${classId}`);
    if (!res.ok) throw new Error('Failed to load class details');
    return res.json();
  },

  async deleteClass(classId) {
    const res = await apiFetch(`/api/teacher/classes/${classId}`, {
      method: 'DELETE',
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({ message: 'Failed to delete class' }));
      throw new Error(err.message || 'Failed to delete class');
    }
    return res.json();
  },

  async createClass(name, gradeLevel = 'GRADE_4') {
    const res = await apiFetch('/api/teacher/classes', {
      method: 'POST',
      body: JSON.stringify({ name, gradeLevel }),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({ message: 'Failed to create class' }));
      throw new Error(err.message || 'Failed to create class');
    }
    return res.json();
  },

  async unenrollStudent(classId, learnerId) {
    const res = await apiFetch(`/api/teacher/classes/${classId}/students/${learnerId}`, {
      method: 'DELETE',
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({ message: 'Failed to unenroll student' }));
      throw new Error(err.message || 'Failed to unenroll student');
    }
    return res.json();
  },

  async searchLearners(query) {
    const res = await apiFetch(`/api/teacher/classes/learners/search?q=${encodeURIComponent(query)}`);
    if (!res.ok) throw new Error('Failed to search learners');
    return res.json();
  },

  async inviteLearner(classId, learnerId) {
    const res = await apiFetch(`/api/teacher/classes/${classId}/invitations`, {
      method: 'POST',
      body: JSON.stringify({ learnerId }),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({ message: 'Failed to invite learner' }));
      throw new Error(err.message || 'Failed to invite learner');
    }
    return res.json();
  },

  async cancelInvitation(classId, invitationId) {
    const res = await apiFetch(`/api/teacher/classes/${classId}/invitations/${invitationId}`, {
      method: 'DELETE',
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({ message: 'Failed to cancel invitation' }));
      throw new Error(err.message || 'Failed to cancel invitation');
    }
    return res.json();
  },

  async reviewJoinRequest(classId, requestId, status) {
    const res = await apiFetch(`/api/teacher/classes/${classId}/requests/${requestId}`, {
      method: 'PATCH',
      body: JSON.stringify({ status }),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({ message: 'Failed to review request' }));
      throw new Error(err.message || 'Failed to review request');
    }
    return res.json();
  },

  async createClassLesson(classId, lessonData) {
    const res = await apiFetch(`/api/teacher/classes/${classId}/lessons`, {
      method: 'POST',
      body: JSON.stringify(lessonData),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({ message: 'Failed to create lesson' }));
      throw new Error(err.message || 'Failed to create lesson');
    }
    return res.json();
  },

  async getClassLessons(classId) {
    const res = await apiFetch(`/api/teacher/classes/${classId}/lessons`);
    if (!res.ok) throw new Error('Failed to load class lessons');
    return res.json();
  },
};
