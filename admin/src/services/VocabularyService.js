import { apiFetch } from './AuthService';

export const VocabularyService = {
  async getWords(lessonId) {
    const res = await apiFetch(`/api/admin/lessons/${lessonId}/vocabulary`);
    if (!res.ok) throw new Error('Failed to fetch vocabulary words');
    return res.json();
  },

  async addWord(lessonId, payload) {
    const backendPayload = {
      englishWord: payload.english_word,
      cebuanoMeaning: payload.cebuano_meaning,
      partOfSpeech: payload.part_of_speech,
      gradeLevel: payload.grade_level,
      exampleSentenceEnglish: payload.example_sentence_english,
      exampleSentenceCebuano: payload.example_sentence_cebuano,
      audioAssetPath: payload.audio_asset_path,
      imageAssetPath: payload.image_asset_path,
      distractorPool: payload.distractor_pool,
      fillBlankSentence: payload.fill_blank_sentence,
      tileSentence: payload.tile_sentence,
      explanationText: payload.explanation_text,
      audioTextCebuano: payload.audio_text_cebuano,
      audioTextEnglish: payload.audio_text_english,
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
        throw new Error(firstErrorMessage || 'Validation failed');
      }
      if (err.fieldErrors && typeof err.fieldErrors === 'object') {
        const firstErrorMessage = Object.values(err.fieldErrors)[0];
        throw new Error(firstErrorMessage || 'Validation failed');
      }
      if (err.message && err.message.startsWith('Validation failed:')) {
         throw new Error(err.message);
      }
      throw new Error(err.message || 'Failed to add word');
    }
    return res.json();
  },

  async updateWord(lessonId, wordId, payload) {
    const backendPayload = {
      englishWord: payload.english_word,
      cebuanoMeaning: payload.cebuano_meaning,
      partOfSpeech: payload.part_of_speech,
      exampleSentenceEnglish: payload.example_sentence_english,
      exampleSentenceCebuano: payload.example_sentence_cebuano,
      audioAssetPath: payload.audio_asset_path,
      imageAssetPath: payload.image_asset_path,
      distractorPool: payload.distractor_pool,
      fillBlankSentence: payload.fill_blank_sentence,
      tileSentence: payload.tile_sentence,
      explanationText: payload.explanation_text,
      audioTextCebuano: payload.audio_text_cebuano,
      audioTextEnglish: payload.audio_text_english,
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
        throw new Error(firstErrorMessage || 'Validation failed');
      }
      if (err.fieldErrors && typeof err.fieldErrors === 'object') {
        const firstErrorMessage = Object.values(err.fieldErrors)[0];
        throw new Error(firstErrorMessage || 'Validation failed');
      }
      if (err.message && err.message.startsWith('Validation failed:')) {
         throw new Error(err.message);
      }
      throw new Error(err.message || 'Failed to update word');
    }
    return res.json();
  },

  async deleteWord(lessonId, wordId) {
    const res = await apiFetch(`/api/admin/lessons/${lessonId}/vocabulary/${wordId}`, {
      method: 'DELETE',
    });
    if (!res.ok) throw new Error('Failed to delete word');
  },

  async bulkImport(lessonId, file, options) {
    const token = localStorage.getItem('vocaboo_admin_token');
    const formData = new FormData();
    formData.append('file', file);
    const BASE_URL = import.meta.env.VITE_API_URL ?? 'http://localhost:8081';
    const url = `${BASE_URL}/api/admin/lessons/${lessonId}/vocabulary/bulk-import${options?.dryRun ? '?dryRun=true' : ''}`;
    const res = await fetch(url, {
      method: 'POST',
      headers: token ? { Authorization: `Bearer ${token}` } : {},
      body: formData,
    });
    if (!res.ok) throw new Error('Bulk import failed');
    return res.json();
  },

  async downloadTemplateFile(lessonId) {
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
