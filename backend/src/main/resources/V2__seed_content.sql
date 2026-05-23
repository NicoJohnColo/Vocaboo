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
  ('b1000000-0000-0000-0000-000000000002','a1000000-0000-0000-0000-000000000002','Lesson 2 - Family Members',         'GRADE_4',1,5),
  ('b1000000-0000-0000-0000-000000000003','a1000000-0000-0000-0000-000000000003','Lesson 3 - Animals',                'GRADE_4',1,5),
  ('b1000000-0000-0000-0000-000000000004','a1000000-0000-0000-0000-000000000004','Lesson 4 - Food and Drinks',        'GRADE_4',1,5),
  ('b1000000-0000-0000-0000-000000000005','a1000000-0000-0000-0000-000000000005','Lesson 5 - Places in the Community','GRADE_4',1,5)
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

-- Lesson 2 words
INSERT INTO vocabulary_words
  (word_id, lesson_id, english_word, cebuano_meaning, example_sentence_english, example_sentence_cebuano, grade_level, word_order, phonological_tip_key)
VALUES
  ('c2000000-0000-0000-0000-000000000001','b1000000-0000-0000-0000-000000000002','Mother',     'Inahan',            'My mother cooks delicious food.',      'Ang akong inahan nagluto og lami nga pagkaon.',         'GRADE_4',1, NULL),
  ('c2000000-0000-0000-0000-000000000002','b1000000-0000-0000-0000-000000000002','Father',     'Amahan',            'My father goes to work every day.',    'Ang akong amahan moadto sa trabaho matag adlaw.',       'GRADE_4',2, 'f_sound'),
  ('c2000000-0000-0000-0000-000000000003','b1000000-0000-0000-0000-000000000002','Sister',     'Igsoon nga babaye', 'My sister helps me study.',            'Ang akong igsoon nga babaye motabang nako sa pagtuon.','GRADE_4',3, NULL),
  ('c2000000-0000-0000-0000-000000000004','b1000000-0000-0000-0000-000000000002','Brother',    'Igsoon nga lalaki', 'My brother plays basketball.',         'Ang akong igsoon nga lalaki magdula og basketball.',    'GRADE_4',4, 'th_sound'),
  ('c2000000-0000-0000-0000-000000000005','b1000000-0000-0000-0000-000000000002','Grandmother','Lola',              'My grandmother tells stories.',        'Ang akong lola magsulti og mga istorya.',               'GRADE_4',5, NULL)
ON CONFLICT (word_id) DO NOTHING;

-- Lesson 3 words
INSERT INTO vocabulary_words
  (word_id, lesson_id, english_word, cebuano_meaning, example_sentence_english, example_sentence_cebuano, grade_level, word_order, phonological_tip_key)
VALUES
  ('c3000000-0000-0000-0000-000000000001','b1000000-0000-0000-0000-000000000003','Dog',  'Iro',    'The dog barks loudly.',        'Kusog nga mobark ang iro.',         'GRADE_4',1, NULL),
  ('c3000000-0000-0000-0000-000000000002','b1000000-0000-0000-0000-000000000003','Cat',  'Iring',  'The cat sleeps on the chair.', 'Ang iring natulog sa lingkuranan.', 'GRADE_4',2, NULL)
ON CONFLICT (word_id) DO UPDATE SET is_confusable_pair_member = true;

-- Update specific rows for is_confusable_pair_member
UPDATE vocabulary_words SET is_confusable_pair_member = true WHERE word_id IN ('c3000000-0000-0000-0000-000000000001', 'c3000000-0000-0000-0000-000000000002');

-- Seed confusable pair
INSERT INTO confusable_word_pairs (pair_id, lesson_id, word_a_id, word_b_id, contrastive_sentence_a, contrastive_sentence_b) VALUES
  ('d1000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000003', 'c3000000-0000-0000-0000-000000000001', 'c3000000-0000-0000-0000-000000000002', 'The dog barks at the mailman.', 'The cat meows when it is hungry.')
ON CONFLICT (pair_id) DO NOTHING;

INSERT INTO vocabulary_words
  (word_id, lesson_id, english_word, cebuano_meaning, example_sentence_english, example_sentence_cebuano, grade_level, word_order, phonological_tip_key)
