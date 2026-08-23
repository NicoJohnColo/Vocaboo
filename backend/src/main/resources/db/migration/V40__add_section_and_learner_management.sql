-- V40: Add sections table, section/grade/active tracking on learners, and fallback count on word performance

CREATE TABLE IF NOT EXISTS sections (
    section_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    section_name VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

ALTER TABLE learners
    ADD COLUMN IF NOT EXISTS section_id UUID REFERENCES sections(section_id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS grade_level grade_level_enum,
    ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE;

CREATE INDEX IF NOT EXISTS idx_learners_section_id ON learners(section_id);
CREATE INDEX IF NOT EXISTS idx_learners_is_active ON learners(is_active);
CREATE INDEX IF NOT EXISTS idx_learners_grade_level ON learners(grade_level);

ALTER TABLE word_performance
    ADD COLUMN IF NOT EXISTS fallback_count INTEGER NOT NULL DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_word_performance_fallback ON word_performance(fallback_count);
