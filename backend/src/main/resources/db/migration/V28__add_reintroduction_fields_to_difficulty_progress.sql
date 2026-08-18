-- V28__add_reintroduction_fields_to_difficulty_progress.sql
ALTER TABLE difficulty_progress 
ADD COLUMN IF NOT EXISTS needs_teacher_review BOOLEAN NOT NULL DEFAULT false;
