-- ══════════════════════════════════════════════════════════════════════════
-- V11 — Phase 2: Lesson & Vocabulary Admin Management Schema Additions
-- ══════════════════════════════════════════════════════════════════════════

-- ── Lesson: admin content management columns ───────────────────────────────
ALTER TABLE lessons
    ADD COLUMN IF NOT EXISTS is_deleted        BOOLEAN     NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS content_status    VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    ADD COLUMN IF NOT EXISTS published_date    TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS published_by_admin_id UUID,
    ADD COLUMN IF NOT EXISTS target_grades     TEXT;

-- ── VocabularyWord: soft delete + asset verification ───────────────────────
ALTER TABLE vocabulary_words
    ADD COLUMN IF NOT EXISTS is_deleted     BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS audio_verified BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS image_verified BOOLEAN NOT NULL DEFAULT FALSE;

-- ── AssetUpload: tracks uploaded audio / image files ──────────────────────
CREATE TABLE IF NOT EXISTS asset_uploads (
    asset_id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    lesson_id           UUID        REFERENCES lessons(lesson_id) ON DELETE SET NULL,
    word_id             UUID        REFERENCES vocabulary_words(word_id) ON DELETE SET NULL,
    asset_type          VARCHAR(10) NOT NULL CHECK (asset_type IN ('AUDIO', 'IMAGE')),
    original_filename   TEXT        NOT NULL,
    cdn_url             TEXT        NOT NULL,
    file_size_kb        INTEGER,
    upload_date         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    uploaded_by_admin_id UUID
);

-- ── BulkImportHistory: tracks CSV vocabulary import jobs ──────────────────
CREATE TABLE IF NOT EXISTS bulk_import_history (
    import_id       UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    lesson_id       UUID        NOT NULL REFERENCES lessons(lesson_id) ON DELETE CASCADE,
    admin_id        UUID        NOT NULL,
    total_rows      INTEGER     NOT NULL DEFAULT 0,
    success_count   INTEGER     NOT NULL DEFAULT 0,
    error_count     INTEGER     NOT NULL DEFAULT 0,
    skipped_count   INTEGER     NOT NULL DEFAULT 0,
    import_date     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    import_status   VARCHAR(10) NOT NULL DEFAULT 'SUCCESS' CHECK (import_status IN ('SUCCESS', 'PARTIAL', 'FAILED')),
    error_log       TEXT
);

-- ── Indexes for performance ────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_lessons_is_deleted        ON lessons(is_deleted);
CREATE INDEX IF NOT EXISTS idx_lessons_content_status    ON lessons(content_status);
CREATE INDEX IF NOT EXISTS idx_vocab_words_is_deleted    ON vocabulary_words(is_deleted);
CREATE INDEX IF NOT EXISTS idx_asset_uploads_lesson      ON asset_uploads(lesson_id);
CREATE INDEX IF NOT EXISTS idx_asset_uploads_word        ON asset_uploads(word_id);
CREATE INDEX IF NOT EXISTS idx_bulk_import_lesson        ON bulk_import_history(lesson_id);
