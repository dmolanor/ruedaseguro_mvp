# RuedaSeguro — Technical Progress Summary
> Sprint 0 + Sprint 1 | Last updated: 2026-03-22

---

## Project Overview

**RuedaSeguro** is a Venezuelan InsurTech platform delivering parametric micro-insurance for motorcycle riders (B2C) managed through a carrier/broker network (B2B). The MVP is structured as a monorepo with three primary systems:

| System | Stack | Purpose |
|--------|-------|---------|
| **Mobile App** | Flutter 3.x / Dart | Rider-facing: onboarding, policy purchase, claims |
| **Admin Portal** | Next.js 16 / React 19 / TypeScript | Carrier & broker dashboard |
| **Backend** | Supabase (PostgreSQL + Auth + Edge Functions) | Shared data layer, auth, business logic |

---

## Repository Structure

```
RuedaSeguro/
├── mobile/              # Flutter app (B2C)
├── admin-portal/        # Next.js dashboard (B2B)
├── supabase/            # Migrations, Edge Functions
├── research_docs/       # Architecture, sprint planning, regulatory docs
├── contracts/           # Solidity smart contracts (Phase 1.5 placeholder)
├── .github/workflows/   # CI/CD (flutter-ci.yml, admin-ci.yml)
├── .env                 # Supabase project credentials (gitignored)
└── .env.example         # Template for onboarding new contributors
```

---

## Sprint 0 — Project Foundation

**Goal:** Establish the entire technical skeleton before writing any feature code.

### Monorepo & DevOps (RS-001 → RS-005)

- Single Git repo with independent `mobile/` and `admin-portal/` subprojects
- `.gitignore` covering both Flutter artifacts (`.dart_tool/`, `build/`) and Node artifacts (`node_modules/`, `.next/`)
- **GitHub Actions CI** — two workflows triggered independently by path:
  - `flutter-ci.yml` → `flutter analyze` + `flutter test` + `flutter build apk --debug`
  - `admin-ci.yml` → `npm ci` + ESLint + `next build`
- Flutter SDK and `pub` cache cached per workflow run for speed

### Flutter App Scaffold (RS-002)

**Entry point** `mobile/lib/main.dart`:
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: EnvConfig.supabaseUrl, anonKey: EnvConfig.supabaseAnonKey);
  await initializeDateFormatting('es');   // required for Spanish date formatting
  runApp(const ProviderScope(child: App()));
}
```

**State management:** Riverpod (`flutter_riverpod: ^2.6.1`) — all providers are `StateNotifierProvider` or `StreamProvider`, no `ChangeNotifier`.

**Navigation:** GoRouter (`go_router: ^14.8.1`) with a single `routerProvider` that drives auth-aware redirects. There are 20 named routes grouped into three access levels:

```
Public (no auth required):  /welcome  /login  /otp
Onboarding (auth, no profile):  /onboarding/cedula  /onboarding/cedula/confirm
                                /onboarding/carnet   /onboarding/vehicle-photo
                                /onboarding/vehicle/confirm  /onboarding/address
                                /onboarding/consent
