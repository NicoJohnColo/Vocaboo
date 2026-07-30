-- V12__create_progress_tracking_tables.sql
-- Create practice tracking schema tables

-- Ensure learners.learner_id has a PRIMARY KEY (repairs DBs created without Flyway V1)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint c
        JOIN pg_class t ON t.oid = c.conrelid
        WHERE t.relname = 'learners'
          AND c.contype = 'p'
    ) THEN
        ALTER TABLE learners ADD PRIMARY KEY (learner_id);
    END IF;
END
$$;

CREATE TABLE IF NOT EXISTS practice_sessions (
    session_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    learner_id UUID NOT NULL REFERENCES learners(learner_id) ON DELETE CASCADE,
    lesson_id UUID NOT NULL REFERENCES lessons(lesson_id) ON DELETE CASCADE,
    module_number INTEGER NOT NULL CHECK (module_number BETWEEN 1 AND 4),
    score NUMERIC(5,2),
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS practice_results (
    result_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES practice_sessions(session_id) ON DELETE CASCADE,
    word_id UUID NOT NULL REFERENCES vocabulary_words(word_id) ON DELETE CASCADE,
    is_correct BOOLEAN NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS learner_mastery (
    mastery_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    learner_id UUID UNIQUE NOT NULL REFERENCES learners(learner_id) ON DELETE CASCADE,
    total_sessions_played INTEGER NOT NULL DEFAULT 0,
    total_correct_answers INTEGER NOT NULL DEFAULT 0,
    total_questions_answered INTEGER NOT NULL DEFAULT 0,
    overall_accuracy NUMERIC(5,2) NOT NULL DEFAULT 0.0,
    words_mastered_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS word_performance (
    performance_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    learner_id UUID NOT NULL REFERENCES learners(learner_id) ON DELETE CASCADE,
    word_id UUID NOT NULL REFERENCES vocabulary_words(word_id) ON DELETE CASCADE,
    correct_count INTEGER NOT NULL DEFAULT 0,
    incorrect_count INTEGER NOT NULL DEFAULT 0,
    total_attempts INTEGER NOT NULL DEFAULT 0,
    accuracy NUMERIC(5,2) NOT NULL DEFAULT 0.0,
    last_practiced_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(learner_id, word_id)
);

CREATE INDEX IF NOT EXISTS idx_practice_sessions_learner ON practice_sessions(learner_id);
CREATE INDEX IF NOT EXISTS idx_practice_sessions_lesson ON practice_sessions(lesson_id);
CREATE INDEX IF NOT EXISTS idx_practice_results_session ON practice_results(session_id);
CREATE INDEX IF NOT EXISTS idx_practice_results_word ON practice_results(word_id);
CREATE INDEX IF NOT EXISTS idx_word_performance_learner_word ON word_performance(learner_id, word_id);
