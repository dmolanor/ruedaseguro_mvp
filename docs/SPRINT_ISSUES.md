# RuedaSeguro — Sprint 0 & Sprint 1 Issues (v2.0)

> **Project:** RuedaSeguro MVP
> **Date:** March 21, 2026
> **Architecture Reference:** MVP_ARCHITECTURE.md v2.0
> **Methodology:** Scrum (7-day sprints)
> **Story Points Scale:** Fibonacci (1, 2, 3, 5, 8, 13)
> **Priority:** P0 = Blocker, P1 = Critical, P2 = Important, P3 = Nice-to-have
> **Changelog v2.0:** Updated to reflect B2B2C sales network, 3-document + vehicle photo onboarding, multi-tier policies, local server migration path, image quality anti-fraud, legal consent (SUDEASEG), cross-validation, updated design system (Navy Blue + Orange, Montserrat + Lato)

---

## Labels Reference

| Label | Color | Description |
|---|---|---|
| `epic` | Purple | High-level grouping of related stories |
| `story` | Blue | User-facing functionality |
| `task` | Green | Technical work, no direct user impact |
| `bug` | Red | Defect (used post-implementation) |
| `spike` | Orange | Research / investigation / prototyping |
| `flutter` | Cyan | Flutter mobile app work |
| `admin` | Teal | Admin portal (Next.js) work |
| `supabase` | Dark Green | Backend / database / Edge Functions |
| `devops` | Gray | CI/CD, infrastructure, tooling |
| `design` | Pink | UI/UX design system work |
| `testing` | Yellow | Test coverage |
| `documentation` | White | Docs, READMEs, guides |
| `b2b2c` | Indigo | Sales network (brokers, promoters, POS) |
| `security` | Dark Orange | Anti-fraud, validation, encryption |
| `P0` | Dark Red | Blocker — Sprint cannot complete without this |
| `P1` | Red | Critical — Core functionality |
| `P2` | Orange | Important — Quality & polish |
| `P3` | Yellow | Nice-to-have — Can defer if time-constrained |

---

# SPRINT 0 — Project Foundation

> **Goal:** Every developer can clone the repo, run `flutter run` and `npm run dev`, and see a working app shell connected to Supabase with the full B2B2C schema. All infrastructure is provisioned, all conventions are established, and the codebase is ready for feature development.
>
> **Duration:** Days 1–3
> **Total Story Points:** 58

---

## Epic: E0.1 — Repository & DevOps Setup

### RS-001: Initialize monorepo and Git configuration
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `devops`, `P0` |
| **Points** | 2 |
| **Assignee** | — |
| **Dependencies** | None (first task) |

**Description**
Create the Git repository with the monorepo structure defined in `MVP_ARCHITECTURE.md` Section 15. Establish branching conventions and protect the main branch.

**Acceptance Criteria**
- [ ] Git repository initialized at project root
- [ ] `.gitignore` configured for Flutter, Next.js, Supabase, and IDE files (Android build artifacts, `node_modules/`, `.env*`, `*.jks`, `.dart_tool/`, `build/`, `.next/`)
- [ ] Branch protection: `main` requires PR with at least 1 approval
- [ ] Branching convention documented: `feat/RS-XXX-short-description`, `fix/RS-XXX-short-description`, `chore/RS-XXX-short-description`
- [ ] Commit convention documented: `type(scope): message` (e.g., `feat(auth): add OTP verification screen`)
- [ ] Root `README.md` with project overview, setup instructions placeholder, and architecture link
- [ ] Folder structure created:
  ```
  RuedaSeguro/
  ├── mobile/
  ├── admin-portal/
  ├── supabase/
  │   ├── migrations/
  │   └── functions/
  ├── contracts/              # Solidity (Phase 1.5 placeholder)
  ├── docs/
  ├── research_docs/
  │   ├── Architects/
  │   └── original_docs/
  └── .github/workflows/
  ```

---

### RS-002: Configure Flutter project with dependencies
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `flutter`, `P0` |
| **Points** | 3 |
| **Assignee** | — |
| **Dependencies** | RS-001 |

**Description**
Initialize the Flutter project inside `mobile/` with all required dependencies from `MVP_ARCHITECTURE.md` Section 4.3. Pin dependency versions for reproducibility. Include Phase 1.5 sensor packages as commented-out stubs.

**Acceptance Criteria**
- [ ] Flutter project created at `mobile/` with `flutter create --org com.ruedaseguro mobile`
- [ ] Minimum SDK: Flutter 3.x, Dart 3.x
- [ ] All dependencies from Section 4.3 added to `pubspec.yaml` with pinned versions
- [ ] Phase 1.5 packages included as comments in `pubspec.yaml` (sensors_plus, background_fetch, geolocator, flutter_background_service)
- [ ] `flutter pub get` succeeds without errors
- [ ] `flutter analyze` returns 0 issues
- [ ] `flutter test` runs (even if no tests yet)
- [ ] `analysis_options.yaml` configured with strict linting rules:
  - `prefer_const_constructors`
  - `always_use_package_imports`
  - `avoid_print` (use logger instead)
  - `prefer_final_locals`
  - `unawaited_futures` warning
- [ ] Android `minSdkVersion` set to 23 (Android 6.0 — required for ML Kit)
- [ ] Android `compileSdkVersion` set to 34+
- [ ] Permissions in `AndroidManifest.xml`: Internet, Camera, Read/Write external storage
- [ ] iOS `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` in `Info.plist`
- [ ] App package name: `com.ruedaseguro.app`
- [ ] App display name: "RuedaSeguro"

---

### RS-003: Configure Next.js admin portal project
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `admin`, `P0` |
| **Points** | 3 |
| **Assignee** | — |
| **Dependencies** | RS-001 |

**Description**
Initialize the Next.js admin portal inside `admin-portal/` with shadcn/ui and Supabase client. The portal serves multiple roles: carrier admins, brokers, and (in Phase 1.5) clinical staff. Route structure must support this from Day 1.

**Acceptance Criteria**
- [ ] Next.js 15 project created at `admin-portal/` with App Router
- [ ] TypeScript configured with strict mode
- [ ] Tailwind CSS 4 installed and configured
- [ ] shadcn/ui initialized with components: `button`, `input`, `card`, `table`, `badge`, `dialog`, `dropdown-menu`, `sheet`, `tabs`, `toast`, `avatar`, `select`
- [ ] `@supabase/supabase-js` and `@supabase/ssr` installed
- [ ] ESLint + Prettier configured
- [ ] Environment variables template (`.env.local.example`) with:
  - `NEXT_PUBLIC_SUPABASE_URL`
  - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
  - `SUPABASE_SERVICE_ROLE_KEY`
- [ ] Route group structure prepared for multi-role access:
  ```
  src/app/
  ├── login/
  ├── (carrier)/dashboard/     # Carrier admin routes
  ├── (broker)/broker/         # Broker-specific routes (Phase 1)
  └── layout.tsx               # Shared layout with role-based sidebar
  ```
- [ ] `npm run dev` starts successfully on `localhost:3000`
- [ ] `npm run build` completes without errors
- [ ] Basic layout shell: sidebar navigation + header + content area

---

### RS-004: Set up GitHub Actions CI pipeline
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `devops`, `P1` |
| **Points** | 3 |
| **Assignee** | — |
| **Dependencies** | RS-002, RS-003 |

**Description**
Create CI workflows that run on every PR and push to main. Separate workflows for Flutter and admin portal.

**Acceptance Criteria**
- [ ] `.github/workflows/flutter-ci.yml`:
  - Triggers on PR and push to `main` (paths: `mobile/**`)
  - Runs `flutter analyze`
  - Runs `flutter test`
  - Builds APK (`flutter build apk --debug`) to verify compilation
  - Caches Flutter SDK and pub cache
- [ ] `.github/workflows/admin-ci.yml`:
  - Triggers on PR and push to `main` (paths: `admin-portal/**`)
  - Runs `npm ci`
  - Runs `npm run lint`
  - Runs `npm run build`
  - Caches `node_modules`
- [ ] Both workflows pass on current codebase
- [ ] Status checks visible on PRs

---

### RS-005: Configure Android release signing
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `flutter`, `devops`, `P2` |
| **Points** | 2 |
| **Assignee** | — |
| **Dependencies** | RS-002 |

**Description**
Set up Android release signing so we can produce signed APKs for distribution. The keystore must NOT be committed to the repository.

**Acceptance Criteria**
- [ ] Upload keystore generated (`ruedaseguro-upload.jks`)
- [ ] `mobile/android/key.properties` added to `.gitignore`
- [ ] `key.properties.example` template committed with placeholder values
- [ ] `mobile/android/app/build.gradle` configured to read signing config from `key.properties`
- [ ] `flutter build apk --release` produces a signed APK
- [ ] Keystore credentials documented securely (shared via password manager, NOT in repo)
- [ ] GitHub Actions secret `KEYSTORE_BASE64` and `KEY_PROPERTIES` configured for CI release builds (optional — can defer)

---

## Epic: E0.2 — Supabase Backend Setup

### RS-006: Create Supabase project and configure environment
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `supabase`, `P0` |
| **Points** | 2 |
| **Assignee** | — |
| **Dependencies** | RS-001 |

**Description**
Provision the Supabase project (free tier) and configure local development with the Supabase CLI. Per MVP Architecture v2.0, Supabase is authorized for initial development and testing — production migration to local Venezuelan server comes in Phase 1.5.

