-- V23__add_activity_content_fields.sql
-- Add per-word activity content fields required by the admin CSV spec.

-- 1. distractor_pool: comma-separated wrong-answer candidates (3-5 words, same POS)
--    e.g. "eraser,ruler,scissors,marker"
ALTER TABLE vocabulary_words
    ADD COLUMN IF NOT EXISTS distractor_pool TEXT;

-- 2. fill_blank_sentence: sentence with {BLANK} placeholder for Fill-in-the-Blank activity
--    e.g. "I sharpen my {BLANK} before class."
ALTER TABLE vocabulary_words
    ADD COLUMN IF NOT EXISTS fill_blank_sentence TEXT;

-- 3. tile_sentence: correct full sentence for Word Tile Arrangement (app scrambles at runtime)
--    e.g. "I put my pencil inside my bag."
ALTER TABLE vocabulary_words
    ADD COLUMN IF NOT EXISTS tile_sentence TEXT;

-- 4. hint_text: optional hint shown only at LEARNING difficulty level
ALTER TABLE vocabulary_words
    ADD COLUMN IF NOT EXISTS hint_text TEXT;

-- 5. audio_text_cebuano: exact text fed to Cebuano TTS (distinct from audio_asset_path file path)
--    e.g. "Lapis. Nagsulat ko og lapis sa akong papel."
ALTER TABLE vocabulary_words
    ADD COLUMN IF NOT EXISTS audio_text_cebuano TEXT;

-- 6. audio_text_english: exact text fed to English TTS
--    e.g. "Pencil. I write notes with a pencil in class."
ALTER TABLE vocabulary_words
    ADD COLUMN IF NOT EXISTS audio_text_english TEXT;
