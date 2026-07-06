import { apiFetch } from './AuthService';

export interface AdminVocabularyWord {
  word_id: string;
  lesson_id: string;
  english_word: string;
  cebuano_meaning: string;
  part_of_speech: string;
  grade_level: string;
  word_order: number;
  example_sentence_english: string;
  example_sentence_cebuano: string | null;
  audio_asset_path: string | null;
  image_asset_path: string | null;
  audio_verified: boolean;
  image_verified: boolean;
  is_confusable_pair_member: boolean;
  created_at: string;
  updated_at: string;
}

export interface AddWordPayload {
  english_word: string;
  cebuano_meaning: string;
  part_of_speech: string;
  grade_level: string;
  example_sentence_english: string;
  example_sentence_cebuano?: string;
  audio_asset_path?: string;
  image_asset_path?: string;
}

export interface UpdateWordPayload {
  english_word?: string;
  cebuano_meaning?: string;
  part_of_speech?: string;
  example_sentence_english?: string;
  example_sentence_cebuano?: string;
  audio_asset_path?: string;
  image_asset_path?: string;
}

export const VocabularyService = {
  async getWords(lessonId: string): Promise<AdminVocabularyWord[]> {
    const res = await apiFetch(`/api/admin/lessons/${lessonId}/vocabulary`);
    if (!res.ok) throw new Error('Failed to fetch vocabulary words');
    return res.json();
  },

  async addWord(lessonId: string, payload: AddWordPayload): Promise<AdminVocabularyWord> {
    const backendPayload = {
      englishWord: payload.english_word,
      cebuanoMeaning: payload.cebuano_meaning,
      partOfSpeech: payload.part_of_speech,
      gradeLevel: payload.grade_level,
      exampleSentenceEnglish: payload.example_sentence_english,
      exampleSentenceCebuano: payload.example_sentence_cebuano,
      audioAssetPath: payload.audio_asset_path,
      imageAssetPath: payload.image_asset_path,
    };
    const res = await apiFetch(`/api/admin/lessons/${lessonId}/vocabulary`, {
      method: 'POST',
      body: JSON.stringify(backendPayload),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      if (err.error === 'VALIDATION_ERROR' && Array.isArray(err.details) && err.details.length > 0) {
        const firstErrorObj = err.details[0];
        const firstErrorMessage = Object.values(firstErrorObj)[0];
        throw new Error((firstErrorMessage as string) || 'Validation failed');
      }
      if (err.fieldErrors && typeof err.fieldErrors === 'object') {
        const firstErrorMessage = Object.values(err.fieldErrors)[0];
        throw new Error((firstErrorMessage as string) || 'Validation failed');
      }
      if (err.message && err.message.startsWith('Validation failed:')) {
         throw new Error(err.message);
      }
      throw new Error(err.message || 'Failed to add word');
    }
    return res.json();
  },

  async updateWord(
    lessonId: string,
    wordId: string,
    payload: UpdateWordPayload
  ): Promise<AdminVocabularyWord> {
    const backendPayload = {
      englishWord: payload.english_word,
      cebuanoMeaning: payload.cebuano_meaning,
      partOfSpeech: payload.part_of_speech,
      exampleSentenceEnglish: payload.example_sentence_english,
      exampleSentenceCebuano: payload.example_sentence_cebuano,
      audioAssetPath: payload.audio_asset_path,
      imageAssetPath: payload.image_asset_path,
    };
    const res = await apiFetch(`/api/admin/lessons/${lessonId}/vocabulary/${wordId}`, {
      method: 'PUT',
      body: JSON.stringify(backendPayload),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      if (err.error === 'VALIDATION_ERROR' && Array.isArray(err.details) && err.details.length > 0) {
        const firstErrorObj = err.details[0];
        const firstErrorMessage = Object.values(firstErrorObj)[0];
        throw new Error((firstErrorMessage as string) || 'Validation failed');
      }
      if (err.fieldErrors && typeof err.fieldErrors === 'object') {
        const firstErrorMessage = Object.values(err.fieldErrors)[0];
        throw new Error((firstErrorMessage as string) || 'Validation failed');
      }
      if (err.message && err.message.startsWith('Validation failed:')) {
         throw new Error(err.message);
      }
      throw new Error(err.message || 'Failed to update word');
    }
    return res.json();
  },

  async deleteWord(lessonId: string, wordId: string): Promise<void> {
    const res = await apiFetch(`/api/admin/lessons/${lessonId}/vocabulary/${wordId}`, {
      method: 'DELETE',
    });
    if (!res.ok) throw new Error('Failed to delete word');
  },

  async bulkImport(lessonId: string, file: File, options?: { dryRun?: boolean }): Promise<Record<string, unknown>> {
    const token = localStorage.getItem('vocaboo_admin_token');
    const formData = new FormData();
    formData.append('file', file);
    const BASE_URL = import.meta.env.VITE_API_URL ?? 'http://localhost:8080';
    const url = `${BASE_URL}/api/admin/lessons/${lessonId}/vocabulary/bulk-import${options?.dryRun ? '?dryRun=true' : ''}`;
    const res = await fetch(url, {
      method: 'POST',
      headers: token ? { Authorization: `Bearer ${token}` } : {},
      body: formData,
    });
    if (!res.ok) throw new Error('Bulk import failed');
    return res.json();
  },

  async downloadTemplateFile(lessonId: string): Promise<void> {
    const res = await apiFetch(`/api/admin/lessons/${lessonId}/vocabulary/bulk-import/template`);
    if (!res.ok) throw new Error('Failed to download template');
    
    const blob = await res.blob();
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'vocabulary_import_template.csv';
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    window.URL.revokeObjectURL(url);
  },
};
