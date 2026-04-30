-- ============================================================
-- RS-041: Comprehensive RLS Policies — Sprint 2A
-- ============================================================
-- Idempotent: drops each policy before recreating it.
-- Safe to run multiple times.
-- Covers all 20 tables. Follows principle:
--   - Riders: own rows only (auth.uid() matches profile FK)
--   - Carrier admins: rows scoped to their carrier_id
--   - B2B network: hierarchy-scoped access
--   - Service-role only: carriers, audit_log
-- ============================================================

-- ============================================================
-- 1. ENABLE RLS on all public-facing tables
--    (safe to call even if already enabled)
-- ============================================================

ALTER TABLE profiles          ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicles          ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents         ENABLE ROW LEVEL SECURITY;
ALTER TABLE policies          ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments          ENABLE ROW LEVEL SECURITY;
ALTER TABLE claims            ENABLE ROW LEVEL SECURITY;
ALTER TABLE claim_evidence    ENABLE ROW LEVEL SECURITY;
ALTER TABLE policy_types      ENABLE ROW LEVEL SECURITY;
ALTER TABLE exchange_rates    ENABLE ROW LEVEL SECURITY;
ALTER TABLE brokers           ENABLE ROW LEVEL SECURITY;
ALTER TABLE promoters         ENABLE ROW LEVEL SECURITY;
ALTER TABLE points_of_sale    ENABLE ROW LEVEL SECURITY;
ALTER TABLE carrier_users     ENABLE ROW LEVEL SECURITY;
ALTER TABLE carriers          ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log         ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 2. PROFILES
-- ============================================================

DROP POLICY IF EXISTS "riders_select_own_profile"   ON profiles;
DROP POLICY IF EXISTS "riders_insert_own_profile"   ON profiles;
DROP POLICY IF EXISTS "riders_update_own_profile"   ON profiles;
DROP POLICY IF EXISTS "carrier_select_policy_profiles" ON profiles;
-- Legacy names from RS-007_05
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;

-- Rider: full ownership of own row
CREATE POLICY "riders_select_own_profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "riders_insert_own_profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "riders_update_own_profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Carrier admin: view profiles that have a policy with their carrier
CREATE POLICY "carrier_select_policy_profiles"
  ON profiles FOR SELECT
  USING (
    id IN (
      SELECT p.profile_id
      FROM policies p
      JOIN carrier_users cu ON cu.carrier_id = p.carrier_id
      WHERE cu.auth_user_id = auth.uid()
        AND cu.is_active = true
    )
  );

-- ============================================================
-- 3. VEHICLES
-- ============================================================

DROP POLICY IF EXISTS "riders_select_own_vehicle"   ON vehicles;
DROP POLICY IF EXISTS "riders_insert_own_vehicle"   ON vehicles;
DROP POLICY IF EXISTS "riders_update_own_vehicle"   ON vehicles;
DROP POLICY IF EXISTS "carrier_select_policy_vehicles" ON vehicles;

CREATE POLICY "riders_select_own_vehicle"
  ON vehicles FOR SELECT
  USING (auth.uid() = owner_id);

CREATE POLICY "riders_insert_own_vehicle"
  ON vehicles FOR INSERT
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "riders_update_own_vehicle"
  ON vehicles FOR UPDATE
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

-- Carrier admin: view vehicles associated with their carrier's policies
CREATE POLICY "carrier_select_policy_vehicles"
  ON vehicles FOR SELECT
  USING (
    id IN (
      SELECT p.vehicle_id
      FROM policies p
      JOIN carrier_users cu ON cu.carrier_id = p.carrier_id
      WHERE cu.auth_user_id = auth.uid()
        AND cu.is_active = true
    )
  );

-- ============================================================
-- 4. DOCUMENTS
-- ============================================================

DROP POLICY IF EXISTS "riders_select_own_documents"  ON documents;
DROP POLICY IF EXISTS "riders_insert_own_documents"  ON documents;
DROP POLICY IF EXISTS "carrier_select_policy_documents" ON documents;
-- Legacy
DROP POLICY IF EXISTS "Users can insert own documents" ON documents;

CREATE POLICY "riders_select_own_documents"
  ON documents FOR SELECT
  USING (auth.uid() = profile_id);

CREATE POLICY "riders_insert_own_documents"
  ON documents FOR INSERT
  WITH CHECK (auth.uid() = profile_id);

-- Carrier admin: view documents for riders with their carrier's policies
CREATE POLICY "carrier_select_policy_documents"
  ON documents FOR SELECT
  USING (
    profile_id IN (
      SELECT p.profile_id
      FROM policies p
      JOIN carrier_users cu ON cu.carrier_id = p.carrier_id
      WHERE cu.auth_user_id = auth.uid()
        AND cu.is_active = true
    )
  );

-- ============================================================
-- 5. POLICIES
-- ============================================================

