-- V68: Add distinction_explanation to confusable_word_pairs for teaching contrast notes

ALTER TABLE confusable_word_pairs
    ADD COLUMN IF NOT EXISTS distinction_explanation TEXT;
