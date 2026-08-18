-- Drop the old unique constraint (uk_learner_word or whatever the system named it)
-- Since it might have a generated name in some databases, we explicitly drop it if it exists.
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM pg_constraint 
        WHERE conname = 'uk_learner_word' 
        AND conrelid = 'difficulty_progress'::regclass
    ) THEN
        ALTER TABLE difficulty_progress DROP CONSTRAINT uk_learner_word;
    END IF;
    
    -- Some earlier migrations might have created it as uniqueconstraints
    IF EXISTS (
        SELECT 1 
        FROM pg_constraint 
        WHERE conname = 'difficulty_progress_learner_id_word_id_key' 
        AND conrelid = 'difficulty_progress'::regclass
    ) THEN
        ALTER TABLE difficulty_progress DROP CONSTRAINT difficulty_progress_learner_id_word_id_key;
    END IF;
END $$;

-- Add module_number column, defaulting existing records to Module 2 (Active Practice)
ALTER TABLE difficulty_progress 
ADD COLUMN module_number INT NOT NULL DEFAULT 2;

-- Add the new composite unique constraint
ALTER TABLE difficulty_progress 
ADD CONSTRAINT uk_learner_word_module UNIQUE (learner_id, word_id, module_number);