**Acceptance Criteria**
- [ ] Supabase project created on `supabase.com` (free tier)
- [ ] Project region selected (closest to Venezuela — `us-east-1` or `sa-east-1`)
- [ ] `supabase/config.toml` configured with project reference
- [ ] Supabase CLI installed and linked to project
- [ ] `supabase start` runs local development instance successfully
- [ ] Environment variables documented:
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`
  - `SUPABASE_SERVICE_ROLE_KEY`
- [ ] `.env` file created for Flutter (`mobile/.env`) with Supabase credentials — added to `.gitignore`
- [ ] `.env.local` file created for admin portal with Supabase credentials — added to `.gitignore`

---

### RS-007: Apply initial database schema migration
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `supabase`, `P0` |
| **Points** | 8 |
| **Assignee** | — |
| **Dependencies** | RS-006 |

**Description**
Create and apply the SQL migration files containing the complete MVP v2.0 schema from `MVP_ARCHITECTURE.md` Section 5.2. This includes the full B2B2C hierarchy (brokers, promoters, points of sale), updated policy tables with consent fields and sales attribution, and expanded RLS policies.

**Acceptance Criteria**
- [ ] Migration file `supabase/migrations/001_initial_schema.sql` created containing:
  - All ENUM types: `policy_status` (with `pending_emission`, `observed`, `rejected_emission`), `payment_status`, `payment_method`, `claim_status`, `document_type` (with `vehicle_photo`, `factura_compra`, `payment_receipt`, `rcv_certificate`), `id_type`, `broker_status`, `promoter_status`
  - Core tables: `carriers` (with `required_documents` JSONB), `carrier_users` (with expanded role options), `profiles` (with address fields: `urbanizacion`, `ciudad`, `municipio`, `estado`, `codigo_postal`; referral tracking; `nationality`, `sex`), `vehicles` (with `vehicle_use`, `rear_photo_url`), `policy_types` (with `tier`, `coverage_details`, `upsell_options`, `target_percentage`, `payment_frequency`), `policies` (with `broker_id`, `promoter_id`, `point_of_sale_id`, `referral_code`, consent booleans, `emission_response`, `certificate_url`, `upsells`), `payments` (with `method` enum, `receipt_url`), `claims` (with oracle validation fields, `triage_level`), `claim_evidence`, `documents` (with `sharpness_score`, `is_screen_photo`), `exchange_rates`, `audit_log`
  - All indexes (exchange rates, audit log, policies by carrier/broker/promoter/status, payments by status, promoters by broker/referral)
  - All constraints (foreign keys, unique constraints, NOT NULL)
- [ ] Migration file `supabase/migrations/002_b2b2c_network.sql` created containing:
  - `brokers` table (with `policy_quota`, `commission_rate`, `status`)
  - `promoters` table (with `referral_code` UNIQUE, `broker_id` FK, `status`)
  - `points_of_sale` table (with `type`, geolocation, `broker_id` FK)
- [ ] Migration file `supabase/migrations/003_rls_policies.sql` created containing:
  - RLS enabled on all user-facing tables
  - Rider policies: own-data access on profiles, vehicles, policies, payments, claims, documents
  - Broker policies: view own broker record, view their promoters, view their points of sale
  - Promoter policies: view own promoter record
  - Public: policy_types (active only), exchange_rates
  - INSERT policies for profiles, vehicles, policies, payments, documents, claim_evidence, claims
- [ ] Migration file `supabase/migrations/004_functions.sql` created containing:
  - `generate_policy_number(p_carrier_id UUID)` function
  - `generate_referral_code(p_promoter_name TEXT)` function
  - `handle_updated_at()` trigger function for `updated_at` columns
  - Triggers attached to all tables with `updated_at` column
- [ ] `supabase db reset` applies all migrations without errors
- [ ] Schema verified via Supabase Dashboard — all tables, columns, types, and RLS policies visible
- [ ] Migration applies cleanly on fresh database (idempotent check)

---

### RS-008: Configure Supabase Auth for phone OTP
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `supabase`, `P0` |
| **Points** | 2 |
| **Assignee** | — |
| **Dependencies** | RS-006 |

**Description**
Configure Supabase Auth to support phone number authentication with OTP via SMS. This is the primary auth method for riders.

**Acceptance Criteria**
- [ ] Phone auth enabled in Supabase Dashboard → Authentication → Providers
- [ ] SMS provider configured (options ranked by preference):
  1. Supabase built-in (free for testing, rate-limited)
  2. Twilio (if free tier is insufficient for testing)
- [ ] OTP message template customized in Spanish: `"Tu código RuedaSeguro es: {{ .Code }}. Válido por 5 minutos."`
- [ ] OTP expiry set to 300 seconds (5 minutes)
- [ ] OTP length set to 6 digits
- [ ] Rate limiting configured: max 3 OTP requests per phone per 10 minutes
- [ ] Test: sending OTP to a Venezuelan phone number (+58) succeeds
- [ ] Test: verifying correct OTP returns a valid JWT session
- [ ] Test: verifying incorrect OTP returns 401
- [ ] Email auth also enabled (for admin portal users — carrier admins, brokers)

---

### RS-009: Configure Supabase Storage buckets
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `supabase`, `P1` |
| **Points** | 2 |
| **Assignee** | — |
| **Dependencies** | RS-006 |

**Description**
Create the Storage buckets needed for document uploads, policy PDFs, payment receipts, and public assets.

**Acceptance Criteria**
- [ ] Bucket `documents` created — **private** (requires auth for access)
  - Purpose: scanned cédulas, carnets de circulación, vehicle rear photos, facturas (future), claim photos
  - Max file size: 10MB
  - Allowed MIME types: `image/jpeg`, `image/png`, `image/webp`, `application/pdf`
- [ ] Bucket `policies` created — **private** (requires auth for access)
  - Purpose: generated policy PDFs and RCV certificates
  - Max file size: 5MB
  - Allowed MIME types: `application/pdf`
- [ ] Bucket `receipts` created — **private** (requires auth for access)
  - Purpose: bank transfer payment receipts
  - Max file size: 10MB
  - Allowed MIME types: `image/jpeg`, `image/png`, `application/pdf`
- [ ] Bucket `public` created — **public** (no auth needed)
  - Purpose: carrier logos, app assets
  - Max file size: 2MB
  - Allowed MIME types: `image/jpeg`, `image/png`, `image/svg+xml`, `image/webp`
- [ ] Storage RLS policies:
  - `documents` bucket: users can upload to their own folder (`{user_id}/`), users can read their own files
  - `policies` bucket: users can read their own folder (`{user_id}/`)
  - `receipts` bucket: users can upload to their own folder (`{user_id}/`), users can read their own files
  - `public` bucket: anyone can read, only service role can write
- [ ] Test: authenticated upload and retrieval of a test image to `documents` bucket

---

### RS-010: Create seed data for development and demos
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `supabase`, `b2b2c`, `P1` |
| **Points** | 3 |
| **Assignee** | — |
| **Dependencies** | RS-007 |

**Description**
Create a SQL seed file with realistic test data including the full B2B2C hierarchy — carriers, brokers, promoters, points of sale, and policy types matching the multi-tier product structure.

**Acceptance Criteria**
- [ ] `supabase/seed.sql` file created with:
  - 1 primary test carrier:
    - "Seguros Pirámide" (RIF: J-00312345-6) — primary strategic partner
  - 1 secondary test carrier:
    - "Seguros Caracas" (RIF: J-00012345-6) — for multi-carrier testing
  - Policy types per carrier (matching v2.0 configurable tiers):
    - "Solo RCV" (code: `RCV_BASICA`, tier: `basica`, $17 USD, coverage $50,000, 365 days)
    - "RCV + Grúa" (code: `RCV_GRUA`, tier: `basica`, $22 USD, coverage $50,000, 365 days, upsell: grúa included)
    - "RCV Plus" (code: `RCV_PLUS`, tier: `plus`, $31 USD, coverage $75,000, 365 days, includes medical)
    - "RCV Ampliada" (code: `RCV_AMPLIADA`, tier: `ampliada`, $110 USD, coverage $150,000, 365 days)
  - 2 test brokers:
    - "María González" (broker, quota: 800, commission: 0.25)
    - "Carlos Rodríguez" (broker, quota: 800, commission: 0.25)
  - 3 test promoters (linked to brokers):
    - "Luis Martínez" (promoter, referral code: RS-LUIS-0001, linked to broker María)
    - "Ana Pérez" (promoter, referral code: RS-ANAP-0002, linked to broker María)
    - "Jorge Ramírez" (promoter, referral code: RS-JORG-0003, linked to broker Carlos)
  - 2 test points of sale:
    - "Estación Caracas Centro" (type: gas_station, linked to broker María)
    - "Repuestos Express Altamira" (type: parts_shop, linked to broker Carlos)
  - 1 test exchange rate (current approximate BCV rate)
  - 2 carrier admin users (linked to email auth accounts):
    - `admin@segurospir.test` (role: admin, carrier: Seguros Pirámide)
    - `admin@seguroscar.test` (role: admin, carrier: Seguros Caracas)
- [ ] Seed data references realistic Venezuelan insurance products and pricing
- [ ] `supabase/seed.sql` is idempotent (uses `ON CONFLICT DO NOTHING` or checks)
- [ ] Documented: how to apply seed data (`supabase db reset` applies migrations + seed)

---

## Epic: E0.3 — Flutter App Foundation

### RS-011: Implement Flutter folder structure and core architecture
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `flutter`, `P0` |
| **Points** | 3 |
| **Assignee** | — |
| **Dependencies** | RS-002 |

**Description**
Create the full folder structure from `MVP_ARCHITECTURE.md` Section 7.1. Set up the architectural foundation: Riverpod providers, GoRouter, and the feature directory convention. Routes reflect the 8-step onboarding flow.

**Acceptance Criteria**
- [ ] Complete folder structure from Section 7.1 created (all directories, placeholder files where needed)
- [ ] `main.dart`:
  - Initializes `WidgetsFlutterBinding`
  - Initializes Supabase client (`Supabase.initialize(url:, anonKey:)`)
  - Wraps app in `ProviderScope` (Riverpod)
  - Runs `App()` widget
- [ ] `app/app.dart`:
  - `MaterialApp.router` with GoRouter
  - Theme applied globally
  - Locale set to Spanish (`es`)
- [ ] `app/router.dart`:
  - GoRouter configured with routes matching the 8-step flow:
    - `/` → Splash/loading
    - `/welcome` → Welcome screen (Step 1)
    - `/login` → Phone input
    - `/otp` → OTP verification (Step 3)
    - `/home` → Home dashboard (Step 4)
    - `/onboarding/cedula` → Cédula scan (Step 6a)
    - `/onboarding/cedula/confirm` → Identity confirmation
    - `/onboarding/carnet` → Carnet scan (Step 6b)
    - `/onboarding/vehicle-photo` → Vehicle rear photo (Step 6c)
    - `/onboarding/vehicle/confirm` → Vehicle confirmation
    - `/onboarding/address` → Address form (Step 7 partial)
    - `/onboarding/consent` → Legal consent (Step 7 partial)
    - `/policy/select` → Product selection (Step 5)
    - `/policy/quote` → Quote summary (Step 7.5)
    - `/policy/:id` → Policy detail
    - `/payment/method` → Payment method selection (Step 8b)
    - `/claims/new` → New claim
    - `/profile` → Profile
  - Auth redirect: unauthenticated users go to `/welcome`
  - Placeholder screens for each route
- [ ] Riverpod `ProviderScope` wrapping the app
- [ ] App compiles and runs with placeholder navigation between all screens

---

### RS-012: Implement design system — theme, colors, typography
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `flutter`, `design`, `P1` |
| **Points** | 3 |
| **Assignee** | — |
| **Dependencies** | RS-011 |

**Description**
Implement the RuedaSeguro design system as defined in `MVP_ARCHITECTURE.md` Section 7.3, updated with v2.0 branding (Navy Blue + Orange, Montserrat + Lato).

**Acceptance Criteria**
- [ ] `core/theme/colors.dart`:
  - `RSColors` class with all color constants:
    - `primary` = Navy Blue (#1A237E) — trust, protection
    - `primaryLight` = Lighter blue for hover/focus states
    - `accent` = Orange (#FF6D00) — alert, urgency, action
    - `success` = Green (#2E7D32)
    - `error` = Red (#C62828)
    - `warning` = Amber (#FFB300) — for "Observada" status, low-confidence fields
    - `background` = Off-white (#FAFAFA) — avoids glare under sunlight
    - `surface` = White (#FFFFFF)
    - `textPrimary` = Off-black (#212121) — high contrast for outdoor readability
    - `textSecondary` = Gray (#757575)
    - `border` = Light gray (#E0E0E0)
- [ ] `core/theme/typography.dart`:
  - `RSTypography` class with `TextStyle` definitions using **Montserrat** (headings) and **Lato** (body):
    - `displayLarge` — Screen titles (Montserrat Bold, 28sp)
    - `displayMedium` — Section headers (Montserrat Bold, 22sp)
    - `titleLarge` — Card titles (Montserrat SemiBold, 18sp)
    - `titleMedium` — Subtitles (Lato Medium, 16sp)
    - `bodyLarge` — Primary text (Lato Regular, 16sp)
    - `bodyMedium` — Secondary text (Lato Regular, 14sp)
    - `labelLarge` — Button text (Montserrat SemiBold, 16sp)
    - `caption` — Small labels (Lato Regular, 12sp)
    - `mono` — Reference numbers, amounts (monospace, 16sp)
  - Minimum text size: 14sp for body text (accessibility)
  - Fonts added to `pubspec.yaml` assets or use Google Fonts package
- [ ] `core/theme/spacing.dart`:
  - `RSSpacing` class with spacing constants on a 4px grid:
    - `xs` = 4, `sm` = 8, `md` = 16, `lg` = 24, `xl` = 32, `xxl` = 48
  - `RSRadius` class: `sm` = 8, `md` = 12, `lg` = 16, `xl` = 24
- [ ] `app/theme.dart`:
  - `ThemeData` composing all of the above into a complete Flutter theme
  - Applied to `MaterialApp.router` in `app.dart`
  - Light theme only for MVP (dark theme deferred)
- [ ] Visual verification: placeholder screens render with correct colors, typography, and spacing

---

### RS-013: Build shared widget library — base components
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `flutter`, `design`, `P1` |
| **Points** | 5 |
| **Assignee** | — |
| **Dependencies** | RS-012 |

**Description**
Build the reusable widget library defined in `MVP_ARCHITECTURE.md` Section 7.1 (`shared/widgets/`). These are the building blocks for all feature screens.

**Acceptance Criteria**
- [ ] `rs_button.dart`:
  - Primary button (filled, accent orange, rounded corners)
  - Secondary button (outlined)
  - Danger button (red, for destructive actions)
  - Loading state (circular progress indicator replacing text)
  - Disabled state (grayed out, non-interactive)
  - Full-width option
  - Minimum tap target: 48x48dp
- [ ] `rs_text_field.dart`:
  - Standard text input with label, hint, and error message
  - Support for `obscureText` (passwords)
  - Support for `prefixIcon` and `suffixIcon`
  - Phone number variant with `+58` prefix
  - Cédula variant with `V-` / `E-` prefix selector
  - Read-only variant (for confirmed OCR data display)
  - Amber highlight variant (for low-confidence OCR fields)
  - Validation support via `validator` callback
- [ ] `rs_card.dart`:
  - Elevated card with consistent padding, border radius, and shadow
  - Tap callback support
  - Supports header/body/footer layout
- [ ] `rs_loading.dart`:
  - Full-screen loading overlay with RuedaSeguro branding
  - Inline shimmer/skeleton loading (for lists and cards)
- [ ] `rs_error.dart`:
  - Error state widget with icon, title, message, and "Reintentar" button
  - Network error variant with offline icon
- [ ] `rs_empty.dart`:
  - Empty state widget with illustration placeholder, title, and subtitle
- [ ] `offline_banner.dart`:
  - Persistent banner shown at top when device is offline
  - Text: "Sin conexión a internet"
  - Animated appearance/disappearance on connectivity change
- [ ] `amount_display.dart`:
  - Dual-currency display: USD amount (large, primary) + VES equivalent (smaller, secondary)
  - Includes exchange rate source and freshness indicator
- [ ] `rs_consent_checkbox.dart`:
  - Checkbox with rich-text label (supports inline links for terms PDFs)
  - Required indicator
  - Error state if unchecked on submit
- [ ] All widgets documented with doc comments
- [ ] All widgets support `Key` parameter for testing

---

### RS-014: Implement core services — Supabase, connectivity, local storage
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `flutter`, `P0` |
| **Points** | 5 |
| **Assignee** | — |
| **Dependencies** | RS-006, RS-011 |

**Description**
Implement the core service layer that all features depend on: Supabase client wrapper, connectivity monitoring, and local storage (SQLite + Hive).

**Acceptance Criteria**
- [ ] `core/services/supabase_service.dart`:
  - Singleton access to Supabase client
  - Helper getters for `.auth`, `.from()`, `.storage`, `.functions`
  - Reads credentials from environment (not hardcoded)
- [ ] `core/network/connectivity_service.dart`:
  - Wraps `connectivity_plus` package
  - Exposes `Stream<bool>` for real-time connectivity status
  - Exposes `Future<bool> isConnected` for synchronous checks
  - Performs actual HTTP ping to confirm real internet access
  - Debounces rapid connectivity changes (500ms)
- [ ] `core/services/local_storage_service.dart`:
  - Initializes SQLite database (via `sqflite`) with schema for offline cache:
    - `cached_profiles` table
    - `cached_vehicles` table
    - `cached_policies` table
    - `cached_exchange_rates` table
    - `pending_sync_queue` table (for Store & Forward pattern)
  - Initializes Hive for simple key-value storage (user preferences, last known rate)
  - `save()`, `get()`, `delete()`, `clearAll()` methods
- [ ] `shared/providers/connectivity_provider.dart`:
  - Riverpod `StreamProvider<bool>` exposing connectivity status
- [ ] `shared/providers/auth_provider.dart`:
  - Riverpod `StateNotifierProvider` wrapping Supabase auth state
  - Exposes: `isAuthenticated`, `currentUser`, `session`
  - Listens to `supabase.auth.onAuthStateChange`
  - Handles token refresh automatically
- [ ] Unit tests:
  - Connectivity service correctly reports connected/disconnected
  - Local storage service CRUD operations work correctly

---

### RS-015: Implement core utilities — validators, formatters, hash helpers, image quality
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `flutter`, `security`, `P1` |
| **Points** | 5 |
| **Assignee** | — |
| **Dependencies** | RS-011 |

**Description**
Implement the utility classes from `MVP_ARCHITECTURE.md` Section 7.1 (`core/utils/`). Includes image quality validation for anti-fraud per v2.0 requirements.

**Acceptance Criteria**
- [ ] `validators.dart`:
  - `isValidCedula(String)` — validates V/E/J/P prefix + 6-9 digits
  - `isValidPhone(String)` — validates Venezuelan phone format (04XX-XXXXXXX or +58 4XX XXXXXXX)
  - `isValidPlate(String)` — validates Venezuelan plate format
  - `isValidReference(String)` — validates Pago Móvil reference (numeric, 8-20 digits)
  - `isValidBankCode(String)` — validates 4-digit bank code
  - `isValidPassword(String)` — min 8 chars, at least 1 number (per Flujo doc)
  - `isValidEmail(String)` — standard email validation
  - `isAdult(DateTime dob)` — verifies age ≥ 18
  - `isNotEmpty(String)` — non-null, non-blank
- [ ] `currency_utils.dart`:
  - `formatUSD(double)` → `"$17.70"`
  - `formatVES(double)` → `"Bs. 658.45"`
  - `convertUsdToVes(double usd, double rate)` → VES amount
  - `formatExchangeRate(double rate)` → `"1 USD = 37.20 Bs."`
- [ ] `hash_utils.dart`:
  - `sha256Hash(Uint8List bytes)` → hex string SHA-256 hash
  - `sha256HashFile(File file)` → hex string SHA-256 hash of file contents
  - `sha256HashString(String input)` → hex string SHA-256 hash of string
- [ ] `date_utils.dart`:
  - `toIso8601(DateTime)` → ISO 8601 string in UTC
  - `fromIso8601(String)` → DateTime
  - `formatDisplayDate(DateTime)` → `"15 Mar 2026"` (Spanish locale)
  - `formatDisplayDateTime(DateTime)` → `"15 Mar 2026, 14:30"`
  - `isExpired(DateTime)` → `bool`
  - `daysUntilExpiry(DateTime)` → `int`
- [ ] `image_quality_utils.dart` — **NEW (v2.0 anti-fraud)**:
  - `double calculateSharpness(File image)` → Laplacian variance score (higher = sharper)
  - `bool isScreenPhoto(File image)` → Detects moiré patterns / pixel grid indicative of photo-of-screen
  - `ImageQualityResult validateImage(File image)` → Returns composite result with sharpness score, isScreenPhoto flag, brightness check, and overall pass/fail
  - Thresholds: sharpness ≥ 100 (Laplacian variance), brightness 40-250 (not too dark/bright)
- [ ] `core/errors/failures.dart`:
  - `Failure` abstract class with `message` property
  - `ServerFailure`, `NetworkFailure`, `CacheFailure`, `AuthFailure`, `ValidationFailure`, `ImageQualityFailure`
- [ ] `core/errors/exceptions.dart`:
  - `ServerException`, `NetworkException`, `CacheException`
- [ ] `core/constants/app_constants.dart`:
  - `impactThreshold = 9.0` (G-force — Phase 1.5 reference)
  - `ocrConfidenceThreshold = 0.9` (updated per Flujo doc)
  - `ocrConfidenceAmber = 0.5` (below this = manual entry)
  - `maxFileSize = 10 * 1024 * 1024` (10MB)
  - `otpLength = 6`
  - `otpExpirySeconds = 300`
  - `otpResendSeconds = 60`
  - `bcvRefreshIntervalMinutes = 30`
  - `venezuelaCountryCode = '+58'`
  - `sharpnessThreshold = 100.0`
- [ ] `core/constants/supabase_constants.dart`:
  - Table names as constants (avoid magic strings)
  - Bucket names as constants (including `receipts`)
  - Edge function names as constants
- [ ] Unit tests for all validators (valid and invalid inputs)
- [ ] Unit tests for all currency formatting functions
- [ ] Unit tests for all hash utilities
- [ ] Unit tests for all date utilities

---

## Epic: E0.4 — Admin Portal Foundation

### RS-016: Build admin portal layout shell and auth gate
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `admin`, `b2b2c`, `P1` |
| **Points** | 5 |
| **Assignee** | — |
| **Dependencies** | RS-003, RS-008 |

**Description**
Build the admin portal's layout structure and authentication gate. Supports two roles from Day 1: carrier admin and broker. Role determines which navigation links and dashboards are shown.

**Acceptance Criteria**
- [ ] `/login` page:
  - Email + password form
  - Supabase Auth sign-in
  - Error handling (invalid credentials, network errors)
  - Redirect to appropriate dashboard based on role
- [ ] Layout component (`DashboardLayout`):
  - Left sidebar with navigation links — **carrier admin view**:
    - Dashboard (icon: LayoutDashboard)
    - Pólizas (icon: FileText)
    - Pagos (icon: CreditCard)
    - Reclamos (icon: AlertTriangle)
    - Corredores (icon: Briefcase) — **NEW**
    - Promotores (icon: Users) — **NEW**
    - Puntos de Venta (icon: MapPin) — **NEW**
    - Configuración (icon: Settings)
  - Left sidebar — **broker view** (subset):
    - Mi Panel (icon: LayoutDashboard)
    - Mis Pólizas (icon: FileText)
    - Mis Promotores (icon: Users)
  - Top header with:
    - Organization name (carrier or broker name)
    - User name + role badge
    - Logout button
  - Mobile-responsive: sidebar collapses to hamburger menu
- [ ] Auth middleware:
  - Unauthenticated users redirected to `/login`
  - Auth state persisted via Supabase SSR cookies
  - Role resolution: check `carrier_users` table first (carrier admin), then `brokers` table (broker). Store role in context.
  - Carrier ID resolved and stored in context
- [ ] `/dashboard` page (carrier admin):
  - Placeholder content: "Bienvenido a RuedaSeguro Admin"
  - Shows carrier name dynamically
- [ ] `/broker/dashboard` page:
  - Placeholder content: "Panel del Corredor"
  - Shows broker name dynamically
- [ ] All navigation links render placeholder pages
- [ ] Deployed to Vercel and accessible via URL

---

### RS-017: Deploy admin portal to Vercel
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `admin`, `devops`, `P2` |
| **Points** | 1 |
| **Assignee** | — |
| **Dependencies** | RS-003 |

**Description**
Connect the admin portal to Vercel for automatic deployments from the `main` branch.

**Acceptance Criteria**
- [ ] Vercel project created and linked to GitHub repository
- [ ] Root directory set to `admin-portal/`
- [ ] Environment variables configured on Vercel (Supabase URL, keys)
- [ ] Automatic deploys on push to `main`
- [ ] Preview deploys on PRs
- [ ] Custom domain planned (e.g., `admin.ruedaseguro.com`) — can configure later
- [ ] Build succeeds and site is accessible via Vercel URL

---

## Epic: E0.5 — BCV Exchange Rate Service

### RS-018: Implement BCV exchange rate Edge Function
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `supabase`, `P1` |
| **Points** | 3 |
| **Assignee** | — |
| **Dependencies** | RS-007, RS-006 |

**Description**
Create the Supabase Edge Function that fetches the official BCV USD/VES exchange rate and caches it in the `exchange_rates` table. This is critical — every payment amount depends on this rate.

**Acceptance Criteria**
- [ ] Edge Function `supabase/functions/bcv-rate/index.ts` created
- [ ] Fetches rate from a reliable source (try in order of reliability):
  1. `https://pydolarve.org/api/v2/dollar?monitor=bcv` (community API)
  2. Direct BCV website scraping as fallback
