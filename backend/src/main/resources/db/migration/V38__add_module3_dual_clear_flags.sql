-- Add dual-clear flags for Module 3 progression
ALTER TABLE difficulty_progress ADD COLUMN IF NOT EXISTS sentence_completion_cleared BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE difficulty_progress ADD COLUMN IF NOT EXISTS sentence_rearrangement_cleared BOOLEAN NOT NULL DEFAULT FALSE;
