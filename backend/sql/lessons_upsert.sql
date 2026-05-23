-- Upsert missing lesson rows needed by vocabulary_words lesson_id foreign keys.
-- Safe to run multiple times.

INSERT INTO lessons
  (lesson_id, category_id, lesson_title, grade_level, lesson_order, total_word_count)
VALUES
  ('b1000000-0000-0000-0000-000000000006','a1000000-0000-0000-0000-000000000001','Lesson 2 - More School Objects','GRADE_4',2,5),
  ('b1000000-0000-0000-0000-000000000007','a1000000-0000-0000-0000-000000000002','Lesson 2 - More Family Members','GRADE_4',2,5),
  ('b1000000-0000-0000-0000-000000000008','a1000000-0000-0000-0000-000000000003','Lesson 2 - More Animals','GRADE_4',2,5),
  ('b1000000-0000-0000-0000-000000000009','a1000000-0000-0000-0000-000000000004','Lesson 2 - More Food and Drinks','GRADE_4',2,5),
  ('b1000000-0000-0000-0000-000000000010','a1000000-0000-0000-0000-000000000005','Lesson 2 - More Places','GRADE_4',2,5)
ON CONFLICT (lesson_id) DO UPDATE SET
  category_id = EXCLUDED.category_id,
  lesson_title = EXCLUDED.lesson_title,
  grade_level = EXCLUDED.grade_level,
  lesson_order = EXCLUDED.lesson_order,
  total_word_count = EXCLUDED.total_word_count,
  updated_at = NOW();
