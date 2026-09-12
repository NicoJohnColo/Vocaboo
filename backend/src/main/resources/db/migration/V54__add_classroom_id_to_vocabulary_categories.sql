-- Migration V54: Add classroom_id to vocabulary_categories
-- Allows teachers to bind categories strictly to a specific classroom.

ALTER TABLE vocabulary_categories
    ADD COLUMN IF NOT EXISTS classroom_id UUID DEFAULT NULL REFERENCES classes(class_id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_vocabulary_categories_classroom_id ON vocabulary_categories(classroom_id);
CREATE INDEX IF NOT EXISTS idx_vocabulary_categories_teacher_classroom ON vocabulary_categories(teacher_id, classroom_id);
