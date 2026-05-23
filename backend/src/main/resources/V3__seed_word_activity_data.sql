-- Vocaboo Seed Content V3 - Activity Data for Modules 2 and 3

CREATE TABLE IF NOT EXISTS word_activity_data (
  word_id UUID PRIMARY KEY REFERENCES vocabulary_words(word_id) ON DELETE CASCADE,
  mc_distractor_1 TEXT NOT NULL,
  mc_distractor_2 TEXT NOT NULL,
  mc_distractor_3 TEXT NOT NULL,
  fitb_sentence TEXT NOT NULL,
  fitb_answer TEXT NOT NULL,
  matching_set JSONB NOT NULL,
  sentence_arrangement_tokens JSONB NOT NULL,
  sentence_completion_sentence TEXT NOT NULL,
  sentence_completion_answer TEXT NOT NULL,
  sentence_completion_option_1 TEXT NOT NULL,
  sentence_completion_option_2 TEXT NOT NULL,
  sentence_completion_option_3 TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE word_activity_data ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS word_activity_select_policy ON word_activity_data;
CREATE POLICY word_activity_select_policy ON word_activity_data
  FOR SELECT TO authenticated USING (true);

-- ============================================================
-- LESSON 1 — SCHOOL OBJECTS
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
('c1000000-0000-0000-0000-000000000001','Eraser','Ruler','Notebook','She sharpened her ___ before the exam.','Pencil','[{"english_word":"Pencil","cebuano_meaning":"Lapis"},{"english_word":"Notebook","cebuano_meaning":"Kuwaderno"},{"english_word":"Eraser","cebuano_meaning":"Pamhid"},{"english_word":"Bag","cebuano_meaning":"Bag"}]','["I","use","a","pencil","to","write","my","answers."]','The student borrowed a ___ to draw the diagram.','Pencil','Ruler','Crayon','Chalk'),
('c1000000-0000-0000-0000-000000000002','Bag','Pencil','Ruler','She wrote her lessons in her ___.','Notebook','[{"english_word":"Notebook","cebuano_meaning":"Kuwaderno"},{"english_word":"Pencil","cebuano_meaning":"Lapis"},{"english_word":"Eraser","cebuano_meaning":"Pamhid"},{"english_word":"Ruler","cebuano_meaning":"Ruler"}]','["My","notebook","is","inside","my","bag."]','He forgot to bring his ___ so he had no paper to write on.','Notebook','Bag','Pencil','Eraser'),
('c1000000-0000-0000-0000-000000000003','Pencil','Chalk','Crayon','She used an ___ to fix her mistake on the paper.','Eraser','[{"english_word":"Eraser","cebuano_meaning":"Pamhid"},{"english_word":"Pencil","cebuano_meaning":"Lapis"},{"english_word":"Ruler","cebuano_meaning":"Ruler"},{"english_word":"Bag","cebuano_meaning":"Bag"}]','["The","eraser","removed","the","mistake."]','He rubbed the ___ on the paper to remove the wrong answer.','Eraser','Pencil','Ruler','Notebook'),
('c1000000-0000-0000-0000-000000000004','Notebook','Ruler','Eraser','She put all her books inside her ___.','Bag','[{"english_word":"Bag","cebuano_meaning":"Bag"},{"english_word":"Notebook","cebuano_meaning":"Kuwaderno"},{"english_word":"Pencil","cebuano_meaning":"Lapis"},{"english_word":"Eraser","cebuano_meaning":"Pamhid"}]','["Her","bag","is","color","blue."]','He carried his ___ on his back when he walked to school.','Bag','Notebook','Eraser','Ruler'),
('c1000000-0000-0000-0000-000000000005','Pencil','Eraser','Bag','She used a ___ to draw a straight line.','Ruler','[{"english_word":"Ruler","cebuano_meaning":"Ruler"},{"english_word":"Pencil","cebuano_meaning":"Lapis"},{"english_word":"Eraser","cebuano_meaning":"Pamhid"},{"english_word":"Notebook","cebuano_meaning":"Kuwaderno"}]','["The","ruler","is","used","to","measure","lines."]','The teacher asked him to use a ___ to measure the rectangle.','Ruler','Pencil','Eraser','Chalk')
ON CONFLICT (word_id) DO NOTHING;

-- ============================================================
-- LESSON 2 — FAMILY MEMBERS
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
('c2000000-0000-0000-0000-000000000001','Father','Sister','Grandmother','My ___ wakes up early to prepare breakfast.','Mother','[{"english_word":"Mother","cebuano_meaning":"Inahan"},{"english_word":"Father","cebuano_meaning":"Amahan"},{"english_word":"Sister","cebuano_meaning":"Igsoon nga babaye"},{"english_word":"Brother","cebuano_meaning":"Igsoon nga lalaki"}]','["My","mother","cooks","delicious","food."]','Her ___ sings a lullaby every night before she sleeps.','Mother','Father','Sister','Grandmother'),
('c2000000-0000-0000-0000-000000000002','Mother','Brother','Uncle','My ___ fixes things around the house.','Father','[{"english_word":"Father","cebuano_meaning":"Amahan"},{"english_word":"Mother","cebuano_meaning":"Inahan"},{"english_word":"Brother","cebuano_meaning":"Igsoon nga lalaki"},{"english_word":"Grandmother","cebuano_meaning":"Lola"}]','["My","father","goes","to","work","every","day."]','Her ___ drives her to school every morning.','Father','Mother','Uncle','Brother'),
('c2000000-0000-0000-0000-000000000003','Brother','Mother','Cousin','My ___ and I share the same bedroom.','Sister','[{"english_word":"Sister","cebuano_meaning":"Igsoon nga babaye"},{"english_word":"Brother","cebuano_meaning":"Igsoon nga lalaki"},{"english_word":"Mother","cebuano_meaning":"Inahan"},{"english_word":"Grandmother","cebuano_meaning":"Lola"}]','["My","sister","helps","me","study."]','His ___ reads him a story before bedtime.','Sister','Brother','Mother','Cousin'),
('c2000000-0000-0000-0000-000000000004','Sister','Father','Cousin','My ___ and I walk to school together.','Brother','[{"english_word":"Brother","cebuano_meaning":"Igsoon nga lalaki"},{"english_word":"Sister","cebuano_meaning":"Igsoon nga babaye"},{"english_word":"Father","cebuano_meaning":"Amahan"},{"english_word":"Uncle","cebuano_meaning":"Tiyo"}]','["My","brother","plays","basketball."]','Her ___ helped her carry the heavy bags from the market.','Brother','Sister','Father','Uncle'),
('c2000000-0000-0000-0000-000000000005','Mother','Aunt','Sister','My ___ knits blankets for the whole family.','Grandmother','[{"english_word":"Grandmother","cebuano_meaning":"Lola"},{"english_word":"Mother","cebuano_meaning":"Inahan"},{"english_word":"Aunt","cebuano_meaning":"Tiya"},{"english_word":"Sister","cebuano_meaning":"Igsoon nga babaye"}]','["My","grandmother","tells","stories."]','His ___ taught him how to make bibingka during Christmas.','Grandmother','Mother','Aunt','Sister')
ON CONFLICT (word_id) DO NOTHING;

-- ============================================================
-- LESSON 3 — ANIMALS
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
('c3000000-0000-0000-0000-000000000001','Cat','Bird','Horse','The ___ wagged its tail when it saw its owner.','Dog','[{"english_word":"Dog","cebuano_meaning":"Iro"},{"english_word":"Cat","cebuano_meaning":"Iring"},{"english_word":"Bird","cebuano_meaning":"Langgam"},{"english_word":"Fish","cebuano_meaning":"Isda"}]','["The","dog","barks","loudly."]','The ___ ran to the gate when the family came home.','Dog','Cat','Horse','Bird'),
('c3000000-0000-0000-0000-000000000002','Dog','Fish','Rabbit','The ___ curled up near the window in the afternoon.','Cat','[{"english_word":"Cat","cebuano_meaning":"Iring"},{"english_word":"Dog","cebuano_meaning":"Iro"},{"english_word":"Fish","cebuano_meaning":"Isda"},{"english_word":"Bird","cebuano_meaning":"Langgam"}]','["The","cat","sleeps","on","the","chair."]','The ___ meowed loudly when it was hungry.','Cat','Dog','Bird','Horse'),
('c3000000-0000-0000-0000-000000000003','Fish','Dog','Horse','A colorful ___ landed on the branch of the mango tree.','Bird','[{"english_word":"Bird","cebuano_meaning":"Langgam"},{"english_word":"Fish","cebuano_meaning":"Isda"},{"english_word":"Horse","cebuano_meaning":"Kabayo"},{"english_word":"Dog","cebuano_meaning":"Iro"}]','["The","bird","flies","in","the","sky."]','The ___ sang a sweet song early in the morning.','Bird','Fish','Dog','Cat'),
('c3000000-0000-0000-0000-000000000004','Bird','Horse','Dog','The ___ hid behind the coral when it was scared.','Fish','[{"english_word":"Fish","cebuano_meaning":"Isda"},{"english_word":"Bird","cebuano_meaning":"Langgam"},{"english_word":"Horse","cebuano_meaning":"Kabayo"},{"english_word":"Cat","cebuano_meaning":"Iring"}]','["The","fish","swims","in","the","water."]','The ___ jumped out of the water and splashed back in.','Fish','Bird','Dog','Horse'),
('c3000000-0000-0000-0000-000000000005','Dog','Bird','Fish','The farmer rides his ___ to the field every morning.','Horse','[{"english_word":"Horse","cebuano_meaning":"Kabayo"},{"english_word":"Dog","cebuano_meaning":"Iro"},{"english_word":"Bird","cebuano_meaning":"Langgam"},{"english_word":"Fish","cebuano_meaning":"Isda"}]','["The","horse","runs","fast."]','The ___ galloped across the open field near the river.','Horse','Dog','Cat','Bird')
ON CONFLICT (word_id) DO NOTHING;

-- ============================================================
-- LESSON 4 — FOOD AND DRINKS
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
('c4000000-0000-0000-0000-000000000001','Bread','Apple','Milk','She cooked a big pot of ___ for the whole family.','Rice','[{"english_word":"Rice","cebuano_meaning":"Kan-on"},{"english_word":"Bread","cebuano_meaning":"Pan"},{"english_word":"Milk","cebuano_meaning":"Gatas"},{"english_word":"Apple","cebuano_meaning":"Mansanas"}]','["Rice","is","our","staple","food."]','They eat ___ with grilled fish for lunch every day.','Rice','Bread','Milk','Soup'),
('c4000000-0000-0000-0000-000000000002','Juice','Milk','Soup','She drank a glass of cold ___ after playing outside.','Water','[{"english_word":"Water","cebuano_meaning":"Tubig"},{"english_word":"Juice","cebuano_meaning":"Luga/Duga"},{"english_word":"Milk","cebuano_meaning":"Gatas"},{"english_word":"Soup","cebuano_meaning":"Sabaw"}]','["Drink","water","every","day."]','The plants in the garden need ___ to grow healthy.','Water','Juice','Milk','Soup'),
('c4000000-0000-0000-0000-000000000003','Rice','Apple','Egg','She bought a loaf of ___ from the bakery near school.','Bread','[{"english_word":"Bread","cebuano_meaning":"Pan"},{"english_word":"Rice","cebuano_meaning":"Kan-on"},{"english_word":"Apple","cebuano_meaning":"Mansanas"},{"english_word":"Milk","cebuano_meaning":"Gatas"}]','["I","eat","bread","for","breakfast."]','He spread butter on a slice of ___ for his morning snack.','Bread','Rice','Cheese','Apple'),
('c4000000-0000-0000-0000-000000000004','Water','Juice','Soup','She drinks a glass of cold ___ with her lunch.','Milk','[{"english_word":"Milk","cebuano_meaning":"Gatas"},{"english_word":"Water","cebuano_meaning":"Tubig"},{"english_word":"Juice","cebuano_meaning":"Luga/Duga"},{"english_word":"Bread","cebuano_meaning":"Pan"}]','["Milk","helps","make","bones","strong."]','The baby only drinks ___ and cannot eat solid food yet.','Milk','Water','Juice','Soup'),
('c4000000-0000-0000-0000-000000000005','Bread','Milk','Banana','She packed an ___ in her bag as a healthy snack.','Apple','[{"english_word":"Apple","cebuano_meaning":"Mansanas"},{"english_word":"Banana","cebuano_meaning":"Saging"},{"english_word":"Bread","cebuano_meaning":"Pan"},{"english_word":"Milk","cebuano_meaning":"Gatas"}]','["The","apple","is","sweet","and","red."]','He bit into a crunchy ___ after school as an afternoon snack.','Apple','Banana','Bread','Milk')
ON CONFLICT (word_id) DO NOTHING;

-- ============================================================
-- LESSON 5 — PLACES IN THE COMMUNITY
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
('c5000000-0000-0000-0000-000000000001','Hospital','Market','Library','Children learn how to read and write at ___.','School','[{"english_word":"School","cebuano_meaning":"Eskwelahan"},{"english_word":"Hospital","cebuano_meaning":"Ospital"},{"english_word":"Market","cebuano_meaning":"Merkado"},{"english_word":"Church","cebuano_meaning":"Simbahan"}]','["The","students","go","to","school","daily."]','She loves going to ___ because she enjoys learning new things.','School','Market','Hospital','Park'),
('c5000000-0000-0000-0000-000000000002','School','Market','Church','The sick child was brought to the ___ by her mother.','Hospital','[{"english_word":"Hospital","cebuano_meaning":"Ospital"},{"english_word":"School","cebuano_meaning":"Eskwelahan"},{"english_word":"Market","cebuano_meaning":"Merkado"},{"english_word":"Park","cebuano_meaning":"Liwasan"}]','["The","doctor","works","in","the","hospital."]','The ambulance rushed the injured man to the nearest ___.','Hospital','School','Market','Church'),
('c5000000-0000-0000-0000-000000000003','School','Park','Bakery','My mother buys fresh fish and vegetables at the ___.','Market','[{"english_word":"Market","cebuano_meaning":"Merkado"},{"english_word":"School","cebuano_meaning":"Eskwelahan"},{"english_word":"Park","cebuano_meaning":"Liwasan"},{"english_word":"Hospital","cebuano_meaning":"Ospital"}]','["Mother","buys","vegetables","in","the","market."]','Vendors sell fruits, vegetables, and meat at the ___ every morning.','Market','Park','Store','School'),
('c5000000-0000-0000-0000-000000000004','School','Market','Park','Our family goes to ___ every Sunday morning.','Church','[{"english_word":"Church","cebuano_meaning":"Simbahan"},{"english_word":"School","cebuano_meaning":"Eskwelahan"},{"english_word":"Market","cebuano_meaning":"Merkado"},{"english_word":"Park","cebuano_meaning":"Liwasan"}]','["We","pray","in","the","church."]','The bells of the ___ rang early on Sunday morning.','Church','School','Market','Park'),
('c5000000-0000-0000-0000-000000000005','Market','School','Church','Families enjoy picnics and walks in the ___ on weekends.','Park','[{"english_word":"Park","cebuano_meaning":"Liwasan"},{"english_word":"Market","cebuano_meaning":"Merkado"},{"english_word":"School","cebuano_meaning":"Eskwelahan"},{"english_word":"Church","cebuano_meaning":"Simbahan"}]','["Children","play","in","the","park."]','They flew their kites at the ___ on a windy Saturday afternoon.','Park','Market','Church','School')
ON CONFLICT (word_id) DO NOTHING;

-- ============================================================
-- LESSON 6 — MORE SCHOOL OBJECTS
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
('c1000000-0000-0000-0000-000000000006','Chair','Chalk','Crayon','She keeps her books neatly on top of her ___.','Desk','[{"english_word":"Desk","cebuano_meaning":"Lamesa"},{"english_word":"Chalk","cebuano_meaning":"Tsok"},{"english_word":"Crayon","cebuano_meaning":"Krayola"},{"english_word":"Glue","cebuano_meaning":"Papilit"}]','["I","sit","at","my","desk","to","read."]','The teacher placed the test papers on each student''s ___.','Desk','Chair','Chalk','Scissors'),
('c1000000-0000-0000-0000-000000000007','Crayon','Pencil','Marker','The teacher used ___ to write the math problem on the board.','Chalk','[{"english_word":"Chalk","cebuano_meaning":"Tsok"},{"english_word":"Crayon","cebuano_meaning":"Krayola"},{"english_word":"Desk","cebuano_meaning":"Lamesa"},{"english_word":"Glue","cebuano_meaning":"Papilit"}]','["The","teacher","writes","with","chalk."]','She drew a hopscotch grid on the ground using a piece of ___.','Chalk','Crayon','Pencil','Glue'),
('c1000000-0000-0000-0000-000000000008','Chalk','Pencil','Marker','She colored the drawing of a rainbow using her set of ___.','Crayon','[{"english_word":"Crayon","cebuano_meaning":"Krayola"},{"english_word":"Chalk","cebuano_meaning":"Tsok"},{"english_word":"Pencil","cebuano_meaning":"Lapis"},{"english_word":"Scissors","cebuano_meaning":"Gunting"}]','["Draw","a","picture","with","a","green","crayon."]','He used a red ___ to color the apple in his drawing.','Crayon','Chalk','Pencil','Glue'),
('c1000000-0000-0000-0000-000000000009','Glue','Ruler','Crayon','The teacher asked the students to use ___ to cut the paper.','Scissors','[{"english_word":"Scissors","cebuano_meaning":"Gunting"},{"english_word":"Glue","cebuano_meaning":"Papilit"},{"english_word":"Ruler","cebuano_meaning":"Ruler"},{"english_word":"Crayon","cebuano_meaning":"Krayola"}]','["Be","careful","when","using","scissors."]','She used ___ to cut out the shapes for her art project.','Scissors','Glue','Ruler','Chalk'),
('c1000000-0000-0000-0000-000000000010','Tape','Scissors','Crayon','She put ___ on the back of the picture before sticking it.','Glue','[{"english_word":"Glue","cebuano_meaning":"Papilit"},{"english_word":"Scissors","cebuano_meaning":"Gunting"},{"english_word":"Chalk","cebuano_meaning":"Tsok"},{"english_word":"Crayon","cebuano_meaning":"Krayola"}]','["Use","glue","to","paste","the","paper."]','The student used ___ to attach the cut-out letters onto the poster.','Glue','Tape','Scissors','Crayon')
ON CONFLICT (word_id) DO NOTHING;

-- ============================================================
-- LESSON 7 — MORE FAMILY MEMBERS
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
('c2000000-0000-0000-0000-000000000006','Aunt','Cousin','Grandfather','My ___ brought us pasalubong from Cebu City.','Uncle','[{"english_word":"Uncle","cebuano_meaning":"Tiyo"},{"english_word":"Aunt","cebuano_meaning":"Tiya"},{"english_word":"Cousin","cebuano_meaning":"Ig-agaw"},{"english_word":"Grandfather","cebuano_meaning":"Lolo"}]','["My","uncle","plays","guitar."]','Her ___ taught her how to ride a bicycle last summer.','Uncle','Aunt','Cousin','Grandfather'),
('c2000000-0000-0000-0000-000000000007','Uncle','Cousin','Grandmother','My ___ made a delicious leche flan for the fiesta.','Aunt','[{"english_word":"Aunt","cebuano_meaning":"Tiya"},{"english_word":"Uncle","cebuano_meaning":"Tiyo"},{"english_word":"Grandmother","cebuano_meaning":"Lola"},{"english_word":"Cousin","cebuano_meaning":"Ig-agaw"}]','["My","aunt","visits","us","on","Sundays."]','His ___ braided his sister''s hair before the school program.','Aunt','Uncle','Grandmother','Mother'),
('c2000000-0000-0000-0000-000000000008','Brother','Uncle','Nephew','My ___ and I always play tag in the yard during summer.','Cousin','[{"english_word":"Cousin","cebuano_meaning":"Ig-agaw"},{"english_word":"Brother","cebuano_meaning":"Igsoon nga lalaki"},{"english_word":"Uncle","cebuano_meaning":"Tiyo"},{"english_word":"Aunt","cebuano_meaning":"Tiya"}]','["I","play","with","my","cousin","in","the","yard."]','Her ___ from Mandaue visited them during the holiday break.','Cousin','Brother','Uncle','Nephew'),
('c2000000-0000-0000-0000-000000000009','Uncle','Father','Grandmother','My ___ wakes up early to water the plants every morning.','Grandfather','[{"english_word":"Grandfather","cebuano_meaning":"Lolo"},{"english_word":"Uncle","cebuano_meaning":"Tiyo"},{"english_word":"Father","cebuano_meaning":"Amahan"},{"english_word":"Grandmother","cebuano_meaning":"Lola"}]','["My","grandfather","loves","gardening."]','Her ___ told her stories about Cebu during the old times.','Grandfather','Uncle','Father','Grandmother'),
('c2000000-0000-0000-0000-000000000010','Cousin','Brother','Uncle','Her ___ always follows her around whenever she visits.','Nephew','[{"english_word":"Nephew","cebuano_meaning":"Pag-umangkon nga lalaki"},{"english_word":"Cousin","cebuano_meaning":"Ig-agaw"},{"english_word":"Brother","cebuano_meaning":"Igsoon nga lalaki"},{"english_word":"Uncle","cebuano_meaning":"Tiyo"}]','["My","nephew","is","very","energetic."]','She bought a toy car as a birthday gift for her little ___.','Nephew','Cousin','Brother','Uncle')
ON CONFLICT (word_id) DO NOTHING;

-- ============================================================
-- LESSON 8 — MORE ANIMALS
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
('c3000000-0000-0000-0000-000000000006','Elephant','Monkey','Horse','A ___ roared loudly inside its enclosure at the zoo.','Lion','[{"english_word":"Lion","cebuano_meaning":"Liyon"},{"english_word":"Elephant","cebuano_meaning":"Elepante"},{"english_word":"Monkey","cebuano_meaning":"Unggoy"},{"english_word":"Rabbit","cebuano_meaning":"Koneho"}]','["The","lion","is","the","king","of","the","jungle."]','The ___ protected its cubs from the approaching danger.','Lion','Tiger','Elephant','Monkey'),
('c3000000-0000-0000-0000-000000000007','Lion','Rabbit','Duck','The ___ swung from branch to branch in the tall trees.','Monkey','[{"english_word":"Monkey","cebuano_meaning":"Unggoy"},{"english_word":"Lion","cebuano_meaning":"Liyon"},{"english_word":"Rabbit","cebuano_meaning":"Koneho"},{"english_word":"Duck","cebuano_meaning":"Bato"}]','["The","monkey","climbs","the","tree."]','The ___ grabbed a banana from the visitor''s hand at the zoo.','Monkey','Lion','Rabbit','Elephant'),
('c3000000-0000-0000-0000-000000000008','Duck','Monkey','Lion','The white ___ hopped around the garden and nibbled on the grass.','Rabbit','[{"english_word":"Rabbit","cebuano_meaning":"Koneho"},{"english_word":"Duck","cebuano_meaning":"Bato"},{"english_word":"Monkey","cebuano_meaning":"Unggoy"},{"english_word":"Lion","cebuano_meaning":"Liyon"}]','["The","rabbit","eats","a","carrot."]','The ___ hid inside its burrow when it heard a loud noise.','Rabbit','Duck','Monkey','Lion'),
('c3000000-0000-0000-0000-000000000009','Lion','Monkey','Horse','The ___ used its long trunk to pick up water from the river.','Elephant','[{"english_word":"Elephant","cebuano_meaning":"Elepante"},{"english_word":"Lion","cebuano_meaning":"Liyon"},{"english_word":"Monkey","cebuano_meaning":"Unggoy"},{"english_word":"Duck","cebuano_meaning":"Bato"}]','["The","elephant","has","a","long","trunk."]','The ___ sprayed water on its back to cool itself in the heat.','Elephant','Lion','Monkey','Horse'),
('c3000000-0000-0000-0000-000000000010','Rabbit','Bird','Fish','The ___ waddled across the muddy path near the rice field.','Duck','[{"english_word":"Duck","cebuano_meaning":"Bato"},{"english_word":"Rabbit","cebuano_meaning":"Koneho"},{"english_word":"Bird","cebuano_meaning":"Langgam"},{"english_word":"Fish","cebuano_meaning":"Isda"}]','["The","duck","quacks","in","the","pond."]','The ___ paddled gently on the calm surface of the pond.','Duck','Rabbit','Bird','Fish')
ON CONFLICT (word_id) DO NOTHING;

-- ============================================================
-- LESSON 9 — MORE FOOD AND DRINKS
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
('c4000000-0000-0000-0000-000000000006','Water','Milk','Soup','She poured a glass of cold ___ to serve her visitors.','Juice','[{"english_word":"Juice","cebuano_meaning":"Luga/Duga"},{"english_word":"Water","cebuano_meaning":"Tubig"},{"english_word":"Milk","cebuano_meaning":"Gatas"},{"english_word":"Soup","cebuano_meaning":"Sabaw"}]','["I","like","orange","juice."]','Her mother squeezed fresh oranges to make a glass of ___.','Juice','Water','Milk','Soup'),
('c4000000-0000-0000-0000-000000000007','Apple','Mango','Egg','She peeled a ripe ___ and gave half to her little brother.','Banana','[{"english_word":"Banana","cebuano_meaning":"Saging"},{"english_word":"Apple","cebuano_meaning":"Mansanas"},{"english_word":"Egg","cebuano_meaning":"Itlog"},{"english_word":"Cheese","cebuano_meaning":"Keso"}]','["A","banana","is","yellow","and","sweet."]','He ate a ___ before his morning run to have quick energy.','Banana','Apple','Mango','Cheese'),
('c4000000-0000-0000-0000-000000000008','Banana','Bread','Cheese','She cracked an ___ into the pan and cooked it sunny side up.','Egg','[{"english_word":"Egg","cebuano_meaning":"Itlog"},{"english_word":"Banana","cebuano_meaning":"Saging"},{"english_word":"Bread","cebuano_meaning":"Pan"},{"english_word":"Soup","cebuano_meaning":"Sabaw"}]','["I","eat","a","boiled","egg","for","breakfast."]','The chef used three pieces of ___ to make the fluffy omelet.','Egg','Banana','Bread','Cheese'),
('c4000000-0000-0000-0000-000000000009','Juice','Milk','Water','She stirred the hot ___ carefully so it would not spill.','Soup','[{"english_word":"Soup","cebuano_meaning":"Sabaw"},{"english_word":"Juice","cebuano_meaning":"Luga/Duga"},{"english_word":"Milk","cebuano_meaning":"Gatas"},{"english_word":"Egg","cebuano_meaning":"Itlog"}]','["The","warm","soup","tastes","good","on","a","rainy","day."]','She cooked a pot of chicken ___ when her brother had a cold.','Soup','Juice','Milk','Bread'),
('c4000000-0000-0000-0000-000000000010','Butter','Egg','Milk','She melted ___ on top of the hot pan de sal.','Cheese','[{"english_word":"Cheese","cebuano_meaning":"Keso"},{"english_word":"Butter","cebuano_meaning":"Mantika"},{"english_word":"Egg","cebuano_meaning":"Itlog"},{"english_word":"Milk","cebuano_meaning":"Gatas"}]','["Put","cheese","on","my","sandwich,","please."]','The pizza was extra delicious because of the thick layer of ___ on top.','Cheese','Butter','Egg','Milk')
ON CONFLICT (word_id) DO NOTHING;

-- ============================================================
-- LESSON 10 — MORE PLACES
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
('c5000000-0000-0000-0000-000000000006','Store','School','Bakery','She borrowed three storybooks from the school ___.','Library','[{"english_word":"Library","cebuano_meaning":"Laibrairi"},{"english_word":"Store","cebuano_meaning":"Tindahan"},{"english_word":"School","cebuano_meaning":"Eskwelahan"},{"english_word":"Bakery","cebuano_meaning":"Panaderya"}]','["We","read","quietly","in","the","library."]','Students visit the ___ to research topics for their projects.','Library','Store','Bakery','Station'),
('c5000000-0000-0000-0000-000000000007','Market','Bakery','Library','She ran to the nearby ___ to buy a bar of soap.','Store','[{"english_word":"Store","cebuano_meaning":"Tindahan"},{"english_word":"Market","cebuano_meaning":"Merkado"},{"english_word":"Bakery","cebuano_meaning":"Panaderya"},{"english_word":"Bridge","cebuano_meaning":"Tulay"}]','["I","buy","candies","at","the","store."]','He stopped at the corner ___ to buy a cold drink after school.','Store','Market','Bakery','Library'),
('c5000000-0000-0000-0000-000000000008','Bridge','Market','Store','They waited for the jeepney at the ___ near the church.','Station','[{"english_word":"Station","cebuano_meaning":"Estasyon"},{"english_word":"Bridge","cebuano_meaning":"Tulay"},{"english_word":"Market","cebuano_meaning":"Merkado"},{"english_word":"Store","cebuano_meaning":"Tindahan"}]','["The","bus","is","waiting","at","the","station."]','The passengers lined up at the ___ to wait for the next bus.','Station','Bridge','Market','Store'),
('c5000000-0000-0000-0000-000000000009','Store','Library','Market','The smell of fresh pan de sal drew her inside the ___.','Bakery','[{"english_word":"Bakery","cebuano_meaning":"Panaderya"},{"english_word":"Store","cebuano_meaning":"Tindahan"},{"english_word":"Library","cebuano_meaning":"Laibrairi"},{"english_word":"Station","cebuano_meaning":"Estasyon"}]','["The","bakery","sells","warm","bread."]','Her mother sent her to the ___ to buy fresh rolls for breakfast.','Bakery','Store','Library','Market'),
('c5000000-0000-0000-0000-000000000010','Station','Park','Store','The children held hands as they walked across the old wooden ___.','Bridge','[{"english_word":"Bridge","cebuano_meaning":"Tulay"},{"english_word":"Station","cebuano_meaning":"Estasyon"},{"english_word":"Park","cebuano_meaning":"Liwasan"},{"english_word":"Store","cebuano_meaning":"Tindahan"}]','["We","cross","the","river","using","the","bridge."]','The fishermen stood on the ___ to cast their fishing lines into the river.','Bridge','Station','Park','Store')
ON CONFLICT (word_id) DO NOTHING;-- Vocaboo Seed Content V3 - Word Activity Data for Modules 2-4

-- Activity data table (one row per vocabulary word, extends vocabulary_words)
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
 '["I","use","a","pencil","to","write","my","answers."]',
 'The student borrowed a ___ to draw the diagram.', 'Pencil',
 'Ruler', 'Crayon', 'Chalk'),

