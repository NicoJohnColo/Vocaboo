import { apiFetch } from './AuthService';

export interface AdminLesson {
  lesson_id: string;
  lesson_title: string;
  lesson_description: string;
  category_id: string;
  category_name: string;
  grade_level: string;
  lesson_order: number;
  total_word_count: number;
  lesson_type: string;
  content_status: string;
  target_grades: string | null;
  published_date: string | null;
  created_at: string;
  updated_at: string;
}

export interface CreateLessonPayload {
  lesson_title: string;
  lesson_description: string;
  category_id: string;
  grade_level: string;
  lesson_type?: string;
}

export interface UpdateLessonPayload {
  lesson_title: string;
  lesson_description?: string;
  grade_level?: string;
}

export const LessonService = {
  async getAll(categoryId?: string): Promise<AdminLesson[]> {
    const url = categoryId
      ? `/api/admin/lessons?categoryId=${categoryId}`
      : '/api/admin/lessons';
    const res = await apiFetch(url);
    if (!res.ok) throw new Error('Failed to fetch lessons');
    return res.json();
  },

  async getById(id: string): Promise<AdminLesson> {
    const res = await apiFetch(`/api/admin/lessons/${id}`);
    if (!res.ok) throw new Error('Lesson not found');
    return res.json();
  },

  async create(payload: CreateLessonPayload): Promise<AdminLesson> {
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

  async update(id: string, payload: UpdateLessonPayload): Promise<AdminLesson> {
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

  async delete(id: string): Promise<void> {
    const res = await apiFetch(`/api/admin/lessons/${id}`, { method: 'DELETE' });
    if (!res.ok) throw new Error('Failed to delete lesson');
  },

  async reorder(id: string, newOrder: number): Promise<void> {
    const res = await apiFetch(`/api/admin/lessons/${id}/order`, {
      method: 'PUT',
      body: JSON.stringify({ new_order: newOrder }),
    });
    if (!res.ok) throw new Error('Failed to reorder lesson');
  },

  async updateStatus(
    id: string,
    status: string,
    targetGrades?: string[]
  ): Promise<void> {
    const res = await apiFetch(`/api/admin/lessons/${id}/status`, {
      method: 'PUT',
      body: JSON.stringify({ status, target_grades: targetGrades }),
    });
    if (!res.ok) throw new Error('Failed to update lesson status');
  },

  async getValidationReport(id: string): Promise<Record<string, unknown>> {
    const res = await apiFetch(`/api/admin/lessons/${id}/validation-report`);
    if (!res.ok) throw new Error('Failed to fetch validation report');
    return res.json();
  },
};
