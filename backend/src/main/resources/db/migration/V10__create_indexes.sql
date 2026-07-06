-- V10: Database Indexing Strategy
-- Adds primary, composite, and full-text indexes for query performance at scale

-- ──────────────────────────────────────────────────────────
-- PRIMARY INDEXES (Foreign Keys)
-- ──────────────────────────────────────────────────────────

-- learner_profiles → school (anticipating school_id addition)
-- Note: learners table does not yet have school_id. This index is a placeholder
--       for when school_id is added via a future migration.
-- CREATE INDEX IF NOT EXISTS idx_learner_profiles_school ON learners(school_id);

-- vocabulary_words → lesson
CREATE INDEX IF NOT EXISTS idx_vocabulary_words_lesson
    ON vocabulary_words(lesson_id);

-- practice_results → learner (using word_progress as the closest equivalent)
CREATE INDEX IF NOT EXISTS idx_word_progress_learner
    ON word_progress(learner_id);

-- word_progress → word
CREATE INDEX IF NOT EXISTS idx_word_progress_word
    ON word_progress(word_id);

-- learner_lesson_status → learner
CREATE INDEX IF NOT EXISTS idx_learner_lesson_status_learner
    ON learner_lesson_status(learner_id);

-- learner_lesson_status → lesson
CREATE INDEX IF NOT EXISTS idx_learner_lesson_status_lesson
    ON learner_lesson_status(lesson_id);

-- confusable_word_pairs → lesson
CREATE INDEX IF NOT EXISTS idx_confusable_word_pairs_lesson
    ON confusable_word_pairs(lesson_id);

-- pronunciation_attempts → learner
CREATE INDEX IF NOT EXISTS idx_pronunciation_attempts_learner
    ON pronunciation_attempts(learner_id);

-- ──────────────────────────────────────────────────────────
-- COMPOSITE INDEXES (Query Performance)
-- ──────────────────────────────────────────────────────────

-- Word progress by learner + lesson + created_at (most recent first)
CREATE INDEX IF NOT EXISTS idx_word_progress_learner_lesson_date
    ON word_progress(learner_id, lesson_id, created_at DESC);

-- Learner lesson status by learner + lesson + completed_at
CREATE INDEX IF NOT EXISTS idx_learner_lesson_status_date
    ON learner_lesson_status(learner_id, lesson_id, completed_at);

-- Pronunciation attempts by learner + lesson + recorded_at
CREATE INDEX IF NOT EXISTS idx_pronunciation_attempts_learner_lesson_date
    ON pronunciation_attempts(learner_id, lesson_id, recorded_at DESC);

-- ──────────────────────────────────────────────────────────
-- FULL-TEXT INDEXES (Search)
-- ──────────────────────────────────────────────────────────

-- Full-text search on vocabulary_words.english_word
CREATE INDEX IF NOT EXISTS idx_vocabulary_words_english
    ON vocabulary_words USING GIN(to_tsvector('english', english_word));

-- Full-text search on vocabulary_words.cebuano_meaning
CREATE INDEX IF NOT EXISTS idx_vocabulary_words_cebuano
    ON vocabulary_words USING GIN(to_tsvector('simple', cebuano_meaning));

-- ──────────────────────────────────────────────────────────
-- ADMIN TABLE INDEXES
-- ──────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_admins_school_id
    ON admins(school_id);

CREATE INDEX IF NOT EXISTS idx_admins_email
    ON admins(email);

CREATE INDEX IF NOT EXISTS idx_admins_is_active
    ON admins(is_active);
