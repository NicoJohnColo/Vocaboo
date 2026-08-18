-- Feature 1: Diagnostic audit fields
ALTER TABLE difficulty_progress
    ADD COLUMN IF NOT EXISTS diagnostic_administered BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS diagnostic_result VARCHAR(20) DEFAULT 'not_administered',
    ADD COLUMN IF NOT EXISTS diagnostic_activity_type VARCHAR(50);

-- Feature 2: Module-level time tracking
ALTER TABLE lesson_module_scores
    ADD COLUMN IF NOT EXISTS time_seconds INTEGER;