-- Notebook
('c1000000-0000-0000-0000-000000000002',
 'Bag', 'Pencil', 'Ruler',
 'She wrote her lessons in her ___.', 'Notebook',
 '[{"english_word":"Notebook","cebuano_meaning":"Kuwaderno"},{"english_word":"Pencil","cebuano_meaning":"Lapis"},{"english_word":"Eraser","cebuano_meaning":"Pamhid"},{"english_word":"Ruler","cebuano_meaning":"Ruler"}]',
 '["My","notebook","is","inside","my","bag."]',
 'He forgot to bring his ___ so he had no paper to write on.', 'Notebook',
 'Bag', 'Pencil', 'Eraser'),

-- Eraser
('c1000000-0000-0000-0000-000000000003',
 'Pencil', 'Chalk', 'Crayon',
 'She used an ___ to fix her mistake on the paper.', 'Eraser',
 '[{"english_word":"Eraser","cebuano_meaning":"Pamhid"},{"english_word":"Pencil","cebuano_meaning":"Lapis"},{"english_word":"Ruler","cebuano_meaning":"Ruler"},{"english_word":"Bag","cebuano_meaning":"Bag"}]',
 '["The","eraser","removed","the","mistake."]',
 'He rubbed the ___ on the paper to remove the wrong answer.', 'Eraser',
 'Pencil', 'Ruler', 'Notebook'),

