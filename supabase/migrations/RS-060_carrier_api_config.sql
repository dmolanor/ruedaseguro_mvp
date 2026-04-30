-- ============================================================
-- RS-060: Carrier API Configuration Table
-- ============================================================
-- Stores connection details for Acsel/Sirway carrier API.
-- Credentials (api_key, auth_token) never stored here — use
-- Supabase Vault / environment variables in Edge Functions.
-- Fill in with real values when William provides sandbox docs.
-- ============================================================

CREATE TABLE IF NOT EXISTS carrier_api_config (
  id                    UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  carrier_id            UUID        NOT NULL REFERENCES carriers(id) ON DELETE CASCADE,
  api_name              TEXT        NOT NULL,
  -- Values: 'acsel' | 'sirway' | 'stub'
  base_url              TEXT        NOT NULL DEFAULT '',
  -- e.g. 'https://api.acsel.com.ve/v1' — set when William provides docs
  auth_type             TEXT        NOT NULL DEFAULT 'bearer',
  -- Values: 'bearer' | 'basic' | 'apikey'
  product_code_basica   TEXT,       -- Carrier code for RCV Básica tier
  product_code_plus     TEXT,       -- Carrier code for RCV Plus tier
  product_code_premium  TEXT,       -- Carrier code for RCV Premium tier
  timeout_seconds       INTEGER     NOT NULL DEFAULT 10,
  max_attempts          INTEGER     NOT NULL DEFAULT 3,
  retry_interval_minutes INTEGER    NOT NULL DEFAULT 15,
  is_active             BOOLEAN     NOT NULL DEFAULT false,
  -- false until real credentials are provided
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),
  UNIQUE (carrier_id, api_name)
);

-- Seed stub config for Seguros Pirámide (Sprint 3 — stub mode)
INSERT INTO carrier_api_config
  (carrier_id, api_name, base_url, auth_type, is_active)
  VALUES (
    '11111111-1111-1111-1111-111111111111',
    'stub',
    '',
    'bearer',
    false
  )
ON CONFLICT (carrier_id, api_name) DO NOTHING;

-- No RLS needed — only service_role accesses this table
ALTER TABLE carrier_api_config ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- WHEN WILLIAM PROVIDES API DOCS:
-- 1. UPDATE carrier_api_config SET base_url='https://...', is_active=true
--    WHERE carrier_id='11111111-...' AND api_name='acsel';
-- 2. Store credentials in Supabase Vault:
--    SELECT vault.create_secret('ACSEL_API_KEY', '<secret>');
-- 3. In policy-retry/index.ts: replace callCarrierApi() stub with real HTTP call
-- 4. In carrier_api_client.dart: implement AcselSirwayClient and wire it in
--    PolicyIssuanceService._client
-- ============================================================