- [ ] Parses the USD/VES rate from response
- [ ] Inserts a new row into `exchange_rates` table with: `rate`, `currency_pair`, `source`, `fetched_at`, `is_official`, `raw_response`
- [ ] Returns the rate in the response body as JSON: `{ "rate": 37.20, "fetched_at": "2026-03-21T..." }`
- [ ] Error handling:
  - If primary source fails, tries fallback
  - If all sources fail, returns 503 with error message
  - Never inserts a rate of 0 or null
- [ ] Rate freshness validation: if the fetched rate differs by >20% from the last stored rate, flag as suspicious but still insert
- [ ] Deployable via `supabase functions deploy bcv-rate`
- [ ] Can be invoked manually: `supabase functions invoke bcv-rate`
- [ ] Scheduled invocation documented (Supabase pg_cron or external cron)
- [ ] Test: function returns a valid rate when invoked

---

## Sprint 0 Summary

| Issue | Title | Points | Priority | Dependencies |
|---|---|---|---|---|
| RS-001 | Initialize monorepo and Git configuration | 2 | P0 | — |
| RS-002 | Configure Flutter project with dependencies | 3 | P0 | RS-001 |
| RS-003 | Configure Next.js admin portal project | 3 | P0 | RS-001 |
| RS-004 | Set up GitHub Actions CI pipeline | 3 | P1 | RS-002, RS-003 |
| RS-005 | Configure Android release signing | 2 | P2 | RS-002 |
| RS-006 | Create Supabase project and configure environment | 2 | P0 | RS-001 |
| RS-007 | Apply initial database schema migration | 8 | P0 | RS-006 |
| RS-008 | Configure Supabase Auth for phone OTP | 2 | P0 | RS-006 |
| RS-009 | Configure Supabase Storage buckets | 2 | P1 | RS-006 |
| RS-010 | Create seed data for development and demos | 3 | P1 | RS-007 |
| RS-011 | Implement Flutter folder structure and core architecture | 3 | P0 | RS-002 |
| RS-012 | Implement design system — theme, colors, typography | 3 | P1 | RS-011 |
| RS-013 | Build shared widget library — base components | 5 | P1 | RS-012 |
| RS-014 | Implement core services — Supabase, connectivity, local storage | 5 | P0 | RS-006, RS-011 |
| RS-015 | Implement core utilities — validators, formatters, hash, image quality | 5 | P1 | RS-011 |
| RS-016 | Build admin portal layout shell with B2B2C auth gate | 5 | P1 | RS-003, RS-008 |
| RS-017 | Deploy admin portal to Vercel | 1 | P2 | RS-003 |
| RS-018 | Implement BCV exchange rate Edge Function | 3 | P1 | RS-007, RS-006 |
| | **Sprint 0 Total** | **58** | | |

