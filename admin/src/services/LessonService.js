import { apiFetch } from './AuthService';

export const LessonService = {
  async getAll(categoryId) {
    const url = categoryId
      ? `/api/admin/lessons?categoryId=${categoryId}`
      : '/api/admin/lessons';
    const res = await apiFetch(url);
    if (!res.ok) throw new Error('Failed to fetch lessons');
    return res.json();
  },

  async getById(id) {
    const res = await apiFetch(`/api/admin/lessons/${id}`);
    if (!res.ok) throw new Error('Lesson not found');
    return res.json();
  },

  async create(payload) {
    const backendPayload = {
      lessonTitle: payload.lesson_title,
      lessonDescription: payload.lesson_description,
      categoryId: payload.category_id,
      gradeLevel: payload.grade_level,
      lessonType: payload.lesson_type,
    };
    const res = await apiFetch('/api/admin/lessons', {
      method: 'POST',
      body: JSON.stringify(backendPayload),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message ?? 'Failed to create lesson');
    }
    return res.json();
  },

  async update(id, payload) {
    const backendPayload = {
      lessonTitle: payload.lesson_title,
      lessonDescription: payload.lesson_description,
      gradeLevel: payload.grade_level,
    };
    const res = await apiFetch(`/api/admin/lessons/${id}`, {
      method: 'PUT',
      body: JSON.stringify(backendPayload),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message ?? 'Failed to update lesson');
    }
    return res.json();
  },

  async delete(id) {
    const res = await apiFetch(`/api/admin/lessons/${id}`, { method: 'DELETE' });
    if (!res.ok) throw new Error('Failed to delete lesson');
  },

  async reorder(id, newOrder) {
    const res = await apiFetch(`/api/admin/lessons/${id}/order`, {
      method: 'PUT',
      body: JSON.stringify({ new_order: newOrder }),
    });
    if (!res.ok) throw new Error('Failed to reorder lesson');
  },

  async updateStatus(id, status, targetGrades) {
    const res = await apiFetch(`/api/admin/lessons/${id}/status`, {
      method: 'PUT',
      body: JSON.stringify({ status, target_grades: targetGrades }),
    });
    if (!res.ok) throw new Error('Failed to update lesson status');
  },

  async getValidationReport(id) {
    const res = await apiFetch(`/api/admin/lessons/${id}/validation-report`);
    if (!res.ok) throw new Error('Failed to fetch validation report');
    return res.json();
  },
};
