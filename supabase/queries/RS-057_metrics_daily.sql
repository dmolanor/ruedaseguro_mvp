-- ============================================================
-- RS-057: metrics_daily Materialized View — Sprint 2B
-- ============================================================
-- Aggregates daily policy, payment, and claim KPIs for
-- Thony's management dashboard (refreshed every 15 minutes
-- via pg_cron).
--
-- Run order: after RS-007 (base tables exist).
-- Idempotent: CREATE ... IF NOT EXISTS + OR REPLACE.
-- ============================================================

-- ── 1. Materialized view ─────────────────────────────────────────

CREATE MATERIALIZED VIEW IF NOT EXISTS metrics_daily AS
SELECT
  -- Date bucket (UTC)
  (p.created_at AT TIME ZONE 'UTC')::DATE          AS date,

  -- Policy counts
  COUNT(p.id)                                        AS policies_created,
  COUNT(p.id) FILTER (
    WHERE p.status IN ('active', 'pending_emission')
  )                                                  AS policies_active,
  COUNT(p.id) FILTER (
    WHERE p.issuance_status = 'provisional'
  )                                                  AS policies_provisional,
  COUNT(p.id) FILTER (
    WHERE p.issuance_status = 'confirmed'
  )                                                  AS policies_confirmed,

  -- Revenue (USD)
  COALESCE(SUM(p.price_usd), 0)                     AS revenue_usd,
  COALESCE(AVG(p.price_usd), 0)                     AS avg_premium_usd,

  -- Tier breakdown
  COUNT(p.id) FILTER (
    WHERE pt.tier = 'basica'
  )                                                  AS tier_basica,
  COUNT(p.id) FILTER (
    WHERE pt.tier = 'plus'
  )                                                  AS tier_plus,
  COUNT(p.id) FILTER (
    WHERE pt.tier = 'ampliada'
  )                                                  AS tier_ampliada,

  -- Payment counts
  COUNT(DISTINCT pay.id)                             AS payments_submitted,
  COUNT(DISTINCT pay.id) FILTER (
    WHERE pay.status = 'verified'
  )                                                  AS payments_verified,
  COUNT(DISTINCT pay.id) FILTER (
    WHERE pay.status = 'rejected'
  )                                                  AS payments_rejected,

  -- Claims
  COUNT(DISTINCT cl.id)                              AS claims_opened

FROM policies p
LEFT JOIN policy_types pt  ON pt.id  = p.policy_type_id
LEFT JOIN payments    pay  ON pay.policy_id = p.id
LEFT JOIN claims      cl   ON cl.policy_id  = p.id
  AND (cl.created_at AT TIME ZONE 'UTC')::DATE =
      (p.created_at  AT TIME ZONE 'UTC')::DATE

GROUP BY (p.created_at AT TIME ZONE 'UTC')::DATE
ORDER BY date DESC
WITH DATA;

-- ── 2. Index for fast date lookups ───────────────────────────────

CREATE UNIQUE INDEX IF NOT EXISTS idx_metrics_daily_date
  ON metrics_daily (date DESC);

-- ── 3. Refresh function ──────────────────────────────────────────

CREATE OR REPLACE FUNCTION refresh_metrics_daily()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY metrics_daily;
END;
$$;

-- ── 4. pg_cron schedule (15-min refresh) ─────────────────────────
-- Requires the pg_cron extension to be enabled in Supabase
-- (Database → Extensions → pg_cron).
--
-- Run this block manually once after enabling pg_cron:
--
-- SELECT cron.schedule(
--   'refresh-metrics-daily',       -- job name
--   '*/15 * * * *',                -- every 15 minutes
--   'SELECT refresh_metrics_daily()'
-- );
--
-- To verify the schedule:
-- SELECT * FROM cron.job WHERE jobname = 'refresh-metrics-daily';
--
-- To remove it:
-- SELECT cron.unschedule('refresh-metrics-daily');

-- ── 5. RLS: service-role only ────────────────────────────────────
-- Materialized views don't support RLS directly.
-- Grant access only to service_role (used by Thony's backend).
-- Anon and authenticated roles have no access.

REVOKE ALL ON metrics_daily FROM anon, authenticated;
GRANT SELECT ON metrics_daily TO service_role;

-- ── VERIFICATION QUERIES ─────────────────────────────────────────
-- SELECT * FROM metrics_daily ORDER BY date DESC LIMIT 7;
-- SELECT refresh_metrics_daily();
-- SELECT * FROM metrics_daily WHERE date = CURRENT_DATE;
