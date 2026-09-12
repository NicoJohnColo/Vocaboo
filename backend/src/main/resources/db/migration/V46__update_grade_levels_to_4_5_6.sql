-- V46: Update grade_level_enum values to GRADE_4, GRADE_5, GRADE_6
ALTER TYPE grade_level_enum RENAME VALUE 'GRADE_3_4' TO 'GRADE_4';
ALTER TYPE grade_level_enum RENAME VALUE 'GRADE_5_6' TO 'GRADE_5';

-- Update target_grades in lessons table
UPDATE lessons
SET target_grades = REPLACE(REPLACE(target_grades, 'GRADE_3_4', 'GRADE_4'), 'GRADE_5_6', 'GRADE_5')
WHERE target_grades IS NOT NULL;