**Critical Path:** RS-001 → RS-006 → RS-007 → RS-010 (backend ready)
**Parallel Path A:** RS-001 → RS-002 → RS-011 → RS-014 (Flutter foundation)
**Parallel Path B:** RS-001 → RS-003 → RS-016 → RS-017 (admin portal)

---

---

# SPRINT 1 — Authentication & Onboarding

> **Goal:** A rider can download the app, register with their phone number, scan their Cédula and Carnet de Circulación via OCR, capture a rear photo of their vehicle, review and confirm data with cross-validation, complete address entry, accept legal terms, and have a complete profile + vehicle + documents saved in Supabase. Anti-fraud image quality checks are active. This is the full onboarding nucleus (Steps 1-7 of the 8-step flow).
>
> **Duration:** Days 4–10
> **Total Story Points:** 86
> **Sprint 0 Blockers:** RS-007, RS-008, RS-011, RS-012, RS-013, RS-014, RS-015 must be complete

---

## Epic: E1.1 — Authentication System

### RS-019: Implement welcome screen
| Field | Value |
|---|---|
| **Type** | `story` |
| **Labels** | `flutter`, `design`, `P0` |
| **Points** | 2 |
| **Assignee** | — |
| **Dependencies** | RS-011, RS-012, RS-013 |

**Description**
**As a** new rider opening the app for the first time,
**I want** to see a clear value proposition and easy entry points,
**so that** I understand what RuedaSeguro does and can start the registration process.

**Acceptance Criteria**
- [ ] Screen displays:
  - RuedaSeguro logo/branding at top (Navy Blue + Orange)
  - Value proposition headline: "Asegura tu vehículo en minutos"
  - Brief subtitle: "Si te caes, no estás solo"
  - Illustration or graphic representing protection/insurance (placeholder acceptable)
  - Primary CTA button: "Crear cuenta" → navigates to phone login
  - Secondary link: "Ingresar" → navigates to phone login (returning users)
