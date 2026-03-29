-- ============================================================
-- RS-007: Schema Migration v1 → v2 — Part 4: Foreign Keys to B2B2C Tables
-- ============================================================
-- Adds FK columns that reference brokers/promoters tables.
-- Run AFTER RS-007_03_b2b2c_network.sql
-- ============================================================

-- ============================================================
-- PROFILES — referral tracking FKs
-- ============================================================

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS referred_by_promoter UUID REFERENCES promoters(id),
  ADD COLUMN IF NOT EXISTS referred_by_code TEXT;

-- ============================================================
-- POLICIES — sales network FKs
-- ============================================================

ALTER TABLE policies
  ADD COLUMN IF NOT EXISTS broker_id UUID REFERENCES brokers(id),
  ADD COLUMN IF NOT EXISTS promoter_id UUID REFERENCES promoters(id);

-- Add FK constraint for point_of_sale_id (column already added in RS-007_02)
ALTER TABLE policies
  ADD CONSTRAINT fk_policies_point_of_sale
  FOREIGN KEY (point_of_sale_id) REFERENCES points_of_sale(id);