-- Bag
('c1000000-0000-0000-0000-000000000004',
 'Notebook', 'Ruler', 'Eraser',
 'She put all her books inside her ___.', 'Bag',
 '[{"english_word":"Bag","cebuano_meaning":"Bag"},{"english_word":"Notebook","cebuano_meaning":"Kuwaderno"},{"english_word":"Pencil","cebuano_meaning":"Lapis"},{"english_word":"Eraser","cebuano_meaning":"Pamhid"}]',
 '["Her","bag","is","color","blue."]',
 'He carried his ___ on his back when he walked to school.', 'Bag',
 'Notebook', 'Eraser', 'Ruler'),

-- Ruler
('c1000000-0000-0000-0000-000000000005',
 'Pencil', 'Eraser', 'Bag',
 'She used a ___ to draw a straight line.', 'Ruler',
 '[{"english_word":"Ruler","cebuano_meaning":"Ruler"},{"english_word":"Pencil","cebuano_meaning":"Lapis"},{"english_word":"Eraser","cebuano_meaning":"Pamhid"},{"english_word":"Notebook","cebuano_meaning":"Kuwaderno"}]',
 '["The","ruler","is","used","to","measure","lines."]',
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
 '["My","mother","cooks","delicious","food."]',
 'Her ___ sings a lullaby every night before she sleeps.', 'Mother',
 'Father', 'Sister', 'Grandmother'),

