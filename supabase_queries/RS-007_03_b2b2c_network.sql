-- ============================================================
-- RS-007: Schema Migration v1 → v2 — Part 3: B2B2C Network Tables
-- ============================================================
-- Creates brokers, promoters, and points_of_sale tables.
-- Run AFTER RS-007_01 and RS-007_02
-- ============================================================

-- ============================================================
-- BROKERS (Corredores de Seguros — Insurance Brokers)
-- ============================================================

CREATE TABLE IF NOT EXISTS brokers (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_user_id    UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  carrier_id      UUID REFERENCES carriers(id) ON DELETE CASCADE,
  -- Broker identity
  full_name       TEXT NOT NULL,
  rif             TEXT,                              -- Broker's RIF
  email           TEXT NOT NULL,
  phone           TEXT NOT NULL,
  -- Quota and performance
  policy_quota    INTEGER DEFAULT 800,               -- Target policies per broker
  status          broker_status DEFAULT 'active',
  -- Commission configuration (per carrier agreement)
  commission_rate DECIMAL(5,4) DEFAULT 0.25,         -- 25% default
  -- Metadata
  config          JSONB DEFAULT '{}',
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- PROMOTERS (Promotores — Motorized Sales Allies)
-- ============================================================

CREATE TABLE IF NOT EXISTS promoters (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_user_id    UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  broker_id       UUID REFERENCES brokers(id) ON DELETE CASCADE,
  -- Promoter identity
  full_name       TEXT NOT NULL,
  id_number       TEXT NOT NULL,                     -- Cédula
  phone           TEXT NOT NULL,
  email           TEXT,
  -- Referral tracking
  referral_code   TEXT UNIQUE NOT NULL,              -- Unique code for tracking sales
  status          promoter_status DEFAULT 'active',
  -- Metadata
  config          JSONB DEFAULT '{}',
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- POINTS OF SALE (Physical locations — gas stations, workshops)
-- ============================================================

CREATE TABLE IF NOT EXISTS points_of_sale (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  broker_id       UUID REFERENCES brokers(id),
  name            TEXT NOT NULL,                     -- e.g., "Estación Caracas Centro"
  type            TEXT NOT NULL,                     -- 'gas_station', 'workshop', 'parts_shop', 'event', 'other'
  address         TEXT,
  city            TEXT,
  state           TEXT,
  latitude        DECIMAL(10,7),
  longitude       DECIMAL(10,7),
  is_active       BOOLEAN DEFAULT true,
  created_at      TIMESTAMPTZ DEFAULT now()
);
