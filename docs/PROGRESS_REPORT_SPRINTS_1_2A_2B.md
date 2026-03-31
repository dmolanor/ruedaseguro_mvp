# RuedaSeguro — Technical Progress Report
## Sprints 1 · 2A · 2B
**As of:** 2026-03-29 | **Prepared by:** Engineering

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture](#2-architecture)
3. [Sprint 0 — Foundation](#3-sprint-0--foundation)
4. [Sprint 1 — Auth & Onboarding](#4-sprint-1--auth--onboarding)
5. [Sprint 2A — Policy & Payments](#5-sprint-2a--policy--payments)
6. [Sprint 2B — Home, Detail & Quality](#6-sprint-2b--home-detail--quality)
7. [Database Schema](#7-database-schema)
8. [Edge Functions](#8-edge-functions)
9. [Security](#9-security)
10. [Infrastructure & DevOps](#10-infrastructure--devops)
11. [Testing](#11-testing)
12. [Known Limitations & Sprint 3 Preview](#12-known-limitations--sprint-3-preview)
13. [How to Run](#13-how-to-run)

---

## 1. Project Overview

**RuedaSeguro** is a B2B2C micro-insurance platform for Venezuelan motorcycle riders, offering real-time policy issuance via mobile app with three coverage tiers:

| Tier | Price/yr | Coverage |
|------|----------|----------|
| Básica | ~$17 | RCV (mandatory liability) |
| Plus | ~$31 | RCV + Venemergencia medical dispatch |
| Ampliada | ~$55 | RCV + full recovery + milestones |

**Sales network:** Carriers → Brokers (800-policy quota each) → Promoters → Riders

**Tech stack:**

| Layer | Technology |
|-------|-----------|
| Mobile app | Flutter 3.41 / Dart 3.x |
| State management | Riverpod 3.3.1 |
| Routing | GoRouter 17 |
| Backend | Supabase (PostgreSQL 16, Auth, Storage, Edge Functions) |
| Edge runtime | Deno (Supabase Functions) |
| SMS/OTP | MessageBird via Supabase Phone Auth |
| CAPTCHA | Cloudflare Turnstile (invisible mode) |
| Exchange rate | BCV via `bcv-rate` edge function |
| PDF generation | `pdf` + `printing` + `crypto` packages |
| OCR | Google ML Kit (on-device, offline) |
| Crash reporting | Sentry (`sentry_flutter` configured) |
| CI/CD | GitHub Actions |

---

## 2. Architecture

### Monorepo structure

```
RuedaSeguro/
├── mobile/                    Flutter app (this document's primary focus)
│   ├── lib/
│   │   ├── app/               Router + App widget
│   │   ├── core/              Theme, services, utils, constants, config
│   │   ├── features/          Feature modules (auth, onboarding, policy, …)
│   │   └── shared/            Providers, reusable widgets
│   ├── test/                  Unit + widget tests
│   └── pubspec.yaml
├── admin-portal/              Next.js (scaffolded; replaced by Thony's platform)
├── supabase/
│   ├── functions/             Deno edge functions
│   └── queries/               SQL migrations (numbered RS-XXX)
└── docs/                      Architecture docs, sprint plans
```

### Data flow

```
Flutter App
  │
  ├─► Supabase Auth (phone OTP via MessageBird)
  │
  ├─► Supabase PostgREST (profiles, policies, payments, claims)
  │
  ├─► Supabase Storage (document images, policy PDFs, receipts)
  │
  ├─► bcv-rate Edge Function ──► pydolarve.org / alcambio.app
  │
  └─► Cloudflare Turnstile (bot protection on auth)
```

### State management pattern

All providers are Riverpod. Three categories:

- **StreamProvider** — Auth state (live `onAuthStateChange` stream)
- **AsyncNotifierProvider** — Policy types (async fetch with loading/error/data states)
- **FutureProvider / FutureProvider.family** — Profile, BCV rate, policy detail, active policy

Screens are `ConsumerWidget` or `ConsumerStatefulWidget`. No `ChangeNotifier` or `setState` for business data.

### Routing & access control

GoRouter with `redirect` callbacks implementing four access levels:

| Level | Routes | Redirect logic |
|-------|--------|----------------|
| Public | `/`, `/login`, `/otp` | — |
| Onboarding | `/onboarding/*` | Requires `authenticated` status |
| Authenticated | `/home`, `/policy/*`, `/payment/*` | Requires `authenticatedWithProfile` |
| Demo | All screens | Bypasses DB calls when `user == null` |

`AuthStatus` enum: `initial → unauthenticated → authenticated → authenticatedWithProfile`

---

## 3. Sprint 0 — Foundation

**Goal:** Monorepo running, Supabase provisioned, design system in place.

### Completed

- **Monorepo** with `.gitignore`, branch protection, GitHub Actions path-based CI/CD
- **Flutter project** — all 26 dependencies pinned, Phase 1.5 sensors stubbed and commented
- **Supabase** — free tier provisioned, 20-table schema, 4 storage buckets, RLS foundations
- **Design system:**
  - Colors: Navy `#1A3A52`, Orange `#FF6B35`, Dark `#0F2236`
  - Typography: Montserrat (headings) + Lato (body)
  - Spacing: 4px base grid (`RSSpacing.xs/sm/md/lg/xl`)
  - Components: `RSButton`, `RSTextField`, `RSCard`, `RSConsentCheckbox`, `RSLoading`, `RSError`, `RSEmpty`
- **20 named routes** with auth-aware redirects
- **Seed data:** Carriers (Seguros Pirámide, Seguros Caracas), brokers, promoters, POSs

---

## 4. Sprint 1 — Auth & Onboarding

**Goal:** Phone number → verified rider identity → profile saved to Supabase.

### 4.1 Authentication

#### Phone OTP flow

1. `LoginScreen` — Country picker (🇻🇪 `+58` / 🇨🇴 `+57`), auto-formatted phone input, E.164 construction
2. `signInWithOtp(phone, captchaToken)` → Supabase Auth → MessageBird SMS
3. `OtpScreen` — 6 separate `TextField` boxes; auto-advance on digit entry; paste support; backspace navigates backwards; 60-second resend countdown; 3-attempt maximum
4. On success: `verifyOtp(phone, token)` → Supabase session → router redirects by `AuthStatus`

**Cloudflare Turnstile** (added post-Sprint 1 during 2B hardening):
- Invisible mode widget mounted in `LoginScreen`
- Token resolved silently by Cloudflare before user taps "Continuar"
- Passed as `captchaToken` to `signInWithOtp`
- On auth failure: `refreshToken()` with guard against uninitialized web controller

**Dev bypass** (`kDebugMode` only):
- `[DEV] Saltar SMS → anónimo` button calls `signInAnonymously()`
- Full onboarding flow works without receiving a real SMS

#### `AuthProvider` (global)

```dart
StreamProvider<RSAuthState>  →  Supabase.onAuthStateChange
RSAuthState { AuthStatus status, User? user }
```

### 4.2 Onboarding — 7 Screens

Complete data collected across one linear flow:

```
Cedula Scan → Cedula Confirm → Licencia Scan → Licencia Confirm
→ Carnet Scan → Address Form → Consent Screen
```

#### Documents captured

| Document | Fields extracted | Confidence threshold |
|----------|-----------------|---------------------|
| Cédula (VE: V/E, CO: CC) | ID type, ID number, first name, last name, DOB, nationality, sex | 0.90 (amber warning below) |
| Licencia de Conducir | License number, categories (A, B, C, D…), expiry date, blood type | 0.85 |
| Carnet de Circulación | Plate (ABC-123-DE or ABC-123), brand, model, year, color, serial motor, serial carrocería | 0.85 |

#### OCR pipeline

```
Camera / ImagePicker
    ↓
ImageQualityValidator (sharpness + glare detection; rejects screen photos)
    ↓
OcrRepository.recognizeText() → Google ML Kit TextRecognizer (on-device, offline)
    ↓
CedulaParser / LicenciaParser / CarnetParser
    ↓
Cross-validation (cedula ID ↔ carnet owner ID)
    ↓
Confidence scores → UI highlights low-confidence fields in amber
    ↓
User confirms/corrects → OnboardingNotifier.update()
```

#### `OnboardingData` — 58 fields, immutable state

```dart
// Identity
String? idType, idNumber, firstName, lastName;
DateTime? dateOfBirth;
String? nationality, sex;
String? emergencyContactName, emergencyContactPhone, emergencyContactRelation;

// License
String? licenciaNumber, bloodType;
List<String>? drivingCategories;
DateTime? licenciaExpiry;

// Vehicle
String? plate, brand, model, year, color, vehicleUse;
String? serialMotor, serialCarroceria;

// Address
String? urbanizacion, ciudad, municipio, estado, codigoPostal;

// Consent (all 4 required)
bool consentRcv, consentVeracidad, consentAntifraude, consentPrivacidad;
DateTime? consentTimestamp;
```

Managed by `OnboardingNotifier` (Riverpod `Notifier`) with `copyWith` + typed `update()` methods.

#### Address collection

Venezuelan address fields: `urbanización`, `ciudad`, `municipio`, `estado`, `código postal`. All required before consent.

#### Consent screen

4 mandatory checkboxes (all-or-nothing):
1. RCV — acknowledgement of mandatory liability coverage
2. Veracidad — truthfulness declaration
3. Antifraude — anti-fraud commitment
4. Privacidad — data privacy agreement

Timestamp saved with consent. Cannot proceed unless all 4 are checked.

#### Profile creation

`OnboardingRepository.createProfile()` writes:
- `profiles` table: identity fields, emergency contact, consent fields, phone from `auth.users`
- `vehicles` table: plate, brand, model, year, color, serials
- Document images → Supabase Storage buckets (`documents/`)

### 4.3 OCR Parsers

#### `CedulaParser`

- Venezuelan: regex `[VEve]-?\d{1,8}` or numeric block `[0-9]{6,9}`
- Colombian: regex `CC\s*\d{7,11}` or 10-digit numeric blocks
- DOB: heuristic date extraction from 6–8 digit sequences
- Name: extracts UPPERCASE blocks, filters Venezuelan ID-type keywords
- Confidence scoring: each field independently scored 0–1; overall = average of parsed fields

#### `CarnetParser`

- VE plates: regex `[A-Z]{2,3}-\d{2,3}-[A-Z]{2}` (new) or `[A-Z]{3}-\d{3}` (old)
- CO plates: regex `[A-Z]{3}-\d{3}`
- Brand matching: 20 brands (Toyota, Honda, Yamaha, Kawasaki, Suzuki, Bajaj, Hero, KTM, Ducati, BMW, Harley, Royal Enfield, Vespa, Piaggio, Kymco, SYM, AKT, TVS, Lifan, Zongshen)
- Serial extraction: `[A-Z0-9]{8,17}` blocks labeled "SERIAL"

#### `CrossValidator`

Compares `cedulaParser.idNumber` with `carnetParser.ownerCedula`. Returns `isMatch: bool + confidence`.

#### `ImageQualityValidator`

- Sharpness: Laplacian variance (rejects < threshold)
- Glare: luminance hotspot detection
- Rejects photos of screens (Moiré pattern heuristic)

### 4.4 Validators

```dart
Validators.isValidVenezuelanPhone('4120001234')  // length=10, starts with 4
Validators.isValidColombianPhone('3101234567')   // length=10, starts with 3
Validators.isValidEmail('user@example.com')
Validators.isValidCedula('V-12345678')           // V/E/CC prefix
Validators.isValidPlate('ABC-123-DE')            // VE new / VE old / CO
```

---

## 5. Sprint 2A — Policy & Payments

**Goal:** Authenticated rider can select a plan, see pricing in USD and VES, and submit a payment reference.

### 5.1 BCV Rate Integration

**`bcv-rate` edge function** (Deno):

```
Request from Flutter
    ↓
Check exchange_rates table (cache TTL: 60 min)
    ├── Cache hit → return immediately
    └── Cache miss → fetch pydolarve.org API (10s timeout)
                   ↓ (fallback)
                   alcambio.app GraphQL
                   ↓ (fallback)
                   Last known rate with stale: true
    ↓
Persist fresh rate to exchange_rates table
Flag suspicious jump (> 20% delta from previous)
Return { rate, fetched_at, source, stale, isSuspicious }
```

**`BcvRate` model:**
```dart
BcvRate { double rate, String fetchedAt, String source, bool stale, bool isSuspicious }
```

**`BcvRateNotifier`** (`AsyncNotifierProvider<BcvRate>`):
- Calls edge function on mount
- Exposes `asData?.value` to UI; stale/offline fallback with amber `(aprox.)` badge

### 5.2 Product Selection Screen

- Fetches `policy_types` from Supabase via `PolicyTypesNotifier`
- **Loading state:** 3 shimmer cards (same layout as real cards)
- **Error fallback:** renders `MockPlans.all` (3 hardcoded plans) — demo always works even if DB is down
- **Plan cards:** name, price in USD, BCV-converted VES price, coverage highlights, "Recomendado" badge for Plus
- BCV rate displayed in footer: `1 USD = XX.XX VES`

**Demo mode:** Authenticated via anonymous login → same UI, no real DB calls for plan data (falls back to mock plans).

### 5.3 Quote Summary Screen

Shown after plan selection. Displays:
- Plan name and tier badge
- Premium in USD (`$31.00`)
- Premium in VES (live: `Bs. 2,480.00` or `(aprox.)` if stale)
- Coverage details per tier
- Rider name, vehicle plate (from `ProfileSummary`)
- "Solicitar emisión" → Payment screen

**`InsurancePlan`** object passed as `Map<String, dynamic>` via `GoRouter.extra`.

### 5.4 Payment Method Screen

Two tabs:

**Pago Móvil P2P**
- Bank selector (dropdown, 8 Venezuelan banks including BDV, Banesco, Mercantil, BBVA, BNC, Bicentenario, BanPlus, BanFondeso)
- Phone number field (auto-formatted)
- Reference number field (numeric, 6–20 chars)
- Submit enabled only when all fields valid

**Transferencia Bancaria**
- Displays RuedaSeguro account details (bank, account number, RIF, beneficiary)
- Reference number field (≥ 6 chars required)

Both tabs submit to `PaymentRepository.createPaymentRecord()` with `method`, `amount_usd`, `amount_ves`, `exchange_rate`.

### 5.5 Emission Screen

Three-step animated progress sequence (~2.8 seconds):

```
Step 1: Verificando pago          (spinner → ✓)
Step 2: Registrando póliza        (spinner → ✓)
Step 3: Generando certificado     (spinner → ✓)
→ SUCCESS state: "PROVISIONAL" amber badge
```

**Under the hood (real mode):**
1. `PolicyRepository.createPolicy()` — inserts policy row (`issuance_status: provisional`)
2. `PaymentRepository.createPaymentRecord()` — inserts payment row (`status: pending`)
3. `AuditRepository.logEvent('policy.provisional_created')`
4. `AuditRepository.logEvent('payment.submitted')`
5. Navigate to Policy Detail

**Demo mode:** Same animation; no DB writes.

### 5.6 Database additions (Sprint 2A SQL migrations)

**RS-007 suite** (applied in order):
- `RS-007_01`: ENUM additions — `payment_method` (pago_movil_p2p, bank_transfer, guia_pay_c2p, card_tokenized, domiciliacion), `broker_status`, `promoter_status`, policy_status additions (pending_emission, observed, rejected_emission)
- `RS-007_02`: Column additions to existing tables
- `RS-007_03`: `brokers`, `promoters`, `points_of_sale` tables with hierarchical FKs
- `RS-007_04`: Foreign key additions from policies/payments to B2B2C tables
- `RS-007_05`: RLS policies (rider owns rows; carrier admin scoped to carrier_id; service_role bypass)
- `RS-007_06`: Indexes (policies.status, policies.profile_id, exchange_rates.fetched_at), triggers (auto-update `updated_at`), helper functions

**RS-041**: Comprehensive RLS overhaul — idempotent DROP + CREATE for all 20 tables

**RS-042**: Consent + emergency contact columns added to `profiles`

**RS-045**: New tables — `telemetry_events`, `tickets`, `ticket_comments`, `renewal_links`, `sla_config`

**RS-046**: `issuance_status` ENUM on `policies` + `carrier_policy_number`, `carrier_api_attempts` columns

**RS-047**: Data lifecycle — `archived_at` + `retain_until` on all financial tables
- Policies / Payments / Claims: 7-year retention (SUDEASEG + SENIAT requirement)
- Documents: 1-year retention
- Audit log: indefinite (never deleted)

---

## 6. Sprint 2B — Home, Detail & Quality

**Goal:** Complete end-to-end flow from home screen to policy PDF download; real data in all screens; test coverage.

### 6.1 Home Screen (rewritten)

`HomeScreen` is a `ConsumerStatefulWidget` with 5 independent `ConsumerWidget` sections:

#### `_GreetingHeader`
- Watches `profileProvider` → shows real first name from `profiles.full_name`
- Avatar: first 2 initials from name
- Loading: shimmer skeleton
- Demo mode: shows "Juan Carlos"

#### `_ActivePolicyCard`
- Watches `activePolicySummaryProvider`
- **No policy:** "Aún no tienes una póliza activa" + "Cotizar ahora" CTA
- **Pending emission:** amber "PROVISIONAL" badge, plan name, display number
- **Active:** green "ACTIVA" badge, days remaining, progress bar, vehicle plate, expiry date
- **Loading:** shimmer skeleton

#### `_ExchangeRateBanner`
- Watches `bcvRateProvider`
- Online: `1 USD = 80.00 VES` (blue pill)
- Stale/offline: `1 USD = 78.50 VES (aprox.)` + "Sin conexión" amber label

#### `_QuickActionsGrid`
- 4 quick actions: Cotizar, Ver Póliza (routes to real policy ID), Siniestro, SOS
- "Ver Póliza" disabled with different color when no active policy

#### `_BottomNav`
- Inicio | Mi Póliza | Siniestros | Perfil
- "Mi Póliza" tab routes to `PolicyDetailScreen` with real active policy ID

### 6.2 Policy Detail Screen

`ConsumerWidget` watching `policyDetailProvider(policyId)`.

**Data source:** 4-table Supabase join:
```sql
SELECT *,
  profiles!profile_id(full_name, id_type, id_number),
  vehicles!vehicle_id(brand, model, year, plate, color),
  policy_types!policy_type_id(name, tier),
  carriers!carrier_id(name)
FROM policies WHERE id = $policyId
```

**Sections:**
- Status badge: `PROVISIONAL` (amber) or `ACTIVA` (green) or `EXPIRADA` (grey)
- Policy number: carrier number if assigned, else `RS-{first8ofUUID}`
- Copy icon → clipboard + snackbar "Copiado al portapapeles"
- Rider block: full name, ID type + number
- Vehicle block: brand, model, year, plate, color
- Validity: start date → end date (formatted in Spanish), days remaining
- Coverage chips: per tier (Básica/Plus/Ampliada)
- Carrier name
- Download PDF button

**Fallback states:**
- Demo mode (`user == null`): renders immediately with `MockPolicy` data
- Loading: shimmer skeleton
- Error: falls back to mock data (no crash)

#### `PolicyDetailModel` — derived helpers

```dart
bool get isProvisional  → issuanceStatus == 'provisional'
bool get isConfirmed    → issuanceStatus == 'confirmed'
bool get isActive       → status == 'active'
String get displayNumber → carrierPolicyNumber ?? 'RS-${id.substring(0,8).toUpperCase()}'
String get formattedStartDate → '29 mar 2026'
int get daysRemaining   → clamped [0, 366]
double get progressFraction → clamped [0.0, 1.0]
```

### 6.3 Policy PDF Service

`PolicyPdfService.generateBytes(PolicyDetailModel?)` generates an A4 PDF:

| Section | Content |
|---------|---------|
| Header | RuedaSeguro logo text + status badge (PROVISIONAL / VIGENTE) |
| Notice box | Provisional watermark text (if applicable) |
| Policy number | Display number in large font |
| Rider (2-column) | Full name, ID type + number |
| Vehicle (2-column) | Brand, model, year, plate, color |
| Validity | Start → end dates, carrier name |
| Coverages | Bullet list per tier |
| Footer | SHA-256 hash: `sha256(policyId|startDate|endDate)` |

`PolicyPdfService.shareProvisionalPdf(policy)` → `Printing.sharePdf()` → system share sheet (any platform).

### 6.4 Providers (Sprint 2B additions)

```dart
// BCV rate — calls bcv-rate edge function
final bcvRateProvider = AsyncNotifierProvider<BcvRateNotifier, BcvRate>

// Profile (first name + initials)
final profileProvider = FutureProvider<ProfileSummary?>

// Policy types list
final policyTypesProvider = AsyncNotifierProvider<PolicyTypesNotifier, List<PolicyTypeModel>>

// Single policy detail (by ID)
final policyDetailProvider = FutureProvider.family<PolicyDetailModel?, String>

// Current user's active policy (chains fetchActivePolicyId → fetchPolicyDetail)
final activePolicySummaryProvider = FutureProvider<PolicyDetailModel?>
```

### 6.5 Audit Log

`AuditRepository.logEvent()` — fire-and-forget, errors swallowed (never crashes app):

```dart
await AuditRepository.instance.logEvent(
  actorId: user.id,
  eventType: 'policy.provisional_created',
  targetTable: 'policies',
  targetId: policyId,
  payload: {'tier': 'plus', 'premium_usd': 31.0},
);
```

Events tracked:
- `policy.provisional_created`
- `payment.submitted`

### 6.6 Emergency Screen

`EmergencyScreen` — accessible via SOS quick action:
- 10-second countdown with pulsing animation
- "ESTOY BIEN" cancels and pops after 1.8s
- At countdown = 0: `_activated = true` state (Phase 1.5 will fire MQTT publish here)

### 6.7 Telemetry Buffer (Phase 1.5 prep)

`TelemetryBufferService` — SQLite ring buffer:
- Stores: `gForce`, `latitude`, `longitude`, `altitudeM`, `speedKmh`, `recordedAt`
- Max window: 15 minutes (auto-prunes every 50 inserts)
- Methods: `insertSample()`, `getWindow()`, `pruneOlderThan()`, `clear()`, `sampleCount`, `peakGForce`
- Sensors (`sensors_plus`, `geolocator`) commented out — activated in Phase 1.5 once telemetry spec confirmed

### 6.8 Metrics Materialized View (RS-057)

```sql
CREATE MATERIALIZED VIEW metrics_daily AS
SELECT
  DATE(created_at AT TIME ZONE 'UTC') AS date,
  COUNT(*) FILTER (WHERE TRUE)            AS policies_created,
  COUNT(*) FILTER (WHERE status='active') AS policies_active,
  SUM(premium_usd)                        AS revenue_usd,
  AVG(premium_usd)                        AS avg_premium_usd,
  -- per-tier counts, payment stats, claim counts
FROM policies LEFT JOIN payments ... LEFT JOIN claims ...
GROUP BY 1;

CREATE UNIQUE INDEX ON metrics_daily(date DESC);

-- Refresh function (call via pg_cron every 15 min):
SELECT cron.schedule('refresh-metrics', '*/15 * * * *',
  'SELECT refresh_metrics_daily()');
```

RLS: REVOKE from anon/authenticated, GRANT SELECT to service_role only.

### 6.9 Data lifecycle additions (RS-047)

All retention-sensitive tables now have:
- `archived_at TIMESTAMPTZ` — set when record is logically deleted
- `retain_until DATE` — computed at insert time; records may not be physically deleted before this date

| Table | Retention |
|-------|-----------|
| policies | 7 years (SUDEASEG) |
| payments | 7 years (SENIAT) |
| claims | 7 years |
| documents | 1 year |
| audit_log | Indefinite |

### 6.10 Security hardening (post-2B)

- **Cloudflare Turnstile** (invisible mode) on `LoginScreen`
  - `SiteKey` compiled into app via `--dart-define=TURNSTILE_SITE_KEY=...`
  - `SecretKey` lives as Supabase project setting (never in mobile app)
  - Widget renders as 0.01×0.01px iframe on web — no visual impact
  - Token passed as `captchaToken` to `signInWithOtp`
- **MessageBird** SMS provider configured in Supabase Phone Auth
- **Dart-define** for all secrets (`--dart-define-from-file=.env`) — no hardcoded credentials
- **VS Code launch.json** pre-configured for `dart-define-from-file=.env`

---

## 7. Database Schema

### Tables (20)

#### B2B2C Network
| Table | Purpose |
|-------|---------|
| `carriers` | Insurance carriers (Seguros Pirámide, etc.) |
| `carrier_users` | Staff accounts scoped to a carrier |
| `brokers` | Broker entities (25 target, 800-policy quota each, 25% commission) |
| `promoters` | Field sales agents under a broker |
| `points_of_sale` | Physical locations (gas stations, workshops) |

#### Rider Identity
| Table | Purpose |
|-------|---------|
| `profiles` | Rider identity: name, ID, DOB, phone, address, consent, emergency contact |
| `vehicles` | Motorcycle data: plate, brand, model, year, color, serials |
| `documents` | File references + SHA-256 hash for cedula, carnet, licencia scans |

#### Insurance Core
| Table | Purpose |
|-------|---------|
| `policy_types` | Product catalog: name, price_usd, coverage_fields (JSONB), active flag |
| `policies` | Issued policies: status, issuance_status, carrier_policy_number, premium |
| `payments` | Payment records: method, amount_usd, amount_ves, reference, status |
| `claims` | Claim records: type, location, injuries, evidence, retain_until |
| `claim_evidence` | Photo/video evidence for claims |

#### Finance & Operations
| Table | Purpose |
|-------|---------|
| `exchange_rates` | BCV rate history: rate, source, fetched_at, is_suspicious |
| `tickets` | Support tickets with priority and status |
| `ticket_comments` | Comments thread on tickets |
| `renewal_links` | Token-based policy renewal links (30-day expiry) |
| `sla_config` | Per-carrier SLA parameters (response hours, settlement hours) |

#### Telemetry & Compliance
| Table | Purpose |
|-------|---------|
| `telemetry_events` | Phase 1.5: G-force, GPS, speed events per rider/policy |
| `audit_log` | Immutable append-only compliance log (never deleted) |

### ENUMs

```sql
payment_method: pago_movil_p2p | bank_transfer | guia_pay_c2p | card_tokenized | domiciliacion
issuance_status: pending | api_submitted | confirmed | provisional | rejected
policy_status: active | expired | cancelled | pending_emission | observed | rejected_emission
broker_status: active | inactive | suspended
promoter_status: active | inactive | suspended
```

### Row Level Security

All tables have RLS enabled. Key policies:

| Actor | Scope |
|-------|-------|
| Authenticated rider | Own rows only (`auth.uid() = profile_id`) |
| Carrier admin | Rows belonging to their carrier (`carrier_id`) |
| Broker | Own broker rows + their promoters |
| `service_role` | Full access (used by edge functions) |
| `anon` | No access to any table |

---

## 8. Edge Functions

All functions are Deno runtime, deployed to Supabase.

### `bcv-rate`

**Endpoint:** `GET /functions/v1/bcv-rate`
**Auth:** Supabase anon key header
**Response:**
```json
{ "rate": 80.25, "fetchedAt": "2026-03-29T14:00:00Z",
  "source": "pydolarve", "stale": false, "isSuspicious": false }
```
**Cache TTL:** 60 minutes (reads DB before hitting external APIs)
**Fallback chain:** pydolarve.org → alcambio.app → last known DB value

### `send-otp`

**Endpoint:** `POST /functions/v1/send-otp`
**Purpose:** Send 6-digit OTP via MessageBird (now replaced by Supabase Phone Auth native flow, kept as fallback)
**Dev bypass:** `SUPABASE_OTP_DEV_BYPASS=true` → OTP printed to function logs, "000000" accepted as master code

### `verify-otp`

**Endpoint:** `POST /functions/v1/verify-otp`
**Purpose:** Validates OTP token against `phone_verifications` table (SHA-256 hash comparison)

### `policy-retry`

**Endpoint:** Cron-triggered
**Purpose:** Retry failed carrier API submissions for provisioned policies
**Logic:** Finds `policies WHERE issuance_status = 'api_submitted' AND carrier_api_attempts < 3 AND updated_at < NOW() - INTERVAL '5 minutes'`

### `renewal-reminder`

**Endpoint:** Cron-triggered (daily at 09:00 VET)
**Purpose:** Sends WhatsApp renewal reminders 30 days before policy expiry

---

## 9. Security

### Credential management

| Secret | Location | Never in |
|--------|----------|---------|
| `SUPABASE_ANON_KEY` | `.env` (dart-define) | Git, hardcoded |
| `SUPABASE_SERVICE_ROLE_KEY` | Root `.env` + Supabase secrets | Mobile app |
| `TURNSTILE_SITE_KEY` | `.env` (dart-define) | Server |
| `TURNSTILE_SECRET_KEY` | Supabase project settings | Mobile app |
| `MESSAGE_BIRD_API_KEY` | Supabase project settings | Mobile app |
| `SENTRY_DSN` | `.env` (dart-define) | Git |

### `.env` pattern

```
mobile/.env          ← real values (gitignored)
mobile/.env.example  ← placeholder template (committed)
.env                 ← root-level full credentials (gitignored)
.env.example         ← root-level template (committed)
```

Flutter reads via `--dart-define-from-file=.env` (Flutter 3.7+ feature).
VS Code `launch.json` pre-configured; no manual flags needed.

### Document integrity

Policy PDFs include a `SHA-256` hash in the footer:
```
sha256(policyId + "|" + startDate + "|" + endDate)
```
Computed client-side with the `crypto` package. Enables tamper detection without blockchain (Phase 1.5 upgrades to ERC-721 NFT).

### Turnstile bot protection

Every `signInWithOtp` call includes a short-lived Cloudflare Turnstile token. Cloudflare validates the token server-side using the secret key before Supabase processes the OTP request. Invalid or missing tokens result in a 400 from Supabase.

---

## 10. Infrastructure & DevOps

### GitHub Actions

**`flutter-ci.yml`** — triggers on `mobile/**` changes:
1. `flutter analyze` — static analysis
2. `flutter test` — all unit + widget tests
3. `flutter build apk --debug` — build validation

**`admin-ci.yml`** — triggers on `admin-portal/**` changes:
1. `npm ci`
2. ESLint
3. `next build`

### Supabase CLI commands

```bash
# Local development
supabase start                          # Start local Docker environment

# Apply a migration
supabase db push                        # Apply all pending migrations

# Deploy edge functions
supabase functions deploy bcv-rate
supabase functions deploy send-otp

# Secrets
supabase secrets set MESSAGE_BIRD_API_KEY=...
supabase secrets set TURNSTILE_SECRET_KEY=...
supabase secrets set SUPABASE_OTP_DEV_BYPASS=true   # dev only

# Logs
supabase functions logs bcv-rate --scroll
supabase functions logs send-otp --scroll
```

### Flutter commands

```bash
cd mobile

# Install dependencies
flutter pub get

# Run with credentials (reads from .env)
flutter run --dart-define-from-file=.env

# Or via VS Code: F5 → "RuedaSeguro (dev)"

# Run tests
flutter test --reporter expanded

# Run specific test
flutter test test/features/policy/domain/policy_detail_model_test.dart -v

# Analyze
flutter analyze

# Build release APK
flutter build apk --release --dart-define-from-file=.env
```

---

## 11. Testing

### Unit tests (7 files, ~120 test cases)

| File | Covers |
|------|--------|
| `currency_utils_test.dart` | `formatUSD`, `formatVES`, `convertUsdToVes`, `formatExchangeRate` |
| `hash_utils_test.dart` | SHA-256 for `Uint8List` and `String`; known vector verification |
| `date_utils_test.dart` | ISO 8601 round-trip, Spanish locale formatting, `isExpired`, `daysUntilExpiry` |
| `validators_test.dart` | Phone (VE + CO), email, cédula, plate regex |
| `cedula_parser_test.dart` | V/E/CC parsing, confidence scoring, name extraction, garbage input |
| `carnet_parser_test.dart` | VE/CO plate parsing, brand detection, serial extraction |
| `cross_validator_test.dart` | ID match/mismatch, missing field handling |

### Sprint 2B tests (3 files)

| File | Covers |
|------|--------|
| `policy_detail_model_test.dart` | `fromMap()` scalar fields, rider fields, vehicle fields, plan/carrier, `carrierPolicyNumber` null/present, int-as-double coercion, `isProvisional/isConfirmed/isActive`, `displayNumber` fallback, `formattedStartDate`, `daysRemaining` (future/expired), `progressFraction` clamping |
| `policy_pdf_service_test.dart` | PDF magic bytes (`%PDF`), null policy (demo mode), provisional policy, confirmed policy, demo ≠ real PDF |
| `product_selection_screen_test.dart` | Shimmer during loading, plan cards when data loaded, mock fallback on provider error, BCV rate label |

### Manual test checklist

`mobile/SPRINT_2B_TEST_CHECKLIST.md` — 35 interaction tests across 7 sections:
1. Demo mode full policy flow (10 steps)
2. Home screen data (4 steps)
3. Authenticated mode full flow (8 steps)
4. Bank transfer payment (4 steps)
5. Edge cases (5 scenarios)
6. Code test commands
7. Supabase verification SQL queries

---

## 12. Known Limitations & Sprint 3 Preview

### Current limitations (as of Sprint 2B)

| Area | Limitation |
|------|-----------|
| Carrier API | No real Acsel/Sirway integration yet — policies are always `provisional`. Waiting for William's API credentials |
| Payment verification | Manual only — admin must verify Pago Móvil references in Supabase dashboard |
| SMS in production | MessageBird configured; Colombian numbers tested; Venezuelan operator coverage to verify |
| Telemetry sensors | `sensors_plus`, `geolocator`, `background_fetch` commented out — activated in Phase 1.5 |
| Admin portal | Next.js scaffold exists but no live data binding — replaced by Thony's Quasar platform |
| MQTT | No code yet — blocked on Thony's broker URL + credentials (guide at `docs/MQTT_INTEGRATION_GUIDE.md`) |
| pg_cron | `metrics_daily` materialized view created but auto-refresh not scheduled (requires Supabase Pro) |
| Sentry | Package installed + DSN config in `EnvConfig` — initialization wiring pending |

### Sprint 3 scope (not covered by this document)

- RS-060: Acsel + Sirway carrier API client (dual-system)
- RS-061: Policy confirmation webhook (issuance_status: provisional → confirmed)
- RS-062: Issuance state machine UI (real-time status polling)
- RS-063: Real SMS OTP (Twilio) — currently MessageBird via Supabase native
- RS-059: MQTT client for GCP dashboard integration
- RS-065: Push notifications (FCM)
- RS-066: Claims with photo evidence upload
- RS-068: Sentry initialization + error boundaries
- RS-070: Full observability dashboard

---

## 13. How to Run

### Prerequisites

- Flutter 3.41+ (`flutter --version`)
- Dart 3.x
- Supabase CLI (`npm install -g supabase`)
- Android Studio / Xcode (for mobile targets)
- Chrome (for web target)

### Environment setup

1. Copy env files:
   ```bash
   cp mobile/.env.example mobile/.env
   cp .env.example .env
   ```

2. Fill in real values:
   - `SUPABASE_URL` — from Supabase Dashboard → Settings → API
   - `SUPABASE_ANON_KEY` — from same page
   - `TURNSTILE_SITE_KEY` — from Cloudflare Dashboard → Turnstile → your site

### Run mobile app

```bash
cd mobile
flutter pub get
flutter run --dart-define-from-file=.env
```

Or press **F5** in VS Code (launch config pre-configured).

### Run tests

```bash
cd mobile
flutter test --reporter expanded
```

### Apply database migrations

```bash
# From repo root
supabase db push
# Or apply individually:
psql $DATABASE_URL -f supabase/queries/RS-007_01_enum_updates.sql
# ... (apply in numerical order)
```

### Deploy edge functions

```bash
supabase functions deploy bcv-rate
supabase functions deploy send-otp
supabase functions deploy verify-otp
supabase functions deploy policy-retry
supabase functions deploy renewal-reminder
```