DROP POLICY IF EXISTS "riders_select_own_policies"   ON policies;
DROP POLICY IF EXISTS "riders_insert_own_policies"   ON policies;
DROP POLICY IF EXISTS "carrier_select_own_policies"  ON policies;
DROP POLICY IF EXISTS "broker_select_own_policies"   ON policies;
-- Legacy
DROP POLICY IF EXISTS "Users can insert own policies" ON policies;

-- Rider: owns their policy rows
CREATE POLICY "riders_select_own_policies"
  ON policies FOR SELECT
  USING (auth.uid() = profile_id);

CREATE POLICY "riders_insert_own_policies"
  ON policies FOR INSERT
  WITH CHECK (auth.uid() = profile_id);

-- Carrier admin: all policies for their carrier
CREATE POLICY "carrier_select_own_policies"
  ON policies FOR SELECT
  USING (
    carrier_id IN (
      SELECT cu.carrier_id
      FROM carrier_users cu
      WHERE cu.auth_user_id = auth.uid()
        AND cu.is_active = true
    )
  );

-- Broker: policies they sold
CREATE POLICY "broker_select_own_policies"
  ON policies FOR SELECT
  USING (
    broker_id IN (
      SELECT b.id
      FROM brokers b
      WHERE b.auth_user_id = auth.uid()
        AND b.status = 'active'
    )
  );

-- ============================================================
-- 6. PAYMENTS
-- ============================================================

DROP POLICY IF EXISTS "riders_select_own_payments"   ON payments;
DROP POLICY IF EXISTS "riders_insert_own_payments"   ON payments;
DROP POLICY IF EXISTS "carrier_select_own_payments"  ON payments;
-- Legacy
DROP POLICY IF EXISTS "Users can insert own payments" ON payments;

CREATE POLICY "riders_select_own_payments"
  ON payments FOR SELECT
  USING (auth.uid() = profile_id);

CREATE POLICY "riders_insert_own_payments"
  ON payments FOR INSERT
  WITH CHECK (auth.uid() = profile_id);

-- Carrier admin: payments for their carrier's policies
CREATE POLICY "carrier_select_own_payments"
  ON payments FOR SELECT
  USING (
    policy_id IN (
      SELECT p.id
      FROM policies p
      JOIN carrier_users cu ON cu.carrier_id = p.carrier_id
      WHERE cu.auth_user_id = auth.uid()
        AND cu.is_active = true
    )
  );

-- ============================================================
-- 7. CLAIMS
-- ============================================================

DROP POLICY IF EXISTS "riders_select_own_claims"     ON claims;
DROP POLICY IF EXISTS "riders_insert_own_claims"     ON claims;
DROP POLICY IF EXISTS "carrier_select_own_claims"    ON claims;

CREATE POLICY "riders_select_own_claims"
  ON claims FOR SELECT
  USING (auth.uid() = profile_id);

CREATE POLICY "riders_insert_own_claims"
  ON claims FOR INSERT
  WITH CHECK (auth.uid() = profile_id);

-- Carrier admin: claims for their carrier's policies
CREATE POLICY "carrier_select_own_claims"
  ON claims FOR SELECT
  USING (
    policy_id IN (
      SELECT p.id
      FROM policies p
      JOIN carrier_users cu ON cu.carrier_id = p.carrier_id
      WHERE cu.auth_user_id = auth.uid()
        AND cu.is_active = true
    )
  );

-- ============================================================
-- 8. CLAIM EVIDENCE
-- ============================================================

DROP POLICY IF EXISTS "riders_select_own_claim_evidence" ON claim_evidence;
DROP POLICY IF EXISTS "riders_insert_own_claim_evidence" ON claim_evidence;
-- Legacy
DROP POLICY IF EXISTS "Users can insert own claim evidence" ON claim_evidence;

CREATE POLICY "riders_select_own_claim_evidence"
  ON claim_evidence FOR SELECT
  USING (
    claim_id IN (
      SELECT id FROM claims WHERE profile_id = auth.uid()
    )
  );

CREATE POLICY "riders_insert_own_claim_evidence"
  ON claim_evidence FOR INSERT
  WITH CHECK (
    claim_id IN (
      SELECT id FROM claims WHERE profile_id = auth.uid()
    )
  );

-- ============================================================
-- 9. POLICY_TYPES — public read for authenticated users
-- ============================================================

DROP POLICY IF EXISTS "authenticated_select_policy_types" ON policy_types;
DROP POLICY IF EXISTS "anon_select_active_policy_types"   ON policy_types;

-- Any authenticated user can read active policy types
CREATE POLICY "authenticated_select_policy_types"
  ON policy_types FOR SELECT
  USING (auth.role() = 'authenticated' AND is_active = true);

-- ============================================================
-- 10. EXCHANGE_RATES — public read (needed for quote screen before login)
-- ============================================================

DROP POLICY IF EXISTS "public_select_exchange_rates" ON exchange_rates;

