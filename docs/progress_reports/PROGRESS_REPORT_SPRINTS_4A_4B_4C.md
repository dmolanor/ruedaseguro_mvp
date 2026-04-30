# RuedaSeguro — Technical Progress Report

## Sprints 4A, 4B, 4C, 4D & 4E — Onboarding Overhaul, Document OCR, Emergency Infrastructure, Digital Carnet & IoT Crash Detection Demo

**As of:** 2026-04-09 | **Prepared by:** Engineering
**Continues from:** `docs/PROGRESS_REPORT_SPRINT_3.md`

---

## Table of Contents

1. [Sprint Overview](#1-sprint-overview)
2. [Sprint 4A — Document Scanning & Domain Validation](#2-sprint-4a--document-scanning--domain-validation)
3. [Sprint 4B — Plan-First UX & Conductor Frecuente](#3-sprint-4b--plan-first-ux--conductor-frecuente)
4. [Sprint 4C — Emergency Infrastructure & IoT REST Integration](#4-sprint-4c--emergency-infrastructure--iot-rest-integration)
5. [Sprint 4D — Digital Carnet, Payments & Profile Wiring](#5-sprint-4d--digital-carnet-payments--profile-wiring)
6. [Sprint 4E — IoT Crash Detection Demo](#6-sprint-4e--iot-crash-detection-demo)
7. [Database Changes (Sprints 4A–4C)](#7-database-changes-sprints-4a4c)
8. [Architecture Changes](#8-architecture-changes)
9. [Testing](#9-testing)
10. [Security](#10-security)
11. [Known Limitations & Sprint 5 Preview](#11-known-limitations--sprint-5-preview)

---

## 1. Sprint Overview

Sprints 4A–4C collectively overhaul the rider onboarding experience from manual data entry to a fully OCR-driven, plan-first flow, and deliver the first phase of the IoT emergency button infrastructure.

### Sprint 4A — Document Scanning & Domain Validation

| Ticket | Description                                                               | Status |
| ------ | ------------------------------------------------------------------------- | ------ |
| RS-075 | CedulaScanScreen — MLKit OCR scanner widget                               | ✅     |
| RS-076 | CedulaConfirmScreen — parsed field display + manual override              | ✅     |
| RS-077 | CertificadoScanScreen — vehicle certificate OCR scanner                   | ✅     |
| RS-078 | CertificadoConfirmScreen — parsed vehicle field display                   | ✅     |
| RS-079 | `cedula_parser.dart` — structured OCR text → `OnboardingData`             | ✅     |
| RS-080 | `onboarding_state.dart` — accumulated state model, cross-field validation | ✅     |
| RS-081 | AddressFormScreen — manual address + GPS capture                          | ✅     |
| RS-082 | ConsentScreen — terms acceptance, onboarding completion gate              | ✅     |

### Sprint 4B — Plan-First UX & Conductor Frecuente

| Ticket | Description                                                                    | Status |
| ------ | ------------------------------------------------------------------------------ | ------ |
| RS-083 | PlanSelectionScreen — plan-first entry point for onboarding                    | ✅     |
| RS-084 | PropertyValidationScreen — property type + owner relationship                  | ✅     |
| RS-085 | Conductor frecuente capture — name + cédula if driver ≠ owner                  | ✅     |
| RS-086 | Router rewrite — plan-first `_onboardingRoutes` list                           | ✅     |
| RS-087 | EmissionScreen — `frequentDriverName/Id` wired into `CarrierSubmissionPayload` | ✅     |

### Sprint 4C — Emergency Infrastructure & IoT REST Integration

| Ticket | Description                                                                                           | Status            |
| ------ | ----------------------------------------------------------------------------------------------------- | ----------------- |
| RS-088 | DB migration: `emergency_contacts` table + profiles geo + vehicles metadata                           | ✅                |
| RS-089 | `EmergencyContactRepository` — CRUD + primary-contact enforcement                                     | ✅                |
| RS-090 | `EmergencyContactsScreen` — full CRUD UI, onboarding-mode footer                                      | ✅                |
| RS-091 | DB already has `first_name`/`last_name` split; `OnboardingData` aligned                               | ✅ (pre-existing) |
| RS-092 | Phone auto-fill from OTP auth state in `OnboardingData`                                               | ✅                |
| RS-093 | `IotApiClient` abstract interface + `StubIotClient`                                                   | ✅                |
| RS-094 | `IotPayloadMapper` — normalisation to Quasar Infotech / Thony format                                  | ✅                |
| RS-095 | `payment_method` enum: `debito_inmediato` added                                                       | ✅                |
| RS-096 | DB migration: `policies` IoT fields + `conductor_frecuente` fields                                    | ✅                |
| RS-097 | `EmergencyScreen` full rewrite — urgency triage, phase-aware dispatch, auto-fall                      | ✅                |
| RS-098 | `EmergencySetupScreen` — 5-page onboarding wizard with SharedPreferences                              | ✅                |
| RS-099 | Router wiring — `/onboarding/emergency-contacts`, `/emergency/setup`, `EmergencyActivationType` param | ✅                |

### Sprint 4D — Digital Carnet, Payments & Profile Wiring

| Ticket | Description                                                                          | Status                                |
| ------ | ------------------------------------------------------------------------------------ | ------------------------------------- |
| RS-100 | Débito Inmediato payment UI stub + "Próximamente" badge                              | ✅                                    |
| RS-101 | QR Carnet — `PolicyCardService` + `PolicyCarnetScreen` with `qr_flutter`             | ✅                                    |
| RS-102 | Post-emission document delivery — `share_plus` share action in `EmissionScreen`      | ✅                                    |
| RS-103 | Profile screen: `_EmergencyContactsSection` wired to live `emergency_contacts` table | ✅                                    |
| RS-104 | Real `CarrierApiClient` for Seguros Pirámide                                         | ⏳ Blocked (awaiting William's docs)  |
| RS-105 | Real `IotApiClient` for Quasar Infotech                                              | ⏳ Blocked (awaiting Thony's API key) |
| RS-106 | Push notifications — FCM configuration + policy status webhooks                      | ⏳ Blocked (external setup)           |

### Sprint 4E — IoT Crash Detection Demo

Pre-meeting sprint (2026-04-09) activating the `sensors_plus` accelerometer to demonstrate crash detection UX ahead of the Thony integration meeting.

| Ticket | Description                                                                                | Status |
| ------ | ------------------------------------------------------------------------------------------ | ------ |
| RS-111 | Activate `sensors_plus: ^4.0.2` in `pubspec.yaml` (was Phase 1.5 stub)                     | ✅     |
| RS-112 | `accelerometerProvider` — `StreamProvider` reading live G-force at 50 Hz                   | ✅     |
| RS-113 | `CrashThresholdNotifier` — user-adjustable detection threshold (1.5–5.0 G)                 | ✅     |
| RS-114 | `CrashMonitorScreen` — live G-force gauge, XYZ axes, MQTT payload preview, simulate button | ✅     |
| RS-115 | Route `/telemetry/crash-monitor` + home screen "Detección de caídas" IoT card              | ✅     |
| RS-116 | Simulate crash → `EmergencyScreen(autoFall)` full dispatch flow                            | ✅     |
| RS-117 | Unit tests: `AccelerometerReading` physics, `CrashThresholdNotifier` state                 | ✅     |

---

## 2. Sprint 4A — Document Scanning & Domain Validation

### Onboarding OCR Pipeline

The pre-Sprint 4A onboarding relied on fully manual text entry. Sprint 4A replaces this with an OCR pipeline powered by `google_mlkit_text_recognition`. The pipeline has two steps for each document type: a scan screen (live camera preview with real-time text detection) followed by a confirm screen (parsed fields displayed for rider verification and manual correction).

**`cedula_parser.dart`** — Parses raw MLKit output into structured `OnboardingData` fields:

- Cédula number (strips `V-` / `E-` prefix, normalises spacing)
- First name, last name (handles both `NOMBRE:` and positional extraction)
- Date of birth (multiple Venezuelan format variants: `DD/MM/YYYY`, `DD-MM-YYYY`)
- Gender code

**`onboarding_state.dart`** — `OnboardingData` is the single accumulation model that flows through all onboarding screens. Key design decisions:

- All fields are nullable; each screen writes only its own fields
- Cross-field validation (`cross_validator.dart`) runs at the confirm screens before advancing
- `OnboardingNotifier` (Riverpod `Notifier`) commits the final `OnboardingData` to Supabase via `OnboardingRepository`

### Address Form

`AddressFormScreen` captures:

- State, municipality, parish (cascading dropdowns, Venezuelan CODIGOS POSTALES)
- Street address line + optional postal code
- GPS coordinates (`latitude`, `longitude`, `addressFromGps`) via device location
- Falls back gracefully when location permission is denied — manual entry only

Now navigates to `/onboarding/emergency-contacts` (updated in Sprint 4C; was `/onboarding/consent` in 4A).

---

## 3. Sprint 4B — Plan-First UX & Conductor Frecuente

### Plan Selection as Onboarding Entry Point

Based on the 2026-03-30 stakeholder meeting, the onboarding flow was restructured so riders **choose their insurance plan before scanning documents**. This change aligns with the sales funnel: plan → capture identity → emit.

`PlanSelectionScreen` displays the three tiers:

- **RCV Básico** — statutory liability only
- **RCV + Accidentes** — liability + personal accident
- **RCV Ampliada** — full comprehensive

Plan choice is stored in `OnboardingData.selectedPlanTier` and flows through to `CarrierSubmissionPayload` and `IotPayloadMapper`.

### Property Validation

`PropertyValidationScreen` captures the relationship between the rider and the vehicle:

- Property type: own, financed, rented, company-assigned
- If financed/company: captures lienholder / company name

This data feeds the carrier API payload and is required by several insurers.

### Conductor Frecuente

Carriers require coverage to reflect the **actual primary driver** when they differ from the registered owner. `EmissionScreen` was updated to capture:

- `frequent_driver_name` (full name)
- `frequent_driver_id` (cédula number)
- `frequent_driver_id_type` (`V` or `E`)

These fields are persisted to `policies.frequent_driver_name / frequent_driver_id / frequent_driver_id_type` (added in RS-096 migration) and included in both the `CarrierSubmissionPayload` and `IotPolicyRequest`.

---

## 4. Sprint 4C — Emergency Infrastructure & IoT REST Integration

### Emergency Contacts — New Data Model

The single `emergency_name / emergency_phone / emergency_relation` flat fields on `profiles` are **deprecated** in favour of a dedicated `emergency_contacts` table supporting multiple contacts per rider.

**`emergency_contacts` schema:**

```sql
emergency_contacts (
  id            uuid PRIMARY KEY,
  profile_id    uuid REFERENCES profiles(id) ON DELETE CASCADE,
  full_name     text NOT NULL,
  phone         text NOT NULL,  -- stored as E.164
  relation      text,           -- madre|padre|pareja|hermano|amigo|otro
  is_primary    boolean DEFAULT false,
  created_at    timestamptz DEFAULT now()
)
```

RLS policy: `Riders manage own emergency contacts` — riders can only read/write rows where `profile_id = auth.uid()`.

**Single-primary constraint** enforced at the DB level via a partial unique index:

```sql
CREATE UNIQUE INDEX emergency_contacts_one_primary
  ON emergency_contacts (profile_id) WHERE is_primary = true;
```

`EmergencyContactRepository.insert()` wraps insertion in a transaction that demotes the existing primary before inserting the new one.

### EmergencyContactsScreen

A full CRUD screen accessible both from onboarding (`onboardingMode: true`) and from the profile section.

- `_ContactCard` — name, phone, relation label (human-readable: `madre` → `Mamá`), primary badge, edit and delete icon buttons
- `_ContactSheet` — bottom sheet form: name/phone text fields + relation dropdown + primary toggle
- `_EmptyBadge` — amber warning when the rider has no contacts saved
- `_OnboardingFooter` — "Continuar" button enabled only once `contacts.isNotEmpty`, navigates to `/onboarding/consent`
- Uses `FutureProvider.autoDispose` so the list always reflects the latest DB state on re-entry

### IoT API Client (Quasar Infotech / Thony)

Sprint 4C introduces the abstraction layer for the Quasar Infotech IoT platform (integration partner: Thony), following the same pattern as `CarrierApiClient`.

**`IotApiClient`** — abstract interface:

```dart
abstract class IotApiClient {
  Future<IotPolicyResponse> issuePolicy(IotPolicyRequest request);
}
```

**`StubIotClient`** — returns a deterministic successful response with:

- `policyNumber`: `QIT-MB-2026-{timestamp}`
- `digitalCardUrl`, `fullPdfUrl`, `receiptUrl`: stub Supabase Storage paths
- `pairingCode`: 6-digit numeric code for IoT device pairing

**`IotPayloadMapper`** — normalises `OnboardingData` + `PolicyData` into Quasar Infotech's expected format:

| Internal            | Quasar Format           |
| ------------------- | ----------------------- |
| `rcv_basico`        | `basic`                 |
| `rcv_accidentes`    | `comprehensive_plus`    |
| `rcv_ampliada`      | `premium`               |
| `AB-123-CD` (plate) | `AB123CD` (no dashes)   |
| `0414-123-4567`     | `+584141234567` (E.164) |
| `DateTime`          | `YYYY-MM-DD`            |
| `V` + `12345678`    | `V-12345678`            |

### EmergencyScreen — Full Rewrite (RS-097)

The emergency button screen was rebuilt to model the full dispatch lifecycle:

**New enums:**

```dart
enum UrgencyLevel { accidentWithInjuries, accidentNoInjuries, assistanceOnly }
enum EmergencyActivationType { manual, autoFall }
enum _DispatchPhase { countdown, sentToService, sentToAll }
```

**Urgency triage sheet** (`_UrgencySheet`) — shown before the countdown for manual activations. Rider selects one of three urgency levels; each drives:

- The SOS ring colour (`_PulsingSosRing`)
- The assistance type sent to the service (medical vs. roadside vs. tow)
- The copy in `_ActivatedView`

**Phase-aware dispatch:**

| Phase           | Trigger                   | Cancel behaviour                           |
| --------------- | ------------------------- | ------------------------------------------ |
| `countdown`     | Immediately on activation | Pops screen, no dispatch                   |
| `sentToService` | At 50% of countdown       | "I'm OK" flow; service notified            |
| `sentToAll`     | Countdown reaches zero    | "I'm OK" flow; contacts + service notified |

**`_ActivatedView`** — shown after dispatch:

- `caseId`: `RS-EMG-{milliseconds_epoch}`
- Live list of notified emergency contacts fetched from `EmergencyContactRepository`
- Phase-indicator row (`_PhaseIndicators`) with animated dots

**Auto-fall activation path** (`EmergencyActivationType.autoFall`):

- Skips urgency sheet (assumes `accidentWithInjuries`)
- Uses a longer countdown (configurable, defaults to 30 s)
- Shows different copy: "Caída detectada" vs. "Activación manual"

### EmergencySetupScreen — 5-Page Wizard (RS-098)

A guided setup wizard that introduces the emergency feature and lets the rider configure response timers.

**Pages:**

1. **Pitch** — "Activa tu respaldo en la calle" emotional copy + feature overview. Two CTAs: "Activarlo ahora" and "Hacerlo después" (defers setup).
2. **Contacts review** — reads `EmergencyContactRepository`; shows existing contacts or a hint linking to the contacts screen.
3. **Timers** — `_TimerSelector` chips for:
   - Contact notification delay: 10 / 30 / 60 / 120 seconds
   - Assistance request delay: 15 / 20 / 30 seconds
4. **Tutorial** — 4 illustrated steps: detect → alert → notify contact → request assistance.
5. **Confirm** — summary of the saved configuration + a 5-second mock countdown preview. "Volver al inicio" completes the wizard.

Timer preferences are persisted to `SharedPreferences` under:

- `emergency_contact_timer_secs`
- `emergency_assist_timer_secs`
- `emergency_setup_done` (boolean gate)

### Router Updates (RS-099)

New routes registered in `mobile/lib/app/router.dart`:

| Route                            | Screen                                          | Notes                                                   |
| -------------------------------- | ----------------------------------------------- | ------------------------------------------------------- |
| `/onboarding/emergency-contacts` | `EmergencyContactsScreen(onboardingMode: true)` | Added to `_onboardingRoutes` list                       |
| `/emergency/setup`               | `EmergencySetupScreen(fromOnboarding: bool)`    | `?fromOnboarding=true` query param                      |
| `/emergency`                     | `EmergencyScreen(activationType: ...)`          | Now accepts `EmergencyActivationType` via `state.extra` |

Onboarding chain updated: `address` → **`emergency-contacts`** → `consent`.

---

## 5. Sprint 4D — Digital Carnet, Payments & Profile Wiring

### RS-101: QR Digital Policy Carnet

Riders now have a **Carnet Digital** — a visual, shareable card with an embedded QR code that proves active coverage to traffic police.

**`PolicyCardService`** (`mobile/lib/features/policy/services/policy_card_service.dart`):

- `generateQrData(...)` — encodes `{id, num, plate, holder, tier, exp}` as compact JSON
- `tierLabel(tier)` — maps `'basica'` → `'RCV Básica'`, etc.

**`PolicyCarnetScreen`** (`mobile/lib/features/policy/presentation/screens/policy_carnet_screen.dart`):

- Works in both **demo mode** (mock data) and **real mode** (`policyDetailProvider` fetch)
- `_CarnetCard` widget — dark navy gradient card matching brand identity, with:
  - Plate number displayed large and centered in a white box
  - Holder name, ID, vehicle, plan, carrier
  - `QrImageView` (128 × 128 px, square modules, navy colour on white)
  - ACTIVA / PROVISIONAL status badge top-right
  - Policy number + expiry in the footer
- Share action via `SharePlus` — exports a text summary with all key policy fields
- Copy-to-clipboard action for the policy number

**Navigation:**

- Route: `/policy/:id/carnet`
- "Ver Carnet Digital (QR)" button added to `PolicyDetailScreen` between PDF download and "Renovar"
- "Ver Carnet Digital" button also in `_SuccessView` of `EmissionScreen` (only when `policyId` is non-null)

**Dependency added:** `qr_flutter: ^4.1.0`

### RS-102: Post-Emission Document Delivery

`_SuccessView` in `EmissionScreen` now includes three additional actions after the main "Ver mi póliza" button:

| Button                  | Action                                                                                                                     |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| Ver Carnet Digital (QR) | `context.push('/policy/$policyId/carnet')` — only shown when `policyId != null`                                            |
| Compartir mi póliza     | `SharePlus.instance.share(...)` — text summary: plan name, price, carrier, "Protegido en la calle con cobertura inmediata" |
| Ir al inicio            | `context.go('/home')`                                                                                                      |

The share text is plain-text formatted for WhatsApp compatibility (no markdown, bullet symbols instead of `-`).

### RS-103: Profile Screen — Live Emergency Contacts

The `_EmergencySection` widget (which read legacy `profile.emergency_name / phone / relation` flat fields) is replaced by `_EmergencyContactsSection`, a `ConsumerWidget` that:

- **Demo mode** → renders the same mock contact using the old `_InfoSection` pattern
- **Real mode** → watches `emergencyContactsProvider` and renders a live list from the `emergency_contacts` table:
  - Shows a compact avatar + name/phone/relation row per contact
  - "Principal" badge on the primary contact
  - "Gestionar contactos" TextButton navigates to `/profile/emergency-contacts`
  - Empty state shows an amber warning banner with "Agregar contactos de emergencia" CTA
- Section title updated: `'Contacto de emergencia'` → `'Contactos de emergencia'`

New router route: `/profile/emergency-contacts` → `EmergencyContactsScreen(onboardingMode: false)`

### RS-100: Débito Inmediato — UI Stub

A third payment method option is added to `PaymentMethodScreen`:

- **Index 2, icon `Icons.flash_on_rounded`**, title "Débito Inmediato", subtitle "Cobro directo desde tu cuenta bancaria"
- Orange "Próximamente" badge rendered inline in the title row
- When selected, `_DebitoInmediatoSection` renders an informational card explaining the feature (instant activation, no manual reference, compatible with main banks)
- Submit button label changes to `'Próximamente disponible'` and `onPressed` is `null` (disabled)
- `_canSubmit` returns `false` when method 2 is selected — prevents any accidental submission path

Integration with the actual bank API will follow once F. Ángeles confirms the developer contact for the real-time debit service.

---

## 6. Sprint 4E — IoT Crash Detection Demo

### Motivation

Before the 2026-04-10 integration meeting with Thony (Quasar Infotech), the team needed a **visual demonstration of the full crash-to-emergency lifecycle** — even though the MQTT broker credentials and crash-detection thresholds are not yet defined. Sprint 4E activates the hardware accelerometer and wires it into an observable demo screen that shows Thony exactly what data the app will send once his infrastructure is configured.

### Accelerometer Provider

`accelerometerProvider` (`StreamProvider.autoDispose<AccelerometerReading>`) subscribes to `sensors_plus` at **50 Hz** (`SensorInterval.gameInterval`). Each event maps to an `AccelerometerReading`:

```dart
final magnitude = sqrt(x² + y² + z²);
final gForce    = magnitude / 9.81;   // normalised to Earth gravity
```

`autoDispose` ensures the accelerometer stops polling as soon as the monitor screen is dismissed — no battery drain in the background.

`CrashThresholdNotifier` (`NotifierProvider<double>`) stores the user-adjustable detection threshold (default **2.5 G**). The screen exposes a slider (1.5–5.0 G) so the demo operator can show different sensitivity levels.

### CrashMonitorScreen

Accessible from the home screen via the "Detección de caídas" IoT card (→ `/telemetry/crash-monitor`).

**Layout:**

| Zone             | Content                                                                                                                                                 |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AppBar badge     | "En vivo" (green) / "Simulador" (grey) depending on sensor availability                                                                                 |
| G-force gauge    | Circular arc gauge (270°); color transitions green → amber → red as G-force approaches threshold; tick mark at threshold angle; peak G-force chip       |
| Axis row         | X / Y / Z raw values in m/s² (hidden when no sensor)                                                                                                    |
| Threshold slider | 1.5 G → 5.0 G, real-time; orange tick on gauge updates live                                                                                             |
| MQTT preview     | Mock JSON payload showing topic structure and 15-min buffer shape — the exact format that will be sent to Quasar Infotech once credentials are provided |
| Bottom button    | Red "Simular impacto fuerte" → triggers emergency flow                                                                                                  |

**Platform behaviour:**

- **Android / iOS (real device):** Live accelerometer data at 50 Hz; shaking or dropping the phone will trigger the emergency if G-force exceeds the threshold.
- **Windows / Chrome (demo environment):** `sensors_plus` has no hardware to read → stream never emits → badge shows "Simulador" and sensor row shows an info message. The simulate button works on all platforms.

**Auto-trigger:** When the stream emits a reading ≥ threshold, the screen performs a 1.4-second "impact detected" red flash, then pushes `EmergencyScreen(activationType: EmergencyActivationType.autoFall)`. This is the same code path the real Phase 1.5 background service will use.

### MQTT Payload Preview

The screen shows a mock payload to anchor the Thony meeting discussion:

```json
// topic: rs/telemetry/{device_id}/anomaly
{
  "event": "impact_detected",
  "g_force": 3.84,
  "timestamp": "2026-04-10T15:32:01Z",
  "lat": 10.488,
  "lng": -66.8792,
  "policy_id": "RS-2026-001234",
  "window_15m": [
    { "t": -14.9, "g": 0.98 },
    { "t": -0.02, "g": 3.84 }
  ]
}
```

The `window_15m` field references the `TelemetryBufferService` (15-minute SQLite ring buffer built in Sprint 3), which will supply the real pre-impact window once Phase 1.5 background collection is activated.

### What Sprint 4E Does NOT Do

- Does **not** activate background accelerometer collection (sensor is only on while the monitor screen is visible)
- Does **not** write samples to `TelemetryBufferService` during the demo stream (avoids SQLite thrash at 50 Hz)
- Does **not** send real MQTT messages (broker URL/credentials pending Thony)

---

## 7. Database Changes (Sprints 4A–4C)

### Migration: `rs088_emergency_contacts_and_profiles_geo`

```sql
-- New table
CREATE TABLE emergency_contacts (...);
CREATE UNIQUE INDEX emergency_contacts_one_primary ON emergency_contacts (profile_id) WHERE is_primary = true;

-- Profiles enhancements
ALTER TABLE profiles
  ADD COLUMN latitude          double precision,
  ADD COLUMN longitude         double precision,
  ADD COLUMN address_from_gps  text;

-- Vehicles enhancements
ALTER TABLE vehicles
  ADD COLUMN vehicle_body_type text,
  ADD COLUMN serial_niv        text,
  ADD COLUMN seats             smallint;
```

### Migration: `rs096_policies_iot_fields_and_conductor_frecuente`

```sql
-- IoT integration output fields
ALTER TABLE policies
  ADD COLUMN iot_card_url       text,
  ADD COLUMN iot_pdf_url        text,
  ADD COLUMN iot_transaction_id text,
  ADD COLUMN iot_pairing_code   text;

-- Conductor frecuente
ALTER TABLE policies
  ADD COLUMN frequent_driver_name    text,
  ADD COLUMN frequent_driver_id      text,
  ADD COLUMN frequent_driver_id_type text;

-- Payment methods
ALTER TYPE payment_method ADD VALUE 'debito_inmediato';
```

### RLS Summary

| Table                | Policy                                 | Effect                                                 |
| -------------------- | -------------------------------------- | ------------------------------------------------------ |
| `emergency_contacts` | `Riders manage own emergency contacts` | Full CRUD on own rows only (`profile_id = auth.uid()`) |

---

## 8. Architecture Changes

### New Feature Structure: `emergency/data/`

```
features/emergency/
├── data/
│   └── emergency_contact_repository.dart    ← NEW (Sprint 4C)
└── presentation/screens/
    ├── emergency_screen.dart                 ← REWRITTEN (Sprint 4C)
    ├── emergency_contacts_screen.dart        ← NEW (Sprint 4C)
    └── emergency_setup_screen.dart           ← NEW (Sprint 4C)
```

### New Feature Structure: `policy/data/` (IoT)

```
features/policy/data/
├── carrier_api_client.dart                  ← existing (Sprint 3)
├── iot_api_client.dart                      ← NEW (Sprint 4C)
└── iot_payload_mapper.dart                  ← NEW (Sprint 4C)
```

### New Feature Structure: `policy/services/` (Sprint 4D)

```
features/policy/services/
├── policy_pdf_service.dart                  ← existing (Sprint 3)
└── policy_card_service.dart                 ← NEW (Sprint 4D)
```

`PolicyCardService` is a pure Dart service (no Flutter dependencies) that generates the QR payload string. Keeping it separate from `PolicyCarnetScreen` makes it trivially unit-testable and reusable in future Edge Functions or background jobs.

### New Feature Structure: `telemetry/presentation/` (Sprint 4E)

```
features/telemetry/
├── services/
│   └── telemetry_buffer_service.dart            ← existing (Sprint 3 — SQLite ring buffer)
└── presentation/
    ├── providers/
    │   └── accelerometer_provider.dart          ← NEW (Sprint 4E)
    └── screens/
        └── crash_monitor_screen.dart            ← NEW (Sprint 4E)
```

The telemetry feature now has a proper `presentation/` layer. Background collection (Phase 1.5) will add a `services/crash_detection_service.dart` once the MQTT spec is confirmed with Thony.

### Onboarding State Growth

`OnboardingData` now accumulates across 9 screens (up from 5 in Sprint 3):

```
plan → cédula → cédula confirm → certificado → certificado confirm
→ property validation → address + GPS → emergency contacts → consent
```

### `IotApiClient` vs `CarrierApiClient` — Separation of Concerns

The two API clients serve different purposes and are kept separate intentionally:

- `CarrierApiClient` — interacts with Venezuelan insurers (Pirámide, Caracas, Mercantil) for policy issuance and status
- `IotApiClient` — interacts with Quasar Infotech's platform (Thony) for IoT device pairing and digital document delivery

A single policy issuance will call **both** clients: carrier first (to get the policy number), then IoT (to register the device and get digital docs).

---

## 9. Testing

### New Test Files

| File                                                                         | Coverage                                                       | Sprint |
| ---------------------------------------------------------------------------- | -------------------------------------------------------------- | ------ |
| `test/features/onboarding/domain/onboarding_notifier_test.dart`              | `OnboardingNotifier` state transitions, cross-validation       | 4A     |
| `test/features/onboarding/presentation/cedula_confirm_screen_test.dart`      | Field display, manual override, navigation                     | 4A     |
| `test/features/onboarding/presentation/certificado_confirm_screen_test.dart` | Vehicle field parsing display                                  | 4A     |
| `test/features/onboarding/presentation/plan_selection_screen_test.dart`      | Plan card render, tap navigation                               | 4B     |
| `test/features/onboarding/presentation/property_validation_screen_test.dart` | Property type selection                                        | 4B     |
| `test/features/onboarding/presentation/helpers/test_helpers.dart`            | Shared `ProviderScope` + router overrides                      | 4A–4B  |
| `test/features/telemetry/providers/accelerometer_provider_test.dart`         | `AccelerometerReading` physics, `CrashThresholdNotifier` state | 4E     |

### Test Counts (as of 2026-04-09)

| Status  | Count                                                                                                                   |
| ------- | ----------------------------------------------------------------------------------------------------------------------- |
| Passing | 321                                                                                                                     |
| Skipped | 12                                                                                                                      |
| Failing | 1 (pre-existing `widget_test.dart` smoke test — `pumpAndSettle` timeout due to Supabase init; unrelated to sprint work) |

### Testing Approach

- All widget tests use `mocktail` mocks for repository classes
- `test_helpers.dart` provides `buildTestWidget(widget, overrides)` that wraps with `ProviderScope` + `MaterialApp.router` pointed at a test `GoRouter`
- OCR-dependent screens (`CedulaScanScreen`, `CertificadoScanScreen`) are not widget-tested (MLKit requires device camera); covered by domain unit tests only
- `sensors_plus` stream provider is not unit-tested (requires native platform channel); the pure-Dart logic (G-force calculation, threshold notifier) has full unit test coverage

---

## 10. Security

- **RLS enforced on `emergency_contacts`**: riders cannot read or modify another rider's emergency contacts
- **No raw phone numbers logged**: `IotPayloadMapper.toE164Venezuela()` never logs the input or output
- **`StubIotClient` is the only active IoT client**: real HTTP calls to Quasar Infotech are blocked until `QUASAR_API_KEY` is set via `--dart-define` and `IotApiClient` is swapped from the stub
- **`EmergencyContactRepository.insert()`** uses a DB-level transaction — the partial unique index prevents race-condition double-primary states
- Emergency contact data is never included in Sentry crash reports (`EmergencyContact` is not serialised to any analytics sink)

---

## 11. Known Limitations & Sprint 5 Preview

### Current Limitations

| Item                            | Notes                                                                                                                                                                                                                                 |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `IotApiClient` stub only        | Real Quasar Infotech integration awaiting API key + endpoint docs from Thony (RS-105)                                                                                                                                                 |
| `CarrierApiClient` stub only    | Seguros Pirámide / Caracas / Mercantil real credentials pending William (RS-104)                                                                                                                                                      |
| Crash detection — demo only     | `CrashMonitorScreen` shows live G-force and simulates the emergency trigger. Background continuous monitoring (Phase 1.5) requires MQTT credentials from Thony + policy decision on `background_fetch` / `flutter_background_service` |
| WhatsApp delivery (server-side) | `share_plus` share from the app is live (RS-102). Server-side proactive delivery (Twilio/MessageBird template) still requires outbound template approval                                                                              |
| Débito Inmediato                | UI stub implemented (RS-100). Real bank API integration awaiting F. Ángeles developer contact                                                                                                                                         |
| QR verify-policy Edge Function  | Carnet QR encodes policy data; the `verify-policy` Edge Function that validates the QR server-side is not yet deployed (requires SUDEASEG integration agreement)                                                                      |
| Push notifications              | FCM project configuration pending (RS-106)                                                                                                                                                                                            |

### Sprint 5 Preview — Real-World Integrations

| Ticket | Description                                                                   |
| ------ | ----------------------------------------------------------------------------- |
| RS-104 | Real `CarrierApiClient` for Seguros Pirámide (awaiting William)               |
| RS-105 | Real `IotApiClient` for Quasar Infotech (awaiting Thony)                      |
| RS-106 | Push notifications — FCM + policy status webhooks                             |
| RS-107 | `verify-policy` Edge Function — QR code server-side validation                |
| RS-108 | Débito Inmediato real bank integration (F. Ángeles contact)                   |
| RS-109 | Proactive WhatsApp/email delivery after policy confirmation (Twilio template) |
| RS-110 | Admin portal: broker policy review queue + carrier emission dashboard         |

---

## Appendix — New File Index

| File                                                                                  | Type             | Sprint |
| ------------------------------------------------------------------------------------- | ---------------- | ------ |
| `mobile/lib/features/onboarding/domain/cedula_parser.dart`                            | Domain           | 4A     |
| `mobile/lib/features/onboarding/domain/onboarding_state.dart`                         | Domain           | 4A     |
| `mobile/lib/features/onboarding/presentation/screens/cedula_scan_screen.dart`         | Screen           | 4A     |
| `mobile/lib/features/onboarding/presentation/screens/cedula_confirm_screen.dart`      | Screen           | 4A     |
| `mobile/lib/features/onboarding/presentation/screens/certificado_scan_screen.dart`    | Screen           | 4A     |
| `mobile/lib/features/onboarding/presentation/screens/certificado_confirm_screen.dart` | Screen           | 4A     |
| `mobile/lib/features/onboarding/presentation/screens/address_form_screen.dart`        | Screen           | 4A     |
| `mobile/lib/features/onboarding/presentation/screens/plan_selection_screen.dart`      | Screen           | 4B     |
| `mobile/lib/features/onboarding/presentation/screens/property_validation_screen.dart` | Screen           | 4B     |
| `mobile/lib/features/emergency/data/emergency_contact_repository.dart`                | Repository       | 4C     |
| `mobile/lib/features/emergency/presentation/screens/emergency_contacts_screen.dart`   | Screen           | 4C     |
| `mobile/lib/features/emergency/presentation/screens/emergency_setup_screen.dart`      | Screen           | 4C     |
| `mobile/lib/features/emergency/presentation/screens/emergency_screen.dart`            | Screen (rewrite) | 4C     |
| `mobile/lib/features/policy/data/iot_api_client.dart`                                 | Data             | 4C     |
| `mobile/lib/features/policy/data/iot_payload_mapper.dart`                             | Data             | 4C     |
| `mobile/lib/features/policy/services/policy_card_service.dart`                        | Service          | 4D     |
| `mobile/lib/features/policy/presentation/screens/policy_carnet_screen.dart`           | Screen           | 4D     |
| `mobile/lib/features/telemetry/presentation/providers/accelerometer_provider.dart`    | Provider         | 4E     |
| `mobile/lib/features/telemetry/presentation/screens/crash_monitor_screen.dart`        | Screen           | 4E     |
| `mobile/test/features/telemetry/providers/accelerometer_provider_test.dart`           | Test             | 4E     |
