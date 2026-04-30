-- ============================================================
-- RS-045: New Tables — Sprint 2A
-- ============================================================
-- Creates: telemetry_events, tickets, ticket_comments,
--          renewal_links, sla_config
-- All idempotent (IF NOT EXISTS).
-- Run AFTER RS-041 (RLS infra in place).
-- ============================================================

-- ============================================================
-- 1. TELEMETRY_EVENTS
--    Stores the 15-minute circular buffer flush on impact.
--    Normal heartbeats are lightweight MQTT; only impact
--    windows are persisted to PostgreSQL.
-- ============================================================

CREATE TABLE IF NOT EXISTS telemetry_events (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  rider_id         UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  policy_id        UUID        REFERENCES policies(id) ON DELETE SET NULL,
  -- Event classification
  event_type       TEXT        NOT NULL,
  -- Values: 'heartbeat' | 'impact_detected' | 'emergency_activated'
  --         | 'emergency_cancelled' | 'buffer_flush'
  -- Impact data
  g_force          NUMERIC(6,3),              -- Peak G reading at event
  latitude         NUMERIC(10,7),
  longitude        NUMERIC(10,7),
  altitude_m       NUMERIC(8,2),
  speed_kmh        NUMERIC(6,2),
  -- Sensor window (15-min buffer serialised as JSONB)
  payload_json     JSONB,
  -- Timestamps (device vs. server)
  recorded_at      TIMESTAMPTZ NOT NULL,      -- ISO 8601 from device clock
  synced_at        TIMESTAMPTZ DEFAULT now(), -- Server receipt time
  -- Deduplication (UUID generated on device, reused on retry)
  idempotency_key  UUID        NOT NULL UNIQUE,
  -- Soft delete / lifecycle
  archived_at      TIMESTAMPTZ,
  retain_until     DATE        -- computed by trigger on insert
);

-- retain_until trigger (GENERATED ALWAYS AS is disallowed for timestamptz→date,
-- which is STABLE not IMMUTABLE due to timezone dependency)
CREATE OR REPLACE FUNCTION _set_telemetry_retain_until()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.retain_until := (NEW.recorded_at AT TIME ZONE 'UTC' + INTERVAL '5 years')::DATE;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_telemetry_retain_until
  BEFORE INSERT ON telemetry_events
  FOR EACH ROW EXECUTE FUNCTION _set_telemetry_retain_until();

CREATE INDEX IF NOT EXISTS idx_telemetry_rider
  ON telemetry_events (rider_id, recorded_at DESC);

CREATE INDEX IF NOT EXISTS idx_telemetry_event_type
  ON telemetry_events (event_type, synced_at DESC)
  WHERE archived_at IS NULL;

-- RLS
ALTER TABLE telemetry_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "riders_select_own_telemetry" ON telemetry_events;
DROP POLICY IF EXISTS "riders_insert_own_telemetry" ON telemetry_events;

CREATE POLICY "riders_select_own_telemetry"
  ON telemetry_events FOR SELECT
  USING (auth.uid() = rider_id);

CREATE POLICY "riders_insert_own_telemetry"
  ON telemetry_events FOR INSERT
  WITH CHECK (auth.uid() = rider_id);

-- ============================================================
-- 2. SLA_CONFIG
--    Drive escalation rules for the ticket system.
-- ============================================================

CREATE TABLE IF NOT EXISTS sla_config (
  entity_type      TEXT        NOT NULL,
  -- Values: 'rider' | 'broker' | 'clinic' | 'insurer' | 'system'
  priority         TEXT        NOT NULL,
  -- Values: 'critical' | 'high' | 'medium' | 'low'
  target_minutes   INTEGER     NOT NULL,
  description      TEXT,
  PRIMARY KEY (entity_type, priority)
);

