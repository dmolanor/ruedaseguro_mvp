-- ============================================================
-- RS-067: Claims Table Enhancements — Sprint 3
-- ============================================================
-- Adds columns needed by the real ClaimRepository.
-- All idempotent (ADD COLUMN IF NOT EXISTS).
-- Run after the base claims table exists (created in RS-007).
-- ============================================================

-- ── claims ─────────────────────────────────────────────────────────
-- Live table already has: claim_number, incident_date, incident_address,
-- incident_description, archived_at, retain_until.
-- We only add the two truly new columns.

ALTER TABLE claims
  ADD COLUMN IF NOT EXISTS incident_type  TEXT,
  -- 'colision' | 'dano_tercero' | 'robo' | 'lesiones'
  ADD COLUMN IF NOT EXISTS has_injuries   BOOLEAN NOT NULL DEFAULT false;

-- Trigger: set retain_until = created_at + 7 years (for new rows going forward)
-- retain_until column already exists — trigger backfills new inserts only.
CREATE OR REPLACE FUNCTION _set_claim_retain_until()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.retain_until IS NULL THEN
    NEW.retain_until := (NEW.created_at AT TIME ZONE 'UTC' + INTERVAL '7 years')::DATE;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_claim_retain_until ON claims;
CREATE TRIGGER trg_claim_retain_until
  BEFORE INSERT ON claims
  FOR EACH ROW EXECUTE FUNCTION _set_claim_retain_until();

CREATE INDEX IF NOT EXISTS idx_claims_profile
  ON claims (profile_id, created_at DESC)
  WHERE archived_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_claims_policy
  ON claims (policy_id)
  WHERE policy_id IS NOT NULL;

-- ── claim_evidence ──────────────────────────────────────────────────
-- Live table already has: id, claim_id, file_url, file_type, description, uploaded_at.
-- No column additions needed — ClaimRepository uses file_type (not evidence_type)
-- and file_url (already present).

-- ============================================================
-- VERIFICATION
-- ============================================================
-- SELECT column_name, data_type
--   FROM information_schema.columns
--   WHERE table_name = 'claims'
--     AND column_name IN (
--       'claim_number','incident_type','location',
--       'has_injuries','incident_at','retain_until'
--     );
