-- Migration V34 - Add Bonus and Points to Learner Lesson Status

ALTER TABLE learner_lesson_status
ADD COLUMN IF NOT EXISTS best_lesson_points INTEGER NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS lesson_completion_bonus_awarded BOOLEAN NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS perfect_score_bonus_awarded BOOLEAN NOT NULL DEFAULT FALSE;
