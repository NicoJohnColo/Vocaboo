-- Vocaboo Seed Content V2 - Categories, Lessons, and Vocabulary Words (No Learners)

-- 5 categories
INSERT INTO vocabulary_categories (category_id, category_name, description, sort_order) VALUES
  ('a1000000-0000-0000-0000-000000000001', 'School Objects',           'Items commonly found in school',        1),
  ('a1000000-0000-0000-0000-000000000002', 'Family Members',           'Words for family relationships',        2),
  ('a1000000-0000-0000-0000-000000000003', 'Animals',                  'Common animals',                        3),
  ('a1000000-0000-0000-0000-000000000004', 'Food and Drinks',          'Everyday food and beverages',           4),
  ('a1000000-0000-0000-0000-000000000005', 'Places in the Community',  'Places in a Filipino community',        5)
ON CONFLICT (category_id) DO NOTHING;

-- 5 lessons (one per category, Grade 4)
INSERT INTO lessons (lesson_id, category_id, lesson_title, grade_level, lesson_order, total_word_count) VALUES
  ('b1000000-0000-0000-0000-000000000001','a1000000-0000-0000-0000-000000000001','Lesson 1 - School Objects',         'GRADE_4',1,5),
  ('b1000000-0000-0000-0000-000000000002','a1000000-0000-0000-0000-000000000002','Lesson 1 - Family Members',         'GRADE_4',1,5),
  ('b1000000-0000-0000-0000-000000000003','a1000000-0000-0000-0000-000000000003','Lesson 1 - Animals',                'GRADE_4',1,5),
  ('b1000000-0000-0000-0000-000000000004','a1000000-0000-0000-0000-000000000004','Lesson 1 - Food and Drinks',        'GRADE_4',1,5),
  ('b1000000-0000-0000-0000-000000000005','a1000000-0000-0000-0000-000000000005','Lesson 1 - Places in the Community','GRADE_4',1,5)
ON CONFLICT (lesson_id) DO NOTHING;

-- Lesson 1 words
INSERT INTO vocabulary_words
  (word_id, lesson_id, english_word, cebuano_meaning, example_sentence_english, example_sentence_cebuano, grade_level, word_order, phonological_tip_key)
VALUES
  ('c1000000-0000-0000-0000-000000000001','b1000000-0000-0000-0000-000000000001','Pencil',  'Lapis',    'I use a pencil to write my answers.',  'Gigamit nako ang lapis sa pagsulat sa akong mga tubag.','GRADE_4',1, NULL),
  ('c1000000-0000-0000-0000-000000000002','b1000000-0000-0000-0000-000000000001','Notebook','Kuwaderno','My notebook is inside my bag.',         'Ang akong kuwaderno naa sulod sa akong bag.',           'GRADE_4',2, NULL),
  ('c1000000-0000-0000-0000-000000000003','b1000000-0000-0000-0000-000000000001','Eraser',  'Pamhid',   'The eraser removed the mistake.',      'Gitangtang sa pamhid ang sayop.',                       'GRADE_4',3, NULL),
  ('c1000000-0000-0000-0000-000000000004','b1000000-0000-0000-0000-000000000001','Bag',     'Bag',      'Her bag is color blue.',                'Asul ang iyang bag.',                                   'GRADE_4',4, NULL),
  ('c1000000-0000-0000-0000-000000000005','b1000000-0000-0000-0000-000000000001','Ruler',   'Ruler',    'The ruler is used to measure lines.',  'Gigamit ang ruler sa pagsukod sa mga linya.',           'GRADE_4',5, NULL)
ON CONFLICT (word_id) DO NOTHING;

-- (rest of file omitted for brevity; full file exists under src/main/resources/V2__seed_content.sql)
