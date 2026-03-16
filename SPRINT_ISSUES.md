# RuedaSeguro — Sprint 0 & Sprint 1 Issues

> **Project:** RuedaSeguro MVP
> **Date:** March 16, 2026
> **Methodology:** Scrum (7-day sprints)
> **Story Points Scale:** Fibonacci (1, 2, 3, 5, 8, 13)
> **Priority:** P0 = Blocker, P1 = Critical, P2 = Important, P3 = Nice-to-have

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
| `P0` | Dark Red | Blocker — Sprint cannot complete without this |
| `P1` | Red | Critical — Core functionality |
| `P2` | Orange | Important — Quality & polish |
| `P3` | Yellow | Nice-to-have — Can defer if time-constrained |

---

# SPRINT 0 — Project Foundation

> **Goal:** Every developer can clone the repo, run `flutter run` and `npm run dev`, and see a working app shell connected to Supabase. All infrastructure is provisioned, all conventions are established, and the codebase is ready for feature development.
>
> **Duration:** Days 1–3
> **Total Story Points:** 47

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
  ├── docs/
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
Initialize the Flutter project inside `mobile/` with all required dependencies from `MVP_ARCHITECTURE.md` Section 4.3. Pin dependency versions for reproducibility.

**Acceptance Criteria**
- [ ] Flutter project created at `mobile/` with `flutter create --org com.ruedaseguro mobile`
- [ ] Minimum SDK: Flutter 3.x, Dart 3.x
- [ ] All dependencies from Section 4.3 added to `pubspec.yaml` with pinned versions
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
- [ ] Internet and camera permissions added to `AndroidManifest.xml`
- [ ] iOS `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` added to `Info.plist`
- [ ] App package name: `com.ruedaseguro.app`
- [ ] App display name: "RuedaSeguro"

---

### RS-003: Configure Next.js admin portal project
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `admin`, `P0` |
| **Points** | 2 |
| **Assignee** | — |
| **Dependencies** | RS-001 |

**Description**
Initialize the Next.js admin portal project inside `admin-portal/` with shadcn/ui and Supabase client.

**Acceptance Criteria**
- [ ] Next.js 15 project created at `admin-portal/` with App Router
- [ ] TypeScript configured with strict mode
- [ ] Tailwind CSS 4 installed and configured
- [ ] shadcn/ui initialized with the following components: `button`, `input`, `card`, `table`, `badge`, `dialog`, `dropdown-menu`, `sheet`, `tabs`, `toast`
- [ ] `@supabase/supabase-js` and `@supabase/ssr` installed
- [ ] ESLint + Prettier configured
- [ ] Environment variables template (`.env.local.example`) with:
  - `NEXT_PUBLIC_SUPABASE_URL`
  - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
  - `SUPABASE_SERVICE_ROLE_KEY`
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
Provision the Supabase project (free tier) and configure local development with the Supabase CLI.

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
| **Points** | 5 |
| **Assignee** | — |
| **Dependencies** | RS-006 |

**Description**
Create and apply the SQL migration file containing the complete MVP schema from `MVP_ARCHITECTURE.md` Section 5.2. This is the foundation all features build on.

**Acceptance Criteria**
- [ ] Migration file `supabase/migrations/001_initial_schema.sql` created containing:
  - All ENUM types (`policy_status`, `payment_status`, `claim_status`, `document_type`, `id_type`)
  - All tables (`carriers`, `carrier_users`, `profiles`, `vehicles`, `policy_types`, `policies`, `payments`, `claims`, `claim_evidence`, `documents`, `exchange_rates`, `audit_log`)
  - All indexes (exchange rates, audit log)
  - All constraints (foreign keys, unique constraints, NOT NULL)
  - All default values
- [ ] Migration file `supabase/migrations/002_rls_policies.sql` created containing:
  - RLS enabled on all user-facing tables
  - All RLS policies from Section 5.2 (user own-data access, public policy types, public exchange rates)
  - INSERT policies for `profiles`, `vehicles`, `policies`, `payments`, `documents`, `claim_evidence`
- [ ] Migration file `supabase/migrations/003_functions.sql` created containing:
  - `generate_policy_number(p_carrier_id UUID)` function
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
- [ ] Email auth also enabled (for admin portal users)

---

### RS-009: Configure Supabase Storage buckets
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `supabase`, `P1` |
| **Points** | 1 |
| **Assignee** | — |
| **Dependencies** | RS-006 |

**Description**
Create the Storage buckets needed for document uploads and policy PDFs.

**Acceptance Criteria**
- [ ] Bucket `documents` created — **private** (requires auth for access)
  - Purpose: scanned cédulas, carnets de circulación, claim photos
  - Max file size: 10MB
  - Allowed MIME types: `image/jpeg`, `image/png`, `image/webp`, `application/pdf`
- [ ] Bucket `policies` created — **private** (requires auth for access)
  - Purpose: generated policy PDFs
  - Max file size: 5MB
  - Allowed MIME types: `application/pdf`
- [ ] Bucket `public` created — **public** (no auth needed)
  - Purpose: carrier logos, app assets
  - Max file size: 2MB
  - Allowed MIME types: `image/jpeg`, `image/png`, `image/svg+xml`, `image/webp`
- [ ] Storage RLS policies:
  - `documents` bucket: users can upload to their own folder (`{user_id}/`), users can read their own files
  - `policies` bucket: users can read their own folder (`{user_id}/`)
  - `public` bucket: anyone can read, only service role can write
- [ ] Test: authenticated upload and retrieval of a test image to `documents` bucket

---

### RS-010: Create seed data for development and demos
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `supabase`, `P1` |
| **Points** | 2 |
| **Assignee** | — |
| **Dependencies** | RS-007 |

**Description**
Create a SQL seed file with realistic test data so developers and demo environments have data to work with immediately.

