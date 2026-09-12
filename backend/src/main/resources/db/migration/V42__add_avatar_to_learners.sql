-- V42: Add avatar column to learners
ALTER TABLE learners
    ADD COLUMN IF NOT EXISTS avatar VARCHAR(100) DEFAULT 'prof1.jpg';
