-- Migration V55: Add grade_level to classes table
ALTER TABLE classes
    ADD COLUMN IF NOT EXISTS grade_level grade_level_enum DEFAULT 'GRADE_4';

UPDATE classes
    SET grade_level = 'GRADE_4'
    WHERE grade_level IS NULL;

CREATE INDEX IF NOT EXISTS idx_classes_grade_level ON classes(grade_level);
