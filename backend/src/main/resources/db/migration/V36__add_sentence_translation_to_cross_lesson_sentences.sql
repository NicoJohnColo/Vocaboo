-- Migration V36 - Ensure sentence_translation column exists on cross_lesson_sentences
ALTER TABLE cross_lesson_sentences ADD COLUMN IF NOT EXISTS sentence_translation TEXT;