**Acceptance Criteria**
- [ ] `supabase/seed.sql` file created with:
  - 2 test carriers:
    - "Seguros Caracas" (RIF: J-00012345-6)
    - "Mapfre Venezuela" (RIF: J-00067890-1)
  - 3 policy types per carrier:
    - RCV Básico ($17.70 USD, coverage $50,000, 365 days)
    - RCV + Accidentes Personales ($25.00 USD, coverage $75,000, 365 days)
    - RCV Premium ($35.00 USD, coverage $100,000, 365 days)
  - 1 test exchange rate (current approximate BCV rate)
  - 2 carrier admin users (linked to email auth accounts):
    - `admin@seguroscaracas.test` (role: admin)
    - `admin@mapfre.test` (role: admin)
- [ ] Seed data references realistic Venezuelan insurance products and pricing
- [ ] `supabase/seed.sql` is idempotent (can be run multiple times without duplicates — uses `ON CONFLICT DO NOTHING` or checks)
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
Create the full folder structure from `MVP_ARCHITECTURE.md` Section 7.1. Set up the architectural foundation: Riverpod providers, GoRouter, and the feature directory convention.

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
  - GoRouter configured with initial placeholder routes:
    - `/` → Splash/loading
    - `/welcome` → Welcome screen
    - `/login` → Login (Phone input)
    - `/otp` → OTP verification
    - `/onboarding/cedula` → Cédula scan
    - `/onboarding/vehicle` → Carnet scan
    - `/home` → Home dashboard
    - `/policy/:id` → Policy detail
    - `/claims/new` → New claim
    - `/profile` → Profile
  - Auth redirect: unauthenticated users go to `/welcome`
  - Placeholder screens for each route (just a `Scaffold` with the route name as title)
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
Implement the RuedaSeguro design system as defined in `MVP_ARCHITECTURE.md` Section 7.3. This establishes the visual identity used by every screen.

