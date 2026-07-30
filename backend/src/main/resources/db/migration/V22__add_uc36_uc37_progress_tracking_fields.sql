-- V22__add_uc36_uc37_progress_tracking_fields.sql
-- Add progress tracking fields for UC-3.6 and adaptive difficulty fields for UC-3.7

-- 1. ALTER practice_results
ALTER TABLE practice_results ADD COLUMN IF NOT EXISTS attempt_number INTEGER NOT NULL DEFAULT 1;
ALTER TABLE practice_results ADD COLUMN IF NOT EXISTS activity_type VARCHAR(30);

UPDATE practice_results
SET activity_type = 'MULTIPLE_CHOICE'
WHERE activity_type IS NULL;

-- 2. ALTER learner_mastery
ALTER TABLE learner_mastery ADD COLUMN IF NOT EXISTS mastery_level VARCHAR(20) NOT NULL DEFAULT 'LEARNING';

UPDATE learner_mastery
SET mastery_level = CASE
    WHEN overall_accuracy >= 90.0 THEN 'MASTERED'
    WHEN overall_accuracy >= 80.0 THEN 'PROFICIENT'
    WHEN overall_accuracy >= 70.0 THEN 'FAMILIAR'
    ELSE 'LEARNING' END;

-- 3. ALTER difficulty_progress
ALTER TABLE difficulty_progress ADD COLUMN IF NOT EXISTS needs_reintroduction BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE difficulty_progress ADD COLUMN IF NOT EXISTS reintroduction_count INTEGER NOT NULL DEFAULT 0;
ALTER TABLE difficulty_progress ADD COLUMN IF NOT EXISTS last_reintroduced_at TIMESTAMPTZ;

-- 4. Add index on difficulty_progress(learner_id, needs_reintroduction) WHERE needs_reintroduction = TRUE
CREATE INDEX IF NOT EXISTS idx_difficulty_progress_needs_reintro
ON difficulty_progress(learner_id, needs_reintroduction)
WHERE needs_reintroduction = TRUE;
