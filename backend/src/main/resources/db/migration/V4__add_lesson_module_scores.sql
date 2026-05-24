-- Add per-module lesson score persistence

CREATE TABLE IF NOT EXISTS lesson_module_scores (
  score_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  learner_id UUID NOT NULL,
  lesson_id UUID NOT NULL,
  module_number INTEGER NOT NULL CHECK (module_number BETWEEN 1 AND 3),
  correct_count INTEGER NOT NULL DEFAULT 0,
  total_count INTEGER NOT NULL DEFAULT 0,
  score NUMERIC(5,2) NOT NULL DEFAULT 0,
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(learner_id, lesson_id, module_number)
);

ALTER TABLE lesson_module_scores ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'lesson_module_scores' 
        AND policyname = 'lesson_module_scores_learner_policy'
    ) THEN
        CREATE POLICY lesson_module_scores_learner_policy ON lesson_module_scores
        FOR ALL USING (true);
    END IF;
END $$;