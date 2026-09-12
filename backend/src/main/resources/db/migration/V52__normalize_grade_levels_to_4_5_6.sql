-- Migration V52: Ensure grade_level_enum values are GRADE_4, GRADE_5, GRADE_6 and update all lessons
DO $$
BEGIN
    -- Rename GRADE_3_4 to GRADE_4 if it still exists
    IF EXISTS (
        SELECT 1 FROM pg_enum e
        JOIN pg_type t ON e.enumtypid = t.oid
        JOIN pg_namespace n ON t.typnamespace = n.oid
        WHERE n.nspname = 'public' AND t.typname = 'grade_level_enum' AND e.enumlabel = 'GRADE_3_4'
    ) THEN
        ALTER TYPE public.grade_level_enum RENAME VALUE 'GRADE_3_4' TO 'GRADE_4';
    END IF;

    -- Rename GRADE_5_6 to GRADE_5 if it still exists
    IF EXISTS (
        SELECT 1 FROM pg_enum e
        JOIN pg_type t ON e.enumtypid = t.oid
        JOIN pg_namespace n ON t.typnamespace = n.oid
        WHERE n.nspname = 'public' AND t.typname = 'grade_level_enum' AND e.enumlabel = 'GRADE_5_6'
    ) THEN
        ALTER TYPE public.grade_level_enum RENAME VALUE 'GRADE_5_6' TO 'GRADE_5';
    END IF;
END $$;

-- Explicitly ensure GRADE_6 is registered in grade_level_enum
ALTER TYPE public.grade_level_enum ADD VALUE IF NOT EXISTS 'GRADE_6';

-- Ensure target_grades and grade_level in lessons table are normalized
UPDATE public.lessons
SET target_grades = REPLACE(REPLACE(target_grades, 'GRADE_3_4', 'GRADE_4'), 'GRADE_5_6', 'GRADE_5')
WHERE target_grades IS NOT NULL AND (target_grades LIKE '%GRADE_3_4%' OR target_grades LIKE '%GRADE_5_6%');

UPDATE public.lessons
SET target_grades = grade_level::text
WHERE target_grades IS NULL;
