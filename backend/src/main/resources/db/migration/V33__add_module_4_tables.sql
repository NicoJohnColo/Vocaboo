-- Migration V33 - Add Module 4 Cumulative Review Tables

-- 1. cross_lesson_sentences
CREATE TABLE IF NOT EXISTS cross_lesson_sentences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sentence_text TEXT NOT NULL,
    sentence_translation TEXT NOT NULL,
    word_a_id UUID NOT NULL REFERENCES vocabulary_words(word_id) ON DELETE CASCADE,
    word_b_id UUID NOT NULL REFERENCES vocabulary_words(word_id) ON DELETE CASCADE,
    lesson_pair_id VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID NULL,
    CONSTRAINT chk_different_words CHECK (word_a_id <> word_b_id)
);

-- 2. cumulative_review_sessions
CREATE TABLE IF NOT EXISTS cumulative_review_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    learner_id UUID NOT NULL REFERENCES learners(learner_id) ON DELETE CASCADE,
    lesson_pair_id VARCHAR(100) NOT NULL,
    session_status VARCHAR(20) NOT NULL DEFAULT 'IN_PROGRESS',
    start_time TIMESTAMPTZ DEFAULT NOW(),
    end_time TIMESTAMPTZ NULL,
    total_attempts INTEGER DEFAULT 0,
    correct_count INTEGER DEFAULT 0,
    accuracy_percent DECIMAL(5,2) NULL,
    badge_awarded VARCHAR(20) NULL,
    points_earned INTEGER DEFAULT 0,
    points_breakdown JSONB NULL
);

-- 3. cumulative_review_results
CREATE TABLE IF NOT EXISTS cumulative_review_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES cumulative_review_sessions(id) ON DELETE CASCADE,
    word_id UUID NOT NULL REFERENCES vocabulary_words(word_id) ON DELETE CASCADE,
    activity_type VARCHAR(50) NOT NULL,
    correct BOOLEAN NOT NULL,
    attempt_number INTEGER NOT NULL DEFAULT 1,
    cross_lesson_sentence_id UUID NULL REFERENCES cross_lesson_sentences(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
