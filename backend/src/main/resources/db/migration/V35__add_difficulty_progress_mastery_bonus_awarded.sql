-- Migration V35 - Add Mastery Bonus Awarded Column to Difficulty Progress

ALTER TABLE difficulty_progress
ADD COLUMN IF NOT EXISTS mastery_bonus_awarded BOOLEAN NOT NULL DEFAULT FALSE;
