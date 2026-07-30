-- V14__create_retrieval_practice_tables.sql
-- Create Retrieval Practice & Reinforcement Engine tables

CREATE TABLE IF NOT EXISTS question_templates (
    template_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_format VARCHAR(50) NOT NULL,
    difficulty_level VARCHAR(20) NOT NULL,
    template_text TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS reinforcement_queue (
    queue_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    learner_id UUID NOT NULL REFERENCES learners(learner_id) ON DELETE CASCADE,
    word_id UUID NOT NULL REFERENCES vocabulary_words(word_id) ON DELETE CASCADE,
    scheduled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    attempts_count INTEGER NOT NULL DEFAULT 0,
    is_resolved BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS adaptive_metrics (
    metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    learner_id UUID NOT NULL REFERENCES learners(learner_id) ON DELETE CASCADE,
    difficulty_level VARCHAR(20) NOT NULL,
    option_count INTEGER NOT NULL DEFAULT 4,
    time_limit_seconds INTEGER NOT NULL DEFAULT 30,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(learner_id, difficulty_level)
);

CREATE INDEX IF NOT EXISTS idx_reinforcement_learner ON reinforcement_queue(learner_id, is_resolved);
CREATE INDEX IF NOT EXISTS idx_templates_format ON question_templates(activity_format, difficulty_level);
