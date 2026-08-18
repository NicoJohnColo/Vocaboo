-- V30__add_missing_difficulty_progress_fields.sql
-- Add missing fields to difficulty_progress table that are present in the JPA entity

ALTER TABLE difficulty_progress ADD COLUMN IF NOT EXISTS recall_in_current_streak BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE difficulty_progress ADD COLUMN IF NOT EXISTS attempt_count_at_current_tier INTEGER NOT NULL DEFAULT 1;
ALTER TABLE difficulty_progress ADD COLUMN IF NOT EXISTS needs_teacher_review BOOLEAN NOT NULL DEFAULT FALSE;
