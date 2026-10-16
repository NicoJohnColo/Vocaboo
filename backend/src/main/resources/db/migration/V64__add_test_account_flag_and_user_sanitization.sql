-- V64: Add is_test_account flag to learners and backfill test accounts identified during MVP validation

ALTER TABLE learners ADD COLUMN IF NOT EXISTS is_test_account BOOLEAN NOT NULL DEFAULT FALSE;

UPDATE learners
SET is_test_account = TRUE
WHERE display_name ILIKE ANY (ARRAY['%tin%', '%aaaa%', '%test%', '%grade4test%']);

CREATE INDEX IF NOT EXISTS idx_learners_is_test_account ON learners(is_test_account);