- [ ] No authentication required to view this screen
- [ ] If user is already authenticated (has valid session), auto-redirect to `/home`
- [ ] Screen uses design system components (`RSButton`, `RSTypography`)
- [ ] Responsive layout: works on phones from 320dp to 428dp width
- [ ] Accessibility: minimum contrast ratio 4.5:1, screen reader labels on all interactive elements

---

### RS-020: Implement phone number input screen
| Field | Value |
|---|---|
| **Type** | `story` |
| **Labels** | `flutter`, `P0` |
| **Points** | 3 |
| **Assignee** | — |
| **Dependencies** | RS-013, RS-014, RS-015 |

**Description**
**As a** rider,
**I want** to enter my Venezuelan phone number to start registration,
**so that** I receive an OTP code to verify my identity.

**Acceptance Criteria**
- [ ] Screen displays:
  - Header: "Ingresa tu número de teléfono"
  - Subtitle: "Te enviaremos un código de verificación por SMS"
  - Phone input field with:
    - Fixed `+58` country code prefix (non-editable, visually attached)
    - Placeholder: `412 1234567`
    - Numeric keyboard automatically opens
    - Input mask: auto-formats as `XXX XXXXXXX`
  - "Continuar" button (disabled until valid phone entered)
- [ ] Validation:
  - Phone number must be 10 digits after country code
  - Must start with `4` (Venezuelan mobile prefixes: 412, 414, 416, 424, 426)
  - Real-time validation feedback (border turns red if invalid)
  - Error message: "Número de teléfono inválido" if format is wrong
- [ ] On tap "Continuar":
  - Show loading state on button
  - Call `supabase.auth.signInWithOtp(phone: '+58$number')`
  - On success: navigate to OTP screen, pass phone number as parameter
  - On failure: show error message via snackbar/toast
    - Rate limit hit: "Has excedido el límite de intentos. Intenta en unos minutos."
    - Network error: "Sin conexión a internet. Verifica tu conexión."
    - Generic error: "Error al enviar el código. Intenta de nuevo."
- [ ] Back button returns to welcome screen

---

### RS-021: Implement OTP verification screen
| Field | Value |
|---|---|
| **Type** | `story` |
| **Labels** | `flutter`, `P0` |
| **Points** | 5 |
| **Assignee** | — |
| **Dependencies** | RS-020, RS-008 |

**Description**
**As a** rider who entered their phone number,
**I want** to enter the 6-digit OTP I received via SMS,
**so that** my identity is verified and I can access the app.

**Acceptance Criteria**
- [ ] Screen displays:
  - Header: "Ingresa el código"
  - Subtitle: "Enviamos un código de 6 dígitos a +58 XXX XXXXXXX" (masked, show last 4 digits)
  - 6 individual digit input boxes with:
    - Auto-focus on first box
    - Auto-advance to next box on digit entry
    - Numeric keyboard
    - Auto-submit when all 6 digits are entered
    - Paste support (SMS auto-fill)
  - Countdown timer: "Reenviar código en XX segundos" (starts at 60s)
  - After countdown: "Reenviar código" link (tappable)
  - "Cambiar número" link → returns to phone input screen
- [ ] OTP verification:
  - Call `supabase.auth.verifyOTP(phone:, token:, type: OtpType.sms)`
  - On success:
    - Session stored securely (`flutter_secure_storage`)
    - Check if profile exists in `profiles` table
    - If profile exists → navigate to `/home` (returning user)
    - If no profile → navigate to `/onboarding/cedula` (new user)
  - On failure:
    - Invalid OTP: clear all boxes, "Código incorrecto. Intenta de nuevo."
    - Expired OTP: "Código expirado. Solicita uno nuevo."
    - Max attempts exceeded: "Demasiados intentos. Espera 10 minutos."
- [ ] Resend OTP:
  - Call `supabase.auth.signInWithOtp(phone:)` again
  - Show toast: "Código reenviado"
  - Reset countdown timer
  - Max 3 resends (then: "Contacta soporte")
- [ ] Haptic feedback on successful verification
- [ ] Loading overlay during verification API call

---

### RS-022: Implement auth state management and session persistence
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `flutter`, `P0` |
| **Points** | 3 |
| **Assignee** | — |
| **Dependencies** | RS-014 |

**Description**
Implement robust auth state management using Riverpod. The app must automatically detect and handle session state across app restarts, token expiry, and logout.

**Acceptance Criteria**
- [ ] `features/auth/data/auth_repository.dart`:
  - `signInWithOtp(phone)` — sends OTP
  - `verifyOtp(phone, token)` — verifies OTP and returns session
  - `signOut()` — clears session, clears local cache
  - `getCurrentSession()` — returns active session or null
  - `onAuthStateChange()` — returns stream of auth events
- [ ] `features/auth/domain/auth_state.dart`:
  - Enum: `AuthStatus { initial, authenticated, unauthenticated, loading }`
  - `AuthState` class with `status`, `user`, `session`, `errorMessage`
- [ ] `shared/providers/auth_provider.dart`:
  - `StateNotifierProvider<AuthNotifier, AuthState>`
  - Listens to `onAuthStateChange` stream
  - Updates state on: `signedIn`, `signedOut`, `tokenRefreshed`, `userUpdated`
  - On `signedOut` or refresh failure: navigate to `/welcome`
- [ ] GoRouter integration:
  - `redirect` function checks auth state
  - Unauthenticated → `/welcome`
  - Authenticated without profile → `/onboarding/cedula`
  - Authenticated with profile → `/home`
- [ ] Session persistence across app restarts
- [ ] Logout clears: Supabase session, SQLite cache, Hive storage

---

### RS-023: Implement splash screen with session check
| Field | Value |
|---|---|
| **Type** | `story` |
| **Labels** | `flutter`, `P1` |
| **Points** | 2 |
| **Assignee** | — |
| **Dependencies** | RS-022, RS-011 |

**Description**
**As a** returning rider opening the app,
**I want** the app to check my session automatically,
**so that** I go directly to the home screen without logging in again.

**Acceptance Criteria**
- [ ] Splash screen shows:
  - RuedaSeguro logo centered
  - Subtle loading animation (fade or pulse)
  - Background color: primary Navy Blue
- [ ] Logic on splash:
  1. Wait for Supabase initialization
  2. Check for existing session
  3. Route based on session and profile existence
  4. Maximum splash duration: 3 seconds (timeout fallback)
- [ ] No flickering between splash and destination screen
- [ ] Works offline: tries cached session

---

## Epic: E1.2 — Document Capture & OCR

### RS-024: Implement camera service with document scanning overlay
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `flutter`, `P0` |
| **Points** | 5 |
| **Assignee** | — |
| **Dependencies** | RS-002 |

**Description**
Build a reusable camera component with a document-alignment overlay that guides the user to position their document within the frame. Used for Cédula, Carnet, and vehicle photo.

**Acceptance Criteria**
- [ ] `shared/widgets/document_scanner.dart` — reusable widget:
  - Opens rear camera at maximum resolution
  - Displays semi-transparent overlay with clear rectangle "window"
  - Corner brackets to guide alignment
  - Customizable instruction text
  - Flashlight toggle button
  - Capture button (large, centered at bottom, "Easy Zone")
  - Gallery pick button (for selecting existing photo)
  - Preview: after capture, show captured image with "Usar foto" / "Reintentar"
- [ ] Camera permissions:
  - Runtime permission request (`permission_handler`)
  - If denied: explanation dialog + link to app settings
  - If permanently denied: "Abrir Configuración" button
- [ ] Image output:
  - Returns `File` object
  - Compressed to max 1920px on longest side
  - EXIF rotation corrected
- [ ] Performance:
  - Camera preview at 30fps minimum
  - Capture-to-preview under 500ms
- [ ] Variant: `vehicle_photo` mode with wider frame and instruction "Toma una foto de la parte trasera de tu moto con la placa visible"

---

### RS-025: Implement Google ML Kit OCR integration
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `flutter`, `P0` |
| **Points** | 3 |
| **Assignee** | — |
| **Dependencies** | RS-002 |

**Description**
Integrate Google ML Kit Text Recognition to extract raw text from document images entirely on-device (no API calls, no cost).

**Acceptance Criteria**
- [ ] `features/onboarding/data/ocr_repository.dart`:
  - `Future<OcrResult> extractText(File imageFile)` method
  - Uses `google_mlkit_text_recognition` package
  - Returns `OcrResult` containing:
    - `rawText` — full extracted text
    - `textBlocks` — list of recognized text blocks with bounding boxes
    - `confidence` — overall confidence score (0.0 to 1.0)
    - `processingTimeMs` — how long OCR took
  - Supports Latin script (Spanish characters: á, é, í, ó, ú, ñ, ü)
  - Handles both landscape and portrait orientations
- [ ] `features/onboarding/domain/ocr_result.dart`:
  - Data class with all fields above
  - `isEmpty` getter
- [ ] Error handling:
  - If ML Kit fails: return `OcrResult.empty()` (triggers manual entry)
- [ ] Performance:
  - OCR under 2 seconds on mid-range Android
  - Runs on background isolate
- [ ] Test: pass test image and verify text extracted

---

### RS-026: Implement Cédula field extraction parser
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `flutter`, `P1` |
| **Points** | 5 |
| **Assignee** | — |
| **Dependencies** | RS-025, RS-015 |

**Description**
Build the regex-based parser that extracts structured fields from raw OCR text of a Venezuelan Cédula de Identidad. Updated for v2.0 to also extract nationality and sex.

**Acceptance Criteria**
- [ ] `features/onboarding/domain/cedula_parser.dart`:
  - `CedulaParseResult parse(String rawText, List<TextBlock> blocks)` method
  - Returns `CedulaParseResult` with:
    - `idType` (V, E)
    - `idNumber` (digits only)
    - `firstName`
    - `lastName`
    - `dateOfBirth` (DateTime, nullable)
    - `nationality` (nullable) — **NEW v2.0**
    - `sex` (M/F, nullable) — **NEW v2.0**
    - `confidence` (0.0-1.0)
    - `fieldConfidences` (map)