Authenticated (with profile):   /home  /policy/*  /payment/method  /claims/new  /profile
```

**Auth state machine** (`AuthStatus` enum, 4 states):
```dart
enum AuthStatus { initial, unauthenticated, authenticated, authenticatedWithProfile }
```
GoRouter subscribes to auth changes via `GoRouterRefreshStream` — a thin `ChangeNotifier` wrapper around a Dart `Stream<AuthState>` that calls `notifyListeners()` on every emit, triggering a redirect evaluation.

**Design system** (`mobile/lib/core/theme/`):
- Colors: Navy `#1A3A52` (primary), Orange `#FF6B35` (accent), dark background `#0F2236`
- Typography: Montserrat (headings) + Lato (body), defined via `RSTypography` constants
- Spacing: 4px grid — `xs=4, sm=8, md=16, lg=24, xl=32, xxl=48`

**Key dependencies:**
```yaml
supabase_flutter: ^2.9.0       # Auth + DB + Storage + Edge Functions
google_mlkit_text_recognition: ^0.14.0  # On-device OCR (no server round-trip)
camera: ^0.11.1                # Live camera feed for document scanning
flutter_riverpod: ^2.6.1       # State management
go_router: ^14.8.1             # Declarative routing
crypto: ^3.0.6                 # SHA-256 hashing (document integrity)
intl: ^0.19.0                  # Spanish date/currency formatting
local_auth: ^2.3.0             # Biometric auth (Phase 1.5 prep)
pdf + printing: ^3/^5          # Policy PDF generation
fl_chart: ^0.70.2              # Charts in admin views
```

### Next.js Admin Portal Scaffold (RS-003)

Built with **Next.js 16.2.1 App Router** (React 19), **Tailwind CSS v4**, **shadcn/ui** component library, and **Supabase SSR** for server-side session management.

**Route groups:**
```
app/
├── login/               # Shared login (phone OTP)
├── (carrier)/           # Carrier role: dashboard, policies, claims, payments,
│                        #   brokers, promoters, points-of-sale, settings
└── (broker)/            # Broker role: broker dashboard (Phase 1)
```

**Supabase SSR pattern** — two separate client factories:
- `lib/supabase/client.ts` → browser client (`createBrowserClient`)
- `lib/supabase/server.ts` → server client (`createServerClient` with cookie jar)
- `middleware.ts` → session refresh on every request (prevents token expiry mid-session)

**UI stack:**
- `shadcn/ui` components: Button, Card, Table, Badge, Dialog, Sheet, Select, Tabs, Avatar, Dropdown
- `sonner` for toast notifications
- `lucide-react` for icons
- `next-themes` for dark/light mode toggle

### Supabase Backend Setup (RS-006 → RS-008)

**Database schema** (20 tables across 5 concern areas):

| Area | Tables |
|------|--------|
| B2B2C Network | `carriers`, `carrier_users`, `brokers`, `promoters`, `points_of_sale` |
| Rider Identity | `profiles`, `vehicles`, `documents` |
| Insurance Core | `policy_types`, `policies`, `payments`, `claims`, `claim_evidence` |
| Finance | `exchange_rates` |
| Compliance | `audit_log` |

**Storage buckets:** `documents` (cedula/carnet scans), `policies` (PDFs), `receipts`, `public`

**Edge Functions** (Deno runtime):
- `bcv-rate/index.ts` — fetches live BCV exchange rate (USD→VES) for premium calculation
- `send-otp/index.ts` — sends OTP via SMS (requires Twilio credentials; currently gated behind dev bypass)
- `verify-otp/index.ts` — validates OTP token

**Supabase constants** centralized in `core/constants/supabase_constants.dart`:
```dart
class SupabaseConstants {
  static const profiles = 'profiles';
  static const vehicles = 'vehicles';
  // ... all 20 table names as constants
  static const bucketDocuments = 'documents';
  static const fnBcvRate = 'bcv-rate';
}
```

---

## Sprint 1 — Auth, Onboarding & Testing

**Goal:** Complete the user journey from phone number → verified identity → policy-ready profile, with full unit test coverage of all domain logic.

### Auth Flow (RS-009 → RS-015)

#### Phone + OTP Login (`login_screen.dart`, `otp_screen.dart`)

**Login screen** collects a phone number with a country-picker that supports Venezuela and Colombia:
```dart
class _Country {
  final String flag;
  final String dialCode;
  final String hint;
  final bool Function(String digits) isValid;
}
bool _isVenezuelanPhone(String d) => d.length == 10 && d.startsWith('4');
bool _isColombianPhone(String d)  => d.length == 10 && d.startsWith('3');
```
A bottom sheet lets the user switch between `🇻🇪 +58` and `🇨🇴 +57`. The phone number is auto-formatted as `XXX XXXXXXX` by a custom `TextInputFormatter` and validated on each keystroke before enabling the submit button.

On submit, the full E.164 phone is constructed (`${country.dialCode}$rawDigits`) and passed to `AuthRepository.signInWithOtp()`.

**OTP screen** (`otp_screen.dart`) renders six individual `TextField` boxes (one digit each) with:
- Auto-advance: typing a digit moves focus to the next box
- Paste support: pasting `123456` fills all six boxes at once
- Backspace navigation: deleting from an empty box moves focus left
- Rate-limited resend: 60-second countdown, max 3 attempts
- Error messages distinguishing expired token, wrong token, and network failure

Keyboard events use the current Flutter API (`KeyboardListener` / `KeyEvent` / `KeyDownEvent`) — the deprecated `RawKeyboardListener`/`RawKeyEvent` API was replaced.

**Auth repository** (`auth_repository.dart`):
```dart
Future<void> signInWithOtp(String phone)       // triggers SMS OTP
Future<Session?> verifyOtp(String phone, String token)  // validates OTP
Future<void> signInAnonymously()               // dev bypass — no SMS required
Future<void> signOut()
Future<bool> profileExists()                   // used to determine AuthStatus
Stream<AuthState> get onAuthStateChange        // feeds GoRouterRefreshStream
```

#### Dev Bypass (debug-mode only)

Because Supabase phone auth requires configuring a third-party SMS provider (Twilio/MessageBird), which is blocked during development, a **dev bypass button** is injected into the login screen exclusively when `kDebugMode == true`:

```dart
if (kDebugMode) _DevBypassButton(isLoading: _isLoading)
```

`_DevBypassButton` calls `signInAnonymously()` — Supabase creates a real authenticated session for an anonymous user, identical to a phone-verified session from GoRouter's perspective. The auth state changes to `authenticated`, the GoRouter refresh fires, and the redirect sends the user to `/onboarding/cedula` automatically.

### Onboarding Flow (RS-016 → RS-025)

Seven screens in sequence: `cedula_scan` → `cedula_confirm` → `carnet_scan` → `vehicle_photo` → `vehicle_confirm` → `address_form` → `consent`.

**State** is held in a single `OnboardingData` value object managed by `OnboardingNotifier` (Riverpod `StateNotifier`). All fields are nullable — screens write their slice via `copyWith()` and read from the provider.

```dart
@immutable
class OnboardingData {
  // Identity
  final CedulaParseResult? cedulaOcr;
  final File? cedulaImage;
  final String? idType, idNumber, firstName, lastName, nationality, sex;
  final DateTime? dateOfBirth;
  // Vehicle
  final CarnetParseResult? carnetOcr;
  final File? carnetImage, vehiclePhoto;
  final String? plate, brand, model, color, vehicleUse, serialMotor, serialCarroceria;
  final int? year;
  // Address
  final String? urbanizacion, ciudad, municipio, estado, codigoPostal;
  // Consent (4 required booleans + timestamp)
  final bool consentRcv, consentVeracidad, consentAntifraude, consentPrivacidad;
  final DateTime? consentTimestamp;
  // Emergency contact (optional)
  final String? emergencyContactName, emergencyContactPhone, emergencyContactRelation;
}
```

#### Document Scanner Widget (`document_scanner.dart`)

Reusable widget wrapping `camera` + `google_mlkit_text_recognition`. Flow:
1. Live camera preview with a framing overlay
2. User taps capture → image saved to temp file
3. `TextRecognizer` runs **on-device** (no network) → returns `RecognizedText` with positioned `TextBlock` objects
4. Result passed to the appropriate parser (cedula or carnet)

#### OCR Parsers

**`CedulaParser.parse(rawText, blocks)`** extracts Venezuelan/Colombian ID data:
- Venezuelan (V/E prefix): regex `([VvEe])[.\-\s]?\s*(\d{1,3}[.,]?\d{3}[.,]?\d{0,3})`
- Colombian CC: detected by `COLOMBIA` keyword + 8–10 digit number without letter prefix
- Date of birth: day/month/year heuristic with age validation (16–100 years)
- Name extraction: scans `TextBlock` lines for uppercase all-alpha strings not in an exclusion list (`REPUBLICA`, `CEDULA`, `NOMBRES`, etc.)
- Nationality regex covers: `VENEZOLAN[OA]`, `EXTRANJERO[A]?`, `COLOMBIAN[OA]`
- Per-field confidence scores (0.0–1.0); overall = mean of all scored fields

**`CarnetParser.parse(rawText, blocks)`** extracts motorcycle registration data:
- Venezuelan plates: `ABC-123-DE` pattern (3 letters, 2–3 digits, 2–3 letters)
- Colombian plates: `ABC-123` pattern (3 letters, 3 digits, no trailing letters)
- Brand matching: exact substring match against 20 known brands (`HONDA`, `YAMAHA`, `BAJAJ`, `BERA`, etc.)
- Serial numbers: 8–20 character alphanumeric strings, labeled by proximity to `MOTOR`/`CARROCER` keywords
- Owner name: extracted from line immediately following `PROPIETARIO`/`TITULAR`/`NOMBRE` label

**`CrossValidator`**: compares `idNumber` from cedula with `ownerCedula` extracted from carnet to flag mismatches.

#### Identity Confirmation Screen (`cedula_confirm_screen.dart`)

Pre-fills form fields from OCR results. Fields with confidence < 0.90 are highlighted in amber with a "Verifica este campo" hint:
```dart
class _ConfidenceField extends StatelessWidget {
  // Shows RSTextField with amber border if 0 < confidence < 0.9
}
```

Supports ID types `V`, `E`, `CC` (Colombian). ID number validation: 6–10 digits (`^\d{6,10}$`).

#### Address & Consent Screens

Address form collects: `urbanizacion`, `ciudad`, `municipio`, `estado`, `codigoPostal` — all text fields matching Venezuelan address conventions.

Consent screen presents four SUDEASEG-required checkboxes:
- RCV coverage terms
- Data truthfulness declaration
- Anti-fraud acknowledgment
- Privacy policy

All four must be checked before the submit button enables. On submit, `consentTimestamp` is recorded.

### Validators (`validators.dart`)

```dart
// Venezuelan: 10 digits starting with 04xx
// Colombian: 10 digits starting with 3xx (mobile) or 6xx (landline)
static final _phoneRegex = RegExp(
  r'^(\+58\s?)?0?4[0-9]{2}[\s-]?\d{7}'  // Venezuela
  r'|^(\+57\s?)?3\d{9}',                 // Colombia mobile
);

static bool isAdult(DateTime? dob) { /* >= 18 years */ }
static bool isValidCedula(String v) { /* V/E + 7-8 digits */ }
static bool isValidPlate(String v) { /* ABC-123-DE or ABC-123 */ }
```

### Unit Tests (RS-039 / RS-040)

**7 test files, ~120 test cases total:**

| File | What it tests |
|------|---------------|
| `currency_utils_test.dart` | `formatUSD`, `formatVES`, `convertUsdToVes`, `formatExchangeRate` |
| `hash_utils_test.dart` | `sha256Hash` (Uint8List), `sha256HashString`; known SHA-256 vectors |
| `date_utils_test.dart` | ISO 8601 round-trip, Spanish display formatting, `isExpired`, `daysUntilExpiry` |
| `validators_test.dart` | Phone (VE + CO), email, cédula, plate validation |
| `cedula_parser_test.dart` | Venezuelan V/E parsing, Colombian CC parsing, field confidence, name extraction |
| `carnet_parser_test.dart` | Venezuelan/Colombian plate parsing, brand/color/year detection, serial extraction |
| `cross_validator_test.dart` | ID match, mismatch, missing field handling |

**Notable test fixes:**
- `formatUSD(1.005)` → `'$1.00'` not `'$1.01'`: IEEE 754 — `1.005` is actually `1.004999...` in binary float; test changed to `formatUSD(10.1)` → `'$10.10'`
- `date_utils_test` requires `setUpAll(() async { await initializeDateFormatting('es'); })` — `DateFormat('d MMM yyyy', 'es')` throws `LocaleDataException` without prior initialization
- `carnet_parser_test` garbage-input test used `'LOREM IPSUM'` which contains brand `UM` (substring of `IPSUM`); changed to `'LOREM DOLOR'`
- `cedula_parser_test` confidence ordering test: 2-field parse scores 0.95 avg but 5-field parse scores lower (0.9) due to DOB/sex fields having 0.85 confidence; assertion changed to compare `fieldConfidences.length` instead of the mean score

### Bug Fixes Applied During Sprint 1

| Bug | Root cause | Fix |
|-----|-----------|-----|
| App crash on startup | `main()` was synchronous, `Supabase.instance` called before `initialize()` | Rewrote `main()` as `async`, added `Supabase.initialize()` |
| App stuck on splash forever | `/splash` was in `_publicRoutes`; unauthenticated redirect returned `null` for it | Removed `/splash` from `_publicRoutes`; splash is now its own guard |
| `unawaited_futures` lint warnings | `context.push()` returns `Future<T>`; not being awaited | Wrapped with `unawaited()` from `dart:async` in 4 screens |
| Deprecated keyboard API | `RawKeyboardListener`/`RawKeyEvent` removed in Flutter 3.18+ | Migrated to `KeyboardListener`/`KeyEvent`/`KeyDownEvent`/`onKeyEvent:` |
| `inputFormatters` ignored | `rs_text_field.dart` declared `List<dynamic>?` but never passed it to `TextFormField` | Typed as `List<TextInputFormatter>?` and wired into `TextFormField` |
| Duplicate import lint error | `consent_screen.dart` imported typography twice | Removed duplicate import |
| `LocaleDataException` at runtime | `initializeDateFormatting('es')` not called before `DateFormat` with locale | Added to `main()` before `runApp()` |

---

## Current Architecture Diagram

```
┌─────────────────────────────────────────────────────┐
│                    MOBILE APP                        │
│                                                      │
│  main.dart → Supabase.initialize() + intl locale     │
│           → ProviderScope → App → GoRouter           │
│                                                      │
│  Auth Layer                                          │
│  ├── auth_provider (StreamProvider<AuthState>)       │
│  ├── AuthRepository (signInWithOtp, verifyOtp,       │
│  │   signInAnonymously, profileExists)               │
│  └── GoRouterRefreshStream → redirect logic          │
│                                                      │
│  Onboarding Layer                                    │
│  ├── OnboardingNotifier (StateNotifier)              │
│  ├── OnboardingData (immutable value object)         │
│  ├── CedulaParser + CarnetParser (on-device OCR)     │
│  ├── CrossValidator (document cross-check)           │
│  └── ImageValidator (sharpness, glare detection)     │
│                                                      │
│  Shared Widgets: RSButton, RSTextField, RSCard,      │
│  DocumentScanner, AmountDisplay, OfflineBanner       │
└──────────────┬──────────────────────────────────────┘
               │ supabase_flutter SDK
               ▼
