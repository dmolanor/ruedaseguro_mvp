-- ============================================================
-- RS-047: Data Lifecycle Columns — Sprint 2A
-- ============================================================
-- Adds archived_at and retain_until to all tables that hold
-- retention-sensitive data per SUDEASEG / SENIAT requirements.
-- All idempotent (ADD COLUMN IF NOT EXISTS).
--
-- Retention policy:
--   policies / payments / claims : 7 years (civil code + SENIAT)
--   documents                    : 1 year after policy expiry
--   profiles                     : while active + 7 years
--   audit_log                    : indefinite (never delete)
--   tickets                      : 3 years
--   telemetry_events impact       : 5 years (done in RS-045 as GENERATED)
-- ============================================================

-- ============================================================
-- 1. POLICIES
-- ============================================================

ALTER TABLE policies
  ADD COLUMN IF NOT EXISTS archived_at  TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS retain_until DATE;

-- Partial index: fast lookup of non-archived active policies
CREATE INDEX IF NOT EXISTS idx_policies_live
  ON policies (profile_id, coverage_end)
  WHERE archived_at IS NULL;

-- ============================================================
-- 2. PAYMENTS
-- ============================================================

ALTER TABLE payments
  ADD COLUMN IF NOT EXISTS archived_at  TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS retain_until DATE;

-- ============================================================
-- 3. CLAIMS
-- ============================================================

ALTER TABLE claims
  ADD COLUMN IF NOT EXISTS archived_at  TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS retain_until DATE;

-- ============================================================
-- 4. DOCUMENTS
-- ============================================================

ALTER TABLE documents
  ADD COLUMN IF NOT EXISTS archived_at  TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS retain_until DATE;

-- ============================================================
-- 5. PROFILES
-- ============================================================

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS archived_at  TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS retain_until DATE;

-- ============================================================
-- 6. TICKETS (already has archived_at from RS-045 GENERATED)
--    retain_until was GENERATED in RS-045 — no change needed.
-- ============================================================

-- ============================================================
-- 7. AUDIT_LOG — no retain_until (indefinite, never archived)
-- ============================================================

-- (intentionally omitted — audit_log is append-only forever)

-- ============================================================
-- 8. FUNCTION: set_retain_until
--    Call on INSERT to auto-populate retain_until based on
--    the table's retention policy.
-- ============================================================

CREATE OR REPLACE FUNCTION set_policy_retain_until()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  -- 7 years from issuance
  IF NEW.retain_until IS NULL THEN
    NEW.retain_until := (NEW.created_at + INTERVAL '7 years')::DATE;
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION set_payment_retain_until()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.retain_until IS NULL THEN
    NEW.retain_until := (NEW.created_at + INTERVAL '7 years')::DATE;
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION set_claim_retain_until()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.retain_until IS NULL THEN
    NEW.retain_until := (NEW.created_at + INTERVAL '7 years')::DATE;
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION set_document_retain_until()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.retain_until IS NULL THEN
    -- 1 year after created; can be extended when linked policy is active
    NEW.retain_until := (NEW.created_at + INTERVAL '1 year')::DATE;
  END IF;
  RETURN NEW;
END;
$$;

-- Attach triggers (DROP first to allow re-run)
DROP TRIGGER IF EXISTS trg_policy_retain_until   ON policies;
DROP TRIGGER IF EXISTS trg_payment_retain_until  ON payments;
DROP TRIGGER IF EXISTS trg_claim_retain_until    ON claims;
DROP TRIGGER IF EXISTS trg_document_retain_until ON documents;

CREATE TRIGGER trg_policy_retain_until
  BEFORE INSERT ON policies
  FOR EACH ROW EXECUTE FUNCTION set_policy_retain_until();

CREATE TRIGGER trg_payment_retain_until
  BEFORE INSERT ON payments
  FOR EACH ROW EXECUTE FUNCTION set_payment_retain_until();

CREATE TRIGGER trg_claim_retain_until
  BEFORE INSERT ON claims
  FOR EACH ROW EXECUTE FUNCTION set_claim_retain_until();

CREATE TRIGGER trg_document_retain_until
  BEFORE INSERT ON documents
  FOR EACH ROW EXECUTE FUNCTION set_document_retain_until();

-- ============================================================
-- 9. Update metrics_daily view to exclude archived rows
--    (now that archived_at exists on policies)
-- ============================================================

DROP MATERIALIZED VIEW IF EXISTS metrics_daily;

CREATE MATERIALIZED VIEW metrics_daily AS
SELECT
  DATE(p.created_at AT TIME ZONE 'America/Caracas') AS date,
  p.carrier_id,
  COUNT(*)                                              AS policies_issued,
  COUNT(*) FILTER (WHERE pt.tier = 'basica')            AS basic_count,
  COUNT(*) FILTER (WHERE pt.tier = 'plus')              AS plus_count,
  COUNT(*) FILTER (WHERE pt.tier = 'ampliada')          AS premium_count,
  SUM(p.price_usd)                                      AS gross_premium_usd,
  COUNT(DISTINCT p.broker_id)                           AS active_brokers
FROM policies p
LEFT JOIN policy_types pt ON pt.id = p.policy_type_id
WHERE p.archived_at IS NULL
GROUP BY DATE(p.created_at AT TIME ZONE 'America/Caracas'), p.carrier_id;

CREATE UNIQUE INDEX IF NOT EXISTS metrics_daily_date_carrier
  ON metrics_daily (date, carrier_id);

-- ============================================================
-- VERIFICATION QUERIES
-- ============================================================
-- SELECT table_name, column_name
--   FROM information_schema.columns
--   WHERE column_name IN ('archived_at','retain_until')
--     AND table_schema = 'public'
--   ORDER BY table_name;
