-- V29: Add sentence-building difficulty tracking columns to difficulty_progress
ALTER TABLE difficulty_progress
    ADD COLUMN IF NOT EXISTS sentence_current_level             VARCHAR(20) NOT NULL DEFAULT 'LEARNING',
    ADD COLUMN IF NOT EXISTS sentence_consecutive_correct       INTEGER     NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS sentence_consecutive_incorrect     INTEGER     NOT NULL DEFAULT 0;