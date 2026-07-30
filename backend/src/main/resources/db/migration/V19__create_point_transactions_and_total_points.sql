-- Vocaboo Schema Migration V19 - Create Point Transactions and Total Points
CREATE TABLE IF NOT EXISTS point_transactions (
  transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  learner_id UUID NOT NULL REFERENCES learners(learner_id) ON DELETE CASCADE,
  action_type VARCHAR(50) NOT NULL,
  points_awarded INTEGER NOT NULL,
  related_session_id UUID NULL,
  related_word_id UUID REFERENCES vocabulary_words(word_id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add total_points to learner_mastery
ALTER TABLE learner_mastery ADD COLUMN IF NOT EXISTS total_points INTEGER NOT NULL DEFAULT 0;