**Acceptance Criteria**
- [ ] `core/theme/colors.dart`:
  - `RSColors` class with all color constants:
    - `primary` = Deep blue (#1A237E)
    - `primaryLight` = Lighter blue for hover/focus states
    - `accent` = Amber (#FFB300)
    - `success` = Green (#2E7D32)
    - `error` = Red (#C62828)
    - `warning` = Orange
    - `background` = Off-white (#FAFAFA)
    - `surface` = White (#FFFFFF)
    - `textPrimary` = Off-black (#212121)
    - `textSecondary` = Gray (#757575)
    - `border` = Light gray (#E0E0E0)
- [ ] `core/theme/typography.dart`:
  - `RSTypography` class with `TextStyle` definitions:
    - `displayLarge` — Screen titles (bold, 28sp)
    - `displayMedium` — Section headers (bold, 22sp)
    - `titleLarge` — Card titles (semi-bold, 18sp)
    - `titleMedium` — Subtitles (medium, 16sp)
    - `bodyLarge` — Primary text (regular, 16sp)
    - `bodyMedium` — Secondary text (regular, 14sp)
    - `labelLarge` — Button text (semi-bold, 16sp)
    - `caption` — Small labels (regular, 12sp)
    - `mono` — Reference numbers, amounts (monospace, 16sp)
  - Font family: system default (or Inter if a custom font is desired)
  - Minimum text size: 14sp for body text (accessibility)
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
  - Primary button (filled, accent color, rounded corners)
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
  - Used when lists have no data (no policies, no claims, etc.)
- [ ] `offline_banner.dart`:
  - Persistent banner shown at top when device is offline
  - Text: "Sin conexión a internet"
  - Animated appearance/disappearance on connectivity change
- [ ] `amount_display.dart`:
  - Dual-currency display: USD amount (large, primary) + VES equivalent (smaller, secondary)
  - Includes exchange rate source and freshness indicator
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
  - Performs actual HTTP ping (not just network interface check) to confirm real internet access
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
  - Used by `offline_banner.dart` and any feature that needs to check connectivity
- [ ] `shared/providers/auth_provider.dart`:
  - Riverpod `StateNotifierProvider` wrapping Supabase auth state
  - Exposes: `isAuthenticated`, `currentUser`, `session`
  - Listens to `supabase.auth.onAuthStateChange`
  - Handles token refresh automatically
- [ ] Unit tests:
  - Connectivity service correctly reports connected/disconnected
  - Local storage service CRUD operations work correctly

---

### RS-015: Implement core utilities — validators, formatters, hash helpers
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `flutter`, `P1` |
| **Points** | 3 |
| **Assignee** | — |
| **Dependencies** | RS-011 |

**Description**
Implement the utility classes from `MVP_ARCHITECTURE.md` Section 7.1 (`core/utils/`). These are pure Dart functions used across the app.

**Acceptance Criteria**
- [ ] `validators.dart`:
  - `isValidCedula(String)` — validates V/E/J/P prefix + 6-9 digits
  - `isValidPhone(String)` — validates Venezuelan phone format (04XX-XXXXXXX or +58 4XX XXXXXXX)
  - `isValidPlate(String)` — validates Venezuelan plate format (e.g., AB123CD)
  - `isValidReference(String)` — validates Pago Móvil reference (numeric, 8-20 digits)
  - `isValidBankCode(String)` — validates 4-digit bank code
  - `isNotEmpty(String)` — non-null, non-blank
- [ ] `currency_utils.dart`:
  - `formatUSD(double)` → `"$17.70"` (2 decimal places, dollar sign)
  - `formatVES(double)` → `"Bs. 658.45"` (2 decimal places, Bs. prefix)
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
- [ ] `core/errors/failures.dart`:
  - `Failure` abstract class with `message` property
  - `ServerFailure`, `NetworkFailure`, `CacheFailure`, `AuthFailure`, `ValidationFailure`
- [ ] `core/errors/exceptions.dart`:
  - `ServerException`, `NetworkException`, `CacheException`
- [ ] `core/constants/app_constants.dart`:
  - `impactThreshold = 9.0` (G-force for severe impact — Phase 2 reference)
  - `ocrConfidenceThreshold = 0.8`
  - `maxFileSize = 10 * 1024 * 1024` (10MB)
  - `otpLength = 6`
  - `otpExpirySeconds = 300`
  - `bcvRefreshIntervalMinutes = 30`
  - `venezuelaCountryCode = '+58'`
- [ ] `core/constants/supabase_constants.dart`:
  - Table names as constants (avoid magic strings)
  - Bucket names as constants
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
| **Labels** | `admin`, `P1` |
| **Points** | 3 |
| **Assignee** | — |
| **Dependencies** | RS-003, RS-008 |

**Description**
Build the admin portal's layout structure and authentication gate. Carrier admins must log in with email/password before accessing any page.

**Acceptance Criteria**
- [ ] `/login` page:
  - Email + password form
  - Supabase Auth sign-in
  - Error handling (invalid credentials, network errors)
  - Redirect to `/dashboard` on success
- [ ] Layout component (`DashboardLayout`):
  - Left sidebar with navigation links:
    - Dashboard (icon: LayoutDashboard)
    - Pólizas (icon: FileText)
    - Pagos (icon: CreditCard)
    - Reclamos (icon: AlertTriangle)
    - Usuarios (icon: Users)
    - Configuración (icon: Settings)
  - Top header with:
    - Carrier name
    - User name
    - Logout button
  - Mobile-responsive: sidebar collapses to hamburger menu on small screens
- [ ] Auth middleware:
  - Unauthenticated users redirected to `/login`
  - Auth state persisted via Supabase SSR cookies
  - Carrier ID resolved from `carrier_users` table and stored in context
- [ ] `/dashboard` page:
  - Placeholder content: "Bienvenido a RuedaSeguro Admin"
  - Shows carrier name dynamically
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
- [ ] Returns the rate in the response body as JSON: `{ "rate": 37.20, "fetched_at": "2026-03-16T..." }`
- [ ] Error handling:
  - If primary source fails, tries fallback
  - If all sources fail, returns 503 with error message
  - Never inserts a rate of 0 or null
- [ ] Rate freshness validation: if the fetched rate differs by >20% from the last stored rate, flag as suspicious but still insert (prevents stale data from a broken scraper, while alerting on anomalies)
- [ ] Deployable via `supabase functions deploy bcv-rate`
- [ ] Can be invoked manually: `supabase functions invoke bcv-rate`
- [ ] Scheduled invocation documented (Supabase cron or external cron — note: Supabase free tier has pg_cron available)
- [ ] Test: function returns a valid rate when invoked

---

## Sprint 0 Summary

| Issue | Title | Points | Priority | Dependencies |
|---|---|---|---|---|
| RS-001 | Initialize monorepo and Git configuration | 2 | P0 | — |
| RS-002 | Configure Flutter project with dependencies | 3 | P0 | RS-001 |
| RS-003 | Configure Next.js admin portal project | 2 | P0 | RS-001 |
| RS-004 | Set up GitHub Actions CI pipeline | 3 | P1 | RS-002, RS-003 |
| RS-005 | Configure Android release signing | 2 | P2 | RS-002 |
| RS-006 | Create Supabase project and configure environment | 2 | P0 | RS-001 |
| RS-007 | Apply initial database schema migration | 5 | P0 | RS-006 |
| RS-008 | Configure Supabase Auth for phone OTP | 2 | P0 | RS-006 |
| RS-009 | Configure Supabase Storage buckets | 1 | P1 | RS-006 |
| RS-010 | Create seed data for development and demos | 2 | P1 | RS-007 |
| RS-011 | Implement Flutter folder structure and core architecture | 3 | P0 | RS-002 |
| RS-012 | Implement design system — theme, colors, typography | 3 | P1 | RS-011 |
| RS-013 | Build shared widget library — base components | 5 | P1 | RS-012 |
| RS-014 | Implement core services — Supabase, connectivity, local storage | 5 | P0 | RS-006, RS-011 |
| RS-015 | Implement core utilities — validators, formatters, hash helpers | 3 | P1 | RS-011 |
| RS-016 | Build admin portal layout shell and auth gate | 3 | P1 | RS-003, RS-008 |
| RS-017 | Deploy admin portal to Vercel | 1 | P2 | RS-003 |
| RS-018 | Implement BCV exchange rate Edge Function | 3 | P1 | RS-007, RS-006 |
| | **Sprint 0 Total** | **47** | | |

**Critical Path:** RS-001 → RS-006 → RS-007 → RS-010 (backend ready)
**Parallel Path A:** RS-001 → RS-002 → RS-011 → RS-014 (Flutter foundation)
**Parallel Path B:** RS-001 → RS-003 → RS-016 → RS-017 (admin portal)

---

---

# SPRINT 1 — Authentication & Onboarding

> **Goal:** A rider can download the app, register with their phone number, scan their Cédula and Carnet de Circulación via OCR, review and confirm their data, and have a complete profile + vehicle saved in Supabase. This is the "60-Second Onboarding Nucleus."
>
> **Duration:** Days 4–10
> **Total Story Points:** 69
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
  - RuedaSeguro logo/branding at top
  - Value proposition headline: "Seguro de moto en 60 segundos"
  - Brief subtitle: "Liquidación inmediata en caso de accidente"
  - Illustration or graphic representing protection/insurance (placeholder is acceptable)
  - Primary CTA button: "Registrarme" → navigates to phone login
  - Secondary link: "Ya tengo cuenta" → navigates to phone login (same flow, different intent tracking)
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
    - Input mask: auto-formats as `XXX XXXXXXX` (e.g., `412 1234567`)
  - "Continuar" button (disabled until valid phone entered)
- [ ] Validation:
  - Phone number must be 10 digits after country code (e.g., 4121234567)
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
- [ ] Phone number persisted in memory (so OTP screen can display "code sent to +58 412...")

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
    - Auto-submit when all 6 digits are entered (no "Confirm" button needed)
    - Paste support (if user copies OTP from SMS, all 6 digits auto-fill)
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
    - Invalid OTP: clear all boxes, show error "Código incorrecto. Intenta de nuevo." Focus returns to first box.
    - Expired OTP: "Código expirado. Solicita uno nuevo."
    - Max attempts exceeded: "Demasiados intentos. Espera 10 minutos."
- [ ] Resend OTP:
  - Call `supabase.auth.signInWithOtp(phone:)` again
  - Show confirmation toast: "Código reenviado"
  - Reset countdown timer
  - Max 3 resends shown to user (then: "Contacta soporte")
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
  - Listens to `onAuthStateChange` stream from Supabase
  - Updates state on: `signedIn`, `signedOut`, `tokenRefreshed`, `userUpdated`
  - On `signedOut` or `tokenRefreshed` failure: navigate to `/welcome`
- [ ] GoRouter integration:
  - `redirect` function checks auth state
  - Unauthenticated users trying to access protected routes → redirect to `/welcome`
  - Authenticated users at `/welcome` or `/login` → redirect to `/home` or `/onboarding/cedula` (based on profile existence)
- [ ] Session persistence:
  - On app cold start, check for existing Supabase session
  - If valid session exists, show splash briefly then go to `/home`
  - If session expired and refresh fails, go to `/welcome`
- [ ] Logout flow:
  - Clears Supabase session
  - Clears local SQLite cache
  - Clears Hive storage
  - Navigates to `/welcome`
- [ ] Test: app restart preserves logged-in state
- [ ] Test: expired token triggers re-authentication

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
  - Background color: primary deep blue
- [ ] Logic on splash:
  1. Wait for Supabase initialization
  2. Check for existing session via `supabase.auth.currentSession`
  3. If valid session:
     - Check if profile exists in `profiles` table
     - If profile exists → navigate to `/home`
     - If no profile → navigate to `/onboarding/cedula`
  4. If no session → navigate to `/welcome`
  5. Maximum splash duration: 3 seconds (navigate even if check is still pending — use timeout)
- [ ] No flickering between splash and destination screen
- [ ] Works offline: if no network, still tries cached session (Supabase stores session locally)

---

## Epic: E1.2 — Onboarding: Identity Capture (Cédula)

### RS-024: Implement camera service with document scanning overlay
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `flutter`, `P0` |
| **Points** | 5 |
| **Assignee** | — |
| **Dependencies** | RS-002 |

**Description**
Build a reusable camera component with a document-alignment overlay that guides the user to position their ID card within the frame. This component is used for both Cédula and Carnet de Circulación scanning.

**Acceptance Criteria**
- [ ] `shared/widgets/document_scanner.dart` — reusable widget:
  - Opens rear camera at maximum resolution
  - Displays a semi-transparent overlay with a clear rectangle "window" where the document should be placed
  - Overlay includes corner brackets to guide alignment
  - Text instruction at top: customizable (e.g., "Coloca tu cédula dentro del recuadro")
  - Flashlight toggle button (for low-light conditions)
  - Capture button (large, centered at bottom, in the "Easy Zone")
  - Gallery pick button (small, for selecting existing photo)
  - Preview: after capture, show the captured image with "Usar foto" / "Reintentar" options
- [ ] Camera permissions:
  - Request camera permission at runtime (`permission_handler`)
  - If denied: show explanation dialog and link to app settings
  - If permanently denied: show message with "Abrir Configuración" button
- [ ] Image output:
  - Returns a `File` object of the captured/selected image
  - Image compressed to max 1920px on longest side (to reduce upload size and OCR processing time)
  - EXIF rotation corrected (common issue on Android)
- [ ] Performance:
  - Camera preview runs at 30fps minimum
  - Capture-to-preview transition under 500ms
- [ ] Accessibility:
  - Capture button has screen reader label: "Tomar foto del documento"
  - Flashlight button has label: "Activar/desactivar linterna"

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
    - `rawText` — full extracted text as single string
    - `textBlocks` — list of recognized text blocks with bounding boxes
    - `confidence` — overall confidence score (0.0 to 1.0, derived from individual block confidences)
    - `processingTimeMs` — how long OCR took
  - Supports Latin script (Spanish characters: á, é, í, ó, ú, ñ, ü)
  - Handles both landscape and portrait document orientations
- [ ] `features/onboarding/domain/ocr_result.dart`:
  - Data class with all fields above
  - `toString()` for debugging
  - `isEmpty` getter
- [ ] Error handling:
  - If ML Kit fails: return `OcrResult.empty()` (triggers manual entry fallback)
  - If image is too blurry: low confidence score naturally triggers manual entry
- [ ] Performance:
  - OCR processing time under 2 seconds on mid-range Android devices
  - Runs on background isolate to avoid blocking UI thread
- [ ] Test: pass a test image of a Venezuelan cédula and verify text is extracted
- [ ] Test: pass a blank/dark image and verify graceful failure

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
Build the regex-based parser that extracts structured fields from raw OCR text of a Venezuelan Cédula de Identidad. This is the "intelligence" that turns raw text into form data.

**Acceptance Criteria**
- [ ] `features/onboarding/domain/cedula_parser.dart`:
  - `CedulaParseResult parse(String rawText, List<TextBlock> blocks)` method
  - Returns `CedulaParseResult` with:
    - `idType` (V, E) — extracted or defaulted to V
    - `idNumber` (string, digits only)
    - `firstName`
    - `lastName`
    - `dateOfBirth` (DateTime, nullable)
    - `confidence` (0.0-1.0 overall parse confidence)
    - `fieldConfidences` (map of field name → individual confidence)
- [ ] Extraction rules:
  - **ID Number**: RegExp `r'[VvEe][-.\s]?\s*(\d{1,3}[.]?\d{3}[.]?\d{3})'` — handles formats like `V-12.345.678`, `V 12345678`, `E-12345678`
  - **ID Type**: First letter before the number (V or E). Default to V if ambiguous.
  - **Names**: Heuristic — look for UPPERCASE text blocks that are NOT numbers, dates, or known keywords (REPUBLICA, BOLIVARIANA, VENEZUELA, CEDULA, IDENTIDAD). Usually the largest text blocks after filtering.
  - **Date of Birth**: RegExp for dd/MM/yyyy or dd-MM-yyyy patterns. Look for dates that would make the person 16-100 years old.
- [ ] Confidence scoring:
  - Each extracted field gets a confidence score based on:
    - Regex match specificity (exact match = 1.0, fuzzy match = 0.6)
    - Text block OCR confidence from ML Kit
    - Multiple matches found = lower confidence (ambiguity)
  - Overall confidence = average of field confidences
- [ ] Edge cases handled:
  - Cédula with dots in number (12.345.678) → strip dots
  - Cédula with spaces → strip spaces
  - Old format vs new format cédulas
  - Faded or partially obscured text → lower confidence, not crash
  - No extractable data → return `CedulaParseResult.empty()` (all fields null, confidence 0)
- [ ] Unit tests with at least 5 sample OCR outputs (varied formats):
  - Clean new cédula
  - Old format cédula
  - Faded/partial text
  - Extranjero (E-prefix) cédula
  - Completely unrecognizable text (should return empty, not throw)

---

### RS-027: Implement Cédula scan screen
| Field | Value |
|---|---|
| **Type** | `story` |
| **Labels** | `flutter`, `P0` |
| **Points** | 3 |
| **Assignee** | — |
| **Dependencies** | RS-024, RS-025, RS-026 |

**Description**
**As a** new rider during onboarding,
**I want** to scan the front of my Cédula de Identidad with my phone camera,
**so that** my personal data is automatically extracted and I don't have to type it manually.

**Acceptance Criteria**
- [ ] Screen uses `DocumentScanner` widget with instruction: "Coloca el frente de tu cédula dentro del recuadro"
- [ ] After photo capture:
  1. Show brief processing indicator: "Leyendo documento..." with shimmer animation
  2. Run Google ML Kit OCR on the captured image
  3. Run `CedulaParser.parse()` on OCR results
  4. Navigate to confirm screen with extracted data
- [ ] If OCR returns empty or very low confidence (<0.3):
  - Show message: "No pudimos leer tu cédula. ¿Deseas reintentar o ingresar los datos manualmente?"
  - Two options: "Reintentar foto" / "Ingresar manualmente"
  - "Ingresar manualmente" navigates to confirm screen with all fields empty
- [ ] Scanned image is saved locally (temp file) for later upload
- [ ] Back button returns to previous onboarding step (or welcome if first step)
- [ ] Progress indicator shows: Step 1 of 4 (or visual breadcrumbs)

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
**so that** my profile information is accurate before I proceed.

**Acceptance Criteria**
- [ ] Screen displays:
  - Header: "Confirma tus datos"
  - Subtitle: "Verifica que la información sea correcta"
  - Thumbnail of the scanned cédula image (tappable to view full-size)
  - Editable form fields pre-filled with OCR data:
    - Tipo de documento (dropdown: V / E) — highlighted if low confidence
    - Número de cédula (text field with numeric keyboard)
    - Nombre(s) (text field)
    - Apellido(s) (text field)
    - Fecha de nacimiento (date picker)
  - Fields with confidence < 0.8 are visually highlighted (amber border) with tooltip: "Verifica este campo"
  - Fields with confidence >= 0.8 show a green checkmark
  - "Continuar" button at bottom
- [ ] Emergency contact section (optional, collapsible):
  - Nombre del contacto de emergencia
  - Teléfono del contacto de emergencia
  - Parentesco (dropdown: Madre, Padre, Esposo/a, Hermano/a, Otro)
- [ ] Validation on "Continuar":
  - Cédula number: required, valid format (6-9 digits)
  - First name: required, min 2 characters
  - Last name: required, min 2 characters
  - Date of birth: optional but validated if provided (must be 16-100 years old)
  - Show inline errors under invalid fields
- [ ] On "Continuar":
  - Save profile data locally (for offline resilience)
  - Navigate to Carnet de Circulación scan screen
  - Do NOT save to Supabase yet (save all at once at end of onboarding)
- [ ] Back button returns to cédula scan screen (with option to retake)
- [ ] Progress indicator: Step 2 of 4

---

## Epic: E1.3 — Onboarding: Vehicle Capture (Carnet de Circulación)

### RS-029: Implement Carnet de Circulación field extraction parser
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `flutter`, `P1` |
| **Points** | 5 |
| **Assignee** | — |
| **Dependencies** | RS-025, RS-015 |

**Description**
Build the parser that extracts vehicle data from raw OCR text of a Venezuelan Carnet de Circulación.

**Acceptance Criteria**
- [ ] `features/onboarding/domain/carnet_parser.dart`:
  - `CarnetParseResult parse(String rawText, List<TextBlock> blocks)` method
  - Returns `CarnetParseResult` with:
    - `plate` (string, Venezuelan format)
    - `brand` (string — e.g., Bera, Empire, Honda, Yamaha, Suzuki)
    - `model` (string)
    - `year` (int)
    - `color` (string, nullable)
    - `serialMotor` (string, nullable)
    - `serialCarroceria` (string, nullable — chassis/VIN)
    - `confidence` (0.0-1.0)
    - `fieldConfidences` (map)
- [ ] Extraction rules:
  - **Plate**: RegExp `r'([A-Z]{2,3})\s*[-]?\s*(\d{2,3})\s*[-]?\s*([A-Z]{2,3})'` — handles `AB123CD`, `AB-123-CD`, `AB 123 CD`
  - **Brand**: Keyword matching against known Venezuelan motorcycle brands list:
    - Bera, Empire, MD, Loncin, Skygo, Keeway, UM, Haojue, Arsen, Jaguar
    - Honda, Yamaha, Suzuki, Kawasaki, TVS, Bajaj, Hero, KTM
  - **Model**: Text adjacent to or following the brand name
  - **Year**: RegExp `r'(19|20)\d{2}'` — filter to plausible years (1980-2027)
  - **Color**: Keyword matching against common colors in Spanish (Negro, Blanco, Rojo, Azul, Gris, Verde, Amarillo, Naranja, Marrón)
  - **Serial Motor / Carrocería**: RegExp for long alphanumeric strings (8-20 chars) — typically labeled "SERIAL DEL MOTOR" or "SERIAL DE CARROCERIA"
- [ ] Confidence scoring (same logic as RS-026)
- [ ] Edge cases:
  - Different carnet formats across Venezuelan states
  - Handwritten fields (very low confidence → manual entry)
  - Multiple years found → pick the one most likely to be the vehicle year (not issuance year)
- [ ] Unit tests with at least 4 sample OCR outputs:
  - Clean modern carnet
  - Older format carnet
  - Motorcycle-specific carnet (not car)
  - Low quality / partial text

---

### RS-030: Implement Carnet de Circulación scan screen
| Field | Value |
|---|---|
| **Type** | `story` |
| **Labels** | `flutter`, `P0` |
| **Points** | 3 |
| **Assignee** | — |
| **Dependencies** | RS-024, RS-025, RS-029 |

**Description**
**As a** new rider during onboarding,
**I want** to scan my Carnet de Circulación,
**so that** my motorcycle data is automatically captured.

**Acceptance Criteria**
- [ ] Screen uses `DocumentScanner` widget with instruction: "Coloca tu carnet de circulación dentro del recuadro"
- [ ] Same capture → OCR → parse → navigate flow as RS-027
- [ ] Low confidence / failure: offer "Reintentar" or "Ingresar manualmente"
- [ ] Progress indicator: Step 3 of 4

---

### RS-031: Implement vehicle confirmation screen
| Field | Value |
|---|---|
| **Type** | `story` |
| **Labels** | `flutter`, `P0` |
| **Points** | 5 |
| **Assignee** | — |
| **Dependencies** | RS-030, RS-013 |

**Description**
**As a** rider who scanned their Carnet de Circulación,
**I want** to review and confirm my motorcycle data,
**so that** my vehicle is correctly registered in the system.

**Acceptance Criteria**
- [ ] Screen displays:
  - Header: "Confirma los datos de tu moto"
  - Thumbnail of scanned carnet (tappable to view full-size)
  - Editable form fields pre-filled with OCR data:
    - Placa (text field, uppercase auto-format)
    - Marca (text field with suggestion dropdown from known brands)
    - Modelo (text field)
    - Año (number input, 4 digits, range 1980-2027)
    - Color (dropdown or text field)
    - Serial del motor (text field, optional but recommended)
    - Serial de carrocería (text field, optional but recommended)
  - Confidence indicators (same as RS-028)
  - "Finalizar registro" primary button
- [ ] Validation on "Finalizar registro":
  - Plate: required, valid Venezuelan format
  - Brand: required
  - Model: required
  - Year: required, valid range
  - Serial fields: optional
- [ ] On "Finalizar registro":
  - Show full-screen loading: "Creando tu perfil..."
  - Execute the full save sequence (see RS-032)
  - On success: navigate to `/home` with success animation/toast
  - On failure: show error with retry option
- [ ] Progress indicator: Step 4 of 4

---

## Epic: E1.4 — Profile & Vehicle Persistence

### RS-032: Implement onboarding data save to Supabase
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `flutter`, `supabase`, `P0` |
| **Points** | 5 |
| **Assignee** | — |
| **Dependencies** | RS-007, RS-009, RS-014 |

**Description**
Implement the repository layer that saves all onboarding data (profile, vehicle, scanned documents) to Supabase in a single atomic flow. This runs when the user taps "Finalizar registro" on the vehicle confirmation screen.

**Acceptance Criteria**
- [ ] `features/onboarding/data/profile_repository.dart`:
  - `Future<Profile> createProfile(ProfileData data)` — inserts into `profiles` table
  - `Future<Profile> getProfile()` — fetches current user's profile
  - `Future<Profile> updateProfile(ProfileData data)` — updates current user's profile
  - `Future<bool> profileExists()` — checks if current user has a profile row
- [ ] `features/onboarding/data/vehicle_repository.dart`:
  - `Future<Vehicle> createVehicle(VehicleData data)` — inserts into `vehicles` table
  - `Future<List<Vehicle>> getVehicles()` — fetches current user's vehicles
- [ ] `features/onboarding/data/document_repository.dart`:
  - `Future<Document> uploadDocument(File file, DocumentType type, {UUID? vehicleId})`:
    1. Upload file to Supabase Storage (`documents/{user_id}/{uuid}.jpg`)
    2. Get the public/signed URL
    3. Calculate SHA-256 hash of file
    4. Insert record into `documents` table with URL, hash, type, OCR data
    5. Return `Document` model
- [ ] Complete onboarding save sequence (executed atomically as possible):
  1. Upload cédula image → get document record
  2. Upload carnet image → get document record
  3. Create profile (with `ocr_raw_data` and `ocr_confidence` stored)
  4. Create vehicle (linked to profile, with `ocr_raw_data` and `ocr_confidence`)
  5. Link document records to profile and vehicle
- [ ] Error handling:
  - If any step fails: show error message, allow retry
  - Partial saves are handled (if profile created but vehicle fails, don't re-create profile on retry)
  - Idempotency: check if profile/vehicle already exists before creating
- [ ] Network failure:
  - If offline during save: store all data locally in SQLite (pending_sync_queue)
  - Show message: "Datos guardados localmente. Se sincronizarán cuando haya conexión."
  - When connectivity restored, automatically sync pending data
- [ ] All Supabase operations use the authenticated user's JWT (RLS enforced)

---

### RS-033: Implement offline data caching for profile and vehicle
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `flutter`, `P1` |
| **Points** | 3 |
| **Assignee** | — |
| **Dependencies** | RS-014, RS-032 |

**Description**
After profile and vehicle data are saved to Supabase (or queued locally), cache them in SQLite so the app works offline for all read operations.

**Acceptance Criteria**
- [ ] After successful Supabase save:
  - Profile data cached in `cached_profiles` SQLite table
  - Vehicle data cached in `cached_vehicles` SQLite table
  - Timestamps stored for cache freshness checking
- [ ] When reading profile/vehicle data:
  - Try Supabase first (if online)
  - On success: update local cache, return data
  - On failure (network): return cached data with "last updated" timestamp
  - If no cache exists and offline: show appropriate empty/error state
- [ ] Cache invalidation:
  - On profile update → update cache
  - On logout → clear all caches
  - Cache TTL: 24 hours (after which, try to refresh on next app open)
- [ ] `pending_sync_queue` table:
  - Stores operations that failed due to network: `{ operation, table, data, created_at, attempts }`
  - Background sync service checks queue when connectivity changes to online
  - Max retry attempts: 5 (then flag for manual resolution)
- [ ] Test: create profile while online → go offline → profile is still viewable
- [ ] Test: create profile while offline → data in sync queue → go online → data syncs automatically

---

## Epic: E1.5 — Quality & Testing

### RS-034: Write unit tests for OCR parsers
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `flutter`, `testing`, `P1` |
| **Points** | 3 |
| **Assignee** | — |
| **Dependencies** | RS-026, RS-029 |

**Description**
Comprehensive unit tests for both the Cédula parser and Carnet de Circulación parser. These parsers are critical — incorrect extraction means incorrect policy data.

**Acceptance Criteria**
- [ ] `test/features/onboarding/domain/cedula_parser_test.dart`:
  - Test: extracts `V-12.345.678` correctly
  - Test: extracts `E-1234567` correctly
  - Test: extracts `V 12345678` (no dash) correctly
  - Test: extracts name in UPPERCASE block format
  - Test: extracts date of birth in dd/MM/yyyy format
  - Test: returns empty result for garbage text
  - Test: returns low confidence when only some fields found
  - Test: handles text with extra whitespace and newlines
  - Test: handles accented characters (María, José, Pérez, Muñoz)
  - At least 10 test cases total
- [ ] `test/features/onboarding/domain/carnet_parser_test.dart`:
  - Test: extracts plate `AB123CD` correctly
  - Test: extracts plate `AB-123-CD` with dashes
  - Test: extracts known brand "BERA" from text
  - Test: extracts year from text containing multiple 4-digit numbers
  - Test: extracts color in Spanish
  - Test: extracts serial numbers (long alphanumeric strings)
  - Test: returns empty result for unreadable text
  - Test: handles motorcycle-specific formats
  - At least 8 test cases total
- [ ] All tests pass with `flutter test`
- [ ] Test coverage for parsers > 90%

---

### RS-035: Write unit tests for validators and utility functions
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `flutter`, `testing`, `P1` |
| **Points** | 2 |
| **Assignee** | — |
| **Dependencies** | RS-015 |

**Description**
Unit tests for all utility functions: validators, currency formatters, hash utilities, and date utilities.

**Acceptance Criteria**
- [ ] `test/core/utils/validators_test.dart`:
  - Valid and invalid cédulas (at least 6 cases each)
  - Valid and invalid phone numbers (at least 5 cases each)
  - Valid and invalid plates (at least 4 cases each)
  - Valid and invalid Pago Móvil references
  - Valid and invalid bank codes
- [ ] `test/core/utils/currency_utils_test.dart`:
  - USD formatting (regular amounts, zero, large amounts)
  - VES formatting (regular, zero, very large amounts common in VES)
  - USD to VES conversion with known rate
  - Exchange rate display formatting
- [ ] `test/core/utils/hash_utils_test.dart`:
  - SHA-256 of known string produces expected hex output
  - SHA-256 of empty input
  - SHA-256 of byte array
- [ ] `test/core/utils/date_utils_test.dart`:
  - ISO 8601 round-trip (DateTime → String → DateTime)
  - Display date formatting in Spanish
  - `isExpired` for past and future dates
  - `daysUntilExpiry` calculation
- [ ] All tests pass with `flutter test`

---

### RS-036: Create onboarding integration test
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `flutter`, `testing`, `P2` |
| **Points** | 3 |
| **Assignee** | — |
| **Dependencies** | RS-028, RS-031, RS-032 |

**Description**
Write an integration (widget) test that verifies the complete onboarding flow works end-to-end, from welcome screen through to profile creation.

**Acceptance Criteria**
- [ ] `integration_test/onboarding_flow_test.dart`:
  - Test navigates: Welcome → Login → OTP → Cédula Confirm → Carnet Confirm → Home
  - Uses mock Supabase client (no real network calls)
  - Uses mock OCR results (pre-defined parse results)
  - Verifies:
    - Phone number validation prevents invalid input
    - OTP screen receives phone number
    - Cédula confirm screen shows pre-filled data
    - Vehicle confirm screen shows pre-filled data
    - "Finalizar registro" calls the save sequence
    - Navigation reaches home on success
- [ ] Test can be run with `flutter test integration_test/`
- [ ] Mocking strategy documented (how to mock Supabase for tests)

---

## Epic: E1.6 — Documentation

### RS-037: Write developer setup guide
| Field | Value |
|---|---|
| **Type** | `task` |
| **Labels** | `documentation`, `P2` |
| **Points** | 2 |
| **Assignee** | — |
| **Dependencies** | RS-002, RS-003, RS-006 |

**Description**
Write a comprehensive setup guide so any new developer can get the project running locally in under 15 minutes.

**Acceptance Criteria**
- [ ] `README.md` at project root updated with:
  - Project description (2-3 sentences)
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
  - Links to architecture docs (`MVP_ARCHITECTURE.md`)
- [ ] `mobile/.env.example` with all required variables and comments
- [ ] `admin-portal/.env.local.example` with all required variables and comments
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
| RS-027 | Implement Cédula scan screen | 3 | P0 | RS-024, RS-025, RS-026 |
| RS-028 | Implement identity confirmation screen | 5 | P0 | RS-027, RS-013 |
| RS-029 | Implement Carnet de Circulación field extraction parser | 5 | P1 | RS-025, RS-015 |
| RS-030 | Implement Carnet de Circulación scan screen | 3 | P0 | RS-024, RS-025, RS-029 |
| RS-031 | Implement vehicle confirmation screen | 5 | P0 | RS-030, RS-013 |
| RS-032 | Implement onboarding data save to Supabase | 5 | P0 | RS-007, RS-009, RS-014 |
| RS-033 | Implement offline data caching for profile and vehicle | 3 | P1 | RS-014, RS-032 |
| RS-034 | Write unit tests for OCR parsers | 3 | P1 | RS-026, RS-029 |
| RS-035 | Write unit tests for validators and utility functions | 2 | P1 | RS-015 |
| RS-036 | Create onboarding integration test | 3 | P2 | RS-028, RS-031, RS-032 |
| RS-037 | Write developer setup guide | 2 | P2 | RS-002, RS-003, RS-006 |
| | **Sprint 1 Total** | **69** | | |

**Critical Path:** RS-024 + RS-025 → RS-026 → RS-027 → RS-028 → RS-032 (scan to save)
**Parallel Path A:** RS-022 → RS-023 (auth + splash, independent of OCR)
**Parallel Path B:** RS-029 → RS-030 → RS-031 (carnet scanning, parallel to cédula after RS-024+025)
**Parallel Path C:** RS-034, RS-035 (tests, can start as soon as parsers are written)

---

# Dependency Graph

```
Sprint 0                                      Sprint 1
────────                                      ────────

RS-001 (repo) ─┬─ RS-002 (flutter) ──── RS-011 (structure) ──┬── RS-012 (theme) ── RS-013 (widgets)──┐
               │                                              │                                       │
               │                                              ├── RS-014 (services) ────┐             │
               │                                              │                         │             │
               ├─ RS-003 (next.js) ──── RS-016 (admin shell)  │                         │             │
               │                   └─── RS-017 (vercel)       │                         ▼             │
               │                                              │                    RS-022 (auth)      │
               └─ RS-006 (supabase) ─┬─ RS-007 (schema) ──┐  │                    RS-023 (splash)    │
                                     │                     │  │                         │             │
                                     ├─ RS-008 (auth cfg)  │  │                         │             │
                                     │                     │  │  RS-019 (welcome) ◀─────┘             │
                                     ├─ RS-009 (storage)   │  │  RS-020 (phone) ◀─────────────────────┤
                                     │                     │  │  RS-021 (otp) ◀── RS-020              │
                                     └─ RS-018 (bcv fn)    │  │                                       │
                                                           │  │  RS-024 (camera) ─────────────────┐   │
               RS-004 (CI) ◀── RS-002 + RS-003             │  │  RS-025 (ml kit) ─────────────┐   │   │
               RS-005 (signing) ◀── RS-002                 │  │                               │   │   │
               RS-010 (seed) ◀── RS-007                    │  │  RS-026 (cédula parser) ◀─────┤   │   │
               RS-015 (utils) ◀── RS-011                   │  │  RS-029 (carnet parser) ◀─────┘   │   │
                                                           │  │                                   │   │
                                                           │  │  RS-027 (scan cédula) ◀───────────┼───┘
                                                           │  │  RS-028 (confirm id) ◀── RS-027   │
                                                           │  │  RS-030 (scan carnet) ◀───────────┘
                                                           │  │  RS-031 (confirm vehicle) ◀── RS-030
                                                           │  │
                                                           │  │  RS-032 (save) ◀── RS-007 + RS-009 + RS-014
                                                           │  │  RS-033 (cache) ◀── RS-032
                                                           ▼  ▼
                                                    RS-034, RS-035, RS-036 (tests)
                                                    RS-037 (docs)
```

---

# Sprint Velocity Notes

| Sprint | Total Points | Notes |
|---|---|---|
| Sprint 0 | 47 | Foundation work — high parallelization possible (backend + Flutter + admin are independent). Achievable in 3 focused days for a 1-2 person team. |
| Sprint 1 | 69 | Feature-heavy. Camera + OCR are the highest-risk items (hardware-dependent). Parser accuracy is iterative. If velocity is too high, defer RS-033 (offline caching), RS-036 (integration test), RS-037 (docs) to Sprint 2 buffer day. |

**Recommended Sprint 1 stretch cut line** (if running behind):
- P0 issues: 48 points (core functionality, must ship)
- P1 issues: 16 points (quality, very important)
- P2 issues: 5 points (can slide to Sprint 2 without blocking Sprint 2 work)
