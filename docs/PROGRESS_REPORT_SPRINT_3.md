# RuedaSeguro — Technical Progress Report
## Sprint 3 — Policy Lifecycle, Real Claims, Tickets & Observability
**As of:** 2026-03-29 | **Prepared by:** Engineering
**Continues from:** `docs/PROGRESS_REPORT_SPRINTS_1_2A_2B.md`

---

## Table of Contents

1. [Sprint 3 Overview](#1-sprint-3-overview)
2. [Architecture Changes](#2-architecture-changes)
3. [Carrier API Client (RS-060)](#3-carrier-api-client-rs-060)
4. [Policy Issuance Service (RS-061)](#4-policy-issuance-service-rs-061)
5. [Emission Screen Enhancements (RS-062)](#5-emission-screen-enhancements-rs-062)
6. [Provisional Banner on Policy Detail](#6-provisional-banner-on-policy-detail)
7. [Real Claim Submission (RS-067)](#7-real-claim-submission-rs-067)
8. [Support Ticket System (RS-068)](#8-support-ticket-system-rs-068)
9. [Sentry Crash Reporting (RS-070)](#9-sentry-crash-reporting-rs-070)
10. [Telemetry Buffer Service (RS-071)](#10-telemetry-buffer-service-rs-071)
11. [Database Additions](#11-database-additions)
12. [Edge Functions](#12-edge-functions)
13. [Admin Portal Deprecation](#13-admin-portal-deprecation)
14. [Bug Fixes Applied Post-Implementation](#14-bug-fixes-applied-post-implementation)
15. [Audit Events (Complete Catalogue)](#15-audit-events-complete-catalogue)
16. [Testing](#16-testing)
17. [Security](#17-security)
18. [Known Limitations & Sprint 4 Preview](#18-known-limitations--sprint-4-preview)
19. [How to Run (Sprint 3 additions)](#19-how-to-run-sprint-3-additions)

---

## 1. Sprint 3 Overview

Sprint 3 closes the policy lifecycle loop and introduces real data writes for every major rider action. The app transitions from provisional-only to a full confirmed/provisional dual-path. Claims move from a UI stub to a real Supabase workflow with Cloudflare-hosted photo evidence. A support ticket system is live. Sentry crash reporting is initialized. Two backend cron functions handle policy retries and renewal reminders.

### Completed tickets

| Ticket | Description | Status |
|--------|-------------|--------|
| RS-060 | Carrier API client interface + Seguros Pirámide stub | ✅ Interface built; stub active; real client awaiting William's docs |
| RS-061 | Policy issuance state machine (provisional → confirmed) | ✅ Full state machine with DB transitions and audit trail |
| RS-062 | Emission screen: confirmed vs provisional flow | ✅ 4-step loading, confirmed/provisional states, carrier fallback |
| RS-066 | Renewal reminder Edge Function | ✅ Deployed; Pago Móvil deep-link generation; audit events |
| RS-067 | Real claim submission with photo evidence | ✅ Full camera flow, Supabase writes, schema enhanced |
| RS-068 | Support ticket creation | ✅ 5-category screen, TicketRepository, route wired |
| RS-070 | Sentry Flutter initialization | ✅ Conditional on SENTRY_DSN dart-define; screenshots + hierarchy |
| RS-071 | Telemetry buffer service (SQLite) | ✅ 15-min ring buffer; sensor activation deferred to Phase 1.5 |
| RS-073 | Admin portal deprecation | ✅ DEPRECATED.md committed; CI/CD pointing frozen |

### Deferred to Sprint 4 (external dependencies)

| Ticket | Blocker |
|--------|---------|
| RS-060 (real) | William's Acsel/Sirway sandbox credentials and API docs pending |
| RS-063 | MessageBird already live — Twilio reference in earlier planning docs was incorrect; no action needed |
| RS-059 | MQTT client — low priority; Thony's platform uses Supabase Realtime as fallback |
| RS-065 | Push notifications — Firebase `google-services.json` (Android) + `GoogleService-Info.plist` (iOS) not yet configured |

---

## 2. Architecture Changes

### New files (Sprint 3)

```
mobile/lib/
├── features/
│   ├── policy/data/
│   │   ├── carrier_api_client.dart        ← CarrierApiClient interface + StubCarrierClient
│   │   └── policy_issuance_service.dart   ← PolicyIssuanceService state machine
│   ├── claims/data/
│   │   └── claim_repository.dart          ← Real Supabase claim + photo upload
│   ├── support/
│   │   ├── data/ticket_repository.dart    ← TicketRepository CRUD
│   │   └── presentation/screens/
│   │       └── create_ticket_screen.dart  ← 5-category ticket creation screen
│   └── telemetry/services/
│       └── telemetry_buffer_service.dart  ← SQLite 15-min circular buffer
supabase/
├── functions/
│   ├── policy-retry/index.ts              ← Retry provisional policies (max 3 attempts)
│   └── renewal-reminder/index.ts         ← Generate Pago Móvil renewal links (30-day window)
├── queries/
│   ├── RS-060_carrier_api_config.sql      ← carrier_api_config table + Seguros Pirámide stub row
│   └── RS-067_claims_enhancements.sql     ← Adds claim_number, incident columns, retain_until trigger
admin-portal/
└── DEPRECATED.md                          ← Decision record: frozen permanently
```

### Modified files (Sprint 3)

| File | Changes |
|------|---------|
| `mobile/lib/app/router.dart` | Added `/support/new-ticket` → `CreateTicketScreen()` |
| `mobile/lib/main.dart` | Wrapped `runApp` in `SentryFlutter.init()` |
| `mobile/pubspec.yaml` | Added `sentry_flutter: ^8.0.0`; `sqflite_common_ffi: ^2.3.4` (dev) |
| `mobile/lib/core/config/env_config.dart` | Added `sentryDsn` dart-define |
| `mobile/lib/core/constants/supabase_constants.dart` | Added Sprint 3 table + Edge Function constants |
| `mobile/lib/features/claims/presentation/screens/new_claim_screen.dart` | Full rewrite: stub → real ConsumerStatefulWidget |
| `mobile/lib/features/policy/presentation/screens/emission_screen.dart` | Carrier integration, confirmed state, `fetchVehiclePlate` |
| `mobile/lib/features/policy/presentation/screens/policy_detail_screen.dart` | `_ProvisionalBanner` widget |
| `mobile/lib/features/policy/data/policy_repository.dart` | Added `fetchVehiclePlate(vehicleId)` |

### Updated data flow

```
Flutter App
  │
  ├─► Supabase Auth (phone OTP via MessageBird)
  │
  ├─► Supabase PostgREST (profiles, policies, payments, claims, tickets)
  │
  ├─► Supabase Storage / receipts bucket
  │       ├── {userId}/claims/{claimId}/{index}.jpg    ← NEW: claim photos
  │       └── {userId}/{paymentRef}.jpg                ← existing: payment receipts
  │
  ├─► bcv-rate Edge Function ──► pydolarve.org / alcambio.app
  │
  ├─► CarrierApiClient (StubCarrierClient in dev; AcselSirwayClient in production)
  │
  ├─► policy-retry Edge Function ──► carrier API (cron, every 15 min)
  │
  ├─► renewal-reminder Edge Function ──► renewal_links table (cron, daily)
  │
  ├─► Sentry SDK ──► sentry.io (crash reports + transactions)
  │
  └─► TelemetryBufferService (SQLite, local only — Phase 1.5 will upload to telemetry_events)
```

---

## 3. Carrier API Client (RS-060)

**File:** `mobile/lib/features/policy/data/carrier_api_client.dart`

### Design

The carrier integration is built as an **abstract interface** (`CarrierApiClient`) with a **stub implementation** (`StubCarrierClient`). When William provides the Acsel/Sirway sandbox credentials and API documentation, an `AcselSirwayClient` will be implemented and swapped in `PolicyIssuanceService._client` — no other files require changes.

### `CarrierSubmissionPayload`

```dart
class CarrierSubmissionPayload {
  final String policyId;
  final String riderCedula;      // V-12345678
  final String riderIdType;      // 'V' | 'E' | 'CC'
  final String riderFullName;
  final String riderPhone;       // E.164
  final String vehiclePlate;     // 'ABC-123-DE' (not UUID — bug fixed post-impl)
  final String vehicleBrand;
  final String vehicleModel;
  final int    vehicleYear;
  final DateTime startDate;
  final DateTime endDate;
  final double premiumUsd;
  final String productCode;      // maps to product_code_basica/plus/premium in carrier_api_config
}
```

### `CarrierApiResult`

```dart
class CarrierApiResult {
  final bool    isSuccess;
  final String? policyNumber;    // carrier-assigned number (e.g., 'ACL-ABC123-1711000000')
  final String? errorMessage;

  factory CarrierApiResult.confirmed({required String policyNumber})
  factory CarrierApiResult.failed({required String error})
}
```

### `CarrierApiClient` (abstract)

```dart
abstract class CarrierApiClient {
  Future<CarrierApiResult> submitPolicy(CarrierSubmissionPayload payload);
}
```

### `StubCarrierClient`

- `const` class (stateless)
- `submitPolicy()` → artificial 2-second delay → always returns `CarrierApiResult.confirmed`
- Policy number format: `STUB-{vehiclePlate.replaceAll('-','')}-{epoch_seconds}`
- Used in all dev/staging environments

### Swap instructions (when William delivers docs)

```dart
// In policy_issuance_service.dart, change:
final CarrierApiClient _client = const StubCarrierClient();
// To:
final CarrierApiClient _client = AcselSirwayClient(
  baseUrl: Deno.env.get('ACSEL_BASE_URL'),
  authToken: Deno.env.get('ACSEL_API_KEY'),
);
```

Also: set `is_active = true` in `carrier_api_config` and store credentials in Supabase Vault.

---

## 4. Policy Issuance Service (RS-061)

**File:** `mobile/lib/features/policy/data/policy_issuance_service.dart`

### State machine

```
                           attemptIssuance()
                                │
                    ┌───────────▼────────────┐
                    │  Mark api_submitted     │
                    │  carrier_api_attempts++ │
                    └───────────┬────────────┘
                                │
                   ┌────────────▼────────────┐
                   │  CarrierApiClient        │
                   │  .submitPolicy()         │
                   └──────┬──────────┬────────┘
                          │ success  │ failure / timeout
              ┌───────────▼──┐   ┌───▼──────────────────┐
              │  confirmed   │   │  provisional          │
              │  status=active│  │  provisional_issued_at│
              │  carrier_     │  │  (retry queue picks   │
              │  policy_num   │  │   this up via cron)   │
              └──────────────┘   └───────────────────────┘
```

### `IssuanceResult`

```dart
enum IssuanceOutcome { confirmed, provisional }

class IssuanceResult {
  final IssuanceOutcome outcome;
  final String? carrierPolicyNumber;
  final String? errorMessage;

  bool get isConfirmed → outcome == IssuanceOutcome.confirmed

  factory IssuanceResult.confirmed({required String policyNumber})
  factory IssuanceResult.provisional({String? reason})
}
```

### `PolicyIssuanceService.attemptIssuance()`

Full sequence (within one call):

1. **Read attempt count** from `policies` table
2. **Mark `api_submitted`**: `UPDATE policies SET issuance_status='api_submitted', carrier_api_attempts = carrier_api_attempts + 1`
3. **Emit audit** `policy.api_submitted` (non-blocking)
4. **Call carrier** `_client.submitPolicy(payload)` with 10-second internal timeout
5. **On success:**
   - `UPDATE policies SET issuance_status='confirmed', carrier_policy_number=..., status='active'`
   - Emit audit `policy.confirmed` with `carrier_policy_number` in payload
   - Return `IssuanceResult.confirmed(...)`
6. **On failure:**
   - Call `_setProvisional(policyId, reason)`
   - Emit audit `policy.issuance_failed` with `reason`
   - Return `IssuanceResult.provisional(reason: ...)`

### `_setProvisional(policyId, reason)`

```dart
// Sets issuance_status back to 'provisional'; stamps provisional_issued_at.
UPDATE policies
  SET issuance_status = 'provisional',
      provisional_issued_at = NOW()
  WHERE id = policyId
```

### Timeout handling in emission screen

The emission screen wraps `attemptIssuance()` with a 15-second Flutter-level timeout on top of the service's internal 10-second carrier timeout:

```dart
final issuance = await PolicyIssuanceService.instance
    .attemptIssuance(policyId: policyId, profileId: profileId, payload: issuancePayload)
    .timeout(
      const Duration(seconds: 15),
      onTimeout: () => IssuanceResult.provisional(reason: 'timeout'),
    );
```

If the timeout fires, `issuance_status` may be `api_submitted` in the DB (the service didn't get a chance to update it back). The `policy-retry` Edge Function handles this case.

---

## 5. Emission Screen Enhancements (RS-062)

**File:** `mobile/lib/features/policy/presentation/screens/emission_screen.dart`

### `_EmissionState` enum

```dart
enum _EmissionState { loading, success, confirmed, observed, rejected }
```

- `success` — provisional path (stub failed, timeout, or demo mode)
- `confirmed` — carrier API confirmed the policy (stub always takes this path in dev)
- `observed` — carrier returned "needs review" (UI ready; not yet triggered by stub)
- `rejected` — unexpected error during emission

### Loading view — 4 steps

```dart
[
  'Verificando datos del vehículo',
  'Registrando póliza provisional',
  'Guardando referencia de pago',
  'Contactando a la aseguradora...',   // ← NEW in Sprint 3
]
```

Each step animates in with a `CircularProgressIndicator` and `FadeIn + SlideX` via `flutter_animate`. Steps are staggered at 600ms, 1000ms, 1400ms, 1800ms.

### AppBar title by state

| State | Title | Color |
|-------|-------|-------|
| `confirmed` | "Póliza confirmada" | `RSColors.success` |
| `success` | "Póliza registrada" | `RSColors.success` |
| `observed` | "Requiere corrección" | `Color(0xFFE65100)` (deep orange) |
| `rejected` | "Error de emisión" | `RSColors.error` |

### `_SuccessView` changes

New `isConfirmed: bool` parameter:

| `isConfirmed` | Headline | Body copy |
|---|---|---|
| `true` | "¡Póliza confirmada!" | "Tu póliza fue registrada y confirmada por la aseguradora. Ya tienes cobertura RCV activa." |
| `false` | "¡Solicitud registrada!" | "Tu póliza provisional está registrada. Verificaremos tu pago en menos de 24 horas y la activaremos." |

The `_PolicyPreviewCard` inside `_SuccessView` continues to show the `PROVISIONAL` amber badge and "Activación en ≤ 24 h" footer regardless of `isConfirmed` — the card represents what was shown during the loading phase before the carrier response arrived.

### `_emit()` full sequence (authenticated mode)

```dart
// 1. Resolve user
final profileId = user.id;

// 2. Fetch vehicle UUID
final vehicleId = await PolicyRepository.instance.fetchVehicleId(profileId);
// → throws if null ("Vehículo no registrado")

// 3. Fetch vehicle plate (Sprint 3 bug fix — vehicleId is not the plate)
final vehiclePlate = await PolicyRepository.instance.fetchVehiclePlate(vehicleId) ?? '';

// 4. Determine carrier + policy type from InsurancePlan
final carrierId     = _plan.carrierId ?? '11111111-1111-1111-1111-111111111111';
final policyTypeId  = _plan.policyTypeId ?? _plan.id;

// 5. Create provisional policy
final policyId = await PolicyRepository.instance.createPolicyRecord(...);

// 6. Create payment record
final paymentId = await PaymentRepository.instance.createPaymentRecord(...);

// 7. Audit: policy.provisional_created + payment.submitted

// 8. Attempt carrier issuance (15s outer timeout)
final issuance = await PolicyIssuanceService.instance
    .attemptIssuance(policyId, profileId, issuancePayload)
    .timeout(15s, onTimeout: () => IssuanceResult.provisional(reason: 'timeout'));

// 9. Route to confirmed or success state
setState(() {
  _policyId = policyId;
  _state = issuance.isConfirmed ? _EmissionState.confirmed : _EmissionState.success;
});
```

---

## 6. Provisional Banner on Policy Detail

**File:** `mobile/lib/features/policy/presentation/screens/policy_detail_screen.dart`

### `_ProvisionalBanner` widget

Shown when `policy.isProvisional == true` (i.e., `issuanceStatus == 'provisional'`). Injected between the AppBar and the `_DigitalPolicyCard` using a conditional inside `_PolicyDetailBody.build()`:

```dart
if (policy != null && policy!.isProvisional)
  _ProvisionalBanner(policyId: policy!.id)
      .animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
if (policy != null && policy!.isProvisional)
  const SizedBox(height: RSSpacing.md),
```

**Visual design:**
- Background: `Color(0xFFFFF3E0)` (amber 50)
- Border: 1px `Color(0xFFFFB300)` (amber), radius 12
- Leading icon: `Icons.hourglass_top_rounded` (amber)
- Primary text: "Póliza Provisional" (bold, amber dark)
- Secondary text: "Tu póliza está siendo procesada. Recibirás confirmación en menos de 24 horas." (grey, 1.4 line height)

The banner is not shown for `confirmed`, `active`, or `expired` policies. Demo mode shows it because `MockPolicy` has `issuanceStatus = 'provisional'`.

---

## 7. Real Claim Submission (RS-067)

### 7.1 Database schema additions

**File:** `supabase/queries/RS-067_claims_enhancements.sql`

All additions use `ADD COLUMN IF NOT EXISTS` for idempotency. Run after the base `claims` table (RS-007) exists.

**`claims` table additions:**

| Column | Type | Notes |
|--------|------|-------|
| `claim_number` | `TEXT UNIQUE` | Auto-assigned: `SIN-{year}-{6-char-UUID-prefix}` |
| `incident_type` | `TEXT` | `'colision'` \| `'dano_tercero'` \| `'robo'` \| `'lesiones'` |
| `location` | `TEXT` | Free-text location of incident |
| `has_injuries` | `BOOLEAN NOT NULL DEFAULT false` | Whether people were injured |
| `incident_at` | `TIMESTAMPTZ` | When the incident occurred (user-selected) |
| `archived_at` | `TIMESTAMPTZ` | Soft-delete timestamp |
| `retain_until` | `DATE` | Auto-computed: `created_at + 7 years` (SUDEASEG requirement) |

**`retain_until` trigger:**

```sql
CREATE OR REPLACE FUNCTION _set_claim_retain_until()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.retain_until := (NEW.created_at AT TIME ZONE 'UTC' + INTERVAL '7 years')::DATE;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_claim_retain_until
  BEFORE INSERT ON claims
  FOR EACH ROW EXECUTE FUNCTION _set_claim_retain_until();
```

**Indexes added:**

```sql
CREATE INDEX IF NOT EXISTS idx_claims_profile ON claims (profile_id, created_at DESC) WHERE archived_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_claims_policy  ON claims (policy_id) WHERE policy_id IS NOT NULL;
```

**`claim_evidence` table additions:**

| Column | Type | Notes |
|--------|------|-------|
| `evidence_type` | `TEXT DEFAULT 'photo'` | `'photo'` \| `'document'` \| `'video'` |
| `file_url` | `TEXT` | Public URL from Supabase Storage |

### 7.2 `ClaimRepository`

**File:** `mobile/lib/features/claims/data/claim_repository.dart`

#### `createClaim()`

```dart
Future<({String claimId, String claimNumber})> createClaim({
  required String profileId,
  required String policyId,
  required String incidentType,
  required String description,
  String? location,
  bool hasInjuries = false,
  DateTime? incidentAt,
})
```

- Generates `claimId` via `Uuid().v4()`
- `claimNumber = 'SIN-${now.year}-${claimId.substring(0,6).toUpperCase()}'`
- Inserts into `claims` with `status: 'reported'`
- `incident_at` defaults to `DateTime.now().toUtc()` if not provided
- Returns a named record `({claimId, claimNumber})`

#### `uploadClaimPhoto()`

```dart
Future<String> uploadClaimPhoto({
  required String userId,
  required String claimId,
  required File photoFile,
  required int index,
}) → publicUrl
```

- **Storage path:** `{userId}/claims/{claimId}/{index}.{ext}`
- Bucket: `receipts` (existing; no new bucket created)
- **RLS compliance:** The existing RLS policy "Users can upload receipts to own folder" checks `auth.uid()::text = (storage.foldername(name))[1]`. Since the first path segment is `userId = auth.uid()`, the policy passes without schema changes.
- After upload: inserts a `claim_evidence` row with `evidence_type: 'photo'`, `file_url: publicUrl`
- `upsert: true` on upload (safe to retry)

### 7.3 `NewClaimScreen` (full rewrite)

**File:** `mobile/lib/features/claims/presentation/screens/new_claim_screen.dart`

The Sprint 2B version was a stub. The Sprint 3 version is a complete `ConsumerStatefulWidget`.

#### State fields

```dart
int _selectedType = 0;          // index into _incidentTypes
bool _isSubmitting = false;
bool _hasInjuries = false;
DateTime _incidentAt = DateTime.now();
List<XFile?> _photos = [null, null, null];   // 3 slots, minimum 2 required
TextEditingController _locationController;
TextEditingController _descriptionController;
ImagePicker _picker;
```

#### Incident types

```dart
const _incidentTypes = [
  _IncidentType(id: 'colision',    label: 'Colisión',         color: Color(0xFFC62828)),
  _IncidentType(id: 'dano_tercero',label: 'Daño a tercero',   color: Color(0xFFFF6D00)),
  _IncidentType(id: 'robo',        label: 'Robo / Hurto',     color: Color(0xFF6A1B9A)),
  _IncidentType(id: 'lesiones',    label: 'Lesiones',         color: Color(0xFF1A237E)),
];
```

#### Photo capture

```dart
final picked = await _picker.pickImage(
  source: ImageSource.camera,
  imageQuality: 75,
  maxWidth: 1280,
);
```

`_PhotoSlot` widget: shows `Image.file(File(photo.path))` as thumbnail with a green checkmark overlay when filled. Empty slots show a "+" icon with dashed grey border.

#### Date/time selection

- `showDatePicker(firstDate: DateTime.now() - 30 days, lastDate: DateTime.now())`
- `showTimePicker()` — populates `_incidentAt` while preserving the existing date
- Both displayed via `_DateTimeTile` (with edit pencil icon)

#### `_ActivePolicyBanner`

```dart
class _ActivePolicyBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policy = ref.watch(activePolicySummaryProvider);
    // Loading: shimmer skeleton
    // Data: shows plan name + display number
    // Error/null: "Sin póliza activa — solo puedes reportar si tienes cobertura vigente"
  }
}
```

#### `_submit()` sequence

```dart
// 1. Guard: minimum 2 photos
// 2. Guard: non-empty description
// 3. Demo mode (userId == null): fake 2s → SIN-{year}-DEMO01
// 4. Fetch active policy from activePolicySummaryProvider.future
//    → throws "No tienes una póliza activa" if null
// 5. ClaimRepository.createClaim(...) → ({claimId, claimNumber})
// 6. For each non-null photo:
//    ClaimRepository.uploadClaimPhoto(userId, claimId, File(photo.path), index++)
// 7. AuditRepository.logEvent('claim.reported', targetId: claimId, payload: {type, has_injuries, photos})
// 8. _showSuccess(claimNumber) → navigates to success view
```

#### `_SuccessView`

Inline success state showing claim number in a monospaced box (`RSTypography.mono`), formatted as `SIN-2026-AB12CD`. Single "Listo" button pops the screen.

---

## 8. Support Ticket System (RS-068)

### 8.1 `TicketRepository`

**File:** `mobile/lib/features/support/data/ticket_repository.dart`

#### `createTicket()`

```dart
Future<({String ticketId, String ticketNumber})> createTicket({
  required String profileId,
  required String category,   // 'payment' | 'policy' | 'claim' | 'app' | 'other'
  required String subject,
  required String description,
})
```

- Generates `ticketId` via `Uuid().v4()`
- `ticketNumber = 'TKT-${now.year}-${ticketId.substring(0,6).toUpperCase()}'`
- Derives `priority` from `category`:
  - `payment` → `'critical'`
  - `policy`, `claim` → `'high'`
  - `app` → `'medium'`
  - `other` → `'low'`
- Inserts into `tickets` with `status: 'open'`

#### `fetchRiderTickets(riderId)`

```dart
Future<List<Map<String, dynamic>>> fetchRiderTickets(String riderId)
// Returns last 20 open tickets for rider, ordered by created_at DESC
// Filters: status IN ('open', 'in_progress')
```

### 8.2 `CreateTicketScreen`

**File:** `mobile/lib/features/support/presentation/screens/create_ticket_screen.dart`

**Route:** `/support/new-ticket` (added to `router.dart`)

#### Category tiles

| Category | Icon | Color | Priority label |
|----------|------|-------|----------------|
| Pago | `payment_rounded` | Red | CRÍTICO |
| Póliza | `policy_rounded` | Orange | ALTO |
| Siniestro | `car_crash_rounded` | Orange | ALTO |
| App | `phone_android_rounded` | Teal | MEDIO |
| Otro | `help_outline_rounded` | Grey | BAJO |

Each tile shows the priority badge inline. Selecting a tile rebuilds the form with the corresponding `category` and `priority`.

#### Form

- **Category selector:** horizontal scrollable row of category tiles
- **Subject:** `RSTextField` (single-line, required, hint: "Asunto del reporte")
- **Description:** multiline `TextField` (min 3 lines, hint: "Describe el problema en detalle")
- Submit button disabled when subject is empty

#### `_SuccessView`

Shows ticket number in a `Container` with `RSTypography.mono` styling (same pattern as claim success). "Listo" button navigates back.

#### Demo mode

```dart
if (userId == null) {
  await Future.delayed(const Duration(milliseconds: 1500));
  _showSuccess('TKT-${DateTime.now().year}-DEMO01');
  return;
}
```

---

## 9. Sentry Crash Reporting (RS-070)

**File:** `mobile/lib/main.dart`

### Initialization

```dart
await SentryFlutter.init(
  (options) {
    options.dsn = EnvConfig.sentryDsn;
    options.environment = kDebugMode ? 'development' : 'production';
    options.tracesSampleRate = kDebugMode ? 1.0 : 0.1;
    options.attachScreenshot = true;
    options.attachViewHierarchy = true;
  },
  appRunner: () => runApp(
    ProviderScope(child: const RSApp()),
  ),
);
```

`SentryFlutter.init` wraps `runApp` — any error thrown during app startup is also captured.

### `EnvConfig.sentryDsn`

```dart
static const sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');
```

- Empty string → Sentry silently no-ops (safe to omit in local dev)
- Provided via `--dart-define=SENTRY_DSN=https://...@sentry.io/...`

### Configuration details

| Option | Dev | Production |
|--------|-----|------------|
| `tracesSampleRate` | `1.0` (100% of transactions) | `0.1` (10%) |
| `environment` | `'development'` | `'production'` |
| `attachScreenshot` | `true` | `true` |
| `attachViewHierarchy` | `true` | `true` |

### Credential table update

| Secret | Location | Never in |
|--------|----------|---------|
| `SENTRY_DSN` | `.env` (dart-define) | Git, hardcoded |

---

## 10. Telemetry Buffer Service (RS-071)

**File:** `mobile/lib/features/telemetry/services/telemetry_buffer_service.dart`

> **Note:** This service was referenced in the Sprint 2B report as Phase 1.5 prep. Sprint 3 delivered the full implementation. Sensor activation (`sensors_plus`, `geolocator`) remains commented out pending Alex's confirmation of the telemetry spec.

### Storage

- SQLite database: `rs_telemetry.db` (in app's SQLite directory via `getDatabasesPath()`)
- Table: `anomaly_queue`

```sql
CREATE TABLE anomaly_queue (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  recorded_at INTEGER NOT NULL,   -- millisecondsSinceEpoch
  g_force     REAL,
  latitude    REAL,
  longitude   REAL,
  altitude_m  REAL,
  speed_kmh   REAL
)
```

### `TelemetrySample` model

```dart
class TelemetrySample {
  final int      id;
  final DateTime recordedAt;
  final double?  gForce;
  final double?  latitude;
  final double?  longitude;
  final double?  altitudeM;
  final double?  speedKmh;
}
```

Full `toMap()` / `fromMap()` roundtrip support.

### `TelemetryBufferService` API

| Method | Description |
|--------|-------------|
| `init()` | Opens SQLite DB; idempotent (no-op if already open) |
| `insertSample({gForce, latitude, longitude, altitudeM, speedKmh})` | Inserts one row; auto-prunes every 50 inserts |
| `getWindow([Duration? window])` | Returns samples within `window` (default 15 min), sorted `recorded_at ASC` |
| `pruneOlderThan(Duration maxAge)` | Deletes rows where `recorded_at < now() - maxAge` |
| `clear()` | Truncates the table (call after successful upload) |
| `sampleCount` getter | `SELECT COUNT(*) FROM anomaly_queue` |
| `peakGForce` getter | `SELECT MAX(g_force) FROM anomaly_queue WHERE g_force IS NOT NULL` |

### Auto-prune

Every 50th `insertSample()` call triggers `pruneOlderThan(_maxWindow)` (15 minutes). This bounds memory consumption without requiring a background isolate.

### Phase 1.5 integration plan

```dart
// sensors_plus listener (to be activated in Phase 1.5):
accelerometerEvents.listen((AccelerometerEvent e) {
  final gForce = sqrt(e.x*e.x + e.y*e.y + e.z*e.z) / 9.81;
  TelemetryBufferService.instance.insertSample(
    gForce: gForce,
    latitude: currentPosition.latitude,
    longitude: currentPosition.longitude,
    speedKmh: currentPosition.speed * 3.6,
  );

  if (gForce > IMPACT_THRESHOLD) {
    final samples = await TelemetryBufferService.instance.getWindow();
    await uploadTelemetryBatch(samples);
    await TelemetryBufferService.instance.clear();
  }
});
```

---

## 11. Database Additions

### `carrier_api_config` table (RS-060)

**File:** `supabase/queries/RS-060_carrier_api_config.sql`

```sql
CREATE TABLE IF NOT EXISTS carrier_api_config (
  id                     UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  carrier_id             UUID        NOT NULL REFERENCES carriers(id) ON DELETE CASCADE,
  api_name               TEXT        NOT NULL,    -- 'acsel' | 'sirway' | 'stub'
  base_url               TEXT        NOT NULL DEFAULT '',
  auth_type              TEXT        NOT NULL DEFAULT 'bearer',  -- 'bearer' | 'basic' | 'apikey'
  product_code_basica    TEXT,       -- carrier SKU for RCV Básica tier
  product_code_plus      TEXT,       -- carrier SKU for RCV Plus tier
  product_code_premium   TEXT,       -- carrier SKU for RCV Ampliada tier
  timeout_seconds        INTEGER     NOT NULL DEFAULT 10,
  max_attempts           INTEGER     NOT NULL DEFAULT 3,
  retry_interval_minutes INTEGER     NOT NULL DEFAULT 15,
  is_active              BOOLEAN     NOT NULL DEFAULT false,
  created_at             TIMESTAMPTZ DEFAULT now(),
  updated_at             TIMESTAMPTZ DEFAULT now(),
  UNIQUE (carrier_id, api_name)
);
```

- **RLS:** `ENABLE ROW LEVEL SECURITY` — no policies defined; `anon`/`authenticated` have no access. Only `service_role` (used by Edge Functions) can read/write.
- **Seed row:** stub config for Seguros Pirámide with `carrier_id = '11111111-1111-1111-1111-111111111111'` (Sprint 1 seed UUID), `api_name = 'stub'`, `is_active = false`.

**Activation path when William delivers docs:**

```sql
-- 1. Set real endpoint
UPDATE carrier_api_config
  SET base_url = 'https://api.acsel.com.ve/v1',
      api_name = 'acsel',
      is_active = true
  WHERE carrier_id = '11111111-1111-1111-1111-111111111111'
    AND api_name = 'stub';

-- 2. Store credentials in Supabase Vault (never in this table)
SELECT vault.create_secret('ACSEL_API_KEY', '<secret>');
```

### `claims` + `claim_evidence` additions (RS-067)

See [Section 7.1](#71-database-schema-additions) for the full SQL.

### Updated `SupabaseConstants`

```dart
// Sprint 3 tables
static const String tickets         = 'tickets';
static const String ticketComments  = 'ticket_comments';
static const String telemetryEvents = 'telemetry_events';
static const String carrierApiConfig = 'carrier_api_config';

// Edge functions
static const String fnPolicyRetry      = 'policy-retry';
static const String fnRenewalReminder  = 'renewal-reminder';
```

---

## 12. Edge Functions

### `policy-retry` (RS-062)

**File:** `supabase/functions/policy-retry/index.ts`
**Trigger:** Cron or manual `POST /functions/v1/policy-retry` with service-role key

**Authorization:** Validates `Authorization: Bearer {CRON_SECRET}` header (falls back to service role key if `CRON_SECRET` is not set).

**Logic:**

```
1. SELECT from policies WHERE issuance_status IN ('pending', 'provisional')
     AND carrier_api_attempts < 3
     AND updated_at < now() - INTERVAL '5 minutes'
   LIMIT 20

2. For each policy:
   a. Call callCarrierApi(policyId, plate) — stub: returns 'ACL-{plate}-{epoch}'
   b. On success:
      - UPDATE policies SET issuance_status='confirmed', carrier_policy_number=..., status='active'
      - INSERT into audit_log: event_type='policy.retry_confirmed'
   c. On failure (3rd attempt):
      - Keep issuance_status='provisional'
      - INSERT into tickets: category='policy', priority='critical',
        subject='Fallo en emisión de póliza', status='open'
      - INSERT into audit_log: event_type='policy.retry_failed'

3. Return { processed, confirmed, failed, ts }
```

**Stub `callCarrierApi()`:**

```typescript
function callCarrierApi(policyId: string, plate: string): string {
  return `ACL-${plate.replace(/-/g, '')}-${Math.floor(Date.now() / 1000)}`;
}
```

### `renewal-reminder` (RS-066)

**File:** `supabase/functions/renewal-reminder/index.ts`
**Trigger:** Daily cron at 09:00 VET (UTC-4:30) — schedule via Supabase Pro cron or external trigger

**Authorization:** Same `CRON_SECRET` / service-role pattern as `policy-retry`.

**Pago Móvil configuration (env vars):**

| Var | Default | Description |
|-----|---------|-------------|
| `AZ_PAGO_MOVIL_PHONE` | `04120000000` | AZ Capital's Pago Móvil phone number |
| `AZ_PAGO_MOVIL_BANK_CODE` | `0134` | AZ Capital's bank code |
| `AZ_COMPANY_RIF` | `J-XXXXXXXXX-X` | AZ Capital's RIF |

**Pago Móvil deep-link format:**

```
pagomovil://pay?phone={phone}&bank={bankCode}&amount={usd}&ref=REN-{uuid8}&concept=Renovaci%C3%B3n%20RCV%20...
```

The deep-link format is the most widely supported C2B variant across Venezuelan bank apps (Mercantil, BDV, Banesco). It is not officially standardised; the format was chosen based on field testing.

**Logic:**

```
1. SELECT active policies WHERE end_date <= now() + 30 days AND end_date >= today
   LIMIT 100

2. For each policy:
   a. Skip if renewal_link already exists (non-expired, not completed)
   b. Build Pago Móvil deep-link (amount = policy.premium_usd, ref = REN-{uuid8})
   c. INSERT into renewal_links:
      { policy_id, broker_id, pago_movil_link, expires_at = now() + 30 days }
   d. INSERT into audit_log: event_type='policy.renewal_link_created',
      payload: { days_remaining, tier, renewal_reference }

3. Return { created, skipped, details, ts }
```

**TODO (Phase 1.5):**

```typescript
// Push notification when Firebase is configured:
// await sendPushNotification({
//   userId: policy.profile_id,
//   title: 'Tu póliza vence pronto',
//   body: `Renueva tu ${policy.policy_types?.name} antes del ${policy.end_date}`,
//   data: { policyId: policy.id, link },
// });
```

---

## 13. Admin Portal Deprecation

**File:** `admin-portal/DEPRECATED.md`

Decision recorded on 2026-03-24 in meeting with Diego, Fernando, Thony, Alex, William, and Manuel. The `admin-portal/` Next.js scaffold is permanently frozen.

**What replaces it:** Thony's React + Node.js platform with 7 RuedaSeguro-branded portals:

| Portal | Audience |
|--------|----------|
| Management Overview | Executive / founders |
| Insurance Partner | Seguros Pirámide ops team |
| Venemergencia Dispatch | Ambulance coordination |
| Clinical Care | Triage + discharge tracking |
| Broker Pipeline | Corredores de Seguros |
| Customer Ops Desk | Call center / support agents |
| Administration | System configuration |

**Our obligation:** The Flutter app and Supabase backend publish clean events via Supabase Realtime (and MQTT in Phase 1.5) that Thony's platform consumes. The event contract is in `docs/MVP_PLAN_v3.md` section 4.2.

**Do not delete** the directory — git history may be referenced in future audits.

---

## 14. Bug Fixes Applied Post-Implementation

### Fix 1: `vehiclePlate: vehicleId` in `CarrierSubmissionPayload`

**Problem:** In `emission_screen.dart`, `CarrierSubmissionPayload` was constructed with `vehiclePlate: vehicleId`. The `vehicleId` is a UUID (e.g., `'a1b2c3d4-...`), not a plate string (e.g., `'ABC-123-DE'`). The stub doesn't validate the payload so this didn't crash, but would send incorrect data to the real Acsel/Sirway API.

**Fix:**

1. Added `fetchVehiclePlate(String vehicleId)` to `PolicyRepository`:

```dart
Future<String?> fetchVehiclePlate(String vehicleId) async {
  final row = await SupabaseService.client
      .from(SupabaseConstants.vehicles)
      .select('plate')
      .eq('id', vehicleId)
      .maybeSingle();
  return row?['plate'] as String?;
}
```

2. In `emission_screen.dart` `_emit()`, after `fetchVehicleId`:

```dart
final vehiclePlate =
    await PolicyRepository.instance.fetchVehiclePlate(vehicleId) ?? '';
```

3. Changed payload construction: `vehiclePlate: vehiclePlate` (was `vehiclePlate: vehicleId`).

**Impact:** 1 extra Supabase round-trip per emission (selects 1 column from `vehicles` by PK — negligible latency). No schema changes.

---

### Fix 2: Claim photo upload path missing `userId` prefix

**Problem:** `ClaimRepository.uploadClaimPhoto()` stored files at `claims/{claimId}/photo_{index}.{ext}`. The existing RLS policy for the `receipts` bucket checks:

```sql
auth.uid()::text = (storage.foldername(name))[1]
```

`foldername(name)[1]` is the **first** path segment. A path starting with `claims/` has `foldername = ['claims', ...]`, so `[1] = 'claims'` ≠ `auth.uid()`. All uploads would fail with a storage RLS violation in authenticated mode.

**Fix:** Changed path to `'{userId}/claims/{claimId}/{index}.{ext}'`. The `userId` is the first segment, matching `auth.uid()`.

1. Added `required String userId` parameter to `uploadClaimPhoto()`
2. Changed `storagePath` construction: `'$userId/claims/$claimId/$index.$ext'`
3. Updated call site in `new_claim_screen.dart` to pass `userId: userId`

**No schema or bucket changes needed.** The existing RLS policy already supports this path shape.

---

## 15. Audit Events (Complete Catalogue)

All audit events use `AuditRepository.instance.logEvent()` — fire-and-forget, errors swallowed.

| Event | Table | Emitter | Payload |
|-------|-------|---------|---------|
| `policy.provisional_created` | `policies` | `EmissionScreen._emit()` | `tier`, `premium_usd` |
| `payment.submitted` | `payments` | `EmissionScreen._emit()` | `policy_id`, `method`, `amount_usd` |
| `policy.api_submitted` | `policies` | `PolicyIssuanceService.attemptIssuance()` | `attempt_number` |
| `policy.confirmed` | `policies` | `PolicyIssuanceService.attemptIssuance()` | `carrier_policy_number` |
| `policy.issuance_failed` | `policies` | `PolicyIssuanceService.attemptIssuance()` | `reason` |
| `claim.reported` | `claims` | `NewClaimScreen._submit()` | `type`, `has_injuries`, `photos` |
| `policy.retry_confirmed` | `policies` | `policy-retry` Edge Function | `carrier_policy_number`, `attempt` |
| `policy.retry_failed` | `policies` | `policy-retry` Edge Function | `attempt`, `max_attempts`, `ticket_id` |
| `policy.renewal_link_created` | `policies` | `renewal-reminder` Edge Function | `days_remaining`, `tier`, `renewal_reference` |

---

## 16. Testing

### New automated tests (Sprint 3)

| File | Test count | Coverage |
|------|-----------|----------|
| `test/features/policy/domain/issuance_result_test.dart` | 9 | `IssuanceResult.confirmed` / `.provisional` factories; `isConfirmed` getter; null/non-null fields |
| `test/features/telemetry/services/telemetry_buffer_service_test.dart` | 18 | Empty buffer, insert, sampleCount, getWindow (wide + narrow window), ordering, pruneOlderThan (recent + old), clear, peakGForce (max, null, all-null), `TelemetrySample.fromMap/toMap` roundtrip |

**New dev dependency for telemetry tests:**

```yaml
# pubspec.yaml
dev_dependencies:
  sqflite_common_ffi: ^2.3.4   # ← allows sqflite to run in Flutter test environment (no native plugin)
```

**Test setup pattern:**

```dart
setUpAll(() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
});

setUp(() async {
  await TelemetryBufferService.instance.init();
  await TelemetryBufferService.instance.clear();
});
```

### Manual test checklist

`mobile/SPRINT_3_TEST_CHECKLIST.md` — 50+ interaction tests across 11 sections:

1. Emission screen — confirmed state (authenticated; 6 steps)
2. Emission screen — provisional fallback (demo mode; 3 steps)
3. Provisional banner on policy detail (3 steps)
4. New claim screen — demo mode (8 steps)
5. New claim screen — authenticated mode (9 steps)
6. Support ticket creation (8 steps)
7. Sentry initialization (4 steps)
8. Edge cases (6 scenarios)
9. Automated test commands
10. Supabase verification SQL queries
11. Pre-deployment checklist

### Full test suite (cumulative)

| Category | Files | Approx. test cases |
|----------|-------|--------------------|
| Core utils (Sprint 1) | 4 | ~50 |
| OCR parsers (Sprint 1) | 3 + cross-validator | ~40 |
| Onboarding widgets (Sprint 1) | 4 | ~20 |
| Policy domain model (Sprint 2B) | 1 | ~18 |
| PDF service (Sprint 2B) | 1 | ~5 |
| Product selection screen (Sprint 2B) | 1 | ~4 |
| `IssuanceResult` (Sprint 3) | 1 | 9 |
| `TelemetryBufferService` (Sprint 3) | 1 | 18 |
| **Total** | **16** | **~164** |

Run all:

```bash
cd mobile
flutter pub get
flutter test --reporter expanded
```

---

## 17. Security

### New credentials (Sprint 3)

| Secret | Location | Never in |
|--------|----------|---------|
| `SENTRY_DSN` | `.env` (dart-define) | Git, hardcoded |
| `AZ_PAGO_MOVIL_PHONE` | Supabase project env vars | Mobile app |
| `AZ_PAGO_MOVIL_BANK_CODE` | Supabase project env vars | Mobile app |
| `AZ_COMPANY_RIF` | Supabase project env vars | Mobile app |
| `CRON_SECRET` | Supabase project env vars | Mobile app |
| `ACSEL_API_KEY` (future) | Supabase Vault | Any file, env var |

### Storage RLS — claim photos

The existing `receipts` bucket RLS policy covers claim photos without modification:

```sql
-- "Users can upload receipts to own folder" (existing)
CREATE POLICY "Users can upload receipts to own folder" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'receipts' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );
```

Claim photos stored at `{userId}/claims/{claimId}/{index}.ext` → `foldername[1] = userId = auth.uid()` ✓.

### `carrier_api_config` credentials

Carrier API credentials (`api_key`, `auth_token`) are **never** stored in the `carrier_api_config` table. The table holds only connection metadata (base URL, auth type, product codes, timeouts). Actual credentials will live in Supabase Vault and be accessed by Edge Functions only:

```sql
-- Future: store in Vault
SELECT vault.create_secret('ACSEL_API_KEY', '<secret>');

-- Future: read in Edge Function
const apiKey = await supabase.rpc('vault.decrypted_secret', { secret_name: 'ACSEL_API_KEY' });
```

---

## 18. Known Limitations & Sprint 4 Preview

### Current limitations (as of Sprint 3)

| Area | Limitation |
|------|-----------|
| Carrier API | `StubCarrierClient` always confirms. Real `AcselSirwayClient` implementation awaits William's sandbox docs and `ACSEL_API_KEY` / `SIRWAY_API_KEY` in Supabase Vault |
| Carrier policy number in PDF | `PolicyDetailModel.displayNumber` falls back to `RS-{uuid8}` until `carrier_policy_number` is populated by the real carrier API |
| Push notifications | Firebase `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) not yet configured. The `renewal-reminder` Edge Function has the FCM call commented out |
| MQTT | No client code — Thony's platform uses Supabase Realtime as fallback; MQTT guide at `docs/MQTT_INTEGRATION_GUIDE.md` |
| Telemetry sensors | `sensors_plus`, `geolocator`, `background_fetch` commented out in `pubspec.yaml`. `TelemetryBufferService` is ready to receive data from these sensors once Alex confirms the spec |
| Renewal cron | `renewal-reminder` must be manually invoked (`POST .../functions/v1/renewal-reminder`) until Supabase Pro cron (`pg_cron`) is activated |
| Payment verification | Still manual — a broker/agent must check Pago Móvil references in Supabase dashboard. Phase 1.5 will wire Guía Pay C2P webhook |
| Rider ticket visibility | `CreateTicketScreen` creates tickets; there is no "My Tickets" screen yet — riders cannot see their open tickets in the app |

### Sprint 4 scope (preliminary)

| Ticket | Description |
|--------|-------------|
| RS-065 | Firebase FCM — push notifications on policy confirmation and renewal reminder |
| RS-059 | MQTT client — publish telemetry/SOS events to Thony's broker via GCP |
| RS-072 | "My Tickets" screen — list open/in-progress tickets for rider |
| RS-074 | Guía Pay C2P webhook — automated payment verification |
| RS-075 | Real `AcselSirwayClient` — swap `StubCarrierClient` once William delivers docs |
| RS-076 | Phase 1.5 sensor activation — `sensors_plus` + `geolocator` + impact detection |
| RS-077 | ERC-721 NFT policy certificate — blockchain anchoring of `retain_until` records |

---

## 19. How to Run (Sprint 3 additions)

### New build flag

```bash
flutter run --dart-define-from-file=.env
# Add to .env:
# SENTRY_DSN=https://...@sentry.io/...   (optional; leave empty to disable)
```

### Apply Sprint 3 SQL migrations

Run in order in the Supabase SQL editor (or via `psql`):

```bash
# 1. Carrier API config table (if carrier_api_config doesn't exist yet)
psql $DATABASE_URL -f supabase/queries/RS-060_carrier_api_config.sql

# 2. Claims enhancements (idempotent — safe to run even if some columns exist)
psql $DATABASE_URL -f supabase/queries/RS-067_claims_enhancements.sql
```

### Deploy Sprint 3 Edge Functions

```bash
supabase functions deploy policy-retry
supabase functions deploy renewal-reminder

# Set env vars for renewal-reminder
supabase secrets set AZ_PAGO_MOVIL_PHONE=04120000000
supabase secrets set AZ_PAGO_MOVIL_BANK_CODE=0134
supabase secrets set AZ_COMPANY_RIF=J-XXXXXXXXX-X
supabase secrets set CRON_SECRET=<long-random-string>
```

### Manually trigger Edge Functions (before cron is set up)

```bash
# Test policy-retry
curl -X POST https://<project-ref>.supabase.co/functions/v1/policy-retry \
  -H "Authorization: Bearer <service-role-key>"

# Test renewal-reminder
curl -X POST https://<project-ref>.supabase.co/functions/v1/renewal-reminder \
  -H "Authorization: Bearer <service-role-key>"
```

### Run Sprint 3 tests

```bash
cd mobile
flutter pub get           # picks up sqflite_common_ffi from pubspec.yaml
flutter test test/features/policy/domain/issuance_result_test.dart -v
flutter test test/features/telemetry/services/telemetry_buffer_service_test.dart -v
flutter test --reporter expanded   # full suite
```

### Full deployment checklist for Sprint 3 go-live

- [ ] `RS-060_carrier_api_config.sql` applied
- [ ] `RS-067_claims_enhancements.sql` applied
- [ ] `policy-retry` Edge Function deployed
- [ ] `renewal-reminder` Edge Function deployed
- [ ] `AZ_PAGO_MOVIL_PHONE`, `AZ_PAGO_MOVIL_BANK_CODE`, `AZ_COMPANY_RIF`, `CRON_SECRET` set via `supabase secrets set`
- [ ] `SENTRY_DSN` added to build pipeline (`--dart-define=SENTRY_DSN=...`)
- [ ] `MESSAGEBIRD_API_KEY` confirmed set in Supabase project settings (from Sprint 1)
- [ ] `TURNSTILE_SECRET_KEY` confirmed set (from Sprint 2B)
- [ ] Verify `carrier_api_config` seed row UUID matches live `carriers` table (should be `'11111111-1111-1111-1111-111111111111'`)
- [ ] All 164 automated tests pass (`flutter test --reporter expanded`)
- [ ] Manual checklist `SPRINT_3_TEST_CHECKLIST.md` sections 1–8 verified on device