-- Father
('c2000000-0000-0000-0000-000000000002',
 'Mother', 'Brother', 'Uncle',
 'My ___ fixes things around the house.', 'Father',
 '[{"english_word":"Father","cebuano_meaning":"Amahan"},{"english_word":"Mother","cebuano_meaning":"Inahan"},{"english_word":"Brother","cebuano_meaning":"Igsoon nga lalaki"},{"english_word":"Grandmother","cebuano_meaning":"Lola"}]',
 '["My","father","goes","to","work","every","day."]',
 'Her ___ drives her to school every morning.', 'Father',
 'Mother', 'Uncle', 'Brother'),

-- Sister
('c2000000-0000-0000-0000-000000000003',
 'Brother', 'Mother', 'Cousin',
 'My ___ and I share the same bedroom.', 'Sister',
 '[{"english_word":"Sister","cebuano_meaning":"Igsoon nga babaye"},{"english_word":"Brother","cebuano_meaning":"Igsoon nga lalaki"},{"english_word":"Mother","cebuano_meaning":"Inahan"},{"english_word":"Grandmother","cebuano_meaning":"Lola"}]',
 '["My","sister","helps","me","study."]',
 'His ___ reads him a story before bedtime.', 'Sister',
 'Brother', 'Mother', 'Cousin'),

