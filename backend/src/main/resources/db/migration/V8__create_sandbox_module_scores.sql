CREATE TABLE IF NOT EXISTS sandbox_module_scores (
  score_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES sandbox_sessions(session_id) ON DELETE CASCADE,
  module_number INTEGER NOT NULL CHECK (module_number BETWEEN 1 AND 3),
  correct INTEGER NOT NULL DEFAULT 0,
  total INTEGER NOT NULL DEFAULT 0,
  score NUMERIC(5,2) NOT NULL DEFAULT 0,
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(session_id, module_number)
);

ALTER TABLE sandbox_module_scores ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'sandbox_module_scores' 
        AND policyname = 'sandbox_module_scores_policy'
    ) THEN
        CREATE POLICY sandbox_module_scores_policy ON sandbox_module_scores
        FOR ALL USING (true);
    END IF;
END $$;
