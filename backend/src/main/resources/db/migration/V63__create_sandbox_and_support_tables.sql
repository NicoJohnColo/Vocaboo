-- V63: Ensure sandbox tables, extended text-only activity columns, and polymorphic difficulty_progress tracking

CREATE TABLE IF NOT EXISTS sandbox_sessions (
    session_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    learner_id UUID NOT NULL REFERENCES learners(learner_id) ON DELETE CASCADE,
    custom_word VARCHAR(100) NOT NULL,
    mastery_score DECIMAL(5,2),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS sandbox_words (
    word_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES sandbox_sessions(session_id) ON DELETE CASCADE,
    english_word VARCHAR(100) NOT NULL,
    cebuano_meaning TEXT NOT NULL,
    example_sentence_english TEXT,
    example_sentence_cebuano TEXT,
    phonological_tip_key VARCHAR(100),
    true_or_false_statement TEXT,
    true_or_false_answer BOOLEAN DEFAULT TRUE,
    hint_clue TEXT,
    confusable_partner_word VARCHAR(100),
    confusable_cebuano_distinction TEXT,
    confusable_contrast_sentence_a TEXT,
    confusable_contrast_sentence_b TEXT,
    word_order INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE sandbox_words ADD COLUMN IF NOT EXISTS true_or_false_statement TEXT;
ALTER TABLE sandbox_words ADD COLUMN IF NOT EXISTS true_or_false_answer BOOLEAN DEFAULT TRUE;
ALTER TABLE sandbox_words ADD COLUMN IF NOT EXISTS hint_clue TEXT;
ALTER TABLE sandbox_words ADD COLUMN IF NOT EXISTS confusable_partner_word VARCHAR(100);
ALTER TABLE sandbox_words ADD COLUMN IF NOT EXISTS confusable_cebuano_distinction TEXT;
ALTER TABLE sandbox_words ADD COLUMN IF NOT EXISTS confusable_contrast_sentence_a TEXT;
ALTER TABLE sandbox_words ADD COLUMN IF NOT EXISTS confusable_contrast_sentence_b TEXT;

CREATE TABLE IF NOT EXISTS sandbox_word_progress (
    progress_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES sandbox_sessions(session_id) ON DELETE CASCADE,
    word_id UUID NOT NULL REFERENCES sandbox_words(word_id) ON DELETE CASCADE,
    module_number INTEGER NOT NULL,
    step_completed INTEGER NOT NULL DEFAULT 0,
    status VARCHAR(30) NOT NULL DEFAULT 'INTRODUCED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS sandbox_module_scores (
    score_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES sandbox_sessions(session_id) ON DELETE CASCADE,
    module_number INTEGER NOT NULL,
    correct INTEGER NOT NULL DEFAULT 0,
    total INTEGER NOT NULL DEFAULT 0,
    score DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(session_id, module_number)
);

-- Make difficulty_progress polymorphic so both curriculum words and AI sandbox words share adaptive tier progression
ALTER TABLE difficulty_progress ALTER COLUMN word_id DROP NOT NULL;
ALTER TABLE difficulty_progress ADD COLUMN IF NOT EXISTS sandbox_word_id UUID REFERENCES sandbox_words(word_id) ON DELETE CASCADE;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_word_or_sandbox_word'
    ) THEN
        ALTER TABLE difficulty_progress ADD CONSTRAINT chk_word_or_sandbox_word
            CHECK ((word_id IS NOT NULL AND sandbox_word_id IS NULL) OR (word_id IS NULL AND sandbox_word_id IS NOT NULL));
    END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS uk_learner_sandbox_word_module
    ON difficulty_progress(learner_id, sandbox_word_id, module_number)
    WHERE sandbox_word_id IS NOT NULL;
