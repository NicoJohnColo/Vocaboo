import { apiFetch } from './AuthService';

// ─── Types ───────────────────────────────────────────────────────────────────

export interface WordSelectorItem {
  word_id: string;
  english_word: string;
  cebuano_meaning: string;
  word_order: number;
  is_confusable_pair_member: boolean;
}

export interface ConfusableWordPair {
  pair_id: string;
  lesson_id: string;
  word_a: { word_id: string; english_word: string; cebuano_meaning: string };
  word_b: { word_id: string; english_word: string; cebuano_meaning: string };
  contrastive_sentence_a: string;
  contrastive_sentence_b: string;
  created_at: string;
}

export interface PairSuggestion {
  word_a: { word_id: string; english_word: string; cebuano_meaning: string };
  word_b: { word_id: string; english_word: string; cebuano_meaning: string };
  reason: string;
}

export interface CreatePairPayload {
  word_a_id: string;
  word_b_id: string;
  contrastive_sentence_a: string;
  contrastive_sentence_b: string;
}

// ─── Service ─────────────────────────────────────────────────────────────────

export const ConfusableWordService = {
  /** GET /api/admin/lessons/{lessonId}/confusable-pairs */
  async getPairs(lessonId: string): Promise<ConfusableWordPair[]> {
    const res = await apiFetch(`/api/admin/lessons/${lessonId}/confusable-pairs`);
    if (!res.ok) throw new Error('Failed to fetch confusable pairs');
    return res.json();
  },

  /** GET /api/admin/lessons/{lessonId}/confusable-pairs/words */
  async getWordSelector(lessonId: string): Promise<WordSelectorItem[]> {
    const res = await apiFetch(`/api/admin/lessons/${lessonId}/confusable-pairs/words`);
    if (!res.ok) throw new Error('Failed to fetch lesson words');
    return res.json();
  },

  /** GET /api/admin/lessons/{lessonId}/confusable-pairs/suggest */
  async getSuggestions(lessonId: string): Promise<PairSuggestion[]> {
    const res = await apiFetch(`/api/admin/lessons/${lessonId}/confusable-pairs/suggest`);
    if (!res.ok) throw new Error('Failed to fetch suggestions');
    return res.json();
  },

  /** POST /api/admin/lessons/{lessonId}/confusable-pairs */
  async createPair(
    lessonId: string,
    payload: CreatePairPayload
  ): Promise<{ pair_id: string; status: string; word_a: string; word_b: string }> {
    const res = await apiFetch(`/api/admin/lessons/${lessonId}/confusable-pairs`, {
      method: 'POST',
      body: JSON.stringify(payload),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({})) as { message?: string };
      throw new Error(err.message ?? 'Failed to create confusable pair');
    }
    return res.json();
  },

  /** DELETE /api/admin/lessons/{lessonId}/confusable-pairs/{pairId} */
  async deletePair(lessonId: string, pairId: string): Promise<void> {
    const res = await apiFetch(
      `/api/admin/lessons/${lessonId}/confusable-pairs/${pairId}`,
      { method: 'DELETE' }
    );
    if (!res.ok) throw new Error('Failed to delete confusable pair');
  },
};
