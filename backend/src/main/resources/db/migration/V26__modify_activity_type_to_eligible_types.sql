-- V26__modify_activity_type_to_eligible_types.sql
-- Adds eligible_activity_types column and sets default value for existing records

ALTER TABLE vocabulary_words 
    ADD COLUMN eligible_activity_types VARCHAR(255) NOT NULL DEFAULT 'MULTIPLE_CHOICE;FILL_IN_BLANK;MATCHING;WORD_SCRAMBLE;TRUE_OR_FALSE';

-- Update existing records to have the full pool of activities (excluding SENTENCE_ARRANGEMENT)
UPDATE vocabulary_words 
SET eligible_activity_types = 'MULTIPLE_CHOICE;FILL_IN_BLANK;MATCHING;WORD_SCRAMBLE;TRUE_OR_FALSE'
WHERE eligible_activity_types IS NOT NULL;