-- Brother
('c2000000-0000-0000-0000-000000000004',
 'Sister', 'Father', 'Cousin',
 'My ___ and I walk to school together.', 'Brother',
 '[{"english_word":"Brother","cebuano_meaning":"Igsoon nga lalaki"},{"english_word":"Sister","cebuano_meaning":"Igsoon nga babaye"},{"english_word":"Father","cebuano_meaning":"Amahan"},{"english_word":"Uncle","cebuano_meaning":"Tiyo"}]',
 '["My","brother","plays","basketball."]',
 'Her ___ helped her carry the heavy bags from the market.', 'Brother',
 'Sister', 'Father', 'Uncle'),

-- Grandmother
('c2000000-0000-0000-0000-000000000005',
 'Mother', 'Aunt', 'Sister',
 'My ___ knits blankets for the whole family.', 'Grandmother',
 '[{"english_word":"Grandmother","cebuano_meaning":"Lola"},{"english_word":"Mother","cebuano_meaning":"Inahan"},{"english_word":"Aunt","cebuano_meaning":"Tiya"},{"english_word":"Sister","cebuano_meaning":"Igsoon nga babaye"}]',
 '["My","grandmother","tells","stories."]',
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
 '["The","dog","barks","loudly."]',
 'The ___ ran to the gate when the family came home.', 'Dog',
 'Cat', 'Horse', 'Bird'),

-- Cat
('c3000000-0000-0000-0000-000000000002',
 'Dog', 'Fish', 'Rabbit',
 'The ___ curled up near the window in the afternoon.', 'Cat',
 '[{"english_word":"Cat","cebuano_meaning":"Iring"},{"english_word":"Dog","cebuano_meaning":"Iro"},{"english_word":"Fish","cebuano_meaning":"Isda"},{"english_word":"Bird","cebuano_meaning":"Langgam"}]',
 '["The","cat","sleeps","on","the","chair."]',
 'The ___ meowed loudly when it was hungry.', 'Cat',
 'Dog', 'Bird', 'Horse'),

-- Bird
('c3000000-0000-0000-0000-000000000003',
 'Fish', 'Dog', 'Horse',
 'A colorful ___ landed on the branch of the mango tree.', 'Bird',
 '[{"english_word":"Bird","cebuano_meaning":"Langgam"},{"english_word":"Fish","cebuano_meaning":"Isda"},{"english_word":"Horse","cebuano_meaning":"Kabayo"},{"english_word":"Dog","cebuano_meaning":"Iro"}]',
 '["The","bird","flies","in","the","sky."]',
 'The ___ sang a sweet song early in the morning.', 'Bird',
 'Fish', 'Dog', 'Cat'),

-- Fish
('c3000000-0000-0000-0000-000000000004',
 'Bird', 'Horse', 'Dog',
 'The ___ hid behind the coral when it was scared.', 'Fish',
 '[{"english_word":"Fish","cebuano_meaning":"Isda"},{"english_word":"Bird","cebuano_meaning":"Langgam"},{"english_word":"Horse","cebuano_meaning":"Kabayo"},{"english_word":"Cat","cebuano_meaning":"Iring"}]',
 '["The","fish","swims","in","the","water."]',
 'The ___ jumped out of the water and splashed back in.', 'Fish',
 'Bird', 'Dog', 'Horse'),

