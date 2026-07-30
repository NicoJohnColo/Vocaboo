-- V17__add_points_and_bonus_columns.sql
-- Add points column to practice_results and points_earned to session_summaries

ALTER TABLE practice_results ADD COLUMN points INTEGER NOT NULL DEFAULT 0;
ALTER TABLE session_summaries ADD COLUMN points_earned INTEGER NOT NULL DEFAULT 0;
