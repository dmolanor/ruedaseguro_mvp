# Sprint 3 — Manual Interaction Test Checklist

Run these on a physical device or emulator after `flutter run`.
Sprint 3 adds: real claim submission, support tickets, carrier API stub,
provisional/confirmed emission states, and Sentry crash reporting.

> **Prerequisites before authenticated-mode tests:**
> 1. Run `RS-067_claims_enhancements.sql` in the Supabase SQL editor.
> 2. Run `RS-060_carrier_api_config.sql` in the Supabase SQL editor.
> 3. Deploy `supabase/functions/policy-retry/` and `supabase/functions/renewal-reminder/`.
> 4. Build with `--dart-define=SENTRY_DSN=<your-dsn>` (or leave blank to skip Sentry).

---

## 1. Emission Screen — Confirmed State (Stub Carrier)

> Authenticated mode only. The stub carrier always confirms after a 2 s delay.

| # | Action | Expected |
|---|--------|----------|
| 1.1 | Complete full flow: Select plan → Quote → Payment → Emission | Emission screen opens. 4 loading rows animate: "Verificando datos...", "Registrando póliza provisional", "Guardando referencia de pago", "Contactando a la aseguradora..." |
| 1.2 | Wait for carrier stub (≤ 5 s) | Screen transitions to **confirmed** state. AppBar title reads "Póliza confirmada" in green. |
| 1.3 | Check success body | Title: "¡Póliza confirmada!". Body copy: "Tu póliza fue registrada y confirmada por la aseguradora." |
| 1.4 | Tap "Ver mi póliza" | Policy detail screen opens. **No** provisional (amber) banner — policy is confirmed. |
| 1.5 | Check Supabase `policies` table | `issuance_status = 'confirmed'`. `carrier_policy_number` starts with `STUB-` (stub format). `status = 'active'`. |
| 1.6 | Check Supabase `audit_log` | 4 rows: `policy.provisional_created`, `payment.submitted`, `policy.api_submitted`, `policy.confirmed`. |

---

## 2. Emission Screen — Provisional Fallback (Demo Mode)

> Demo mode path is unchanged from Sprint 2B but now shows 4 loading steps.

| # | Action | Expected |
|---|--------|----------|
| 2.1 | Tap "Probar demo" → full flow → emission | 4 loading steps animate (including "Contactando a la aseguradora..."). |
| 2.2 | After ~2.8 s | Shows **provisional** state (demo never calls carrier). AppBar: "Póliza registrada". |
| 2.3 | Card badge | "PROVISIONAL" amber pill visible on the preview card. Footer: "Activación en ≤ 24 h". |

---

## 3. Provisional Banner on Policy Detail

| # | Action | Expected |
|---|--------|----------|
| 3.1 | Open policy detail for a policy with `issuance_status = 'provisional'` | Amber banner appears above the digital policy card. Icon: hourglass. Text: "Póliza Provisional — Tu póliza está siendo procesada. Recibirás confirmación en menos de 24 horas." |
| 3.2 | Open policy detail for a confirmed policy | No banner. Digital policy card shows normally. |
| 3.3 | Demo mode → "Mi Póliza" tab | Provisional banner shows (mock policy uses `issuanceStatus = 'provisional'`). |

---

## 4. New Claim Screen — Demo Mode

| # | Action | Expected |
|---|--------|----------|
| 4.1 | Home → "Siniestros" → "Reportar siniestro" (demo mode) | Screen opens. 4 incident type chips: Colisión (red), Daño a tercero (orange), Robo/Hurto (purple), Lesiones (navy). |
| 4.2 | Policy banner at top | Shows "Sin póliza activa" or demo mock policy info. No crash. |
| 4.3 | Tap date/time tiles | Date picker and time picker open and close without error. Selected values update in tile. |
| 4.4 | Tap a photo slot | Camera intent fires (or gallery picker appears). On simulator: photo library shown. |
| 4.5 | Add only 1 photo, tap submit | Snackbar: "Debes agregar al menos 2 fotos del incidente". |
| 4.6 | Leave description empty, add 2 photos, tap submit | Snackbar: "Describe brevemente lo ocurrido". |
| 4.7 | Fill all fields + 2 photos (demo mode, no session) | Fake 2 s delay → success view. Claim number: `SIN-{year}-DEMO01`. |
| 4.8 | Tap "Listo" on success view | Navigates back to home or previous screen. |

---

## 5. New Claim Screen — Authenticated Mode

> Pre-condition: RS-067 migration applied. User has an active policy.

| # | Action | Expected |
|---|--------|----------|
| 5.1 | Open new claim screen (authenticated) | Policy banner shows active policy number and plan name. |
| 5.2 | Select incident type "Colisión" | Chip highlights in red. |
| 5.3 | Enable "Lesiones / heridos" toggle | Medical assistance note appears below toggle. |
| 5.4 | Add 3 photos via camera | All 3 slots show thumbnail with green check overlay. |
| 5.5 | Fill location and description, tap submit | Loading spinner. Then success view with real `SIN-{year}-XXXXXX` claim number. |
| 5.6 | Check Supabase `claims` table | 1 new row: `claim_number`, `incident_type`, `has_injuries = true`, `location`, `incident_at`, `retain_until` (7 years from creation). |
| 5.7 | Check Supabase `claim_evidence` table | 3 rows with `evidence_type = 'photo'` and `file_url` pointing to receipts bucket. |
| 5.8 | Check Supabase Storage `receipts` bucket | Files at path `{userId}/claims/{claimId}/0.jpg`, `1.jpg`, `2.jpg`. |
| 5.9 | Check Supabase `audit_log` | 1 row: `claim.reported` with `type`, `has_injuries`, `photos: 3`. |

