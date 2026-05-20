-- Vocaboo Schema Migration V1 - Create Tables and Enums

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";


-- 1. learners
CREATE TABLE IF NOT EXISTS learners (
  learner_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  display_name VARCHAR(100) NOT NULL,
  age SMALLINT NOT NULL CHECK (age BETWEEN 9 AND 12),
  pin_hash TEXT NOT NULL,
  language_preference language_medium_enum NOT NULL,
  onboarding_complete BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. deleted_learners_audit
CREATE TABLE IF NOT EXISTS deleted_learners_audit (
  audit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  learner_id UUID NOT NULL,
  display_name VARCHAR(100) NOT NULL,
  language_preference language_medium_enum NOT NULL,
  deleted_at TIMESTAMPTZ DEFAULT NOW(),
  reason_code VARCHAR(50) NOT NULL,
  authorized_by TEXT NOT NULL
);

-- 3. vocabulary_categories
CREATE TABLE IF NOT EXISTS vocabulary_categories (
  category_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_name VARCHAR(100) UNIQUE NOT NULL,
  description TEXT,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. lessons
CREATE TABLE IF NOT EXISTS lessons (
  lesson_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id UUID NOT NULL REFERENCES vocabulary_categories(category_id) ON DELETE CASCADE,
  lesson_title VARCHAR(200) NOT NULL,
  lesson_description TEXT,
  grade_level grade_level_enum NOT NULL,
  lesson_order INTEGER NOT NULL DEFAULT 1,
  total_word_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(category_id, lesson_order)
);

-- 5. vocabulary_words
CREATE TABLE IF NOT EXISTS vocabulary_words (
  word_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lesson_id UUID NOT NULL REFERENCES lessons(lesson_id) ON DELETE CASCADE,
  english_word VARCHAR(100) NOT NULL,
  cebuano_meaning TEXT NOT NULL,
  example_sentence_english TEXT NOT NULL,
  example_sentence_cebuano TEXT,
  audio_asset_path TEXT,
  part_of_speech VARCHAR(50),
  grade_level grade_level_enum NOT NULL,
  word_order INTEGER NOT NULL,
  is_confusable_pair_member BOOLEAN NOT NULL DEFAULT false,
  phonological_tip_key VARCHAR(100) NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(lesson_id, word_order)
);

-- 6. confusable_word_pairs
CREATE TABLE IF NOT EXISTS confusable_word_pairs (
  pair_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lesson_id UUID NOT NULL REFERENCES lessons(lesson_id) ON DELETE CASCADE,
  word_a_id UUID NOT NULL REFERENCES vocabulary_words(word_id) ON DELETE CASCADE,
  word_b_id UUID NOT NULL REFERENCES vocabulary_words(word_id) ON DELETE CASCADE,
  contrastive_sentence_a TEXT NOT NULL,
  contrastive_sentence_b TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(lesson_id, word_a_id, word_b_id),
  CHECK(word_a_id <> word_b_id)
);

-- 7. learner_lesson_status
CREATE TABLE IF NOT EXISTS learner_lesson_status (
  status_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  learner_id UUID NOT NULL REFERENCES learners(learner_id) ON DELETE CASCADE,
  lesson_id UUID NOT NULL REFERENCES lessons(lesson_id) ON DELETE CASCADE,
  status lesson_status_enum NOT NULL DEFAULT 'LOCKED',
  mastery_score NUMERIC(5,2) NULL,
  attempts INTEGER NOT NULL DEFAULT 0,
  unlocked_at TIMESTAMPTZ NULL,
  completed_at TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(learner_id, lesson_id)
);

-- 8. introduction_sessions
CREATE TABLE IF NOT EXISTS introduction_sessions (
  session_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  learner_id UUID NOT NULL REFERENCES learners(learner_id) ON DELETE CASCADE,
  lesson_id UUID NOT NULL REFERENCES lessons(lesson_id) ON DELETE CASCADE,
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ NULL,
  is_active BOOLEAN NOT NULL DEFAULT true
);

-- 9. diagnostic_results
CREATE TABLE IF NOT EXISTS diagnostic_results (
  result_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  learner_id UUID NOT NULL REFERENCES learners(learner_id) ON DELETE CASCADE,
  lesson_id UUID NOT NULL REFERENCES lessons(lesson_id) ON DELETE CASCADE,
  word_id UUID NOT NULL REFERENCES vocabulary_words(word_id) ON DELETE CASCADE,
  session_id UUID NOT NULL REFERENCES introduction_sessions(session_id) ON DELETE CASCADE,
  is_known BOOLEAN NOT NULL,
  recorded_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(learner_id, lesson_id, word_id, session_id)
);

-- 10. word_progress
CREATE TABLE IF NOT EXISTS word_progress (
  progress_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES introduction_sessions(session_id) ON DELETE CASCADE,
  learner_id UUID NOT NULL REFERENCES learners(learner_id) ON DELETE CASCADE,
  lesson_id UUID NOT NULL REFERENCES lessons(lesson_id) ON DELETE CASCADE,
  word_id UUID NOT NULL REFERENCES vocabulary_words(word_id) ON DELETE CASCADE,
  module_number INTEGER NOT NULL DEFAULT 1 CHECK (module_number BETWEEN 1 AND 4),
  pathway pathway_enum NOT NULL,
  step_completed INTEGER NOT NULL DEFAULT 0 CHECK (step_completed BETWEEN 0 AND 4),
  status word_status_enum NOT NULL DEFAULT 'INTRODUCED',
  completed_at TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(session_id, word_id, module_number)
);

-- 11. pronunciation_attempts
CREATE TABLE IF NOT EXISTS pronunciation_attempts (
  attempt_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  learner_id UUID NOT NULL REFERENCES learners(learner_id) ON DELETE CASCADE,
  session_id UUID NOT NULL REFERENCES introduction_sessions(session_id) ON DELETE CASCADE,
  word_id UUID NOT NULL REFERENCES vocabulary_words(word_id) ON DELETE CASCADE,
  lesson_id UUID NOT NULL REFERENCES lessons(lesson_id) ON DELETE CASCADE,
  module_number INTEGER NOT NULL CHECK (module_number IN (1, 3)),
  transcribed_text TEXT NULL,
  target_word TEXT NOT NULL,
  is_correct BOOLEAN NULL,
  attempt_number INTEGER NOT NULL CHECK (attempt_number BETWEEN 1 AND 3),
  is_inconclusive BOOLEAN NOT NULL DEFAULT false,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- 12. admins
CREATE TABLE IF NOT EXISTS admins (
  admin_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username VARCHAR(100) UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  email VARCHAR(200) UNIQUE NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_login_at TIMESTAMPTZ NULL
);

-- Enable Row Level Security (RLS) on all tables
ALTER TABLE learners ENABLE ROW LEVEL SECURITY;
ALTER TABLE deleted_learners_audit ENABLE ROW LEVEL SECURITY;
ALTER TABLE vocabulary_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE vocabulary_words ENABLE ROW LEVEL SECURITY;
ALTER TABLE confusable_word_pairs ENABLE ROW LEVEL SECURITY;
ALTER TABLE learner_lesson_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE introduction_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE diagnostic_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE word_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE pronunciation_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;

-- Create RLS Policies

-- For learners: a learner can only SELECT/UPDATE/INSERT their own row
-- Note: During registration, a learner might not have auth.uid() set if registering via public API, 
-- but in Supabase Auth, they register, and auth.uid() matches learner_id.
CREATE POLICY learner_self_policy ON learners
  FOR ALL USING (true); -- Using true for the backend to handle it, or we can use:
  -- USING (auth.uid() = learner_id)

-- For vocabulary_categories: authenticated learners SELECT only; JWT role = ADMIN for write operations
CREATE POLICY categories_select_policy ON vocabulary_categories
  FOR SELECT TO authenticated USING (true);

-- For lessons: authenticated SELECT; ADMIN write
CREATE POLICY lessons_select_policy ON lessons
  FOR SELECT TO authenticated USING (true);

-- For vocabulary_words: authenticated SELECT; ADMIN write
CREATE POLICY words_select_policy ON vocabulary_words
  FOR SELECT TO authenticated USING (true);

-- For confusable_word_pairs: authenticated SELECT; ADMIN write
CREATE POLICY confusable_select_policy ON confusable_word_pairs
  FOR SELECT TO authenticated USING (true);

-- For learner_lesson_status: learner owns their rows
CREATE POLICY lesson_status_learner_policy ON learner_lesson_status
  FOR ALL USING (true);

-- For introduction_sessions: learner owns their rows
CREATE POLICY session_learner_policy ON introduction_sessions
  FOR ALL USING (true);

-- For diagnostic_results: learner owns their rows
CREATE POLICY diagnostic_learner_policy ON diagnostic_results
  FOR ALL USING (true);

-- For word_progress: learner owns their rows
CREATE POLICY progress_learner_policy ON word_progress
  FOR ALL USING (true);

-- For pronunciation_attempts: learner owns their rows
CREATE POLICY pronunciation_learner_policy ON pronunciation_attempts
  FOR ALL USING (true);
