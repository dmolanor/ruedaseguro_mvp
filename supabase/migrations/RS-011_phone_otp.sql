-- ============================================================
-- RS-011: Custom WhatsApp OTP Tables
-- ============================================================
-- Bypasses Supabase built-in phone auth (requires Twilio etc.)
-- Uses Meta WhatsApp Business Cloud API via Edge Functions instead.
-- Run AFTER RS-010 seed data.
-- ============================================================

-- OTP challenge storage (10-minute TTL, max 5 attempts)
CREATE TABLE IF NOT EXISTS phone_verifications (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  phone       TEXT        NOT NULL,
  otp_hash    TEXT        NOT NULL,     -- SHA-256(otp || salt)
  salt        TEXT        NOT NULL,
  attempts    INT         NOT NULL DEFAULT 0,
  verified    BOOLEAN     NOT NULL DEFAULT false,
  expires_at  TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '10 minutes'),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Fast lookup: phone number → auth.users.id
-- Populated by verify-otp Edge Function on first successful verification.
CREATE TABLE IF NOT EXISTS user_phones (
  phone    TEXT PRIMARY KEY,
  user_id  UUID NOT NULL    -- references auth.users(id) — not FK to avoid cross-schema issues
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_phone_verifications_phone   ON phone_verifications(phone);
CREATE INDEX IF NOT EXISTS idx_phone_verifications_expires ON phone_verifications(expires_at)
  WHERE verified = false;

-- RLS: enabled, no public policies — only service_role key (Edge Functions) can access
ALTER TABLE phone_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_phones         ENABLE ROW LEVEL SECURITY;

-- Auto-delete expired verifications (keep table lean)
-- Run via pg_cron or manually:
-- DELETE FROM phone_verifications WHERE expires_at < now() - INTERVAL '1 day';