VALUES
  ('c3000000-0000-0000-0000-000000000003','b1000000-0000-0000-0000-000000000003','Bird', 'Langgam','The bird flies in the sky.',   'Ang langgam naglupad sa langit.',   'GRADE_4',3, NULL),
  ('c3000000-0000-0000-0000-000000000004','b1000000-0000-0000-0000-000000000003','Fish', 'Isda',   'The fish swims in the water.', 'Ang isda naglangoy sa tubig.',      'GRADE_4',4, 'f_sound'),
  ('c3000000-0000-0000-0000-000000000005','b1000000-0000-0000-0000-000000000003','Horse','Kabayo', 'The horse runs fast.',         'Kusog modagan ang kabayo.',         'GRADE_4',5, NULL)
ON CONFLICT (word_id) DO NOTHING;

-- Lesson 4 words
INSERT INTO vocabulary_words
  (word_id, lesson_id, english_word, cebuano_meaning, example_sentence_english, example_sentence_cebuano, grade_level, word_order, phonological_tip_key)
VALUES
  ('c4000000-0000-0000-0000-000000000001','b1000000-0000-0000-0000-000000000004','Rice', 'Kan-on',  'Rice is our staple food.',      'Ang kan-on mao ang atong pangunang pagkaon.',  'GRADE_4',1, NULL),
  ('c4000000-0000-0000-0000-000000000002','b1000000-0000-0000-0000-000000000004','Water','Tubig',   'Drink water every day.',        'Pag-inom og tubig matag adlaw.',               'GRADE_4',2, NULL),
  ('c4000000-0000-0000-0000-000000000003','b1000000-0000-0000-0000-000000000004','Bread','Pan',     'I eat bread for breakfast.',    'Mokaon ko og pan sa pamahaw.',                 'GRADE_4',3, NULL),
  ('c4000000-0000-0000-0000-000000000004','b1000000-0000-0000-0000-000000000004','Milk', 'Gatas',   'Milk helps make bones strong.','Ang gatas makatabang sa pagpalig-on sa bukog.','GRADE_4',4, NULL),
  ('c4000000-0000-0000-0000-000000000005','b1000000-0000-0000-0000-000000000004','Apple','Mansanas','The apple is sweet and red.',   'Ang mansanas tam-is ug pula.',                 'GRADE_4',5, NULL)
ON CONFLICT (word_id) DO NOTHING;

-- Lesson 5 words
INSERT INTO vocabulary_words
  (word_id, lesson_id, english_word, cebuano_meaning, example_sentence_english, example_sentence_cebuano, grade_level, word_order, phonological_tip_key)
VALUES
  ('c5000000-0000-0000-0000-000000000001','b1000000-0000-0000-0000-000000000005','School',  'Eskwelahan','The students go to school daily.',      'Ang mga estudyante moadto sa eskwelahan matag adlaw.','GRADE_4',1, NULL),
  ('c5000000-0000-0000-0000-000000000002','b1000000-0000-0000-0000-000000000005','Hospital','Ospital',   'The doctor works in the hospital.',    'Ang doktor nagtrabaho sa ospital.',                   'GRADE_4',2, NULL),
  ('c5000000-0000-0000-0000-000000000003','b1000000-0000-0000-0000-000000000005','Market',  'Merkado',   'Mother buys vegetables in the market.','Ang inahan mopalit og utanon sa merkado.',             'GRADE_4',3, NULL),
  ('c5000000-0000-0000-0000-000000000004','b1000000-0000-0000-0000-000000000005','Church',  'Simbahan',  'We pray in the church.',               'Nag-ampo kami sa simbahan.',                          'GRADE_4',4, 'th_sound'),
  ('c5000000-0000-0000-0000-000000000005','b1000000-0000-0000-0000-000000000005','Park',    'Liwasan',   'Children play in the park.',           'Ang mga bata nagdula sa liwasan.',                    'GRADE_4',5, NULL)
ON CONFLICT (word_id) DO NOTHING;

-- Lesson 2 per category (Totaling 5 new lessons, b1000000-0000-0000-0000-000000000006 to 0010)
INSERT INTO lessons (lesson_id, category_id, lesson_title, grade_level, lesson_order, total_word_count) VALUES
  ('b1000000-0000-0000-0000-000000000006','a1000000-0000-0000-0000-000000000001','Lesson 2 - More School Objects','GRADE_4',2,5),
  ('b1000000-0000-0000-0000-000000000007','a1000000-0000-0000-0000-000000000002','Lesson 2 - More Family Members','GRADE_4',2,5),
  ('b1000000-0000-0000-0000-000000000008','a1000000-0000-0000-0000-000000000003','Lesson 2 - More Animals',       'GRADE_4',2,5),
  ('b1000000-0000-0000-0000-000000000009','a1000000-0000-0000-0000-000000000004','Lesson 2 - More Food and Drinks','GRADE_4',2,5),
  ('b1000000-0000-0000-0000-000000000010','a1000000-0000-0000-0000-000000000005','Lesson 2 - More Places',         'GRADE_4',2,5)