- [ ] Extraction rules:
  - **ID Number**: `r'[VvEe][-.\s]?\s*(\d{1,3}[.]?\d{3}[.]?\d{3})'`
  - **ID Type**: First letter before number (V or E, default V)
  - **Names**: Heuristic — UPPERCASE blocks excluding keywords
  - **Date of Birth**: dd/MM/yyyy or dd-MM-yyyy, age 16-100
  - **Nationality**: Keywords "VENEZOLANO/A" or "EXTRANJERO/A"
  - **Sex**: Keywords "M", "F", "MASCULINO", "FEMENINO"
- [ ] Confidence scoring per field
- [ ] Edge cases: dots in number, spaces, old vs new format, faded text
- [ ] Unit tests with at least 5 varied samples

---

### RS-027: Implement Cédula scan screen
| Field | Value |
|---|---|
| **Type** | `story` |
| **Labels** | `flutter`, `P0` |
| **Points** | 3 |
| **Assignee** | — |
| **Dependencies** | RS-024, RS-025, RS-026, RS-038 |

**Description**
**As a** new rider during onboarding,
**I want** to scan my Cédula de Identidad with my phone camera,
**so that** my personal data is automatically extracted.

**Acceptance Criteria**
- [ ] Screen uses `DocumentScanner` with instruction: "Coloca el frente de tu cédula dentro del recuadro"
- [ ] After capture:
  1. Run image quality validation (RS-038) — reject if blurry or photo-of-screen
  2. Show "Leyendo documento..." with shimmer animation
  3. Run ML Kit OCR → CedulaParser
  4. Navigate to confirm screen with extracted data
- [ ] Quality failure: "La foto no es legible. Asegúrate de buena iluminación y sin reflejos." + "Reintentar"
- [ ] OCR failure (empty/confidence < 0.3): "No pudimos leer tu cédula." → "Reintentar foto" / "Ingresar manualmente"
- [ ] Scanned image saved locally (temp file for later upload)
- [ ] Progress indicator: Step 1 of 3 documents
- [ ] Photo tips visible: "Buena iluminación, sin reflejos, bordes completos"

---

### RS-028: Implement identity confirmation screen
| Field | Value |
|---|---|
| **Type** | `story` |
| **Labels** | `flutter`, `P0` |
| **Points** | 5 |
| **Assignee** | — |
| **Dependencies** | RS-027, RS-013 |

**Description**
**As a** rider who just scanned their Cédula,
**I want** to review the extracted data and correct any errors,
**so that** my profile information is accurate.

**Acceptance Criteria**
- [ ] Screen displays:
  - Header: "Confirma tus datos"
  - Subtitle: "Verifica que la información sea correcta"
  - Thumbnail of scanned cédula (tappable to view full-size)
  - Editable form fields pre-filled with OCR data:
    - Tipo de documento (dropdown: V / E)
    - Número de cédula (numeric keyboard)
    - Nombre(s)
    - Apellido(s)
    - Fecha de nacimiento (date picker)
    - Nacionalidad (if extracted)
    - Sexo (M/F dropdown, if extracted)
  - Fields with confidence < 0.9: green checkmark
  - Fields with confidence 0.5-0.9: amber border + "Verifica este campo"
  - Fields with confidence < 0.5: red border + manual entry required
- [ ] Emergency contact section (optional, collapsible):
  - Nombre del contacto de emergencia
  - Teléfono del contacto de emergencia
  - Parentesco (dropdown)
- [ ] Validation on "Continuar":
  - Cédula: required, valid format (6-9 digits)
  - First name: required, min 2 characters
  - Last name: required, min 2 characters
  - Date of birth: validated if provided (age ≥ 18)
- [ ] On "Continuar": save data locally, navigate to Carnet scan
- [ ] Back button returns to cédula scan (option to retake)

---

### RS-029: Implement Carnet de Circulación field extraction parser
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `flutter`, `P1` |
| **Points** | 5 |
| **Assignee** | — |
| **Dependencies** | RS-025, RS-015 |

**Description**
Build the parser that extracts vehicle data from raw OCR text of a Venezuelan Carnet de Circulación. Updated for v2.0 to include `vehicle_use` field.

**Acceptance Criteria**
- [ ] `features/onboarding/domain/carnet_parser.dart`:
  - `CarnetParseResult parse(String rawText, List<TextBlock> blocks)` method
  - Returns `CarnetParseResult` with:
    - `plate` (Venezuelan format)
    - `brand` (e.g., Bera, Empire, Honda)
    - `model`
    - `year` (int)
    - `color` (nullable)
    - `serialMotor` (nullable)
    - `serialCarroceria` (nullable)
    - `vehicleUse` ('particular' or 'cargo') — **NEW v2.0**
    - `ownerName` (nullable) — **NEW v2.0** (for cross-validation with Cédula)
    - `ownerCedula` (nullable) — **NEW v2.0** (for cross-validation)
    - `confidence` (0.0-1.0)
    - `fieldConfidences` (map)
- [ ] Extraction rules:
  - **Plate**: `r'([A-Z]{2,3})\s*[-]?\s*(\d{2,3})\s*[-]?\s*([A-Z]{2,3})'`
  - **Brand**: Keyword matching against known motorcycle brands
  - **Year**: `r'(19|20)\d{2}'` filtered to plausible range
  - **Color**: Spanish color keyword matching
  - **Vehicle Use**: Keywords "PARTICULAR", "CARGA"
  - **Owner**: Name/CI extraction (same heuristics as Cédula parser)
  - **Serial Motor / Carrocería**: Long alphanumeric strings (8-20 chars)
- [ ] Unit tests with at least 5 varied samples

---

### RS-030: Implement Carnet de Circulación scan screen
| Field | Value |
|---|---|
| **Type** | `story` |
| **Labels** | `flutter`, `P0` |
| **Points** | 3 |
| **Assignee** | — |
| **Dependencies** | RS-024, RS-025, RS-029, RS-038 |

**Description**
**As a** new rider during onboarding,
**I want** to scan my Carnet de Circulación,
**so that** my motorcycle data is automatically captured.

**Acceptance Criteria**
- [ ] Same capture → quality check → OCR → parse → navigate flow as RS-027
- [ ] Instruction: "Coloca tu carnet de circulación dentro del recuadro"
- [ ] Image quality validation active (RS-038)
- [ ] Progress indicator: Step 2 of 3 documents

---

### RS-031: Implement vehicle confirmation screen with cross-validation
| Field | Value |
|---|---|
| **Type** | `story` |
| **Labels** | `flutter`, `security`, `P0` |
| **Points** | 5 |
| **Assignee** | — |
| **Dependencies** | RS-030, RS-013, RS-039 |

**Description**
**As a** rider who scanned their Carnet de Circulación,
**I want** to review and confirm my motorcycle data,
**so that** my vehicle is correctly registered. The system also cross-validates that the Cédula name matches the Carnet owner.

**Acceptance Criteria**
- [ ] Screen displays:
  - Header: "Confirma los datos de tu moto"
  - Thumbnail of scanned carnet (tappable to view full-size)
  - Editable form fields pre-filled with OCR data:
    - Placa (uppercase auto-format)
    - Marca (text with suggestion dropdown)
    - Modelo
    - Año (number, range 1980-2027)
    - Color (dropdown or text)
    - Uso (dropdown: Particular / Carga) — **NEW v2.0**
    - Serial del motor (optional)
    - Serial de carrocería (optional)
  - Confidence indicators (green/amber/red)
- [ ] **Cross-validation (v2.0 anti-fraud)**:
  - Compare Cédula name/CI with Carnet owner name/CI (from RS-039)
  - If match: green "Datos verificados" banner
  - If mismatch: red banner with message "El nombre del propietario no coincide con la cédula"
    - Options: [Subir nueva cédula] / [Soy representante legal]
    - "Soy representante legal" allows proceeding with a note in metadata
- [ ] "Continuar" button (navigates to vehicle photo capture)
- [ ] Validation: plate, brand, model, year required

---

### RS-032: Implement vehicle rear photo capture screen
| Field | Value |
|---|---|
| **Type** | `story` |
| **Labels** | `flutter`, `P0` |
| **Points** | 3 |
| **Assignee** | — |
| **Dependencies** | RS-024, RS-038 |

**Description**
**As a** rider during onboarding,
**I want** to take a photo of the rear of my motorcycle showing the license plate,
**so that** the insurer can verify my vehicle visually.

**Acceptance Criteria**
- [ ] Uses `DocumentScanner` in `vehicle_photo` mode with wider frame
- [ ] Instruction: "Toma una foto de la parte trasera de tu moto con la placa visible"
- [ ] Image quality check: sharpness validation, screen-photo rejection
- [ ] After capture: preview with "Usar foto" / "Reintentar"
- [ ] Plate text not extracted via OCR (just the photo is stored)
- [ ] Photo saved locally for later upload
- [ ] Progress indicator: Step 3 of 3 documents
- [ ] On "Usar foto": navigate to address form (RS-040)

---

## Epic: E1.3 — Data Review, Address & Consent

### RS-033: Implement address form screen
| Field | Value |
|---|---|
| **Type** | `story` |
| **Labels** | `flutter`, `P1` |
| **Points** | 3 |
| **Assignee** | — |
| **Dependencies** | RS-013 |

**Description**
**As a** rider completing onboarding,
**I want** to enter my address information,
**so that** my profile is complete for policy issuance. These fields are not captured via OCR — they must be entered manually (per Flujo doc specification).

**Acceptance Criteria**
- [ ] Screen displays:
  - Header: "Tu dirección"
  - Subtitle: "Necesitamos tu dirección para emitir la póliza"
  - Form fields:
    - Urbanización / Sector (text field, required)
    - Ciudad (text field, required)
    - Municipio (text field, required)
    - Estado (dropdown with Venezuelan states, required)
    - Código Postal (text field, optional)
  - "Continuar" button
