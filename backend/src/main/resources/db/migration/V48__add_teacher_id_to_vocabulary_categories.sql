-- Migration V48: Add teacher_id to vocabulary_categories for teacher category authorship
-- Allows teachers to create classroom-specific categories and keeps global curriculum categories isolated.

ALTER TABLE vocabulary_categories ADD COLUMN IF NOT EXISTS teacher_id UUID DEFAULT NULL REFERENCES teachers(teacher_id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_vocabulary_categories_teacher_id ON vocabulary_categories(teacher_id);

-- Drop old global unique constraint on category_name so teachers can name categories freely
ALTER TABLE vocabulary_categories DROP CONSTRAINT IF EXISTS vocabulary_categories_category_name_key;
