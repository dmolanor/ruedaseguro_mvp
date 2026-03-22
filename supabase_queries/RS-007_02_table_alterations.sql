-- ============================================================
-- RS-007: Schema Migration v1 → v2 — Part 2: Table Alterations
-- ============================================================
-- Adds new columns to existing tables to match MVP_ARCHITECTURE v2.0.
-- Run AFTER RS-007_01_enum_updates.sql
-- ============================================================

-- ============================================================
-- CARRIERS — add required_documents configuration
-- ============================================================

ALTER TABLE carriers
  ADD COLUMN IF NOT EXISTS required_documents JSONB DEFAULT '["cedula","carnet_circulacion","vehicle_photo"]';

-- ============================================================
-- PROFILES — add address fields, nationality, sex, referral tracking
-- ============================================================

-- Rename v1 columns to v2 names (city → ciudad, state → estado, address → urbanizacion)
ALTER TABLE profiles RENAME COLUMN address TO urbanizacion;
ALTER TABLE profiles RENAME COLUMN city TO ciudad;
ALTER TABLE profiles RENAME COLUMN state TO estado;

-- Add new v2 columns
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS nationality TEXT,
  ADD COLUMN IF NOT EXISTS sex TEXT,                -- 'M', 'F' (from Cédula OCR)
  ADD COLUMN IF NOT EXISTS municipio TEXT,
  ADD COLUMN IF NOT EXISTS codigo_postal TEXT;

-- Referral tracking columns (added after promoters table exists — see RS-007_03)
-- These will be added in RS-007_04_post_b2b2c.sql

-- ============================================================
-- VEHICLES — add vehicle_use, rear_photo_url
-- ============================================================

ALTER TABLE vehicles
  ADD COLUMN IF NOT EXISTS vehicle_use TEXT DEFAULT 'particular',   -- 'particular', 'cargo'
  ADD COLUMN IF NOT EXISTS rear_photo_url TEXT;                      -- Rear photo with visible plate

-- ============================================================
-- POLICY_TYPES — add tier, coverage_details, payment_frequency, upsell_options, target_percentage
-- ============================================================

ALTER TABLE policy_types
  ADD COLUMN IF NOT EXISTS tier TEXT NOT NULL DEFAULT 'basica',            -- 'basica', 'plus', 'ampliada'
  ADD COLUMN IF NOT EXISTS coverage_details JSONB DEFAULT '{}',           -- { "danos_cosas": 5000, ... }
  ADD COLUMN IF NOT EXISTS payment_frequency TEXT DEFAULT 'annual',       -- 'annual', 'monthly'
  ADD COLUMN IF NOT EXISTS upsell_options JSONB DEFAULT '[]',             -- [{ "name": "Grúa", "price_usd": 5 }]
  ADD COLUMN IF NOT EXISTS target_percentage DECIMAL(5,2);                -- 70%, 30%, 5%

-- ============================================================
-- POLICIES — add B2B2C tracking, consent fields, emission response
-- ============================================================

-- Sales network tracking (broker_id/promoter_id FKs added in RS-007_04 after B2B2C tables exist)
ALTER TABLE policies
  ADD COLUMN IF NOT EXISTS point_of_sale_id UUID,
  ADD COLUMN IF NOT EXISTS referral_code TEXT,
  -- Selected upsells
  ADD COLUMN IF NOT EXISTS upsells JSONB DEFAULT '[]',
  -- Legal consent (SUDEASEG compliance)
  ADD COLUMN IF NOT EXISTS accepted_terms BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS accepted_data_truthfulness BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS accepted_antifraud BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS accepted_privacy BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS consent_timestamp TIMESTAMPTZ,
  -- Document URLs
  ADD COLUMN IF NOT EXISTS certificate_url TEXT,
  -- Emission response from carrier
  ADD COLUMN IF NOT EXISTS emission_response JSONB,
  ADD COLUMN IF NOT EXISTS emission_notes TEXT;

-- ============================================================
-- PAYMENTS — add method enum column, receipt_url
-- ============================================================

-- v1 has `payment_method TEXT` — v2 uses `method payment_method` (enum)
-- Strategy: add the new enum column, migrate data, drop old column

ALTER TABLE payments
  ADD COLUMN IF NOT EXISTS method payment_method NOT NULL DEFAULT 'pago_movil_p2p',
  ADD COLUMN IF NOT EXISTS receipt_url TEXT;

-- Migrate existing data from payment_method (TEXT) to method (enum)
UPDATE payments SET method = payment_method::payment_method WHERE payment_method IS NOT NULL;

-- Drop the old TEXT column
ALTER TABLE payments DROP COLUMN IF EXISTS payment_method;

-- ============================================================
-- CLAIMS — add oracle validation and triage fields
-- ============================================================

ALTER TABLE claims
  ADD COLUMN IF NOT EXISTS oracle_validated BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS oracle_validation_token TEXT,
  ADD COLUMN IF NOT EXISTS oracle_validated_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS oracle_provider TEXT,                 -- 'venemergencia', 'nueve_once', 'angeles'
  ADD COLUMN IF NOT EXISTS triage_level TEXT;                    -- 'emergencia', 'urgencia', 'leve'

-- ============================================================
-- DOCUMENTS — add anti-fraud metadata
-- ============================================================

ALTER TABLE documents
  ADD COLUMN IF NOT EXISTS sharpness_score REAL,
  ADD COLUMN IF NOT EXISTS is_screen_photo BOOLEAN DEFAULT false;
