# Sprint 2B — Manual Interaction Test Checklist

Run these on a physical device or emulator after `flutter run`.
Each step includes what to verify and what the expected result is.

---

## 1. Demo Mode — Full Policy Flow

**Entry:** Welcome screen → "Probar demo"

| # | Action | Expected |
|---|--------|----------|
| 1.1 | Tap "Probar demo" | Home screen appears. Greeting shows "Juan Carlos". Active policy card shows mock data in blue. |
| 1.2 | Tap "Cotizar" quick action | Product selection screen opens. 3 shimmer cards appear briefly, then 3 plan cards (Básica / Plus / Ampliada). BCV rate shows at bottom. |
| 1.3 | Tap "Seleccionar Plus" | Quote summary screen opens. USD price shows $31. VES price shows live BCV × 31. "Recomendado" badge visible. |
| 1.4 | Tap "Solicitar emisión" | Payment method screen opens (NOT emission — verify correct). Pago Móvil tab selected by default. Bank details card visible. |
| 1.5 | Select bank "Banco de Venezuela (0102)" | Dropdown updates. |
| 1.6 | Type reference "12345678" | Submit button becomes enabled. |
| 1.7 | Tap "Confirmar Pago Móvil" | Emission screen opens. 3 loading steps animate. After ~2.8s shows SUCCESS state with "PROVISIONAL" badge. |
| 1.8 | Tap "Ver mi póliza" | Policy detail screen opens. PROVISIONAL badge (amber) shown. Mock rider name, vehicle, dates visible. |
| 1.9 | Tap "Descargar póliza en PDF" | System share sheet opens. PDF contains "PÓLIZA PROVISIONAL" header, rider name, vehicle, SHA-256 hash. |
| 1.10 | Tap copy icon next to policy number | Snackbar "Copiado al portapapeles" appears. |

---

## 2. Demo Mode — Home Screen Data

| # | Action | Expected |
|---|--------|----------|
| 2.1 | Open home screen | BCV rate banner shows live rate from edge function (not mock 78.50 unless offline). |
| 2.2 | If offline | BCV banner shows "(aprox.)" suffix and "Sin conexión" label. |
| 2.3 | Tap "Mi Póliza" bottom tab | PolicyDetailScreen opens with mock data (demo mode). ACTIVA badge (green). |
| 2.4 | Tap SOS button | Emergency countdown screen (10 seconds). "ESTOY BIEN" button cancels it. |

---

## 3. Authenticated Mode — Full Flow (requires real Supabase session)

> Pre-condition: complete onboarding (cedula → licencia → carnet → vehicle → address → consent)

| # | Action | Expected |
|---|--------|----------|
| 3.1 | Open home screen after login | Greeting shows real first name from `profiles.full_name`. Avatar shows real initials. |
| 3.2 | No policy yet | Active policy card shows "Aún no tienes una póliza activa" + "Cotizar ahora" button. |
| 3.3 | Complete full flow: Select plan → Quote → Payment → Emission | Emission screen writes to Supabase. Policy + payment rows created. |
| 3.4 | Return to home screen | Active policy card now shows real plan name, policy number (RS-XXXXXXXX), expiry date, days remaining. |
| 3.5 | Tap policy card | Policy detail screen opens. Data matches what was inserted (plan, vehicle, dates). PROVISIONAL badge. |
| 3.6 | Go to "Mi Póliza" tab | Same policy shown. Rider name matches real profile. |
| 3.7 | Download PDF | PDF shows real rider name, real vehicle plate, provisional watermark. SHA-256 derived from real policy UUID. |
| 3.8 | Check Supabase dashboard | `policies` table: 1 row with `issuance_status = provisional`. `payments` table: 1 row with `status = pending`. `audit_log` table: 2 rows — `policy.provisional_created` and `payment.submitted`. |

---

## 4. Bank Transfer Payment Method

| # | Action | Expected |
|---|--------|----------|
| 4.1 | On payment screen, tap "Transferencia Bancaria" | Bank details card shows RuedaSeguro account info. Reference field visible. |
| 4.2 | Type reference < 6 chars | Submit button disabled. |
| 4.3 | Type reference ≥ 6 chars | Submit button enabled. |
| 4.4 | Submit | Emission screen opens, same flow as Pago Móvil. |

---

## 5. Edge Cases

| # | Scenario | Expected |
|---|----------|----------|
| 5.1 | Kill app during emission loading step | On reopen, emission screen is gone (no partial state). Home screen has no policy yet. |
| 5.2 | Go offline before emission | Emission screen shows rejected state with error message. No crash. |
| 5.3 | BCV edge function unreachable | Quote summary shows VES price with "(aprox.)" suffix and amber warning icon. |
| 5.4 | Policy detail for non-existent ID | Screen shows mock data (error fallback). No crash. |
| 5.5 | Tap "Renovar póliza" on policy detail | Navigates to product selection. |

---

## 6. Running Code Tests

```bash
cd mobile

# All unit tests
flutter test test/features/policy/domain/policy_detail_model_test.dart -v

# PDF service test
flutter test test/features/policy/services/policy_pdf_service_test.dart -v

# ProductSelectionScreen widget test
flutter test test/features/policy/presentation/product_selection_screen_test.dart -v

# Full suite
flutter test --reporter expanded
```

Expected: all tests pass. The PDF test validates %PDF magic bytes.

---

## 7. Supabase Verification Queries

Run in Supabase SQL editor after completing step 3.3:

```sql
-- Confirm policy record
SELECT id, status, issuance_status, premium_usd, start_date, end_date
FROM policies ORDER BY created_at DESC LIMIT 1;

-- Confirm payment record
SELECT id, policy_id, method, amount_usd, status
FROM payments ORDER BY created_at DESC LIMIT 1;

-- Confirm audit trail
SELECT event_type, target_table, target_id, payload, created_at
FROM audit_log ORDER BY created_at DESC LIMIT 5;

-- Confirm metrics view refreshed
SELECT * FROM metrics_daily WHERE date = CURRENT_DATE;
-- (after calling: SELECT refresh_metrics_daily();)
```