- [ ] Validation: urbanización, ciudad, municipio, estado are required
- [ ] On "Continuar": save address data locally, navigate to consent screen
- [ ] Back button returns to vehicle confirmation

---

### RS-034: Implement legal consent screen (SUDEASEG compliance)
| Field | Value |
|---|---|
| **Type** | `story` |
| **Labels** | `flutter`, `security`, `P0` |
| **Points** | 3 |
| **Assignee** | — |
| **Dependencies** | RS-013 |

**Description**
**As a** rider completing onboarding,
**I want** to review and accept the required legal terms,
**so that** my policy issuance is compliant with SUDEASEG regulations.

**Acceptance Criteria**
- [ ] Screen displays:
  - Header: "Términos y condiciones"
  - Subtitle: "Para emitir tu póliza necesitamos tu consentimiento"
  - 4 mandatory checkboxes using `rs_consent_checkbox`:
    1. ☐ "Acepto las Condiciones Generales del RCV" (link to PDF opens in-app viewer)
    2. ☐ "Declaro la veracidad de los datos suministrados"
    3. ☐ "Autorizo la consulta y verificación antifraude (SAIME/INTT)"
    4. ☐ "Acepto la política de privacidad" (link to privacy policy)
  - "Finalizar registro" primary button (disabled until all 4 checked)
- [ ] Each checkbox records acceptance timestamp
- [ ] On "Finalizar registro":
  - Show full-screen loading: "Creando tu perfil..."
  - Execute complete save sequence (RS-035)
  - On success: navigate to `/home` with success toast "¡Registro completado!"
  - On failure: error with retry
- [ ] All consent data stored in local state for inclusion in profile/policy save

---

## Epic: E1.4 — Profile & Vehicle Persistence

### RS-035: Implement onboarding data save to Supabase
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `flutter`, `supabase`, `P0` |
| **Points** | 5 |
| **Assignee** | — |
| **Dependencies** | RS-007, RS-009, RS-014 |

**Description**
Implement the repository layer that saves all onboarding data (profile, vehicle, 3 documents, consent) to Supabase in a single atomic flow. Runs when user taps "Finalizar registro."

**Acceptance Criteria**
- [ ] `features/onboarding/data/profile_repository.dart`:
  - `Future<Profile> createProfile(ProfileData data)` — inserts into `profiles` table (including address fields, nationality, sex, referral code)
  - `Future<Profile> getProfile()` — fetches current user's profile
  - `Future<Profile> updateProfile(ProfileData data)` — updates current user's profile
  - `Future<bool> profileExists()` — checks if current user has a profile row
- [ ] `features/onboarding/data/vehicle_repository.dart`:
  - `Future<Vehicle> createVehicle(VehicleData data)` — inserts into `vehicles` table (including `vehicle_use`, `rear_photo_url`)
  - `Future<List<Vehicle>> getVehicles()` — fetches current user's vehicles
- [ ] `features/onboarding/data/document_repository.dart`:
  - `Future<Document> uploadDocument(File file, DocumentType type, {UUID? vehicleId})`:
    1. Upload file to Supabase Storage (`documents/{user_id}/{uuid}.jpg`)
    2. Get the signed URL
    3. Calculate SHA-256 hash of file
    4. Insert record into `documents` table with URL, hash, type, OCR data, `sharpness_score`, `is_screen_photo`
    5. Return `Document` model
- [ ] Complete onboarding save sequence:
  1. Upload cédula image → document record
  2. Upload carnet image → document record
  3. Upload vehicle rear photo → document record
  4. Create profile (with OCR data, address, consent timestamps, referral tracking)
  5. Create vehicle (linked to profile, with rear_photo_url)
  6. Link document records to profile and vehicle
