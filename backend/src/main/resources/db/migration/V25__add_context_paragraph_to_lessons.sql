-- V25__add_context_paragraph_to_lessons.sql

ALTER TABLE lessons
    ADD COLUMN IF NOT EXISTS context_paragraph TEXT;
