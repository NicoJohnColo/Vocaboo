-- V24__add_pos_focus_to_learners.sql

ALTER TABLE learners
    ADD COLUMN IF NOT EXISTS pos_focus VARCHAR(50) DEFAULT 'ALL';
