-- V44: Add separate Sentence Building (Module 3) streak & progression thresholds and streak celebration settings

ALTER TABLE lessons
    ADD COLUMN IF NOT EXISTS module3_upgrade_streak_required INT DEFAULT 2,
    ADD COLUMN IF NOT EXISTS module3_demotion_threshold INT DEFAULT 1,
    ADD COLUMN IF NOT EXISTS streak_celebration_threshold INT DEFAULT 3;
