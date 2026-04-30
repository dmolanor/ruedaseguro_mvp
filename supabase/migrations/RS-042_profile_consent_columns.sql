-- ============================================================
-- RS-042: Add consent columns to profiles table
-- ============================================================
-- SUDEASEG requires proof of rider consent at the profile level,
-- not only at the policy level. These columns store the consents
-- given during onboarding (before any policy is issued).
-- All idempotent (ADD COLUMN IF NOT EXISTS).
-- ============================================================

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS consent_rcv          BOOLEAN     NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS consent_veracidad    BOOLEAN     NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS consent_antifraude   BOOLEAN     NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS consent_privacidad   BOOLEAN     NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS consent_timestamp    TIMESTAMPTZ;

-- A profile is "fully consented" when all four flags are true.
-- The app enforces this before allowing policy purchase.
CREATE INDEX IF NOT EXISTS idx_profiles_consented
  ON profiles (id)
  WHERE consent_rcv = true
    AND consent_veracidad = true
    AND consent_antifraude = true
    AND consent_privacidad = true;

-- ============================================================
-- VERIFICATION
-- ============================================================
-- SELECT column_name, data_type, column_default
--   FROM information_schema.columns
--   WHERE table_name = 'profiles'
--     AND column_name LIKE 'consent_%'
--   ORDER BY column_name;
