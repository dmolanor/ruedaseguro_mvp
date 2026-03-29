-- ============================================================
-- RS-007: Schema Migration v1 → v2 — Part 6: Functions & Indexes
-- ============================================================
-- Adds generate_referral_code, handle_updated_at trigger,
-- and performance indexes.
-- Run AFTER RS-007_05
-- ============================================================

-- ============================================================
-- FUNCTION: generate_referral_code
-- ============================================================

CREATE OR REPLACE FUNCTION generate_referral_code(p_promoter_name TEXT)
RETURNS TEXT AS $$
DECLARE
  name_prefix TEXT;
  random_suffix TEXT;
BEGIN
  name_prefix := UPPER(LEFT(REGEXP_REPLACE(p_promoter_name, '[^a-zA-Z]', '', 'g'), 4));
  random_suffix := LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');
  RETURN 'RS-' || name_prefix || '-' || random_suffix;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- FUNCTION: handle_updated_at trigger
-- ============================================================

CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach trigger to all tables with updated_at column
CREATE TRIGGER set_updated_at BEFORE UPDATE ON carriers
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON vehicles
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON policy_types
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON policies
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON payments
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON claims
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON brokers
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON promoters
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

-- ============================================================
-- INDEXES for v2 performance
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_policies_carrier ON policies(carrier_id);
CREATE INDEX IF NOT EXISTS idx_policies_broker ON policies(broker_id);
CREATE INDEX IF NOT EXISTS idx_policies_promoter ON policies(promoter_id);
CREATE INDEX IF NOT EXISTS idx_policies_status ON policies(status);
CREATE INDEX IF NOT EXISTS idx_policies_profile ON policies(profile_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_promoters_broker ON promoters(broker_id);
CREATE INDEX IF NOT EXISTS idx_promoters_referral ON promoters(referral_code);
CREATE INDEX IF NOT EXISTS idx_profiles_referred ON profiles(referred_by_promoter);
