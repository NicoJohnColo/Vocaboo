-- Migration to fix incorrect lesson titles for the first lesson in categories 2, 3, 4, and 5.
-- This ensures the roadmap renders sequentially from top to bottom (Lesson 1 -> Lesson 2 -> Cumulative Review).

UPDATE lessons
SET lesson_title = 'Lesson 1 - Family Members'
WHERE lesson_id = 'b1000000-0000-0000-0000-000000000002';

UPDATE lessons
SET lesson_title = 'Lesson 1 - Animals'
WHERE lesson_id = 'b1000000-0000-0000-0000-000000000003';

UPDATE lessons
SET lesson_title = 'Lesson 1 - Food and Drinks'
WHERE lesson_id = 'b1000000-0000-0000-0000-000000000004';

UPDATE lessons
SET lesson_title = 'Lesson 1 - Places in the Community'
WHERE lesson_id = 'b1000000-0000-0000-0000-000000000005';