-- Horse
('c3000000-0000-0000-0000-000000000005',
 'Dog', 'Bird', 'Fish',
 'The farmer rides his ___ to the field every morning.', 'Horse',
 '[{"english_word":"Horse","cebuano_meaning":"Kabayo"},{"english_word":"Dog","cebuano_meaning":"Iro"},{"english_word":"Bird","cebuano_meaning":"Langgam"},{"english_word":"Fish","cebuano_meaning":"Isda"}]',
 '["The","horse","runs","fast."]',
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
 '["Rice","is","our","staple","food."]',
 'They eat ___ with grilled fish for lunch every day.', 'Rice',
 'Bread', 'Milk', 'Soup'),

-- Water
('c4000000-0000-0000-0000-000000000002',
 'Juice', 'Milk', 'Soup',
 'She drank a glass of cold ___ after playing outside.', 'Water',
 '[{"english_word":"Water","cebuano_meaning":"Tubig"},{"english_word":"Juice","cebuano_meaning":"Luga/Duga"},{"english_word":"Milk","cebuano_meaning":"Gatas"},{"english_word":"Soup","cebuano_meaning":"Sabaw"}]',
 '["Drink","water","every","day."]',
 'The plants in the garden need ___ to grow healthy.', 'Water',
 'Juice', 'Milk', 'Soup'),

-- Bread
('c4000000-0000-0000-0000-000000000003',
 'Rice', 'Apple', 'Egg',
 'She bought a loaf of ___ from the bakery near school.', 'Bread',
 '[{"english_word":"Bread","cebuano_meaning":"Pan"},{"english_word":"Rice","cebuano_meaning":"Kan-on"},{"english_word":"Apple","cebuano_meaning":"Mansanas"},{"english_word":"Milk","cebuano_meaning":"Gatas"}]',
 '["I","eat","bread","for","breakfast."]',
 'He spread butter on a slice of ___ for his morning snack.', 'Bread',
 'Rice', 'Cheese', 'Apple'),

-- Milk
('c4000000-0000-0000-0000-000000000004',
 'Water', 'Juice', 'Soup',
 'She drinks a glass of cold ___ with her lunch.', 'Milk',
 '[{"english_word":"Milk","cebuano_meaning":"Gatas"},{"english_word":"Water","cebuano_meaning":"Tubig"},{"english_word":"Juice","cebuano_meaning":"Luga/Duga"},{"english_word":"Bread","cebuano_meaning":"Pan"}]',
 '["Milk","helps","make","bones","strong."]',
 'The baby only drinks ___ and cannot eat solid food yet.', 'Milk',
 'Water', 'Juice', 'Soup'),

-- Apple
('c4000000-0000-0000-0000-000000000005',
 'Bread', 'Milk', 'Banana',
 'She packed an ___ in her bag as a healthy snack.', 'Apple',
 '[{"english_word":"Apple","cebuano_meaning":"Mansanas"},{"english_word":"Banana","cebuano_meaning":"Saging"},{"english_word":"Bread","cebuano_meaning":"Pan"},{"english_word":"Milk","cebuano_meaning":"Gatas"}]',
 '["The","apple","is","sweet","and","red."]',
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
 '["The","students","go","to","school","daily."]',
 'She loves going to ___ because she enjoys learning new things.', 'School',
 'Market', 'Hospital', 'Park'),

-- Hospital
('c5000000-0000-0000-0000-000000000002',
 'School', 'Market', 'Church',
 'The sick child was brought to the ___ by her mother.', 'Hospital',
 '[{"english_word":"Hospital","cebuano_meaning":"Ospital"},{"english_word":"School","cebuano_meaning":"Eskwelahan"},{"english_word":"Market","cebuano_meaning":"Merkado"},{"english_word":"Park","cebuano_meaning":"Liwasan"}]',
 '["The","doctor","works","in","the","hospital."]',
 'The ambulance rushed the injured man to the nearest ___.', 'Hospital',
 'School', 'Market', 'Church'),

-- Market
('c5000000-0000-0000-0000-000000000003',
 'School', 'Park', 'Bakery',
 'My mother buys fresh fish and vegetables at the ___.', 'Market',
 '[{"english_word":"Market","cebuano_meaning":"Merkado"},{"english_word":"School","cebuano_meaning":"Eskwelahan"},{"english_word":"Park","cebuano_meaning":"Liwasan"},{"english_word":"Hospital","cebuano_meaning":"Ospital"}]',
 '["Mother","buys","vegetables","in","the","market."]',
 'Vendors sell fruits, vegetables, and meat at the ___ every morning.', 'Market',
 'Park', 'Store', 'School'),

-- Church
('c5000000-0000-0000-0000-000000000004',
 'School', 'Market', 'Park',
 'Our family goes to ___ every Sunday morning.', 'Church',
 '[{"english_word":"Church","cebuano_meaning":"Simbahan"},{"english_word":"School","cebuano_meaning":"Eskwelahan"},{"english_word":"Market","cebuano_meaning":"Merkado"},{"english_word":"Park","cebuano_meaning":"Liwasan"}]',
 '["We","pray","in","the","church."]',
 'The bells of the ___ rang early on Sunday morning.', 'Church',
 'School', 'Market', 'Park'),

-- Park
('c5000000-0000-0000-0000-000000000005',
 'Market', 'School', 'Church',
 'Families enjoy picnics and walks in the ___ on weekends.', 'Park',
 '[{"english_word":"Park","cebuano_meaning":"Liwasan"},{"english_word":"Market","cebuano_meaning":"Merkado"},{"english_word":"School","cebuano_meaning":"Eskwelahan"},{"english_word":"Church","cebuano_meaning":"Simbahan"}]',
 '["Children","play","in","the","park."]',
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
 '["I","sit","at","my","desk","to","read."]',
 'The teacher placed the test papers on each student''s ___.', 'Desk',
 'Chair', 'Chalk', 'Scissors'),

-- Chalk
('c1000000-0000-0000-0000-000000000007',
 'Crayon', 'Pencil', 'Marker',
 'The teacher used ___ to write the math problem on the board.', 'Chalk',
 '[{"english_word":"Chalk","cebuano_meaning":"Tsok"},{"english_word":"Crayon","cebuano_meaning":"Krayola"},{"english_word":"Desk","cebuano_meaning":"Lamesa"},{"english_word":"Glue","cebuano_meaning":"Papilit"}]',
 '["The","teacher","writes","with","chalk."]',
 'She drew a hopscotch grid on the ground using a piece of ___.', 'Chalk',
 'Crayon', 'Pencil', 'Glue'),

-- Crayon
('c1000000-0000-0000-0000-000000000008',
 'Chalk', 'Pencil', 'Marker',
 'She colored the drawing of a rainbow using her set of ___.', 'Crayon',
 '[{"english_word":"Crayon","cebuano_meaning":"Krayola"},{"english_word":"Chalk","cebuano_meaning":"Tsok"},{"english_word":"Pencil","cebuano_meaning":"Lapis"},{"english_word":"Scissors","cebuano_meaning":"Gunting"}]',
 '["Draw","a","picture","with","a","green","crayon."]',
 'He used a red ___ to color the apple in his drawing.', 'Crayon',
 'Chalk', 'Pencil', 'Glue'),

