-- V65: Create delayed_retention_results table for 3-7 day longitudinal retention checks

CREATE TABLE IF NOT EXISTS delayed_retention_results (
    retention_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    learner_id UUID NOT NULL REFERENCES learners(learner_id) ON DELETE CASCADE,
    lesson_id UUID NOT NULL REFERENCES lessons(lesson_id) ON DELETE CASCADE,
    retention_score DECIMAL(5,2) NOT NULL,
    correct_count INTEGER NOT NULL DEFAULT 0,
    total_count INTEGER NOT NULL DEFAULT 6,
    days_elapsed INTEGER NOT NULL,
    completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_retention_learner_lesson ON delayed_retention_results(learner_id, lesson_id);
