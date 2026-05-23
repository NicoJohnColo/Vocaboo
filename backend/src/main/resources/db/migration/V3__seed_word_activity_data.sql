
CREATE TABLE IF NOT EXISTS word_activity_data (
  word_id                       UUID PRIMARY KEY REFERENCES vocabulary_words(word_id) ON DELETE CASCADE,

  -- Module 2: Multiple Choice
  mc_distractor_1               TEXT NOT NULL,
  mc_distractor_2               TEXT NOT NULL,
  mc_distractor_3               TEXT NOT NULL,

  -- Module 2: Fill-in-the-Blank
  fitb_sentence                 TEXT NOT NULL,
  fitb_answer                   TEXT NOT NULL,

  -- Module 2: Matching set (JSON array of {english_word, cebuano_meaning} objects including this word)
  matching_set                  JSONB NOT NULL,

  -- Module 3: Sentence Arrangement
  sentence_arrangement_tokens   JSONB NOT NULL,

  -- Module 3: Sentence Completion
  sentence_completion_sentence  TEXT NOT NULL,
  sentence_completion_answer    TEXT NOT NULL,
  sentence_completion_option_1  TEXT NOT NULL,
  sentence_completion_option_2  TEXT NOT NULL,
  sentence_completion_option_3  TEXT NOT NULL,

  created_at                    TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- LESSON 1 — SCHOOL OBJECTS (Words: Pencil, Notebook, Eraser, Bag, Ruler)
-- ============================================================

INSERT INTO word_activity_data (
  word_id,
  mc_distractor_1, mc_distractor_2, mc_distractor_3,
  fitb_sentence, fitb_answer,
  matching_set,
  sentence_arrangement_tokens,
  sentence_completion_sentence, sentence_completion_answer,
  sentence_completion_option_1, sentence_completion_option_2, sentence_completion_option_3
) VALUES

-- Pencil
('c1000000-0000-0000-0000-000000000001',
 'Eraser', 'Ruler', 'Notebook',
 'She sharpened her ___ before the exam.', 'Pencil',
 '[{"english_word":"Pencil","cebuano_meaning":"Lapis"},{"english_word":"Notebook","cebuano_meaning":"Kuwaderno"},{"english_word":"Eraser","cebuano_meaning":"Pamhid"},{"english_word":"Bag","cebuano_meaning":"Bag"}]',
 '[["I","use","a","pencil","to","write","my","answers."]]',
 'The student borrowed a ___ to draw the diagram.', 'Pencil',
 'Ruler', 'Crayon', 'Chalk'),

-- Notebook
('c1000000-0000-0000-0000-000000000002',
 'Bag', 'Pencil', 'Ruler',
 'She wrote her lessons in her ___.', 'Notebook',
 '[{"english_word":"Notebook","cebuano_meaning":"Kuwaderno"},{"english_word":"Pencil","cebuano_meaning":"Lapis"},{"english_word":"Eraser","cebuano_meaning":"Pamhid"},{"english_word":"Ruler","cebuano_meaning":"Ruler"}]',
 '[["My","notebook","is","inside","my","bag."]]',
 'He forgot to bring his ___ so he had no paper to write on.', 'Notebook',
 'Bag', 'Pencil', 'Eraser'),

-- Eraser
('c1000000-0000-0000-0000-000000000003',
 'Pencil', 'Chalk', 'Crayon',
 'She used an ___ to fix her mistake on the paper.', 'Eraser',
 '[{"english_word":"Eraser","cebuano_meaning":"Pamhid"},{"english_word":"Pencil","cebuano_meaning":"Lapis"},{"english_word":"Ruler","cebuano_meaning":"Ruler"},{"english_word":"Bag","cebuano_meaning":"Bag"}]',
 '[["The","eraser","removed","the","mistake."]]',
 'He rubbed the ___ on the paper to remove the wrong answer.', 'Eraser',
 'Pencil', 'Ruler', 'Notebook'),

-- Bag
('c1000000-0000-0000-0000-000000000004',
 'Notebook', 'Ruler', 'Eraser',
 'She put all her books inside her ___.', 'Bag',
 '[{"english_word":"Bag","cebuano_meaning":"Bag"},{"english_word":"Notebook","cebuano_meaning":"Kuwaderno"},{"english_word":"Pencil","cebuano_meaning":"Lapis"},{"english_word":"Eraser","cebuano_meaning":"Pamhid"}]',
 '[["Her","bag","is","color","blue."]]',
 'He carried his ___ on his back when he walked to school.', 'Bag',
 'Notebook', 'Eraser', 'Ruler'),

-- Ruler
('c1000000-0000-0000-0000-000000000005',
 'Pencil', 'Eraser', 'Bag',
 'She used a ___ to draw a straight line.', 'Ruler',
 '[{"english_word":"Ruler","cebuano_meaning":"Ruler"},{"english_word":"Pencil","cebuano_meaning":"Lapis"},{"english_word":"Eraser","cebuano_meaning":"Pamhid"},{"english_word":"Notebook","cebuano_meaning":"Kuwaderno"}]',
 '[["The","ruler","is","used","to","measure","lines."]]',
 'The teacher asked him to use a ___ to measure the rectangle.', 'Ruler',
 'Pencil', 'Eraser', 'Chalk')
ON CONFLICT (word_id) DO NOTHING;

-- ============================================================
-- LESSON 2 — FAMILY MEMBERS (Words: Mother, Father, Sister, Brother, Grandmother)
-- ============================================================

INSERT INTO word_activity_data (
  word_id,
  mc_distractor_1, mc_distractor_2, mc_distractor_3,
  fitb_sentence, fitb_answer,
  matching_set,
  sentence_arrangement_tokens,
  sentence_completion_sentence, sentence_completion_answer,
  sentence_completion_option_1, sentence_completion_option_2, sentence_completion_option_3
) VALUES

-- Mother
('c2000000-0000-0000-0000-000000000001',
 'Father', 'Sister', 'Grandmother',
 'My ___ wakes up early to prepare breakfast.', 'Mother',
 '[{"english_word":"Mother","cebuano_meaning":"Inahan"},{"english_word":"Father","cebuano_meaning":"Amahan"},{"english_word":"Sister","cebuano_meaning":"Igsoon nga babaye"},{"english_word":"Brother","cebuano_meaning":"Igsoon nga lalaki"}]',
 '[["My","mother","cooks","delicious","food."]]',
 'Her ___ sings a lullaby every night before she sleeps.', 'Mother',
 'Father', 'Sister', 'Grandmother'),

-- Father
('c2000000-0000-0000-0000-000000000002',
 'Mother', 'Brother', 'Uncle',
 'My ___ fixes things around the house.', 'Father',
 '[{"english_word":"Father","cebuano_meaning":"Amahan"},{"english_word":"Mother","cebuano_meaning":"Inahan"},{"english_word":"Brother","cebuano_meaning":"Igsoon nga lalaki"},{"english_word":"Grandmother","cebuano_meaning":"Lola"}]',
 '[["My","father","goes","to","work","every","day."]]',
 'Her ___ drives her to school every morning.', 'Father',
 'Mother', 'Uncle', 'Brother'),

-- Sister
('c2000000-0000-0000-0000-000000000003',
 'Brother', 'Mother', 'Cousin',
 'My ___ and I share the same bedroom.', 'Sister',
 '[{"english_word":"Sister","cebuano_meaning":"Igsoon nga babaye"},{"english_word":"Brother","cebuano_meaning":"Igsoon nga lalaki"},{"english_word":"Mother","cebuano_meaning":"Inahan"},{"english_word":"Grandmother","cebuano_meaning":"Lola"}]',
 '[["My","sister","helps","me","study."]]',
 'His ___ reads him a story before bedtime.', 'Sister',
 'Brother', 'Mother', 'Cousin'),

-- Brother
('c2000000-0000-0000-0000-000000000004',
 'Sister', 'Father', 'Cousin',
 'My ___ and I walk to school together.', 'Brother',
 '[{"english_word":"Brother","cebuano_meaning":"Igsoon nga lalaki"},{"english_word":"Sister","cebuano_meaning":"Igsoon nga babaye"},{"english_word":"Father","cebuano_meaning":"Amahan"},{"english_word":"Uncle","cebuano_meaning":"Tiyo"}]',
 '[["My","brother","plays","basketball."]]',
 'Her ___ helped her carry the heavy bags from the market.', 'Brother',
 'Sister', 'Father', 'Uncle'),

-- Grandmother
('c2000000-0000-0000-0000-000000000005',
 'Mother', 'Aunt', 'Sister',
 'My ___ knits blankets for the whole family.', 'Grandmother',
 '[{"english_word":"Grandmother","cebuano_meaning":"Lola"},{"english_word":"Mother","cebuano_meaning":"Inahan"},{"english_word":"Aunt","cebuano_meaning":"Tiya"},{"english_word":"Sister","cebuano_meaning":"Igsoon nga babaye"}]',
 '[["My","grandmother","tells","stories."]]',
 'His ___ taught him how to make bibingka during Christmas.', 'Grandmother',
 'Mother', 'Aunt', 'Sister')
ON CONFLICT (word_id) DO NOTHING;

-- ============================================================
-- LESSON 3 — ANIMALS (Words: Dog, Cat, Bird, Fish, Horse)
-- ============================================================

INSERT INTO word_activity_data (
  word_id,
  mc_distractor_1, mc_distractor_2, mc_distractor_3,
  fitb_sentence, fitb_answer,
  matching_set,
  sentence_arrangement_tokens,
  sentence_completion_sentence, sentence_completion_answer,
  sentence_completion_option_1, sentence_completion_option_2, sentence_completion_option_3
) VALUES

-- Dog
('c3000000-0000-0000-0000-000000000001',
 'Cat', 'Bird', 'Horse',
 'The ___ wagged its tail when it saw its owner.', 'Dog',
 '[{"english_word":"Dog","cebuano_meaning":"Iro"},{"english_word":"Cat","cebuano_meaning":"Iring"},{"english_word":"Bird","cebuano_meaning":"Langgam"},{"english_word":"Fish","cebuano_meaning":"Isda"}]',
 '[["The","dog","barks","loudly."]]',
 'The ___ ran to the gate when the family came home.', 'Dog',
 'Cat', 'Horse', 'Bird'),

-- Cat
('c3000000-0000-0000-0000-000000000002',
 'Dog', 'Fish', 'Rabbit',
 'The ___ curled up near the window in the afternoon.', 'Cat',
 '[{"english_word":"Cat","cebuano_meaning":"Iring"},{"english_word":"Dog","cebuano_meaning":"Iro"},{"english_word":"Fish","cebuano_meaning":"Isda"},{"english_word":"Bird","cebuano_meaning":"Langgam"}]',
 '[["The","cat","sleeps","on","the","chair."]]',
 'The ___ meowed loudly when it was hungry.', 'Cat',
 'Dog', 'Bird', 'Horse'),

-- Bird
('c3000000-0000-0000-0000-000000000003',
 'Fish', 'Dog', 'Horse',
 'A colorful ___ landed on the branch of the mango tree.', 'Bird',
 '[{"english_word":"Bird","cebuano_meaning":"Langgam"},{"english_word":"Fish","cebuano_meaning":"Isda"},{"english_word":"Horse","cebuano_meaning":"Kabayo"},{"english_word":"Dog","cebuano_meaning":"Iro"}]',
 '[["The","bird","flies","in","the","sky."]]',
 'The ___ sang a sweet song early in the morning.', 'Bird',
 'Fish', 'Dog', 'Cat'),

-- Fish
('c3000000-0000-0000-0000-000000000004',
 'Bird', 'Horse', 'Dog',
 'The ___ hid behind the coral when it was scared.', 'Fish',
 '[{"english_word":"Fish","cebuano_meaning":"Isda"},{"english_word":"Bird","cebuano_meaning":"Langgam"},{"english_word":"Horse","cebuano_meaning":"Kabayo"},{"english_word":"Cat","cebuano_meaning":"Iring"}]',
 '[["The","fish","swims","in","the","water."]]',
 'The ___ jumped out of the water and splashed back in.', 'Fish',
 'Bird', 'Dog', 'Horse'),

-- Horse
('c3000000-0000-0000-0000-000000000005',
 'Dog', 'Bird', 'Fish',
 'The farmer rides his ___ to the field every morning.', 'Horse',
 '[{"english_word":"Horse","cebuano_meaning":"Kabayo"},{"english_word":"Dog","cebuano_meaning":"Iro"},{"english_word":"Bird","cebuano_meaning":"Langgam"},{"english_word":"Fish","cebuano_meaning":"Isda"}]',
 '[["The","horse","runs","fast."]]',
 'The ___ galloped across the open field near the river.', 'Horse',
 'Dog', 'Cat', 'Bird')
ON CONFLICT (word_id) DO NOTHING;

-- ============================================================
-- LESSON 4 — FOOD AND DRINKS (Words: Rice, Water, Bread, Milk, Apple)
-- ============================================================

INSERT INTO word_activity_data (
  word_id,
  mc_distractor_1, mc_distractor_2, mc_distractor_3,
  fitb_sentence, fitb_answer,
  matching_set,
  sentence_arrangement_tokens,
  sentence_completion_sentence, sentence_completion_answer,
  sentence_completion_option_1, sentence_completion_option_2, sentence_completion_option_3
) VALUES

-- Rice
('c4000000-0000-0000-0000-000000000001',
 'Bread', 'Apple', 'Milk',
 'She cooked a big pot of ___ for the whole family.', 'Rice',
 '[{"english_word":"Rice","cebuano_meaning":"Kan-on"},{"english_word":"Bread","cebuano_meaning":"Pan"},{"english_word":"Milk","cebuano_meaning":"Gatas"},{"english_word":"Apple","cebuano_meaning":"Mansanas"}]',
 '[["Rice","is","our","staple","food."]]',
 'They eat ___ with grilled fish for lunch every day.', 'Rice',
 'Bread', 'Milk', 'Soup'),

-- Water
('c4000000-0000-0000-0000-000000000002',
 'Juice', 'Milk', 'Soup',
 'She drank a glass of cold ___ after playing outside.', 'Water',
 '[{"english_word":"Water","cebuano_meaning":"Tubig"},{"english_word":"Juice","cebuano_meaning":"Luga/Duga"},{"english_word":"Milk","cebuano_meaning":"Gatas"},{"english_word":"Soup","cebuano_meaning":"Sabaw"}]',
 '[["Drink","water","every","day."]]',
 'The plants in the garden need ___ to grow healthy.', 'Water',
 'Juice', 'Milk', 'Soup'),

-- Bread
('c4000000-0000-0000-0000-000000000003',
 'Rice', 'Apple', 'Egg',
 'She bought a loaf of ___ from the bakery near school.', 'Bread',
 '[{"english_word":"Bread","cebuano_meaning":"Pan"},{"english_word":"Rice","cebuano_meaning":"Kan-on"},{"english_word":"Apple","cebuano_meaning":"Mansanas"},{"english_word":"Milk","cebuano_meaning":"Gatas"}]',
 '[["I","eat","bread","for","breakfast."]]',
 'He spread butter on a slice of ___ for his morning snack.', 'Bread',
 'Rice', 'Cheese', 'Apple'),

-- Milk
('c4000000-0000-0000-0000-000000000004',
 'Water', 'Juice', 'Soup',
 'She drinks a glass of cold ___ with her lunch.', 'Milk',
 '[{"english_word":"Milk","cebuano_meaning":"Gatas"},{"english_word":"Water","cebuano_meaning":"Tubig"},{"english_word":"Juice","cebuano_meaning":"Luga/Duga"},{"english_word":"Bread","cebuano_meaning":"Pan"}]',
 '[["Milk","helps","make","bones","strong."]]',
 'The baby only drinks ___ and cannot eat solid food yet.', 'Milk',
 'Water', 'Juice', 'Soup'),

-- Apple
('c4000000-0000-0000-0000-000000000005',
 'Bread', 'Milk', 'Banana',
 'She packed an ___ in her bag as a healthy snack.', 'Apple',
 '[{"english_word":"Apple","cebuano_meaning":"Mansanas"},{"english_word":"Banana","cebuano_meaning":"Saging"},{"english_word":"Bread","cebuano_meaning":"Pan"},{"english_word":"Milk","cebuano_meaning":"Gatas"}]',
 '[["The","apple","is","sweet","and","red."]]',
 'He bit into a crunchy ___ after school as an afternoon snack.', 'Apple',
 'Banana', 'Bread', 'Milk')
ON CONFLICT (word_id) DO NOTHING;

-- ============================================================
-- LESSON 5 — PLACES IN THE COMMUNITY (Words: School, Hospital, Market, Church, Park)
-- ============================================================

INSERT INTO word_activity_data (
  word_id,
  mc_distractor_1, mc_distractor_2, mc_distractor_3,
  fitb_sentence, fitb_answer,
  matching_set,
  sentence_arrangement_tokens,
  sentence_completion_sentence, sentence_completion_answer,
  sentence_completion_option_1, sentence_completion_option_2, sentence_completion_option_3
) VALUES

-- School
('c5000000-0000-0000-0000-000000000001',
 'Hospital', 'Market', 'Library',
 'Children learn how to read and write at ___.', 'School',
 '[{"english_word":"School","cebuano_meaning":"Eskwelahan"},{"english_word":"Hospital","cebuano_meaning":"Ospital"},{"english_word":"Market","cebuano_meaning":"Merkado"},{"english_word":"Church","cebuano_meaning":"Simbahan"}]',
 '[["The","students","go","to","school","daily."]]',
 'She loves going to ___ because she enjoys learning new things.', 'School',
 'Market', 'Hospital', 'Park'),

-- Hospital
('c5000000-0000-0000-0000-000000000002',
 'School', 'Market', 'Church',
 'The sick child was brought to the ___ by her mother.', 'Hospital',
 '[{"english_word":"Hospital","cebuano_meaning":"Ospital"},{"english_word":"School","cebuano_meaning":"Eskwelahan"},{"english_word":"Market","cebuano_meaning":"Merkado"},{"english_word":"Park","cebuano_meaning":"Liwasan"}]',
 '[["The","doctor","works","in","the","hospital."]]',
 'The ambulance rushed the injured man to the nearest ___.', 'Hospital',
 'School', 'Market', 'Church'),

-- Market
('c5000000-0000-0000-0000-000000000003',
 'School', 'Park', 'Bakery',
 'My mother buys fresh fish and vegetables at the ___.', 'Market',
 '[{"english_word":"Market","cebuano_meaning":"Merkado"},{"english_word":"School","cebuano_meaning":"Eskwelahan"},{"english_word":"Park","cebuano_meaning":"Liwasan"},{"english_word":"Hospital","cebuano_meaning":"Ospital"}]',
 '[["Mother","buys","vegetables","in","the","market."]]',
 'Vendors sell fruits, vegetables, and meat at the ___ every morning.', 'Market',
 'Park', 'Store', 'School'),

-- Church
('c5000000-0000-0000-0000-000000000004',
 'School', 'Market', 'Park',
 'Our family goes to ___ every Sunday morning.', 'Church',
 '[{"english_word":"Church","cebuano_meaning":"Simbahan"},{"english_word":"School","cebuano_meaning":"Eskwelahan"},{"english_word":"Market","cebuano_meaning":"Merkado"},{"english_word":"Park","cebuano_meaning":"Liwasan"}]',
 '[["We","pray","in","the","church."]]',
 'The bells of the ___ rang early on Sunday morning.', 'Church',
 'School', 'Market', 'Park'),

-- Park
('c5000000-0000-0000-0000-000000000005',
 'Market', 'School', 'Church',
 'Families enjoy picnics and walks in the ___ on weekends.', 'Park',
 '[{"english_word":"Park","cebuano_meaning":"Liwasan"},{"english_word":"Market","cebuano_meaning":"Merkado"},{"english_word":"School","cebuano_meaning":"Eskwelahan"},{"english_word":"Church","cebuano_meaning":"Simbahan"}]',
 '[["Children","play","in","the","park."]]',
 'They flew their kites at the ___ on a windy Saturday afternoon.', 'Park',
 'Market', 'Church', 'School')
ON CONFLICT (word_id) DO NOTHING;

-- ============================================================
-- LESSON 6 — MORE SCHOOL OBJECTS (Words: Desk, Chalk, Crayon, Scissors, Glue)
-- ============================================================

INSERT INTO word_activity_data (
  word_id,
  mc_distractor_1, mc_distractor_2, mc_distractor_3,
  fitb_sentence, fitb_answer,
  matching_set,
  sentence_arrangement_tokens,
  sentence_completion_sentence, sentence_completion_answer,
  sentence_completion_option_1, sentence_completion_option_2, sentence_completion_option_3
) VALUES

-- Desk
('c1000000-0000-0000-0000-000000000006',
 'Chair', 'Chalk', 'Crayon',
 'She keeps her books neatly on top of her ___.', 'Desk',
 '[{"english_word":"Desk","cebuano_meaning":"Lamesa"},{"english_word":"Chalk","cebuano_meaning":"Tsok"},{"english_word":"Crayon","cebuano_meaning":"Krayola"},{"english_word":"Glue","cebuano_meaning":"Papilit"}]',
 '[["I","sit","at","my","desk","to","read."]]',
 'The teacher placed the test papers on each student''s ___.', 'Desk',
 'Chair', 'Chalk', 'Scissors'),

-- Chalk
('c1000000-0000-0000-0000-000000000007',
 'Crayon', 'Pencil', 'Marker',
 'The teacher used ___ to write the math problem on the board.', 'Chalk',
 '[{"english_word":"Chalk","cebuano_meaning":"Tsok"},{"english_word":"Crayon","cebuano_meaning":"Krayola"},{"english_word":"Desk","cebuano_meaning":"Lamesa"},{"english_word":"Glue","cebuano_meaning":"Papilit"}]',
 '[["The","teacher","writes","with","chalk."]]',
 'She drew a hopscotch grid on the ground using a piece of ___.', 'Chalk',
 'Crayon', 'Pencil', 'Glue'),

-- Crayon
('c1000000-0000-0000-0000-000000000008',
 'Chalk', 'Pencil', 'Marker',
 'She colored the drawing of a rainbow using her set of ___.', 'Crayon',
 '[{"english_word":"Crayon","cebuano_meaning":"Krayola"},{"english_word":"Chalk","cebuano_meaning":"Tsok"},{"english_word":"Pencil","cebuano_meaning":"Lapis"},{"english_word":"Scissors","cebuano_meaning":"Gunting"}]',
 '[["Draw","a","picture","with","a","green","crayon."]]',
 'He used a red ___ to color the apple in his drawing.', 'Crayon',
 'Chalk', 'Pencil', 'Glue'),

-- Scissors
('c1000000-0000-0000-0000-000000000009',
 'Glue', 'Ruler', 'Crayon',
 'The teacher asked the students to use ___ to cut the paper.', 'Scissors',
 '[{"english_word":"Scissors","cebuano_meaning":"Gunting"},{"english_word":"Glue","cebuano_meaning":"Papilit"},{"english_word":"Ruler","cebuano_meaning":"Ruler"},{"english_word":"Crayon","cebuano_meaning":"Krayola"}]',
 '[["Be","careful","when","using","scissors."]]',
 'She used ___ to cut out the shapes for her art project.', 'Scissors',
 'Glue', 'Ruler', 'Chalk'),

-- Glue
('c1000000-0000-0000-0000-000000000010',
 'Tape', 'Scissors', 'Crayon',
 'She put ___ on the back of the picture before sticking it.', 'Glue',
 '[{"english_word":"Glue","cebuano_meaning":"Papilit"},{"english_word":"Scissors","cebuano_meaning":"Gunting"},{"english_word":"Chalk","cebuano_meaning":"Tsok"},{"english_word":"Crayon","cebuano_meaning":"Krayola"}]',
 '[["Use","glue","to","paste","the","paper."]]',
 'The student used ___ to attach the cut-out letters onto the poster.', 'Glue',
 'Tape', 'Scissors', 'Crayon')
ON CONFLICT (word_id) DO NOTHING;

-- (file continues with remaining lesson inserts)
