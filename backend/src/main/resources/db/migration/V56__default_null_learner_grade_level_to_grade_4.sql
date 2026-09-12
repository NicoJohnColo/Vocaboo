-- Migration V56: Default NULL learner, lesson, and class grade_level to GRADE_4
UPDATE learners
SET grade_level = 'GRADE_4'
WHERE grade_level IS NULL;

UPDATE lessons
SET grade_level = 'GRADE_4'
WHERE grade_level IS NULL;

UPDATE classes
SET grade_level = 'GRADE_4'
WHERE grade_level IS NULL;