CREATE POLICY "public_select_exchange_rates"
  ON exchange_rates FOR SELECT
  USING (true);  -- anon + authenticated

-- ============================================================
-- 11. BROKERS
-- ============================================================

DROP POLICY IF EXISTS "brokers_select_own_record"    ON brokers;
DROP POLICY IF EXISTS "carrier_select_own_brokers"   ON brokers;
-- Legacy
DROP POLICY IF EXISTS "Brokers can view own broker record" ON brokers;

CREATE POLICY "brokers_select_own_record"
  ON brokers FOR SELECT
  USING (auth.uid() = auth_user_id);

-- Carrier admin: see all brokers for their carrier
CREATE POLICY "carrier_select_own_brokers"
  ON brokers FOR SELECT
  USING (
    carrier_id IN (
      SELECT cu.carrier_id
      FROM carrier_users cu
      WHERE cu.auth_user_id = auth.uid()
        AND cu.is_active = true
    )
  );

-- ============================================================
-- 12. PROMOTERS
-- ============================================================

DROP POLICY IF EXISTS "promoters_select_own_record"     ON promoters;
DROP POLICY IF EXISTS "brokers_select_their_promoters"  ON promoters;
-- Legacy
DROP POLICY IF EXISTS "Promoters can view own record"        ON promoters;
DROP POLICY IF EXISTS "Brokers can view their promoters"     ON promoters;

CREATE POLICY "promoters_select_own_record"
  ON promoters FOR SELECT
  USING (auth.uid() = auth_user_id);

CREATE POLICY "brokers_select_their_promoters"
  ON promoters FOR SELECT
  USING (
    broker_id IN (
      SELECT id FROM brokers WHERE auth_user_id = auth.uid()
    )
  );

-- ============================================================
-- 13. POINTS OF SALE
-- ============================================================

DROP POLICY IF EXISTS "brokers_select_their_pos"  ON points_of_sale;
-- Legacy
DROP POLICY IF EXISTS "Brokers can view their points of sale" ON points_of_sale;

CREATE POLICY "brokers_select_their_pos"
  ON points_of_sale FOR SELECT
  USING (
    broker_id IN (
      SELECT id FROM brokers WHERE auth_user_id = auth.uid()
    )
  );

-- ============================================================
-- 14. CARRIER_USERS — users see their own carrier_user record
-- ============================================================

DROP POLICY IF EXISTS "carrier_users_select_own" ON carrier_users;

CREATE POLICY "carrier_users_select_own"
  ON carrier_users FOR SELECT
  USING (auth.uid() = auth_user_id AND is_active = true);

-- ============================================================
-- 15. CARRIERS — service_role only (no public policies)
--    Rider app reads carrier info via policy_types join.
--    No direct public access needed.
-- ============================================================
-- (No CREATE POLICY — service_role bypasses RLS)

-- ============================================================
-- 16. AUDIT_LOG — service_role only (append-only, no public read)
-- ============================================================
-- (No CREATE POLICY — service_role bypasses RLS)

-- ============================================================
-- 17. Metrics materialized view
-- ============================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS metrics_daily AS
SELECT
  DATE(created_at AT TIME ZONE 'America/Caracas') AS date,
  carrier_id,
  COUNT(*) FILTER (WHERE status IN ('active', 'pending_emission', 'pending_payment')) AS policies_issued,
  COUNT(*) FILTER (WHERE tier_info.tier = 'basica') AS basic_count,
  COUNT(*) FILTER (WHERE tier_info.tier = 'plus')   AS plus_count,
  COUNT(*) FILTER (WHERE tier_info.tier = 'ampliada') AS premium_count,
  SUM(price_usd)  AS gross_premium_usd,
  COUNT(DISTINCT broker_id) AS active_brokers
FROM policies
LEFT JOIN (
  SELECT id, tier FROM policy_types
) tier_info ON tier_info.id = policies.policy_type_id
-- NOTE: archived_at filter added after RS-047 runs
GROUP BY DATE(created_at AT TIME ZONE 'America/Caracas'), carrier_id;

-- Index for fast dashboard queries
CREATE UNIQUE INDEX IF NOT EXISTS metrics_daily_date_carrier
  ON metrics_daily (date, carrier_id);

-- Refresh function (call from Edge Function on a schedule)
CREATE OR REPLACE FUNCTION refresh_metrics_daily()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY metrics_daily;
END;
$$;

-- ============================================================
-- VERIFICATION QUERIES (run after applying to confirm)
-- ============================================================
-- SELECT schemaname, tablename, rowsecurity
--   FROM pg_tables
--   WHERE schemaname = 'public'
--   ORDER BY tablename;
--
-- SELECT schemaname, tablename, policyname, cmd, qual
--   FROM pg_policies
--   WHERE schemaname = 'public'
--   ORDER BY tablename, policyname;
