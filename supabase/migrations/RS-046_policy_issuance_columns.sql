-- ============================================================
-- RS-046: Policy Issuance Columns — Sprint 2A
-- ============================================================
-- Adds columns required for the dual-channel issuance state
-- machine (real-time API → provisional fallback).
-- Also adds payment verification columns.
-- All idempotent (ADD COLUMN IF NOT EXISTS).
-- ============================================================

-- ============================================================
-- 1. POLICIES — issuance state machine
-- ============================================================

-- Add issuance_status enum
DO $$ BEGIN
  CREATE TYPE issuance_status AS ENUM (
    'pending',       -- Payment confirmed, carrier API not yet called
    'api_submitted', -- API call in flight or recently returned
    'confirmed',     -- Carrier returned a valid policy_number
    'provisional',   -- API failed; provisional PDF issued; retrying
    'rejected'       -- Carrier rejected; refund triggered
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

ALTER TABLE policies
  ADD COLUMN IF NOT EXISTS issuance_status   issuance_status NOT NULL DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS carrier_policy_number TEXT,          -- From Acsel/Sirway
  ADD COLUMN IF NOT EXISTS carrier_api_attempts  INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS provisional_issued_at TIMESTAMPTZ,  -- When provisional PDF sent
  ADD COLUMN IF NOT EXISTS confirmed_at          TIMESTAMPTZ;  -- When carrier confirmed

-- Index for retry queue (find provisionals that need re-attempt)
CREATE INDEX IF NOT EXISTS idx_policies_issuance_status
  ON policies (issuance_status, carrier_api_attempts)
  WHERE issuance_status IN ('pending', 'provisional');

-- ============================================================
-- 2. PAYMENTS — manual verification workflow
-- ============================================================

ALTER TABLE payments
  ADD COLUMN IF NOT EXISTS pago_movil_reference TEXT,     -- 8–15 digit bank reference
  ADD COLUMN IF NOT EXISTS pago_movil_bank_code  TEXT,    -- 4-digit bank code (e.g. '0134')
  ADD COLUMN IF NOT EXISTS verified_by_email     TEXT,    -- Agent who verified (email, not UUID)
  ADD COLUMN IF NOT EXISTS rejection_reason      TEXT;    -- Why it was rejected (if applicable)

-- NOTE: verified_by (UUID) and verified_at (TIMESTAMPTZ) already exist from v1 schema.
-- pago_movil_reference stores the reference number the rider enters after transferring.

-- ============================================================
-- 3. CARRIER_USERS — role hierarchy
-- ============================================================

-- Ensure carrier_users has an 'editor' role value for
-- agents who can verify payments (not just 'viewer')
-- The role column is TEXT so no enum change needed.
-- Roles: 'admin' | 'editor' | 'viewer'
-- (no migration required — existing TEXT column is flexible)

-- ============================================================
-- VERIFICATION QUERIES
-- ============================================================
-- \d policies
-- SELECT column_name, data_type, column_default
--   FROM information_schema.columns
--   WHERE table_name = 'policies'
--     AND column_name IN (
--       'issuance_status','carrier_policy_number',
--       'carrier_api_attempts','provisional_issued_at','confirmed_at'
--     );
--
-- SELECT column_name, data_type
--   FROM information_schema.columns
--   WHERE table_name = 'payments'
--     AND column_name IN (
--       'pago_movil_reference','pago_movil_bank_code','verified_by_email'
--     );
