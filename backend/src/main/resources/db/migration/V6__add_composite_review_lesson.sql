-- Add composite review lesson type and configuration

-- Add lesson_type enum
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'lesson_type_enum') THEN
        CREATE TYPE lesson_type_enum AS ENUM ('REGULAR', 'COMPOSITE_REVIEW');
    END IF;
END $$;

-- Add lesson_type column to lessons table
ALTER TABLE lessons ADD COLUMN IF NOT EXISTS lesson_type lesson_type_enum DEFAULT 'REGULAR';

-- Add source_lesson_ids column for composite review lessons (array of lesson IDs)
ALTER TABLE lessons ADD COLUMN IF NOT EXISTS source_lesson_ids UUID[] DEFAULT NULL;

-- Add composite_review_after_lesson_id column for configurable node insertion position
ALTER TABLE lessons ADD COLUMN IF NOT EXISTS composite_review_after_lesson_id UUID DEFAULT NULL;

-- Add index for composite review configuration
CREATE INDEX IF NOT EXISTS idx_lessons_composite_review_after ON lessons(composite_review_after_lesson_id) WHERE composite_review_after_lesson_id IS NOT NULL;

-- Add index for lesson type
CREATE INDEX IF NOT EXISTS idx_lessons_type ON lessons(lesson_type);

-- Add comment to document the new columns
COMMENT ON COLUMN lessons.lesson_type IS 'Type of lesson: REGULAR or COMPOSITE_REVIEW';
COMMENT ON COLUMN lessons.source_lesson_ids IS 'Array of source lesson IDs for composite review lessons';
COMMENT ON COLUMN lessons.composite_review_after_lesson_id IS 'Lesson ID after which this composite review should appear (for configurable node insertion)';
