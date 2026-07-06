-- V9: Add admin security tables and modify admins table
-- Adds: refresh_tokens, admin_audit_logs, and new columns on admins

-- ──────────────────────────────────────────────────────────
-- 1. Extend admins table with account management fields
-- ──────────────────────────────────────────────────────────
ALTER TABLE admins
    ADD COLUMN IF NOT EXISTS school_id UUID NULL,
    ADD COLUMN IF NOT EXISTS password_reset_token TEXT NULL,
    ADD COLUMN IF NOT EXISTS password_reset_expiry TIMESTAMPTZ NULL,
    ADD COLUMN IF NOT EXISTS must_change_password BOOLEAN NOT NULL DEFAULT false;

-- ──────────────────────────────────────────────────────────
-- 2. refresh_tokens — stores hashed refresh tokens for learners (and future admin refresh)
-- ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS refresh_tokens (
    token_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL,           -- learner_id or admin_id (no FK — flexible)
    token_hash  TEXT NOT NULL,           -- BCrypt hash of the raw token
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at  TIMESTAMPTZ NOT NULL,
    revoked_at  TIMESTAMPTZ NULL
);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id   ON refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_token_hash ON refresh_tokens(token_hash);

ALTER TABLE refresh_tokens ENABLE ROW LEVEL SECURITY;
CREATE POLICY refresh_tokens_policy ON refresh_tokens FOR ALL USING (true);

-- ──────────────────────────────────────────────────────────
-- 3. admin_audit_logs — append-only log of admin actions
-- ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS admin_audit_logs (
    audit_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id    UUID NOT NULL REFERENCES admins(admin_id) ON DELETE CASCADE,
    action      VARCHAR(100) NOT NULL,   -- e.g. CREATE_ADMIN, DISABLE_ADMIN, RESET_PASSWORD
    target_id   UUID NULL,               -- the affected entity UUID (another admin, learner, etc.)
    details     TEXT NULL,               -- JSON or plain text extra context
    timestamp   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_admin_id  ON admin_audit_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_timestamp ON admin_audit_logs(timestamp DESC);

ALTER TABLE admin_audit_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY audit_logs_policy ON admin_audit_logs FOR ALL USING (true);
