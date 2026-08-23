import { apiFetch } from './AuthService';

export const ConfusableWordService = {
  /** GET /api/admin/lessons/{lessonId}/confusable-pairs */
  async getPairs(lessonId) {
    const res = await apiFetch(`/api/admin/lessons/${lessonId}/confusable-pairs`);
    if (!res.ok) throw new Error('Failed to fetch confusable pairs');
    return res.json();
  },

  /** GET /api/admin/lessons/{lessonId}/confusable-pairs/words */
  async getWordSelector(lessonId) {
    const res = await apiFetch(`/api/admin/lessons/${lessonId}/confusable-pairs/words`);
    if (!res.ok) throw new Error('Failed to fetch lesson words');
    return res.json();
  },

  /** GET /api/admin/lessons/{lessonId}/confusable-pairs/suggest */
  async getSuggestions(lessonId) {
    const res = await apiFetch(`/api/admin/lessons/${lessonId}/confusable-pairs/suggest`);
    if (!res.ok) throw new Error('Failed to fetch suggestions');
    return res.json();
  },

  /** POST /api/admin/lessons/{lessonId}/confusable-pairs */
  async createPair(lessonId, payload) {
    const res = await apiFetch(`/api/admin/lessons/${lessonId}/confusable-pairs`, {
      method: 'POST',
      body: JSON.stringify(payload),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message ?? 'Failed to create confusable pair');
    }
    return res.json();
  },

  /** DELETE /api/admin/lessons/{lessonId}/confusable-pairs/{pairId} */
  async deletePair(lessonId, pairId) {
    const res = await apiFetch(
      `/api/admin/lessons/${lessonId}/confusable-pairs/${pairId}`,
      { method: 'DELETE' }
    );
    if (!res.ok) throw new Error('Failed to delete confusable pair');
  },
};