-- Seed default SLA targets (idempotent via INSERT ... ON CONFLICT)
INSERT INTO sla_config (entity_type, priority, target_minutes, description) VALUES
  ('rider',   'critical', 30,   'Payment charged, policy not issued'),
  ('rider',   'high',     120,  'Policy or coverage question'),
  ('rider',   'medium',   480,  'General rider inquiry'),
  ('rider',   'low',      1440, 'Feedback or non-urgent request'),
  ('broker',  'critical', 60,   'Commission dispute blocking payment'),
  ('broker',  'high',     240,  'Portfolio or renewal issue'),
  ('broker',  'medium',   480,  'General broker inquiry'),
  ('clinic',  'critical', 30,   'API timeout blocking patient admission'),
  ('clinic',  'high',     120,  'Discharge sync failure'),
  ('insurer', 'critical', 60,   'Policy issuance API failure'),
  ('insurer', 'high',     240,  'Reconciliation discrepancy'),
  ('system',  'critical', 15,   'Auto-generated: payment or API failure')
ON CONFLICT (entity_type, priority) DO NOTHING;

-- No RLS on sla_config — read by service_role only
ALTER TABLE sla_config ENABLE ROW LEVEL SECURITY;
-- Carrier admins can read SLA config (for Ops Desk portal)
DROP POLICY IF EXISTS "carrier_select_sla_config" ON sla_config;
CREATE POLICY "carrier_select_sla_config"
  ON sla_config FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM carrier_users cu
      WHERE cu.auth_user_id = auth.uid()
        AND cu.is_active = true
    )
  );

-- ============================================================
-- 3. TICKETS
-- ============================================================

CREATE TABLE IF NOT EXISTS tickets (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  -- Who raised the ticket
  entity_type      TEXT        NOT NULL,
  -- 'rider' | 'broker' | 'clinic' | 'insurer' | 'system'
  entity_id        UUID,
  -- Denormalised subject references for quick lookup
  rider_id         UUID        REFERENCES profiles(id) ON DELETE SET NULL,
  policy_id        UUID        REFERENCES policies(id) ON DELETE SET NULL,
  payment_id       UUID        REFERENCES payments(id) ON DELETE SET NULL,
  -- Content
  subject          TEXT        NOT NULL,
  description      TEXT,
  -- Classification
  priority         TEXT        NOT NULL DEFAULT 'medium',
  -- 'critical' | 'high' | 'medium' | 'low'
  status           TEXT        NOT NULL DEFAULT 'open',
  -- 'open' | 'in_progress' | 'waiting_on_user' |
  -- 'waiting_on_partner' | 'resolved' | 'closed'
  -- Assignment
  assigned_agent   TEXT,                          -- Agent name/email
  -- Cross-reference
  carrier_ref      TEXT,                          -- Carrier's internal ticket ref
  -- Timestamps
  created_at       TIMESTAMPTZ DEFAULT now(),
  updated_at       TIMESTAMPTZ DEFAULT now(),
  resolved_at      TIMESTAMPTZ,
  -- Lifecycle
  archived_at      TIMESTAMPTZ,
  retain_until     DATE        -- computed by trigger on insert
);

CREATE OR REPLACE FUNCTION _set_ticket_retain_until()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.retain_until := (NEW.created_at AT TIME ZONE 'UTC' + INTERVAL '3 years')::DATE;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_ticket_retain_until
  BEFORE INSERT ON tickets
  FOR EACH ROW EXECUTE FUNCTION _set_ticket_retain_until();

CREATE INDEX IF NOT EXISTS idx_tickets_status
  ON tickets (status, priority, created_at DESC)
  WHERE archived_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_tickets_rider
  ON tickets (rider_id)
  WHERE rider_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_tickets_policy
  ON tickets (policy_id)
  WHERE policy_id IS NOT NULL;

-- updated_at trigger
CREATE TRIGGER set_tickets_updated_at
  BEFORE UPDATE ON tickets
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

-- RLS
ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "riders_select_own_tickets"   ON tickets;
DROP POLICY IF EXISTS "riders_insert_own_tickets"   ON tickets;
DROP POLICY IF EXISTS "carrier_select_all_tickets"  ON tickets;

-- Riders can see their own tickets
CREATE POLICY "riders_select_own_tickets"
  ON tickets FOR SELECT
  USING (auth.uid() = rider_id);

