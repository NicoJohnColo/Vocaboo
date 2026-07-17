-- V18__add_mastery_apply_mode_to_learners.sql
-- Add mastery_apply_immediately column to learners

ALTER TABLE learners ADD COLUMN mastery_apply_immediately BOOLEAN NOT NULL DEFAULT TRUE;
