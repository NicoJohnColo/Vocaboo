-- Schema migration for Mastery Review & Rewards

CREATE TABLE IF NOT EXISTS session_summaries (
    summary_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    learner_id UUID NOT NULL REFERENCES learners(learner_id) ON DELETE CASCADE,
    session_id UUID NOT NULL,
    lesson_id UUID NOT NULL REFERENCES lessons(lesson_id) ON DELETE CASCADE,
    total_words_reviewed INTEGER NOT NULL,
    correct_pronunciations INTEGER NOT NULL,
    incorrect_pronunciations INTEGER NOT NULL,
    total_attempts INTEGER NOT NULL,
    accuracy_rate NUMERIC(5,2) NOT NULL,
    demerit_points INTEGER NOT NULL,
    completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS rewards_data (
    reward_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    learner_id UUID NOT NULL REFERENCES learners(learner_id) ON DELETE CASCADE,
    lesson_id UUID NOT NULL REFERENCES lessons(lesson_id) ON DELETE CASCADE,
    badge_type VARCHAR(50) NOT NULL,
    earned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(learner_id, lesson_id, badge_type)
);

CREATE INDEX IF NOT EXISTS idx_session_summaries_learner ON session_summaries(learner_id);
CREATE INDEX IF NOT EXISTS idx_rewards_data_learner ON rewards_data(learner_id);
