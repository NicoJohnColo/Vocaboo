-- Schema migration for Sentence Building & Wrong Answer Tracking

CREATE TABLE IF NOT EXISTS sentence_templates (
    template_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lesson_id UUID NOT NULL REFERENCES lessons(lesson_id) ON DELETE CASCADE,
    word_id UUID NOT NULL REFERENCES vocabulary_words(word_id) ON DELETE CASCADE,
    template_text TEXT NOT NULL,
    cebuano_translation TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS wrong_answer_records (
    record_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    learner_id UUID NOT NULL REFERENCES learners(learner_id) ON DELETE CASCADE,
    word_id UUID NOT NULL REFERENCES vocabulary_words(word_id) ON DELETE CASCADE,
    wrong_answer TEXT NOT NULL,
    activity_format VARCHAR(50) NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS phonetic_tips (
    tip_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sound_key VARCHAR(50) UNIQUE NOT NULL,
    tip_cebuano TEXT NOT NULL,
    tip_english TEXT NOT NULL,
    tip_mixed TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sentence_templates_word ON sentence_templates(word_id);
CREATE INDEX IF NOT EXISTS idx_wrong_answers_learner ON wrong_answer_records(learner_id);
CREATE INDEX IF NOT EXISTS idx_phonetic_tips_key ON phonetic_tips(sound_key);