ON CONFLICT (lesson_id) DO NOTHING;

-- Vocabulary words for Lesson 6 (More School Objects)
INSERT INTO vocabulary_words
  (word_id, lesson_id, english_word, cebuano_meaning, example_sentence_english, example_sentence_cebuano, grade_level, word_order, phonological_tip_key)
VALUES
  ('c1000000-0000-0000-0000-000000000006','b1000000-0000-0000-0000-000000000006','Desk',    'Lamesa',   'I sit at my desk to read.',            'Naglingkod ko sa akong lamesa aron magbasa.',          'GRADE_4',1, NULL),
  ('c1000000-0000-0000-0000-000000000007','b1000000-0000-0000-0000-000000000006','Chalk',   'Tsok',     'The teacher writes with chalk.',       'Nagsulat ang maestra gamit ang tsok.',                 'GRADE_4',2, NULL),
  ('c1000000-0000-0000-0000-000000000008','b1000000-0000-0000-0000-000000000006','Crayon',  'Krayola',  'Draw a picture with a green crayon.',  'Pagdibuho og hulagway gamit ang berde nga krayola.',   'GRADE_4',3, NULL),
  ('c1000000-0000-0000-0000-000000000009','b1000000-0000-0000-0000-000000000006','Scissors','Gunting',  'Be careful when using scissors.',      'Pag-amping sa paggamit sa gunting.',                   'GRADE_4',4, NULL),
  ('c1000000-0000-0000-0000-000000000010','b1000000-0000-0000-0000-000000000006','Glue',    'Papilit',  'Use glue to paste the paper.',         'Gamita ang papilit aron idikit ang papel.',            'GRADE_4',5, NULL)
ON CONFLICT (word_id) DO NOTHING;

-- Vocabulary words for Lesson 7 (More Family Members)
INSERT INTO vocabulary_words
  (word_id, lesson_id, english_word, cebuano_meaning, example_sentence_english, example_sentence_cebuano, grade_level, word_order, phonological_tip_key)
VALUES
  ('c2000000-0000-0000-0000-000000000006','b1000000-0000-0000-0000-000000000007','Uncle',      'Tiyo',     'My uncle plays guitar.',               'Ang akong tiyo magdula og gitara.',                   'GRADE_4',1, NULL),
  ('c2000000-0000-0000-0000-000000000007','b1000000-0000-0000-0000-000000000007','Aunt',       'Tiya',     'My aunt visits us on Sundays.',        'Ang akong tiya moduaw kanamo matag Dominggo.',         'GRADE_4',2, NULL),
  ('c2000000-0000-0000-0000-000000000008','b1000000-0000-0000-0000-000000000007','Cousin',     'Ig-agaw',  'I play with my cousin in the yard.',   'Nagdula ko uban sa akong ig-agaw sa nataran.',         'GRADE_4',3, NULL),
  ('c2000000-0000-0000-0000-000000000009','b1000000-0000-0000-0000-000000000007','Grandfather','Lolo',     'My grandfather loves gardening.',      'Ganahan mananom ang akong lolo.',                      'GRADE_4',4, NULL),
  ('c2000000-0000-0000-0000-000000000010','b1000000-0000-0000-0000-000000000007','Nephew',     'Pag-umangkon nga lalaki', 'My nephew is very energetic.', 'Enerhiko kaayo ang akong pag-umangkon nga lalaki.', 'GRADE_4',5, 'v_sound')
ON CONFLICT (word_id) DO NOTHING;

-- Vocabulary words for Lesson 8 (More Animals)
INSERT INTO vocabulary_words
  (word_id, lesson_id, english_word, cebuano_meaning, example_sentence_english, example_sentence_cebuano, grade_level, word_order, phonological_tip_key)
