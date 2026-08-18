import type { CrossLessonSentence } from '../types';
import { apiFetch } from './AuthService';

class CumulativeReviewService {
  async getAllCrossLessonSentences(): Promise<CrossLessonSentence[]> {
    const res = await apiFetch(`/api/admin/cross-lesson-sentences`);
    if (!res.ok) {
      const err = await res.text().catch(() => '');
      throw new Error(err || 'Failed to fetch cross-lesson sentences');
    }
    return res.json();
  }

  async createCrossLessonSentence(sentence: CrossLessonSentence): Promise<CrossLessonSentence> {
    const res = await apiFetch(`/api/admin/cross-lesson-sentences`, {
      method: 'POST',
      body: JSON.stringify(sentence),
    });
    if (!res.ok) {
      const err = await res.text().catch(() => '');
      throw new Error(err || `Failed to create cross-lesson sentence (${res.status})`);
    }
    return res.json();
  }

  async deleteCrossLessonSentence(id: string): Promise<void> {
    const res = await apiFetch(`/api/admin/cross-lesson-sentences/${id}`, {
      method: 'DELETE',
    });
    if (!res.ok) {
      const err = await res.text().catch(() => '');
      throw new Error(err || 'Failed to delete cross-lesson sentence');
    }
  }

  async getCoverageGaps(lesson1Id: string, lesson2Id: string): Promise<any[]> {
    const res = await apiFetch(`/api/admin/cross-lesson-sentences/coverage?lesson1Id=${lesson1Id}&lesson2Id=${lesson2Id}`);
    if (!res.ok) {
      const err = await res.text().catch(() => '');
      throw new Error(err || 'Failed to fetch coverage gaps');
    }
    return res.json();
  }
}

export default new CumulativeReviewService();