- [ ] Error handling:
  - Partial saves handled (don't re-create on retry)
  - Idempotency checks
- [ ] Offline: store in SQLite pending_sync_queue, sync when connectivity restored
- [ ] All operations use authenticated user's JWT (RLS enforced)

---

### RS-036: Implement offline data caching for profile and vehicle
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `flutter`, `P1` |
| **Points** | 3 |
| **Assignee** | — |
| **Dependencies** | RS-014, RS-035 |

**Description**
After onboarding data is saved, cache it locally in SQLite so the app works offline for all read operations.

**Acceptance Criteria**
- [ ] After successful Supabase save:
  - Profile cached in `cached_profiles` SQLite table
  - Vehicle cached in `cached_vehicles` SQLite table
  - Timestamps stored for freshness checking
- [ ] When reading profile/vehicle data:
  - Try Supabase first (if online)
  - On network failure: return cached data with "last updated" timestamp
  - If no cache and offline: show appropriate empty/error state
- [ ] Cache invalidation: on profile update, on logout (clear all)
- [ ] Cache TTL: 24 hours (try refresh on app open)
- [ ] `pending_sync_queue`:
  - Stores operations that failed due to network
  - Background sync on connectivity change
  - Max retry attempts: 5
- [ ] Test: create profile online → go offline → profile viewable
- [ ] Test: create profile offline → data in sync queue → go online → syncs

---

## Epic: E1.5 — Anti-Fraud & Validation Services

### RS-037: Implement image quality validation service
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `flutter`, `security`, `P0` |
| **Points** | 3 |
| **Assignee** | — |
| **Dependencies** | RS-015 |

**Description**
Build the image quality validation service that checks document photos for sharpness and detects photos taken of digital screens (anti-fraud requirement from v2.0 architecture).

**Acceptance Criteria**
- [ ] `features/onboarding/domain/image_validator.dart`:
  - `Future<ImageQualityResult> validate(File image)` method
  - Returns `ImageQualityResult`:
    - `sharpnessScore` (double — Laplacian variance)
    - `isSharp` (bool — above threshold)
    - `isScreenPhoto` (bool — moiré/pixel grid detected)
    - `brightnessOk` (bool — not too dark/bright)
    - `overallPass` (bool — all checks pass)
    - `failureReason` (nullable string — human-readable reason for failure)
  - Failure reasons (in Spanish):
    - "La imagen está borrosa. Intenta con mejor enfoque."
    - "Parece una foto de una pantalla. Usa el documento original."
    - "La imagen está muy oscura. Busca mejor iluminación."
    - "La imagen está sobreexpuesta. Evita la luz directa."
- [ ] Implementation approach:
  - Sharpness: Laplacian variance on grayscale image (can use `image` package for Dart)
  - Screen detection: analyze for regular pixel patterns (moiré) via frequency analysis or gradient patterns
  - Brightness: mean pixel value of grayscale image
- [ ] Thresholds configurable via `app_constants.dart`
- [ ] Runs in under 500ms on mid-range devices
- [ ] Unit test: sharp photo passes
- [ ] Unit test: blurry photo fails
- [ ] Unit test: photo-of-screen detected (if test samples available)

---

### RS-038: Implement cross-validation service (Cédula ↔ Carnet)
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `flutter`, `security`, `P1` |
| **Points** | 2 |
| **Assignee** | — |
| **Dependencies** | RS-026, RS-029 |

**Description**
Build the cross-validation service that compares the name and CI extracted from the Cédula with the owner information from the Carnet de Circulación. Flags mismatches for user resolution.

**Acceptance Criteria**
- [ ] `features/onboarding/domain/cross_validator.dart`:
  - `CrossValidationResult validate(CedulaParseResult cedula, CarnetParseResult carnet)` method
  - Returns `CrossValidationResult`:
    - `nameMatch` (bool — fuzzy match of names)
    - `cedulaMatch` (bool — exact match of CI numbers)
    - `overallMatch` (bool)
    - `mismatchDetails` (nullable string describing the mismatch)
  - Fuzzy name matching: Levenshtein distance ≤ 2, case-insensitive, accent-insensitive
  - CI matching: strip dots, dashes, spaces before comparing
- [ ] If carnet doesn't contain owner name/CI (extraction failed): skip validation, return `overallMatch = true` with a note
- [ ] Unit test: matching names/CI returns true
- [ ] Unit test: different names returns false with details
- [ ] Unit test: fuzzy match (accents, spacing) returns true

---

## Epic: E1.6 — Quality & Testing

### RS-039: Write unit tests for OCR parsers
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `flutter`, `testing`, `P1` |
| **Points** | 3 |
| **Assignee** | — |
| **Dependencies** | RS-026, RS-029 |

**Description**
Comprehensive unit tests for Cédula parser, Carnet parser, and cross-validation.

**Acceptance Criteria**
- [ ] `test/features/onboarding/domain/cedula_parser_test.dart`:
  - At least 10 test cases covering: V/E prefixes, dot/space formats, names, DOB, nationality, sex, garbage text, low confidence, accented chars
- [ ] `test/features/onboarding/domain/carnet_parser_test.dart`:
  - At least 8 test cases covering: plate formats, brands, years, colors, serials, vehicle use, owner extraction, unreadable text
- [ ] `test/features/onboarding/domain/cross_validator_test.dart`:
  - At least 5 test cases: exact match, fuzzy match, mismatch, missing data, CI-only match
- [ ] All tests pass with `flutter test`
- [ ] Test coverage for parsers > 90%

---

### RS-040: Write unit tests for validators, utilities, and image quality
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `flutter`, `testing`, `P1` |
| **Points** | 2 |
| **Assignee** | — |
| **Dependencies** | RS-015 |

**Description**
Unit tests for all utility functions: validators, currency formatters, hash utilities, date utilities.

**Acceptance Criteria**
- [ ] `test/core/utils/validators_test.dart`:
  - Valid/invalid cédulas, phones, plates, references, bank codes, passwords, emails, age check
- [ ] `test/core/utils/currency_utils_test.dart`:
  - USD/VES formatting, conversion, exchange rate display
- [ ] `test/core/utils/hash_utils_test.dart`:
  - SHA-256 of known strings, empty input, byte arrays
- [ ] `test/core/utils/date_utils_test.dart`:
  - ISO 8601 round-trip, display formatting, expiry checks
- [ ] All tests pass with `flutter test`

---

### RS-041: Create onboarding integration test
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `flutter`, `testing`, `P2` |
| **Points** | 3 |
| **Assignee** | — |
| **Dependencies** | RS-028, RS-031, RS-035 |

**Description**
Write an integration (widget) test verifying the complete onboarding flow end-to-end.

**Acceptance Criteria**
- [ ] `integration_test/onboarding_flow_test.dart`:
  - Test navigates: Welcome → Login → OTP → Cédula Confirm → Carnet Confirm → Vehicle Photo → Address → Consent → Home
  - Uses mock Supabase client and mock OCR results
  - Verifies: phone validation, OTP handling, OCR data display, cross-validation banner, address form, consent checkboxes, save sequence
- [ ] Test runs with `flutter test integration_test/`
- [ ] Mocking strategy documented

---

## Epic: E1.7 — Documentation

### RS-042: Write developer setup guide
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `documentation`, `P2` |
| **Points** | 2 |
| **Assignee** | — |
| **Dependencies** | RS-002, RS-003, RS-006 |

**Description**
Comprehensive setup guide so any new developer can get the project running locally in under 15 minutes.

**Acceptance Criteria**
- [ ] `README.md` at project root updated with:
  - Project description (B2B2C InsurTech platform for Venezuelan motorcycle RCV insurance)
  - Prerequisites: Flutter 3.x, Node.js 20+, Supabase CLI, Git
  - Step-by-step setup:
    1. Clone repo
    2. Copy `.env.example` files and fill in values
    3. `cd mobile && flutter pub get`
    4. `cd admin-portal && npm install`
    5. `supabase start` (local dev) or configure remote project
    6. `supabase db reset` (apply migrations + seed)
    7. `flutter run` (mobile)
    8. `npm run dev` (admin portal)
  - Common issues and solutions
  - Links to `MVP_ARCHITECTURE.md` (v2.0)
- [ ] `mobile/.env.example` with all required variables
- [ ] `admin-portal/.env.local.example` with all required variables
- [ ] `supabase/README.md` with migration and seed instructions

---

## Sprint 1 Summary

| Issue | Title | Points | Priority | Dependencies |
|---|---|---|---|---|
| RS-019 | Implement welcome screen | 2 | P0 | RS-011, RS-012, RS-013 |
| RS-020 | Implement phone number input screen | 3 | P0 | RS-013, RS-014, RS-015 |
| RS-021 | Implement OTP verification screen | 5 | P0 | RS-020, RS-008 |
| RS-022 | Implement auth state management and session persistence | 3 | P0 | RS-014 |
| RS-023 | Implement splash screen with session check | 2 | P1 | RS-022, RS-011 |
| RS-024 | Implement camera service with document scanning overlay | 5 | P0 | RS-002 |
| RS-025 | Implement Google ML Kit OCR integration | 3 | P0 | RS-002 |
| RS-026 | Implement Cédula field extraction parser | 5 | P1 | RS-025, RS-015 |
| RS-027 | Implement Cédula scan screen | 3 | P0 | RS-024, RS-025, RS-026, RS-037 |
| RS-028 | Implement identity confirmation screen | 5 | P0 | RS-027, RS-013 |
| RS-029 | Implement Carnet de Circulación field extraction parser | 5 | P1 | RS-025, RS-015 |
| RS-030 | Implement Carnet scan screen | 3 | P0 | RS-024, RS-025, RS-029, RS-037 |
| RS-031 | Implement vehicle confirmation with cross-validation | 5 | P0 | RS-030, RS-013, RS-038 |
| RS-032 | Implement vehicle rear photo capture | 3 | P0 | RS-024, RS-037 |
| RS-033 | Implement address form screen | 3 | P1 | RS-013 |
| RS-034 | Implement legal consent screen (SUDEASEG) | 3 | P0 | RS-013 |
| RS-035 | Implement onboarding data save to Supabase | 5 | P0 | RS-007, RS-009, RS-014 |
| RS-036 | Implement offline data caching | 3 | P1 | RS-014, RS-035 |
| RS-037 | Implement image quality validation service | 3 | P0 | RS-015 |
| RS-038 | Implement cross-validation service (Cédula ↔ Carnet) | 2 | P1 | RS-026, RS-029 |
| RS-039 | Write unit tests for OCR parsers + cross-validation | 3 | P1 | RS-026, RS-029 |
| RS-040 | Write unit tests for validators and utilities | 2 | P1 | RS-015 |
| RS-041 | Create onboarding integration test | 3 | P2 | RS-028, RS-031, RS-035 |
| RS-042 | Write developer setup guide | 2 | P2 | RS-002, RS-003, RS-006 |
| | **Sprint 1 Total** | **86** | | |

**Critical Path:** RS-037 → RS-024 + RS-025 → RS-026 → RS-027 → RS-028 → RS-031 → RS-032 → RS-033 → RS-034 → RS-035 (scan to save)
**Parallel Path A:** RS-022 → RS-023 (auth + splash, independent of OCR)
**Parallel Path B:** RS-029 → RS-030 (carnet scanning, parallel to cédula after RS-024+025)
**Parallel Path C:** RS-038 (cross-validation, parallel after parsers done)
**Parallel Path D:** RS-039, RS-040 (tests, as soon as parsers/utils written)

---

# Dependency Graph

```
Sprint 0                                         Sprint 1
────────                                         ────────

RS-001 (repo) ─┬─ RS-002 (flutter) ──── RS-011 (structure) ──┬── RS-012 (theme) ── RS-013 (widgets)──┐
               │                                              │                                       │
               │                                              ├── RS-014 (services) ────┐             │
               │                                              │                         │             │
               ├─ RS-003 (next.js) ──── RS-016 (admin B2B2C)  │                         │             │
               │                   └─── RS-017 (vercel)       │                         ▼             │
               │                                              │                    RS-022 (auth)      │
               └─ RS-006 (supabase) ─┬─ RS-007 (schema) ──┐  │                    RS-023 (splash)    │
                                     │                     │  │                         │             │
                                     ├─ RS-008 (auth cfg)  │  │                         │             │
                                     │                     │  │  RS-019 (welcome) ◀─────┘             │
                                     ├─ RS-009 (storage)   │  │  RS-020 (phone) ◀─────────────────────┤
                                     │                     │  │  RS-021 (otp) ◀── RS-020              │
                                     └─ RS-018 (bcv fn)    │  │                                       │
                                                           │  │  RS-037 (image quality) ◀── RS-015    │
               RS-004 (CI) ◀── RS-002 + RS-003             │  │                                       │
               RS-005 (signing) ◀── RS-002                 │  │  RS-024 (camera) ─────────────────┐   │
               RS-010 (seed) ◀── RS-007                    │  │  RS-025 (ml kit) ─────────────┐   │   │
               RS-015 (utils+imgQ) ◀── RS-011              │  │                               │   │   │
                                                           │  │  RS-026 (cédula parser) ◀─────┤   │   │
                                                           │  │  RS-029 (carnet parser) ◀─────┘   │   │
                                                           │  │  RS-038 (cross-val) ◀── parsers   │   │
                                                           │  │                                   │   │
                                                           │  │  RS-027 (scan cédula) ◀───────────┼───┘
                                                           │  │  RS-028 (confirm id) ◀── RS-027   │
                                                           │  │  RS-030 (scan carnet) ◀───────────┘
                                                           │  │  RS-031 (confirm vehicle) ◀── RS-030 + RS-038
                                                           │  │  RS-032 (vehicle photo) ◀── RS-024 + RS-037
                                                           │  │  RS-033 (address form)
                                                           │  │  RS-034 (legal consent) ◀── RS-013
                                                           │  │
                                                           │  │  RS-035 (save) ◀── RS-007 + RS-009 + RS-014
                                                           │  │  RS-036 (cache) ◀── RS-035
                                                           ▼  ▼
                                                    RS-039, RS-040 (unit tests)
                                                    RS-041 (integration test)
                                                    RS-042 (docs)
```

---

# Sprint Velocity Notes

| Sprint | Total Points | Notes |
|---|---|---|
| Sprint 0 | 58 | Foundation work — high parallelization (backend + Flutter + admin are independent). Schema is larger due to B2B2C tables (+11 pts from v1). Achievable in 3 focused days for a 1-2 person team. |
| Sprint 1 | 86 | Feature-heavy. Camera + OCR + image quality are highest-risk items. New screens: vehicle photo, address form, legal consent, cross-validation. If velocity is tight, defer RS-036 (cache), RS-041 (integration test), RS-042 (docs), RS-033 (address — can collect during policy purchase instead) to Sprint 2 buffer. |

**Recommended Sprint 1 priority cut lines:**

| Priority | Issues | Points | Includes |
|---|---|---|---|
| **P0 (Must ship)** | 14 issues | 56 pts | Auth, OCR scanning, confirmations, vehicle photo, consent, save, image quality |
| **P1 (Very important)** | 7 issues | 23 pts | Splash, parsers, address form, cross-validation, offline cache, unit tests |
| **P2 (Can slide)** | 3 issues | 7 pts | Integration test, docs |

**v1 → v2 Issue Number Mapping:**
Issues RS-001 through RS-031 retain their numbers with updated content. The old RS-032 through RS-037 have been renumbered and new issues added:

| v2 Issue | Content | Notes |
|---|---|---|
| RS-032 | Vehicle rear photo capture | **NEW** — was not in v1 |
| RS-033 | Address form screen | **NEW** — was not in v1 |
| RS-034 | Legal consent screen | **NEW** — was not in v1 |
| RS-035 | Onboarding data save (was RS-032) | Renumbered, updated for 3 docs + consent |
| RS-036 | Offline caching (was RS-033) | Renumbered |
| RS-037 | Image quality validation | **NEW** — anti-fraud requirement from v2.0 |
| RS-038 | Cross-validation service | **NEW** — CI↔Carnet name match |
| RS-039 | OCR parser unit tests (was RS-034) | Renumbered, added cross-validation tests |
| RS-040 | Validator unit tests (was RS-035) | Renumbered |
| RS-041 | Integration test (was RS-036) | Renumbered, updated flow |
| RS-042 | Developer setup guide (was RS-037) | Renumbered |
