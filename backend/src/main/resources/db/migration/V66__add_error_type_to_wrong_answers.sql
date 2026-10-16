-- V66: Add error_type classification to wrong_answer_records for confusable pair & phonetic tracking

ALTER TABLE wrong_answer_records
    ADD COLUMN IF NOT EXISTS error_type VARCHAR(50) NOT NULL DEFAULT 'INCORRECT_CHOICE';

CREATE INDEX IF NOT EXISTS idx_wrong_answers_error_type ON wrong_answer_records(error_type);
