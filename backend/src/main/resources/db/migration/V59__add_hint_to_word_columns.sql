-- V59: Add hint_definition and hint_cebuano_sentence columns to vocabulary_words
-- These support the new HINT_TO_WORD (9th) activity type.
-- hint_definition: short English definition/synonym clue for FAMILIAR/PROFICIENT tiers
-- hint_cebuano_sentence: short Cebuano clue for LEARNING tier (falls back to example_sentence_cebuano)
ALTER TABLE vocabulary_words
    ADD COLUMN IF NOT EXISTS hint_definition TEXT,
    ADD COLUMN IF NOT EXISTS hint_cebuano_sentence TEXT;
