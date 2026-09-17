CREATE TABLE daily_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    learner_id UUID NOT NULL REFERENCES learners(learner_id) ON DELETE CASCADE,
    goal_date DATE NOT NULL,
    target_count INTEGER NOT NULL DEFAULT 10,
    current_progress INTEGER NOT NULL DEFAULT 0,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    points_awarded BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_daily_goal_learner_date UNIQUE (learner_id, goal_date)
);

CREATE INDEX idx_daily_goals_learner_id ON daily_goals(learner_id);
CREATE INDEX idx_daily_goals_date ON daily_goals(goal_date);
