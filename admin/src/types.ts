export interface AdminAuthResponse {
  token: string;
  adminId: string;
  username: string;
  email: string;
  mustChangePassword?: boolean;
  role?: string; // "admin" | "teacher"
}

export interface AdminInfo {
  adminId: string;
  username: string;
  email: string;
  mustChangePassword?: boolean;
}

export interface AdminAccount {
  admin_id: string;
  username: string;
  email: string;
  is_active: boolean;
  school_id?: string;
  created_at: string;
  last_login?: string;
}

export interface VocabularyWord {
  wordId: string;
  englishWord: string;
  cebuanoMeaning: string;
  partOfSpeech?: string;
}

export interface CrossLessonSentence {
  id?: string;
  sentenceText: string;
  sentenceTranslation: string;
  wordA: VocabularyWord;
  wordB: VocabularyWord;
  lessonPairId: string;
}