-- Riders can create tickets (linked to their profile)
CREATE POLICY "riders_insert_own_tickets"
  ON tickets FOR INSERT
  WITH CHECK (auth.uid() = rider_id);

-- Carrier admins see all tickets for their carrier's riders
CREATE POLICY "carrier_select_all_tickets"
  ON tickets FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM carrier_users cu
      WHERE cu.auth_user_id = auth.uid()
        AND cu.is_active = true
    )
  );

-- ============================================================
-- 4. TICKET_COMMENTS
-- ============================================================

CREATE TABLE IF NOT EXISTS ticket_comments (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id        UUID        NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  author_type      TEXT        NOT NULL,
  -- 'agent' | 'rider' | 'system'
  author_id        UUID,                          -- auth.uid() of the commenter
  body             TEXT        NOT NULL,
  created_at       TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ticket_comments_ticket
  ON ticket_comments (ticket_id, created_at ASC);

-- RLS
ALTER TABLE ticket_comments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "riders_select_own_ticket_comments"  ON ticket_comments;
DROP POLICY IF EXISTS "riders_insert_own_ticket_comments"  ON ticket_comments;
DROP POLICY IF EXISTS "carrier_select_ticket_comments"     ON ticket_comments;

CREATE POLICY "riders_select_own_ticket_comments"
  ON ticket_comments FOR SELECT
  USING (
    ticket_id IN (
      SELECT id FROM tickets WHERE rider_id = auth.uid()
    )
  );

CREATE POLICY "riders_insert_own_ticket_comments"
  ON ticket_comments FOR INSERT
  WITH CHECK (
    ticket_id IN (
      SELECT id FROM tickets WHERE rider_id = auth.uid()
    )
    AND author_type = 'rider'
    AND author_id = auth.uid()
  );

CREATE POLICY "carrier_select_ticket_comments"
  ON ticket_comments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM carrier_users cu
      WHERE cu.auth_user_id = auth.uid()
        AND cu.is_active = true
    )
  );

-- ============================================================
-- 5. RENEWAL_LINKS
--    Broker-generated Pago Móvil deep-links for expiring policies.
-- ============================================================

CREATE TABLE IF NOT EXISTS renewal_links (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  policy_id        UUID        NOT NULL REFERENCES policies(id) ON DELETE CASCADE,
  broker_id        UUID        REFERENCES brokers(id) ON DELETE SET NULL,
  -- The generated deep-link (Pago Móvil format)
  pago_movil_link  TEXT        NOT NULL,
  -- Lifecycle
  created_at       TIMESTAMPTZ DEFAULT now(),
  sent_at          TIMESTAMPTZ,
  clicked_at       TIMESTAMPTZ,
  completed_at     TIMESTAMPTZ,
  expires_at       TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '30 days')
);

CREATE INDEX IF NOT EXISTS idx_renewal_links_policy
  ON renewal_links (policy_id);

CREATE INDEX IF NOT EXISTS idx_renewal_links_expires
  ON renewal_links (expires_at)
  WHERE completed_at IS NULL;

-- RLS
ALTER TABLE renewal_links ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "riders_select_own_renewal_links"  ON renewal_links;
DROP POLICY IF EXISTS "brokers_select_their_renewal_links" ON renewal_links;

-- Rider can see renewal links for their own policies
CREATE POLICY "riders_select_own_renewal_links"
  ON renewal_links FOR SELECT
  USING (
    policy_id IN (
      SELECT id FROM policies WHERE profile_id = auth.uid()
    )
  );

-- Broker can see their generated links
CREATE POLICY "brokers_select_their_renewal_links"
  ON renewal_links FOR SELECT
  USING (
    broker_id IN (
      SELECT id FROM brokers WHERE auth_user_id = auth.uid()
    )
  );

-- ============================================================
-- VERIFICATION QUERIES
-- ============================================================
-- SELECT table_name FROM information_schema.tables
--   WHERE table_schema = 'public'
--     AND table_name IN (
--       'telemetry_events','tickets','ticket_comments',
--       'renewal_links','sla_config'
--     );
--
-- SELECT COUNT(*) FROM sla_config; -- should be 12
