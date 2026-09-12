-- Migration V47: Add Classroom Context Columns and Class Performance Table

-- 1. Add classroom_context_id to practice_sessions
ALTER TABLE practice_sessions ADD COLUMN IF NOT EXISTS classroom_context_id UUID DEFAULT NULL REFERENCES classes(class_id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_practice_sessions_classroom_context_id ON practice_sessions(classroom_context_id);

-- 2. Add context_type and classroom_id to lesson_module_scores
ALTER TABLE lesson_module_scores ADD COLUMN IF NOT EXISTS context_type VARCHAR(10) NOT NULL DEFAULT 'GLOBAL';
ALTER TABLE lesson_module_scores ADD COLUMN IF NOT EXISTS classroom_id UUID DEFAULT NULL REFERENCES classes(class_id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_lesson_module_scores_classroom_id ON lesson_module_scores(classroom_id);

-- 3. Add context_type and classroom_id to session_summaries
ALTER TABLE session_summaries ADD COLUMN IF NOT EXISTS context_type VARCHAR(10) NOT NULL DEFAULT 'GLOBAL';
ALTER TABLE session_summaries ADD COLUMN IF NOT EXISTS classroom_id UUID DEFAULT NULL REFERENCES classes(class_id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_session_summaries_classroom_id ON session_summaries(classroom_id);

-- 4. Add context_type and classroom_id to point_transactions
ALTER TABLE point_transactions ADD COLUMN IF NOT EXISTS context_type VARCHAR(10) NOT NULL DEFAULT 'GLOBAL';
ALTER TABLE point_transactions ADD COLUMN IF NOT EXISTS classroom_id UUID DEFAULT NULL REFERENCES classes(class_id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_point_transactions_classroom_id ON point_transactions(classroom_id);

-- 5. Create class_performance table if it doesn't exist
CREATE TABLE IF NOT EXISTS class_performance (
    class_performance_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    learner_id UUID NOT NULL REFERENCES learners(learner_id) ON DELETE CASCADE,
    classroom_id UUID NOT NULL REFERENCES classes(class_id) ON DELETE CASCADE,
    class_points INTEGER NOT NULL DEFAULT 0,
    class_correct_answers INTEGER NOT NULL DEFAULT 0,
    class_total_questions INTEGER NOT NULL DEFAULT 0,
    class_accuracy NUMERIC(5, 2) NOT NULL DEFAULT 0.00,
    class_sessions_played INTEGER NOT NULL DEFAULT 0,
    class_mastery_level VARCHAR(20) NOT NULL DEFAULT 'LEARNING',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_learner_classroom UNIQUE (learner_id, classroom_id)
);

CREATE INDEX IF NOT EXISTS idx_class_perf_learner ON class_performance(learner_id);
CREATE INDEX IF NOT EXISTS idx_class_perf_classroom ON class_performance(classroom_id);
