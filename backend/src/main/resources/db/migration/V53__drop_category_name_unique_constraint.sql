-- Migration V53: Drop old global unique constraint on vocabulary_categories.category_name
-- In V48, DROP CONSTRAINT IF EXISTS vocabulary_categories_category_name_key was attempted,
-- but the constraint created by Hibernate was named "ukeab9wk57ansv8cpsnhbn5iewx".
-- This allows teachers to create custom classroom categories (e.g. "Animals") even if
-- a global category or another teacher already has a category with that name.

DO $$
DECLARE
    r RECORD;
BEGIN
    -- Drop any unique constraints on vocabulary_categories
    FOR r IN (
        SELECT conname
        FROM pg_constraint con
        JOIN pg_class rel ON rel.oid = con.conrelid
        JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
        WHERE rel.relname = 'vocabulary_categories'
          AND con.contype = 'u'
    ) LOOP
        EXECUTE 'ALTER TABLE vocabulary_categories DROP CONSTRAINT IF EXISTS ' || quote_ident(r.conname);
    END LOOP;
END $$;

ALTER TABLE vocabulary_categories DROP CONSTRAINT IF EXISTS ukeab9wk57ansv8cpsnhbn5iewx;
ALTER TABLE vocabulary_categories DROP CONSTRAINT IF EXISTS vocabulary_categories_category_name_key;
DROP INDEX IF EXISTS ukeab9wk57ansv8cpsnhbn5iewx;
DROP INDEX IF EXISTS vocabulary_categories_category_name_key;
