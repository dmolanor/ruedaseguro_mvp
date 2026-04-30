-- ============================================================
-- RS-007: Schema Migration v1 → v2 — Part 5: Additional RLS Policies
-- ============================================================
-- Adds INSERT policies for rider tables, enables RLS on B2B2C
-- tables, and adds broker/promoter access policies.
-- Run AFTER RS-007_04
-- ============================================================

-- ============================================================
-- ENABLE RLS ON B2B2C TABLES
-- ============================================================

ALTER TABLE brokers ENABLE ROW LEVEL SECURITY;
ALTER TABLE promoters ENABLE ROW LEVEL SECURITY;
ALTER TABLE points_of_sale ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- RIDER INSERT POLICIES (missing from v1)
-- ============================================================

-- Riders can create their own profile
CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Riders can create policies (draft)
CREATE POLICY "Users can insert own policies"
  ON policies FOR INSERT WITH CHECK (auth.uid() = profile_id);

-- Riders can submit payments
CREATE POLICY "Users can insert own payments"
  ON payments FOR INSERT WITH CHECK (auth.uid() = profile_id);

-- Riders can upload documents
CREATE POLICY "Users can insert own documents"
  ON documents FOR INSERT WITH CHECK (auth.uid() = profile_id);

-- Riders can upload claim evidence
CREATE POLICY "Users can insert own claim evidence"
  ON claim_evidence FOR INSERT
  WITH CHECK (claim_id IN (SELECT id FROM claims WHERE profile_id = auth.uid()));

-- ============================================================
-- BROKER RLS POLICIES
-- ============================================================

-- Brokers can view their own broker record
CREATE POLICY "Brokers can view own broker record"
  ON brokers FOR SELECT USING (auth.uid() = auth_user_id);

-- Brokers can view their promoters
CREATE POLICY "Brokers can view their promoters"
  ON promoters FOR SELECT
  USING (broker_id IN (SELECT id FROM brokers WHERE auth_user_id = auth.uid()));

-- ============================================================
-- PROMOTER RLS POLICIES
-- ============================================================

-- Promoters can see their own record
CREATE POLICY "Promoters can view own record"
  ON promoters FOR SELECT USING (auth.uid() = auth_user_id);

-- ============================================================
-- POINTS OF SALE RLS POLICIES
-- ============================================================

-- Brokers can view their points of sale
CREATE POLICY "Brokers can view their points of sale"
  ON points_of_sale FOR SELECT
  USING (broker_id IN (SELECT id FROM brokers WHERE auth_user_id = auth.uid()));