---

## 6. Support Ticket Creation

| # | Action | Expected |
|---|--------|----------|
| 6.1 | Navigate to `/support/new-ticket` | Screen opens. Title: "Nuevo Reporte". 5 category tiles visible. |
| 6.2 | Category tiles | Pago (red), Póliza (orange), Siniestro (orange), App (teal), Otro (grey). |
| 6.3 | Tap "Pago" category | Tile highlights. Priority badge shows "CRÍTICO" or "ALTO". |
| 6.4 | Leave subject empty, tap submit | Button disabled or validation error shown. |
| 6.5 | Fill subject + description (demo mode, no session) | Fake 1.5 s delay → success view. Ticket number: `TKT-{year}-DEMO01`. |
| 6.6 | Tap "Listo" | Navigates back. |
| 6.7 | Authenticated mode — fill and submit | Success view shows real `TKT-{year}-XXXXXX` number. |
| 6.8 | Check Supabase `tickets` table | 1 row: `category`, `subject`, `description`, `priority`, `status = 'open'`, `ticket_number`. |

---

## 7. Sentry Initialization

| # | Action | Expected |
|---|--------|----------|
| 7.1 | Run with `--dart-define=SENTRY_DSN=` (empty) | App starts normally. No Sentry errors in console. Sentry silently no-ops when DSN is empty. |
| 7.2 | Run with a valid Sentry DSN | Sentry initializes (log line: `[Sentry] SDK initialized`). |
| 7.3 | Force a test exception (add `throw Exception('test')` temporarily) | Error appears in Sentry dashboard within ~30 s. Stack trace includes Flutter frames. |
| 7.4 | Check `tracesSampleRate` | In debug build: 1.0 (all transactions). In release: 0.1 (10%). |

---

## 8. Edge Cases

| # | Scenario | Expected |
|---|----------|----------|
| 8.1 | Emission — carrier API times out (15 s budget) | Falls back to provisional state. No crash. AppBar shows "Póliza registrada". |
| 8.2 | Claim submit without active policy (authenticated) | Snackbar: "No tienes una póliza activa". Form not submitted. |
| 8.3 | Upload photo with no network | Supabase storage upload fails. `catch` block shows error snackbar. No crash. |
| 8.4 | Navigate to `/support/new-ticket` in demo mode | Screen loads. Submit succeeds with fake data. |
| 8.5 | RS-067 migration NOT applied (column missing) | Claim submit produces error snackbar: Postgres 42703 column not found. App does not crash. |
| 8.6 | `peakGForce` on empty telemetry buffer | Returns `null`. No crash. (Unit test covers this; verify in `flutter test`.) |

---

## 9. Running Automated Tests

```bash
cd mobile

# Sprint 3 — IssuanceResult domain model
flutter test test/features/policy/domain/issuance_result_test.dart -v

# Sprint 3 — TelemetryBufferService (SQLite circular buffer)
flutter test test/features/telemetry/services/telemetry_buffer_service_test.dart -v

# Sprint 2 regression — policy domain model (isProvisional/isConfirmed helpers)
flutter test test/features/policy/domain/policy_detail_model_test.dart -v

# Full suite
flutter test --reporter expanded
```

Expected: all tests pass. The telemetry test validates insert, window query,
pruning, clear, and peak G-force across multiple samples.

---

## 10. Supabase Verification Queries

Run in Supabase SQL editor after completing tests in sections 5 and 6:

```sql
-- Most recent claim with evidence
SELECT c.id, c.claim_number, c.incident_type, c.has_injuries,
       c.location, c.incident_at, c.retain_until,
       COUNT(ce.id) AS photo_count
  FROM claims c
  LEFT JOIN claim_evidence ce ON ce.claim_id = c.id
 ORDER BY c.created_at DESC
 LIMIT 1;

-- Verify photo paths are correctly namespaced under userId
SELECT file_url FROM claim_evidence ORDER BY created_at DESC LIMIT 5;
-- URLs should contain: /receipts/{userId}/claims/{claimId}/

-- Most recent ticket
SELECT ticket_number, category, priority, status, created_at
  FROM tickets ORDER BY created_at DESC LIMIT 1;

-- Verify policy is confirmed after emission
SELECT id, status, issuance_status, carrier_policy_number
  FROM policies ORDER BY created_at DESC LIMIT 1;
-- issuance_status = 'confirmed', carrier_policy_number LIKE 'STUB-%'

-- Audit trail for latest claim
SELECT event_type, target_table, payload, created_at
  FROM audit_log
 WHERE event_type LIKE 'claim.%'
 ORDER BY created_at DESC
 LIMIT 5;
```

---

## 11. Pre-Deployment Checklist

Before pushing to production (when William provides Acsel/Sirway credentials):

- [ ] Run `RS-067_claims_enhancements.sql` in Supabase (idempotent, safe to re-run)
- [ ] Run `RS-060_carrier_api_config.sql` in Supabase (verify `carrier_id` UUID matches live `carriers` table)
- [ ] Deploy `supabase/functions/policy-retry/` Edge Function
- [ ] Deploy `supabase/functions/renewal-reminder/` Edge Function
- [ ] Set `SENTRY_DSN` in build pipeline (`--dart-define=SENTRY_DSN=...`)
- [ ] Verify MessageBird credentials set in Supabase project env vars (`MESSAGEBIRD_API_KEY`)
- [ ] Schedule `renewal-reminder` function as daily cron via Supabase dashboard
- [ ] Schedule `policy-retry` function to run every 15 min or on-demand via webhook