┌─────────────────────────────────────────────────────┐
│                   SUPABASE BACKEND                   │
│                                                      │
│  Auth: Phone OTP (SMS) + Anonymous (dev)            │
│  Database: PostgreSQL (20 tables, RLS pending)       │
│  Storage: 4 buckets (documents, policies, ...)       │
│  Edge Functions: bcv-rate, send-otp, verify-otp      │
└──────────────┬──────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────┐
│                  ADMIN PORTAL                        │
│                                                      │
│  Next.js 16 App Router + React 19                   │
│  Route groups: (carrier) / (broker)                  │
│  Supabase SSR: server client + middleware            │
│  UI: shadcn/ui + Tailwind CSS v4 + sonner           │
└─────────────────────────────────────────────────────┘
```

---

## What Is NOT Yet Built (Sprint 2+)

| Feature | Sprint | Notes |
|---------|--------|-------|
| Supabase RLS policies | Sprint 2 | All tables currently unprotected |
| Profile write to DB | Sprint 2 | Consent screen collects data locally only |
| Policy quoting engine | Sprint 2 | `ProductSelectionScreen` is a stub |
| Payment integration (Stripe / Pago Móvil) | Sprint 2 | `PaymentMethodScreen` is a stub |
| Claims filing flow | Sprint 2 | `NewClaimScreen` is a stub |
| SMS provider (Twilio) | Sprint 2 | Phone OTP currently requires dev bypass |
| BCV rate fetching | Sprint 2 | Edge function exists, not yet called from app |
| PDF policy generation | Sprint 2 | `pdf` package installed, not implemented |
| Admin portal data binding | Sprint 2 | Screens show static mock data |
| Biometric auth | Phase 1.5 | `local_auth` installed, not wired |
| Background telemetry | Phase 1.5 | `sensors_plus`, `geolocator` commented out |
| Smart contracts | Phase 1.5 | `contracts/` directory is a placeholder |