-- Scissors
('c1000000-0000-0000-0000-000000000009',
 'Glue', 'Ruler', 'Crayon',
 'The teacher asked the students to use ___ to cut the paper.', 'Scissors',
 '[{"english_word":"Scissors","cebuano_meaning":"Gunting"},{"english_word":"Glue","cebuano_meaning":"Papilit"},{"english_word":"Ruler","cebuano_meaning":"Ruler"},{"english_word":"Crayon","cebuano_meaning":"Krayola"}]',
 '["Be","careful","when","using","scissors."]',
 'She used ___ to cut out the shapes for her art project.', 'Scissors',
 'Glue', 'Ruler', 'Chalk'),

-- Glue
('c1000000-0000-0000-0000-000000000010',
 'Tape', 'Scissors', 'Crayon',
 'She put ___ on the back of the picture before sticking it.', 'Glue',
 '[{"english_word":"Glue","cebuano_meaning":"Papilit"},{"english_word":"Scissors","cebuano_meaning":"Gunting"},{"english_word":"Chalk","cebuano_meaning":"Tsok"},{"english_word":"Crayon","cebuano_meaning":"Krayola"}]',
 '["Use","glue","to","paste","the","paper."]',
 'The student used ___ to attach the cut-out letters onto the poster.', 'Glue',
 'Tape', 'Scissors', 'Crayon')
ON CONFLICT (word_id) DO NOTHING;

-- ============================================================
-- LESSON 7 — MORE FAMILY MEMBERS (Words: Uncle, Aunt, Cousin, Grandfather, Nephew)
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

-- Uncle
('c2000000-0000-0000-0000-000000000006',
 'Aunt', 'Cousin', 'Grandfather',
 'My ___ brought us pasalubong from Cebu City.', 'Uncle',
 '[{"english_word":"Uncle","cebuano_meaning":"Tiyo"},{"english_word":"Aunt","cebuano_meaning":"Tiya"},{"english_word":"Cousin","cebuano_meaning":"Ig-agaw"},{"english_word":"Grandfather","cebuano_meaning":"Lolo"}]',
 '["My","uncle","plays","guitar."]',
 'Her ___ taught her how to ride a bicycle last summer.', 'Uncle',
 'Aunt', 'Cousin', 'Grandfather'),

-- Aunt
('c2000000-0000-0000-0000-000000000007',
 'Uncle', 'Cousin', 'Grandmother',
 'My ___ made a delicious leche flan for the fiesta.', 'Aunt',
 '[{"english_word":"Aunt","cebuano_meaning":"Tiya"},{"english_word":"Uncle","cebuano_meaning":"Tiyo"},{"english_word":"Grandmother","cebuano_meaning":"Lola"},{"english_word":"Cousin","cebuano_meaning":"Ig-agaw"}]',
 '["My","aunt","visits","us","on","Sundays."]',
 'His ___ braided his sister''s hair before the school program.', 'Aunt',
 'Uncle', 'Grandmother', 'Mother'),

-- Cousin
('c2000000-0000-0000-0000-000000000008',
 'Brother', 'Uncle', 'Nephew',
 'My ___ and I always play tag in the yard during summer.', 'Cousin',
 '[{"english_word":"Cousin","cebuano_meaning":"Ig-agaw"},{"english_word":"Brother","cebuano_meaning":"Igsoon nga lalaki"},{"english_word":"Uncle","cebuano_meaning":"Tiyo"},{"english_word":"Aunt","cebuano_meaning":"Tiya"}]',
 '["I","play","with","my","cousin","in","the","yard."]',
 'Her ___ from Mandaue visited them during the holiday break.', 'Cousin',
 'Brother', 'Uncle', 'Nephew'),

-- Grandfather
('c2000000-0000-0000-0000-000000000009',
 'Uncle', 'Father', 'Grandmother',
 'My ___ wakes up early to water the plants every morning.', 'Grandfather',
 '[{"english_word":"Grandfather","cebuano_meaning":"Lolo"},{"english_word":"Uncle","cebuano_meaning":"Tiyo"},{"english_word":"Father","cebuano_meaning":"Amahan"},{"english_word":"Grandmother","cebuano_meaning":"Lola"}]',
 '["My","grandfather","loves","gardening."]',
 'Her ___ told her stories about Cebu during the old times.', 'Grandfather',
 'Uncle', 'Father', 'Grandmother'),

-- Nephew
('c2000000-0000-0000-0000-000000000010',
 'Cousin', 'Brother', 'Uncle',
 'Her ___ always follows her around whenever she visits.', 'Nephew',
 '[{"english_word":"Nephew","cebuano_meaning":"Pag-umangkon nga lalaki"},{"english_word":"Cousin","cebuano_meaning":"Ig-agaw"},{"english_word":"Brother","cebuano_meaning":"Igsoon nga lalaki"},{"english_word":"Uncle","cebuano_meaning":"Tiyo"}]',
 '["My","nephew","is","very","energetic."]',
 'She bought a toy car as a birthday gift for her little ___.', 'Nephew',
 'Cousin', 'Brother', 'Uncle')
ON CONFLICT (word_id) DO NOTHING;

-- ============================================================
-- LESSON 8 — MORE ANIMALS (Words: Lion, Monkey, Rabbit, Elephant, Duck)
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

-- Lion
('c3000000-0000-0000-0000-000000000006',
 'Elephant', 'Monkey', 'Horse',
 'A ___ roared loudly inside its enclosure at the zoo.', 'Lion',
 '[{"english_word":"Lion","cebuano_meaning":"Liyon"},{"english_word":"Elephant","cebuano_meaning":"Elepante"},{"english_word":"Monkey","cebuano_meaning":"Unggoy"},{"english_word":"Rabbit","cebuano_meaning":"Koneho"}]',
 '["The","lion","is","the","king","of","the","jungle."]',
 'The ___ protected its cubs from the approaching danger.', 'Lion',
 'Tiger', 'Elephant', 'Monkey'),

-- Monkey
('c3000000-0000-0000-0000-000000000007',
 'Lion', 'Rabbit', 'Duck',
 'The ___ swung from branch to branch in the tall trees.', 'Monkey',
 '[{"english_word":"Monkey","cebuano_meaning":"Unggoy"},{"english_word":"Lion","cebuano_meaning":"Liyon"},{"english_word":"Rabbit","cebuano_meaning":"Koneho"},{"english_word":"Duck","cebuano_meaning":"Bato"}]',
 '["The","monkey","climbs","the","tree."]',
 'The ___ grabbed a banana from the visitor''s hand at the zoo.', 'Monkey',
 'Lion', 'Rabbit', 'Elephant'),

-- Rabbit
('c3000000-0000-0000-0000-000000000008',
 'Duck', 'Monkey', 'Lion',
 'The white ___ hopped around the garden and nibbled on the grass.', 'Rabbit',
 '[{"english_word":"Rabbit","cebuano_meaning":"Koneho"},{"english_word":"Duck","cebuano_meaning":"Bato"},{"english_word":"Monkey","cebuano_meaning":"Unggoy"},{"english_word":"Lion","cebuano_meaning":"Liyon"}]',
 '["The","rabbit","eats","a","carrot."]',
 'The ___ hid inside its burrow when it heard a loud noise.', 'Rabbit',
 'Duck', 'Monkey', 'Lion'),

-- Elephant
('c3000000-0000-0000-0000-000000000009',
 'Lion', 'Monkey', 'Horse',
 'The ___ used its long trunk to pick up water from the river.', 'Elephant',
 '[{"english_word":"Elephant","cebuano_meaning":"Elepante"},{"english_word":"Lion","cebuano_meaning":"Liyon"},{"english_word":"Monkey","cebuano_meaning":"Unggoy"},{"english_word":"Duck","cebuano_meaning":"Bato"}]',
 '["The","elephant","has","a","long","trunk."]',
 'The ___ sprayed water on its back to cool itself in the heat.', 'Elephant',
 'Lion', 'Monkey', 'Horse'),

