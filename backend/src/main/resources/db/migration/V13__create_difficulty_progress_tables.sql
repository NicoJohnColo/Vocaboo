-- V13__create_difficulty_progress_tables.sql
-- Create Adaptive Difficulty tracking tables

CREATE TABLE IF NOT EXISTS difficulty_progress (
    progress_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    learner_id UUID NOT NULL REFERENCES learners(learner_id) ON DELETE CASCADE,
    word_id UUID NOT NULL REFERENCES vocabulary_words(word_id) ON DELETE CASCADE,
    current_level VARCHAR(20) NOT NULL DEFAULT 'LEARNING',
    consecutive_correct INTEGER NOT NULL DEFAULT 0,
    consecutive_incorrect INTEGER NOT NULL DEFAULT 0,
    last_adjusted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(learner_id, word_id)
);

CREATE TABLE IF NOT EXISTS difficulty_audit_logs (
    audit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    learner_id UUID NOT NULL REFERENCES learners(learner_id) ON DELETE CASCADE,
    word_id UUID NOT NULL REFERENCES vocabulary_words(word_id) ON DELETE CASCADE,
    old_level VARCHAR(20) NOT NULL,
    new_level VARCHAR(20) NOT NULL,
    reason VARCHAR(100) NOT NULL,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_difficulty_progress_learner ON difficulty_progress(learner_id);
CREATE INDEX IF NOT EXISTS idx_difficulty_progress_word ON difficulty_progress(word_id);
CREATE INDEX IF NOT EXISTS idx_difficulty_audit_learner ON difficulty_audit_logs(learner_id);
CREATE INDEX IF NOT EXISTS idx_difficulty_audit_word ON difficulty_audit_logs(word_id);