VALUES
  ('c3000000-0000-0000-0000-000000000006','b1000000-0000-0000-0000-000000000008','Lion',    'Liyon',    'The lion is the king of the jungle.',  'Ang liyon ang hari sa lasang.',                        'GRADE_4',1, NULL),
  ('c3000000-0000-0000-0000-000000000007','b1000000-0000-0000-0000-000000000008','Monkey',  'Unggoy',   'The monkey climbs the tree.',          'Nakatkat sa kahoy ang unggoy.',                        'GRADE_4',2, NULL),
  ('c3000000-0000-0000-0000-000000000008','b1000000-0000-0000-0000-000000000008','Rabbit',  'Koneho',   'The rabbit eats a carrot.',            'Ang koneho mokaon og karot.',                          'GRADE_4',3, NULL),
  ('c3000000-0000-0000-0000-000000000009','b1000000-0000-0000-0000-000000000008','Elephant','Elepante', 'The elephant has a long trunk.',       'Ang elepante adunay taas nga tusk/ilong.',             'GRADE_4',4, 'f_sound'),
  ('c3000000-0000-0000-0000-000000000010','b1000000-0000-0000-0000-000000000008','Duck',    'Bato',     'The duck quacks in the pond.',         'Nag-quack ang pato sa lim-aw.',                        'GRADE_4',5, NULL)
ON CONFLICT (word_id) DO NOTHING;

-- Vocabulary words for Lesson 9 (More Food and Drinks)
INSERT INTO vocabulary_words
  (word_id, lesson_id, english_word, cebuano_meaning, example_sentence_english, example_sentence_cebuano, grade_level, word_order, phonological_tip_key)
VALUES
  ('c4000000-0000-0000-0000-000000000006','b1000000-0000-0000-0000-000000000009','Juice',  'Luga/Duga','I like orange juice.',                 'Ganahan ko og duga sa orens.',                         'GRADE_4',1, NULL),
  ('c4000000-0000-0000-0000-000000000007','b1000000-0000-0000-0000-000000000009','Banana', 'Saging',    'A banana is yellow and sweet.',        'Ang saging dalag ug tam-is.',                          'GRADE_4',2, NULL),
  ('c4000000-0000-0000-0000-000000000008','b1000000-0000-0000-0000-000000000009','Egg',    'Itlog',     'I eat a boiled egg for breakfast.',    'Mokaon ko og nilabog nga itlog sa pamahaw.',           'GRADE_4',3, NULL),
  ('c4000000-0000-0000-0000-000000000009','b1000000-0000-0000-0000-000000000009','Soup',   'Sabaw',     'The warm soup tastes good on a rainy day.','Lami ang init nga sabaw sa ting-ulan.',            'GRADE_4',4, NULL),
  ('c4000000-0000-0000-0000-000000000010','b1000000-0000-0000-0000-000000000009','Cheese',  'Keso',      'Put cheese on my sandwich, please.',   'Butangi og keso ang akong sandwich, palihog.',         'GRADE_4',5, 'short_i')
ON CONFLICT (word_id) DO NOTHING;

-- Vocabulary words for Lesson 10 (More Places)
INSERT INTO vocabulary_words
  (word_id, lesson_id, english_word, cebuano_meaning, example_sentence_english, example_sentence_cebuano, grade_level, word_order, phonological_tip_key)
VALUES
  ('c5000000-0000-0000-0000-000000000006','b1000000-0000-0000-0000-000000000010','Library', 'Laibrairi/Talaan sa mga basahon', 'We read quietly in the library.', 'Hilom kami nga nagbasa sa library.', 'GRADE_4',1, NULL),
  ('c5000000-0000-0000-0000-000000000007','b1000000-0000-0000-0000-000000000010','Store',   'Tindahan',  'I buy candies at the store.',          'Mopalit ko og kendi sa tindahan.',                     'GRADE_4',2, NULL),
  ('c5000000-0000-0000-0000-000000000008','b1000000-0000-0000-0000-000000000010','Station', 'Estasyon',  'The bus is waiting at the station.',   'Nagpaabot ang bus sa estasyon.',                       'GRADE_4',3, 'sh_sound'),
  ('c5000000-0000-0000-0000-000000000009','b1000000-0000-0000-0000-000000000010','Bakery',  'Panaderya', 'The bakery sells warm bread.',         'Namaligya ang panaderya og init nga pan.',             'GRADE_4',4, NULL),
  ('c5000000-0000-0000-0000-000000000010','b1000000-0000-0000-0000-000000000010','Bridge',  'Tulay',     'We cross the river using the bridge.', 'Nakatabok kami sa suba gamit ang tulay.',               'GRADE_4',5, NULL)
ON CONFLICT (word_id) DO NOTHING;