-- Duck
('c3000000-0000-0000-0000-000000000010',
 'Rabbit', 'Bird', 'Fish',
 'The ___ waddled across the muddy path near the rice field.', 'Duck',
 '[{"english_word":"Duck","cebuano_meaning":"Bato"},{"english_word":"Rabbit","cebuano_meaning":"Koneho"},{"english_word":"Bird","cebuano_meaning":"Langgam"},{"english_word":"Fish","cebuano_meaning":"Isda"}]',
 '["The","duck","quacks","in","the","pond."]',
 'The ___ paddled gently on the calm surface of the pond.', 'Duck',
 'Rabbit', 'Bird', 'Fish')
ON CONFLICT (word_id) DO NOTHING;

-- ============================================================
-- LESSON 9 — MORE FOOD AND DRINKS (Words: Juice, Banana, Egg, Soup, Cheese)
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

-- Juice
('c4000000-0000-0000-0000-000000000006',
 'Water', 'Milk', 'Soup',
 'She poured a glass of cold ___ to serve her visitors.', 'Juice',
 '[{"english_word":"Juice","cebuano_meaning":"Luga/Duga"},{"english_word":"Water","cebuano_meaning":"Tubig"},{"english_word":"Milk","cebuano_meaning":"Gatas"},{"english_word":"Soup","cebuano_meaning":"Sabaw"}]',
 '["I","like","orange","juice."]',
 'Her mother squeezed fresh oranges to make a glass of ___.', 'Juice',
 'Water', 'Milk', 'Soup'),

-- Banana
('c4000000-0000-0000-0000-000000000007',
 'Apple', 'Mango', 'Egg',
 'She peeled a ripe ___ and gave half to her little brother.', 'Banana',
 '[{"english_word":"Banana","cebuano_meaning":"Saging"},{"english_word":"Apple","cebuano_meaning":"Mansanas"},{"english_word":"Egg","cebuano_meaning":"Itlog"},{"english_word":"Cheese","cebuano_meaning":"Keso"}]',
 '["A","banana","is","yellow","and","sweet."]',
 'He ate a ___ before his morning run to have quick energy.', 'Banana',
 'Apple', 'Mango', 'Cheese'),

-- Egg
('c4000000-0000-0000-0000-000000000008',
 'Banana', 'Bread', 'Cheese',
 'She cracked an ___ into the pan and cooked it sunny side up.', 'Egg',
 '[{"english_word":"Egg","cebuano_meaning":"Itlog"},{"english_word":"Banana","cebuano_meaning":"Saging"},{"english_word":"Bread","cebuano_meaning":"Pan"},{"english_word":"Soup","cebuano_meaning":"Sabaw"}]',
 '["I","eat","a","boiled","egg","for","breakfast."]',
 'The chef used three pieces of ___ to make the fluffy omelet.', 'Egg',
 'Banana', 'Bread', 'Cheese'),

-- Soup
('c4000000-0000-0000-0000-000000000009',
 'Juice', 'Milk', 'Water',
 'She stirred the hot ___ carefully so it would not spill.', 'Soup',
 '[{"english_word":"Soup","cebuano_meaning":"Sabaw"},{"english_word":"Juice","cebuano_meaning":"Luga/Duga"},{"english_word":"Milk","cebuano_meaning":"Gatas"},{"english_word":"Egg","cebuano_meaning":"Itlog"}]',
 '["The","warm","soup","tastes","good","on","a","rainy","day."]',
 'She cooked a pot of chicken ___ when her brother had a cold.', 'Soup',
 'Juice', 'Milk', 'Bread'),

-- Cheese
('c4000000-0000-0000-0000-000000000010',
 'Butter', 'Egg', 'Milk',
 'She melted ___ on top of the hot pan de sal.', 'Cheese',
 '[{"english_word":"Cheese","cebuano_meaning":"Keso"},{"english_word":"Butter","cebuano_meaning":"Mantika"},{"english_word":"Egg","cebuano_meaning":"Itlog"},{"english_word":"Milk","cebuano_meaning":"Gatas"}]',
 '["Put","cheese","on","my","sandwich,","please."]',
 'The pizza was extra delicious because of the thick layer of ___ on top.', 'Cheese',
 'Butter', 'Egg', 'Milk')
ON CONFLICT (word_id) DO NOTHING;

-- ============================================================
-- LESSON 10 — MORE PLACES (Words: Library, Store, Station, Bakery, Bridge)
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

-- Library
('c5000000-0000-0000-0000-000000000006',
 'Store', 'School', 'Bakery',
 'She borrowed three storybooks from the school ___.', 'Library',
 '[{"english_word":"Library","cebuano_meaning":"Laibrairi"},{"english_word":"Store","cebuano_meaning":"Tindahan"},{"english_word":"School","cebuano_meaning":"Eskwelahan"},{"english_word":"Bakery","cebuano_meaning":"Panaderya"}]',
 '["We","read","quietly","in","the","library."]',
 'Students visit the ___ to research topics for their projects.', 'Library',
 'Store', 'Bakery', 'Station'),

-- Store
('c5000000-0000-0000-0000-000000000007',
 'Market', 'Bakery', 'Library',
 'She ran to the nearby ___ to buy a bar of soap.', 'Store',
 '[{"english_word":"Store","cebuano_meaning":"Tindahan"},{"english_word":"Market","cebuano_meaning":"Merkado"},{"english_word":"Bakery","cebuano_meaning":"Panaderya"},{"english_word":"Bridge","cebuano_meaning":"Tulay"}]',
 '["I","buy","candies","at","the","store."]',
 'He stopped at the corner ___ to buy a cold drink after school.', 'Store',
 'Market', 'Bakery', 'Library'),

-- Station
('c5000000-0000-0000-0000-000000000008',
 'Bridge', 'Market', 'Store',
 'They waited for the jeepney at the ___ near the church.', 'Station',
 '[{"english_word":"Station","cebuano_meaning":"Estasyon"},{"english_word":"Bridge","cebuano_meaning":"Tulay"},{"english_word":"Market","cebuano_meaning":"Merkado"},{"english_word":"Store","cebuano_meaning":"Tindahan"}]',
 '["The","bus","is","waiting","at","the","station."]',
 'The passengers lined up at the ___ to wait for the next bus.', 'Station',
 'Bridge', 'Market', 'Store'),

-- Bakery
('c5000000-0000-0000-0000-000000000009',
 'Store', 'Library', 'Market',
 'The smell of fresh pan de sal drew her inside the ___.', 'Bakery',
 '[{"english_word":"Bakery","cebuano_meaning":"Panaderya"},{"english_word":"Store","cebuano_meaning":"Tindahan"},{"english_word":"Library","cebuano_meaning":"Laibrairi"},{"english_word":"Station","cebuano_meaning":"Estasyon"}]',
 '["The","bakery","sells","warm","bread."]',
 'Her mother sent her to the ___ to buy fresh rolls for breakfast.', 'Bakery',
 'Store', 'Library', 'Market'),

-- Bridge
('c5000000-0000-0000-0000-000000000010',
 'Station', 'Park', 'Store',
 'The children held hands as they walked across the old wooden ___.', 'Bridge',
 '[{"english_word":"Bridge","cebuano_meaning":"Tulay"},{"english_word":"Station","cebuano_meaning":"Estasyon"},{"english_word":"Park","cebuano_meaning":"Liwasan"},{"english_word":"Store","cebuano_meaning":"Tindahan"}]',
 '["We","cross","the","river","using","the","bridge."]',
 'The fishermen stood on the ___ to cast their fishing lines into the river.', 'Bridge',
 'Station', 'Park', 'Store')
ON CONFLICT (word_id) DO NOTHING;
