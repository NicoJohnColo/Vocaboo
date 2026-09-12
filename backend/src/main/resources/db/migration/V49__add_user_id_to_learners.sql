-- V49: Add structured user_id (format XX-XXXX-XXX) to learners table and backfill existing learners

ALTER TABLE learners ADD COLUMN IF NOT EXISTS user_id VARCHAR(11);

DO $$
DECLARE
    r RECORD;
    v_num INT := 1;
    v_prefix VARCHAR(2);
    v_mid VARCHAR(4);
    v_suffix VARCHAR(3);
    v_uid VARCHAR(11);
BEGIN
    FOR r IN SELECT learner_id, created_at FROM learners WHERE user_id IS NULL ORDER BY created_at ASC NULLS LAST, learner_id ASC LOOP
        IF r.created_at IS NOT NULL THEN
            v_prefix := to_char(r.created_at, 'YY');
        ELSE
            v_prefix := '26';
        END IF;

        v_mid := lpad((v_num % 10000)::text, 4, '0');
        v_suffix := lpad((floor(random() * 900 + 100))::text, 3, '0');
        v_uid := v_prefix || '-' || v_mid || '-' || v_suffix;

        WHILE EXISTS (SELECT 1 FROM learners WHERE user_id = v_uid) LOOP
            v_suffix := lpad((floor(random() * 900 + 100))::text, 3, '0');
            v_uid := v_prefix || '-' || v_mid || '-' || v_suffix;
        END LOOP;

        UPDATE learners SET user_id = v_uid WHERE learner_id = r.learner_id;
        v_num := v_num + 1;
    END LOOP;
END $$;

ALTER TABLE learners ALTER COLUMN user_id SET NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uq_learners_user_id'
    ) THEN
        ALTER TABLE learners ADD CONSTRAINT uq_learners_user_id UNIQUE (user_id);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_learners_user_id ON learners(user_id);
