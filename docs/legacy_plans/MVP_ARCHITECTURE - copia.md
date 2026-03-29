# RuedaSeguro MVP — Architectural Blueprint

> **Version:** 1.0 — March 15, 2026
> **Status:** Ready for implementation
> **Target:** Production-grade MVP for pitching to insurance carriers and onboarding real users

---

## 1. Executive Summary

RuedaSeguro is a B2B2C InsurTech platform that enables Venezuelan motorcycle riders to purchase mandatory RCV insurance in under 60 seconds and receive parametric "Stabilization Payments" within 15 minutes of a verified crash. This document defines the **MVP architecture** — a production-ready first version that delivers real value to riders and insurance carriers while maintaining a clear migration path to the enterprise-grade system described in the research documents.

**MVP Scope:** Fast onboarding via OCR, digital policy issuance, Pago Móvil payment collection, digital policy cards, BCV exchange rate integration, basic claims flow, and a B2B admin portal for insurance carriers.

**Cost Target:** $0/month for infrastructure during the first weeks (free tiers), scaling to <$50/month as users grow.

---

## 2. MVP Philosophy

### 2.1 Guiding Principles

1. **Ship fast, iterate faster.** The MVP must be deployable within weeks, not months. Every architectural decision optimizes for speed-to-market without sacrificing the ability to scale.
2. **Free-tier first, pay later.** Use services with generous free tiers (Supabase, Vercel, Google ML Kit). When traffic demands it, upgrade — never before.
3. **Prepare the upgrade path.** Every component is chosen so that it can be swapped for an enterprise-grade equivalent without rewriting core logic. PostgreSQL now → Aurora later. On-device OCR now → Textract/PaddleOCR later. SHA-256 hashes now → Polygon NFTs later.
4. **Real value from day one.** The app must issue a real, compliant digital insurance policy that a rider can show to a traffic officer. Everything else is secondary.
5. **Offline-resilient by default.** Venezuela has intermittent connectivity. The app must function offline for core features (viewing policy, caching data).

### 2.2 What "MVP" Means for RuedaSeguro

| Category | In MVP | Deferred |
|---|---|---|
| **Onboarding** | OCR scan of Cédula + Carnet de Circulación | Biometric identity verification |
| **Policy Issuance** | RCV digital policy with PDF + SHA-256 hash | NFT minting on Polygon (Phase 1.5) |
| **Payments** | Pago Móvil manual reference verification | C2P pull-based API (Phase 1.5) |
| **Claims** | Manual claims submission with photo evidence | Automatic crash detection + SLI (Phase 2) |
| **Telemetry** | None | Accelerometer/gyroscope tracking (Phase 2) |
| **Blockchain** | SHA-256 hash of policy stored in DB | ERC-721 NFT on Polygon (Phase 1.5) |
| **AI** | None | LLM liability analysis (Phase 3) |
| **B2B Portal** | Web dashboard for carriers | Grafana-level analytics (Phase 2) |
| **Infrastructure** | Supabase free tier | AWS Graviton4 / Aurora (at scale) |

---

## 3. Tension Resolutions

The 8 research documents surfaced several architectural tensions. Here is the definitive resolution for each:

### 3.1 Infrastructure: IBM Power vs. AWS vs. Supabase

**Decision: Supabase (free tier) → AWS (Graviton4 + Aurora) → IBM Power (only if proven necessary)**

- IBM PowerVS is enterprise infrastructure for 150k+ policies. A startup with 0 users doesn't need 3.7x faster random access patterns. It needs $0/month hosting.
- AWS Graviton4 + Aurora is the right target for Phase 2 (10k+ policies). It provides 40% better price-performance than x86 and seamless scaling.
- Supabase (PostgreSQL under the hood) is the perfect MVP backend: free tier includes 500MB database, 1GB storage, 50k monthly active users, Edge Functions, Auth, and Realtime subscriptions. When we outgrow it, migrating from Supabase PostgreSQL to Aurora PostgreSQL is a straightforward database migration.
- IBM Power is deferred indefinitely. The research documents cite it for raw transactional throughput, but Aurora PostgreSQL handles the concurrency levels we'll see for years. If we ever process 100k+ simultaneous policy updates, we reassess.

### 3.2 OCR Provider: AWS Textract vs. Google Cloud Vision vs. PaddleOCR

**Decision: Google ML Kit (free, on-device) → PaddleOCR (self-hosted) → AWS Textract (at enterprise scale)**

- Google ML Kit runs directly on the smartphone. Zero API cost. Zero latency. No network dependency. For Venezuelan cédulas and carnets de circulación, on-device text recognition is sufficient with post-processing regex patterns.
- If accuracy is insufficient for certain document types, PaddleOCR (167x cheaper than Textract) can be deployed as a Supabase Edge Function or sidecar.
- AWS Textract is the enterprise fallback. At $1.50/1000 pages, it only makes sense when accuracy requirements justify the cost (complex multi-language documents, damaged documents).

### 3.3 Database: IBM DB2 vs. Aurora PostgreSQL vs. Supabase

**Decision: Supabase PostgreSQL (free) → Amazon Aurora PostgreSQL (at scale). Skip DB2.**

- All the documents' data models are relational and map cleanly to PostgreSQL. There is no DB2-specific feature that justifies the vendor lock-in or cost.
- Supabase PostgreSQL supports JSON/JSONB natively (replacing DB2's JSON support), full-text search, and Row Level Security for multi-tenant B2B isolation.
- Time-series telemetry data (Phase 2) will use **TimescaleDB** (a PostgreSQL extension) rather than a separate InfluxDB instance. This keeps the stack unified. TimescaleDB is available on Supabase and Aurora.

### 3.4 Blockchain: Polygon NFT from Day 1 vs. Deferred

**Decision: SHA-256 policy hashes stored in PostgreSQL now → Polygon ERC-721 minting in Phase 1.5**

- Blockchain provides trust/immutability, but the MVP needs to prove product-market fit first. A SHA-256 hash of the policy PDF, stored in the database and printed on the digital policy card, provides verifiable document integrity without blockchain complexity.
- The data model includes all EIP-1523 metadata fields from day one. When we add Polygon minting, it's a matter of calling a smart contract with data that already exists.
- Polygon mainnet gas fees are <$0.01 per mint, so cost isn't the barrier — complexity and development time are. We prioritize shipping the core product.

### 3.5 Payments: C2P API vs. Manual Verification

**Decision: Manual Pago Móvil reference verification → C2P API integration (Phase 1.5)**

- The C2P API (Mercantil, Banesco) requires commercial agreements, API keys, and AES/ECB/PKCS5Padding encryption integration. This is a multi-week integration that shouldn't block the MVP launch.
- For MVP: the rider makes a standard Pago Móvil P2P transfer to RuedaSeguro's bank account, enters the reference number in the app, and the admin verifies it. This is how most Venezuelan digital commerce works today — users understand the flow.
- The payment record stores all fields needed for future C2P integration (bank_code, phone, cedula, amount_ves, amount_usd, exchange_rate, reference).

### 3.6 AI Integration Depth: 5-Layer Architecture vs. No AI

**Decision: No AI in MVP. Design the architecture to accommodate AI at each layer in the future.**

- Document 7's 5-layer model (NeMo Guardrails, AIOps, 93% automated liability) describes a Year 3-5 vision. Building AI into a product with 0 users generates zero value.
- The MVP architecture uses clean separation of concerns (Edge → API → Logic → Storage → Compute) that naturally maps to the 5-layer model. Adding AI later means adding new services at specific layers, not refactoring.

### 3.7 Naming: "Quasarhub" vs. "RuedaSeguro"

**Decision: RuedaSeguro is the brand. Quasarhub was an earlier working name.**

Document 8 (Startup Insurance Analysis) evaluates the original blueprint under the name "Quasarhub." All subsequent documents use "RuedaSeguro." The brand is RuedaSeguro.

### 3.8 anomaly_queue Schema: With or Without raw_data_blob

**Decision: Include raw_data_blob in the schema design. Implement when telemetry is activated (Phase 2).**

The 3-second sensor window around an impact event is critical forensic evidence. The field must exist in the schema even if the telemetry collection code is not yet active.

### 3.9 Encryption Standards

**Decision: AES-256-GCM for all application data. AES/ECB/PKCS5Padding only for C2P bank API (mandated by Venezuelan banks).**

- ECB mode is cryptographically weak but is mandated by Mercantil Bank's C2P API specification. We comply with the bank's requirement but do NOT use ECB for any other purpose.
- All other encryption (data at rest, data in transit, document hashing) uses modern standards: AES-256-GCM, TLS 1.3, SHA-256.

---

## 4. Tech Stack

### 4.1 Stack Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENTS                                  │
│  ┌──────────────────┐    ┌──────────────────────────────────┐   │
│  │  Flutter Mobile   │    │  Next.js Admin Portal (B2B)      │   │
│  │  (Android + iOS)  │    │  (Insurance Carrier Dashboard)   │   │
│  │  Rider-facing app │    │  Hosted on Vercel                │   │
│  └────────┬─────────┘    └──────────────┬───────────────────┘   │
│           │                              │                       │
└───────────┼──────────────────────────────┼───────────────────────┘
            │         HTTPS/WSS           │
┌───────────┼──────────────────────────────┼───────────────────────┐
│           ▼          SUPABASE            ▼                       │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    Supabase Platform                     │    │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌───────────┐  │    │
│  │  │   Auth   │ │ Database │ │ Storage  │ │   Edge    │  │    │
│  │  │  (GoTrue)│ │(Postgres)│ │  (S3)    │ │ Functions │  │    │
│  │  │          │ │          │ │          │ │  (Deno)   │  │    │
│  │  │ Phone OTP│ │ RLS +    │ │ Policy   │ │ BCV Rate  │  │    │
│  │  │ Email    │ │ Multi-   │ │ PDFs     │ │ PDF Gen   │  │    │
│  │  │ OAuth    │ │ tenant   │ │ Photos   │ │ Webhooks  │  │    │
│  │  └──────────┘ └──────────┘ └──────────┘ └───────────┘  │    │
│  │  ┌──────────────────────────────────────────────────┐   │    │
│  │  │              Realtime (WebSockets)                │   │    │
│  │  │  Live policy status, payment confirmations       │   │    │
│  │  └──────────────────────────────────────────────────┘   │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │              External Integrations                      │    │
│  │  ┌──────────┐ ┌──────────────┐ ┌────────────────────┐  │    │
│  │  │ BCV API  │ │ Pago Móvil   │ │ Polygon (Future)   │  │    │
│  │  │ Exchange │ │ C2P (Future) │ │ ERC-721 NFT Mint   │  │    │
│  │  │ Rate     │ │              │ │                    │  │    │
│  │  └──────────┘ └──────────────┘ └────────────────────┘  │    │
│  └─────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────┘
```

### 4.2 Component Selection

| Component | MVP Choice | Cost (MVP) | Enterprise Upgrade Path | Rationale |
|---|---|---|---|---|
| **Mobile App** | Flutter 3.x | Free | Same | Cross-platform, single codebase, mature ecosystem |
| **State Management** | Riverpod | Free | Same | Compile-safe, testable, scales well |
| **Local DB** | SQLite (sqflite) | Free | Same | ACID-compliant, Store & Forward ready |
| **OCR** | Google ML Kit | Free | PaddleOCR → Textract | On-device, zero API cost, offline-capable |
| **Backend** | Supabase | Free tier | Aurora PostgreSQL | PostgreSQL-based, auth + storage + realtime included |
| **Database** | Supabase PostgreSQL | Free (500MB) | Aurora PostgreSQL (Graviton4) | Standard SQL, RLS for multi-tenancy, JSONB support |
| **Auth** | Supabase Auth (GoTrue) | Free (50k MAU) | Same or Auth0 | Phone OTP, magic links, JWT-based |
| **File Storage** | Supabase Storage | Free (1GB) | AWS S3 | S3-compatible API, same interface |
| **Edge Functions** | Supabase Edge Functions (Deno) | Free (500k invocations) | AWS Lambda | Lightweight serverless for BCV, PDF generation |
| **Admin Portal** | Next.js 15 + shadcn/ui | Free | Same | Fast to build dashboards, Vercel free hosting |
| **Admin Hosting** | Vercel | Free tier | Same | Zero-config deploys, edge network |
| **PDF Generation** | Flutter `pdf` package | Free | Server-side (Deno/Node) | Client-side generation, upload to Storage |
| **Push Notifications** | Firebase Cloud Messaging | Free | Same | Industry standard, Flutter integration |
| **Exchange Rate** | BCV scraping (Edge Function) | Free | Dedicated API | Community libraries exist (jrafaaael/cbv) |
| **CI/CD** | GitHub Actions | Free (2000 min/month) | Same | Standard, well-supported |
| **Monitoring** | Supabase Dashboard + Sentry Free | Free | Datadog/Grafana | Basic but sufficient for MVP |

### 4.3 Key Flutter Packages

```yaml
dependencies:
  # Core
  flutter_riverpod: ^2.x          # State management
  go_router: ^14.x                # Navigation/routing
  supabase_flutter: ^2.x          # Supabase SDK (auth, db, storage, realtime)

  # OCR & Camera
  google_mlkit_text_recognition: ^0.x  # On-device OCR (free)
  camera: ^0.x                    # Camera access
  image_picker: ^1.x              # Photo selection

  # Local Storage
  sqflite: ^2.x                   # SQLite for offline data
  shared_preferences: ^2.x       # Simple key-value storage
  hive: ^2.x                     # Fast local cache (exchange rates, user prefs)

  # Security
  local_auth: ^2.x               # Fingerprint/FaceID
  flutter_secure_storage: ^9.x   # Encrypted storage for tokens
  crypto: ^3.x                   # SHA-256 hashing

  # Connectivity & Network
  connectivity_plus: ^6.x        # Network state monitoring
  dio: ^5.x                      # HTTP client with interceptors

  # PDF & Documents
  pdf: ^3.x                      # PDF generation
  printing: ^5.x                 # PDF preview/share
  share_plus: ^9.x               # Share policy card

  # UI
  flutter_animate: ^4.x          # Micro-interactions
  shimmer: ^3.x                  # Loading skeletons
  cached_network_image: ^3.x     # Image caching
  fl_chart: ^0.x                 # Charts (safety score, etc.)

  # Utils
  intl: ^0.x                     # i18n, date/number formatting
  uuid: ^4.x                     # UUID generation for idempotency
  permission_handler: ^11.x      # Runtime permissions
```

---

## 5. Data Model

### 5.1 Entity Relationship Overview

```
carriers (B2B insurance companies)
  │
  ├── carrier_users (admin portal users)
  │
  └── policies ────── policy_types
        │
        ├── payments
        │
        └── claims
              │
              └── claim_evidence (photos, docs)

profiles (riders) ──── vehicles
  │
  ├── documents (scanned IDs, registrations)
  │
  └── policies

exchange_rates (BCV rate cache)

audit_log (all state changes)
```

### 5.2 Database Schema (PostgreSQL / Supabase)

```sql
-- ============================================================
-- ENUMS
-- ============================================================

CREATE TYPE policy_status AS ENUM (
  'draft',          -- Policy created but not paid
  'pending_payment', -- Awaiting payment verification
  'active',         -- Paid and active
  'expired',        -- Past coverage_end date
  'claimed',        -- Claim has been filed and settled
  'cancelled'       -- Manually cancelled
);

CREATE TYPE payment_status AS ENUM (
  'pending',        -- Payment submitted, awaiting verification
  'verified',       -- Payment confirmed by admin
  'rejected',       -- Payment rejected (invalid reference, etc.)
  'refunded'        -- Payment reversed
);

CREATE TYPE claim_status AS ENUM (
  'submitted',      -- Claim filed by rider
  'under_review',   -- Being reviewed by carrier
  'approved',       -- Claim approved, payout pending
  'paid',           -- Payout completed
  'rejected',       -- Claim denied
  'withdrawn'       -- Withdrawn by rider
);

CREATE TYPE document_type AS ENUM (
  'cedula',              -- National ID
  'carnet_circulacion',  -- Vehicle registration
  'license',             -- Driver's license
  'policy_pdf',          -- Generated policy document
  'claim_photo',         -- Claim evidence photo
  'claim_document'       -- Claim supporting document
);

CREATE TYPE id_type AS ENUM ('V', 'E', 'J', 'P', 'G');

-- ============================================================
-- CARRIERS (B2B Insurance Companies)
-- ============================================================

CREATE TABLE carriers (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            TEXT NOT NULL,
  rif             TEXT UNIQUE NOT NULL,          -- Venezuelan tax ID (RIF)
  contact_email   TEXT NOT NULL,
  contact_phone   TEXT,
  logo_url        TEXT,
  is_active       BOOLEAN DEFAULT true,
  config          JSONB DEFAULT '{}',            -- Carrier-specific settings
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- CARRIER USERS (Admin portal users for insurance companies)
-- ============================================================

CREATE TABLE carrier_users (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_user_id    UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  carrier_id      UUID REFERENCES carriers(id) ON DELETE CASCADE,
  role            TEXT NOT NULL DEFAULT 'viewer', -- 'admin', 'manager', 'viewer'
  full_name       TEXT NOT NULL,
  email           TEXT NOT NULL,
  is_active       BOOLEAN DEFAULT true,
  created_at      TIMESTAMPTZ DEFAULT now(),
  UNIQUE(auth_user_id, carrier_id)
);

-- ============================================================
-- PROFILES (Riders / Policyholders)
-- ============================================================

CREATE TABLE profiles (
  id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  id_type         id_type NOT NULL DEFAULT 'V',
  id_number       TEXT NOT NULL,                 -- Cédula number
  first_name      TEXT NOT NULL,
  last_name       TEXT NOT NULL,
  phone           TEXT NOT NULL,                 -- Verified phone (from auth)
  email           TEXT,
  date_of_birth   DATE,
  address         TEXT,
  city            TEXT,
  state           TEXT,
  avatar_url      TEXT,
  -- Emergency contact
  emergency_name  TEXT,
  emergency_phone TEXT,
  emergency_relation TEXT,
  -- OCR metadata
  ocr_confidence  REAL,                          -- OCR extraction confidence score
  ocr_raw_data    JSONB,                         -- Raw OCR extraction for audit
  --
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- VEHICLES (Motorcycles)
-- ============================================================

CREATE TABLE vehicles (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id        UUID REFERENCES profiles(id) ON DELETE CASCADE,
  -- From OCR extraction of Carnet de Circulación
  plate           TEXT NOT NULL,
  brand           TEXT NOT NULL,                 -- e.g., Bera, Empire, Honda
  model           TEXT NOT NULL,
  year            INTEGER NOT NULL,
  color           TEXT,
  serial_motor    TEXT,                          -- Engine serial number
  serial_carroceria TEXT,                        -- Chassis/VIN
  vehicle_type    TEXT DEFAULT 'motorcycle',
  -- OCR metadata
  ocr_confidence  REAL,
  ocr_raw_data    JSONB,
  --
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- POLICY TYPES (Insurance products offered)
-- ============================================================

CREATE TABLE policy_types (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  carrier_id      UUID REFERENCES carriers(id) ON DELETE CASCADE,
  code            TEXT NOT NULL,                  -- 'RCV', 'PERSONAL_ACCIDENT', etc.
  name            TEXT NOT NULL,                  -- Display name
  description     TEXT,
  price_usd       DECIMAL(10,2) NOT NULL,         -- Price in USD (stable reference)
  coverage_amount_usd DECIMAL(10,2) NOT NULL,     -- Coverage limit in USD
  duration_days   INTEGER NOT NULL DEFAULT 365,    -- Coverage duration
  terms_url       TEXT,                           -- Link to terms & conditions
  is_active       BOOLEAN DEFAULT true,
  config          JSONB DEFAULT '{}',             -- Exclusions, conditions, etc.
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now(),
  UNIQUE(carrier_id, code)
);

-- ============================================================
-- POLICIES (Issued insurance policies)
-- ============================================================

CREATE TABLE policies (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  policy_number   TEXT UNIQUE NOT NULL,           -- Human-readable policy number
  profile_id      UUID REFERENCES profiles(id),
  vehicle_id      UUID REFERENCES vehicles(id),
  policy_type_id  UUID REFERENCES policy_types(id),
  carrier_id      UUID REFERENCES carriers(id),
  -- Coverage details
  status          policy_status NOT NULL DEFAULT 'draft',
  price_usd       DECIMAL(10,2) NOT NULL,
  price_ves       DECIMAL(20,2) NOT NULL,
  exchange_rate   DECIMAL(20,6) NOT NULL,          -- BCV rate at issuance
  rate_timestamp  TIMESTAMPTZ NOT NULL,            -- When the rate was fetched
  coverage_start  TIMESTAMPTZ,
  coverage_end    TIMESTAMPTZ,
  -- Document integrity (future blockchain-ready)
  pdf_url         TEXT,                            -- Supabase Storage URL
  document_hash   TEXT,                            -- SHA-256 hash of the policy PDF
  -- EIP-1523 ready fields (for future NFT minting)
  holder_address  TEXT,                            -- Ethereum address (when available)
  token_id        BIGINT,                          -- NFT token ID (when minted)
  tx_hash         TEXT,                            -- Polygon transaction hash (when minted)
  -- Metadata
  metadata        JSONB DEFAULT '{}',
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- PAYMENTS
-- ============================================================

CREATE TABLE payments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  policy_id       UUID REFERENCES policies(id),
  profile_id      UUID REFERENCES profiles(id),
  -- Payment details
  idempotency_key UUID UNIQUE NOT NULL,            -- Prevents duplicate payments
  amount_usd      DECIMAL(10,2) NOT NULL,
  amount_ves      DECIMAL(20,2) NOT NULL,
  exchange_rate   DECIMAL(20,6) NOT NULL,
  rate_timestamp  TIMESTAMPTZ NOT NULL,
  -- Pago Móvil fields (ready for C2P migration)
  payment_method  TEXT NOT NULL DEFAULT 'pago_movil_p2p',
  bank_code       TEXT,                             -- 4-digit bank code
  phone_number    TEXT,                             -- Payer phone
  reference       TEXT,                             -- Pago Móvil reference number
  -- Status
  status          payment_status NOT NULL DEFAULT 'pending',
  verified_at     TIMESTAMPTZ,
  verified_by     UUID REFERENCES carrier_users(id),
  rejection_reason TEXT,
  -- Metadata
  metadata        JSONB DEFAULT '{}',
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- CLAIMS
-- ============================================================

CREATE TABLE claims (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  claim_number    TEXT UNIQUE NOT NULL,
  policy_id       UUID REFERENCES policies(id),
  profile_id      UUID REFERENCES profiles(id),
  -- Incident details
  incident_date   TIMESTAMPTZ NOT NULL,
  incident_location_lat DECIMAL(10,7),
  incident_location_lng DECIMAL(10,7),
  incident_address TEXT,
  incident_description TEXT NOT NULL,
  -- Status
  status          claim_status NOT NULL DEFAULT 'submitted',
  -- Settlement (for future SLI)
  settlement_amount_usd DECIMAL(10,2),
  settlement_amount_ves DECIMAL(20,2),
  settlement_exchange_rate DECIMAL(20,6),
  settlement_tx_hash TEXT,                          -- Blockchain tx (future)
  -- Review
  reviewer_id     UUID REFERENCES carrier_users(id),
  review_notes    TEXT,
  reviewed_at     TIMESTAMPTZ,
  -- Telemetry data (Phase 2 - future)
  impact_magnitude REAL,                            -- 9G threshold data
  telemetry_data  JSONB,                            -- Sensor snapshot
  --
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- CLAIM EVIDENCE (Photos and documents)
-- ============================================================

CREATE TABLE claim_evidence (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  claim_id        UUID REFERENCES claims(id) ON DELETE CASCADE,
  file_url        TEXT NOT NULL,
  file_type       TEXT NOT NULL,                    -- 'image/jpeg', 'application/pdf'
  description     TEXT,
  uploaded_at     TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- DOCUMENTS (Scanned identity and vehicle documents)
-- ============================================================

CREATE TABLE documents (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id      UUID REFERENCES profiles(id) ON DELETE CASCADE,
  vehicle_id      UUID REFERENCES vehicles(id),
  doc_type        document_type NOT NULL,
  file_url        TEXT NOT NULL,                    -- Supabase Storage URL
  file_hash       TEXT,                             -- SHA-256 hash
  ocr_extracted   JSONB,                            -- Raw OCR output
  ocr_confidence  REAL,
  created_at      TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- EXCHANGE RATES (BCV rate cache)
-- ============================================================

CREATE TABLE exchange_rates (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  currency_pair   TEXT NOT NULL DEFAULT 'USD/VES',
  rate            DECIMAL(20,6) NOT NULL,
  source          TEXT NOT NULL DEFAULT 'BCV',
  fetched_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_official     BOOLEAN DEFAULT true,
  raw_response    JSONB
);

CREATE INDEX idx_exchange_rates_fetched ON exchange_rates(fetched_at DESC);

-- ============================================================
-- AUDIT LOG (All state changes for compliance)
-- ============================================================

CREATE TABLE audit_log (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  table_name      TEXT NOT NULL,
  record_id       UUID NOT NULL,
  action          TEXT NOT NULL,                    -- 'INSERT', 'UPDATE', 'DELETE'
  old_data        JSONB,
  new_data        JSONB,
  performed_by    UUID,                             -- auth.users.id
  performed_at    TIMESTAMPTZ DEFAULT now(),
  ip_address      TEXT,
  user_agent      TEXT
);

CREATE INDEX idx_audit_log_table ON audit_log(table_name, record_id);
CREATE INDEX idx_audit_log_time ON audit_log(performed_at DESC);

-- ============================================================
-- FUTURE: TELEMETRY (Phase 2 - anomaly_queue equivalent)
-- ============================================================
-- This table is designed but NOT created in MVP.
-- It implements the anomaly_queue from the Data Architecture doc.
--
-- CREATE TABLE telemetry_events (
--   id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--   profile_id      UUID REFERENCES profiles(id),
--   policy_id       UUID REFERENCES policies(id),
--   event_type      TEXT NOT NULL,                 -- 'IMPACT', 'BRAKE', 'ACCELERATION'
--   timestamp       TIMESTAMPTZ NOT NULL,          -- ISO 8601 from device
--   magnitude       REAL NOT NULL,                 -- Vector magnitude
--   raw_x           REAL,
--   raw_y           REAL,
--   raw_z           REAL,
--   raw_data_blob   BYTEA,                         -- 3-second sensor window
--   gps_lat         DECIMAL(10,7),
--   gps_lng         DECIMAL(10,7),
--   gps_speed       REAL,
--   bcv_rate        DECIMAL(20,6),
--   device_model    TEXT,
--   sync_lag_ms     INTEGER,                       -- Time between event and server receipt
--   created_at      TIMESTAMPTZ DEFAULT now()
-- );

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE claims ENABLE ROW LEVEL SECURITY;
ALTER TABLE claim_evidence ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Riders can only see their own data
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can view own vehicles"
  ON vehicles FOR SELECT USING (auth.uid() = owner_id);

CREATE POLICY "Users can insert own vehicles"
  ON vehicles FOR INSERT WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can view own policies"
  ON policies FOR SELECT USING (auth.uid() = profile_id);

CREATE POLICY "Users can view own payments"
  ON payments FOR SELECT USING (auth.uid() = profile_id);

CREATE POLICY "Users can view own claims"
  ON claims FOR SELECT USING (auth.uid() = profile_id);

CREATE POLICY "Users can insert own claims"
  ON claims FOR INSERT WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Users can view own claim evidence"
  ON claim_evidence FOR SELECT
  USING (claim_id IN (SELECT id FROM claims WHERE profile_id = auth.uid()));

CREATE POLICY "Users can view own documents"
  ON documents FOR SELECT USING (auth.uid() = profile_id);

-- Carrier users: access via carrier_id (implemented with a helper function)
-- CREATE FUNCTION get_user_carrier_id() ...
-- Carrier policies are accessible through the admin portal API, not direct RLS.

-- Policy types are public (readable by all authenticated users)
ALTER TABLE policy_types ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Policy types are viewable by all"
  ON policy_types FOR SELECT USING (is_active = true);

-- Exchange rates are public
ALTER TABLE exchange_rates ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Exchange rates are viewable by all"
  ON exchange_rates FOR SELECT USING (true);
```

### 5.3 Policy Number Generation

Policy numbers follow the format: `RS-{CARRIER_CODE}-{YEAR}{MONTH}-{SEQUENCE}`

Example: `RS-SCA-202604-00001` (RuedaSeguro, Seguros Caracas, April 2026, policy #1)

Generated via a PostgreSQL function:

```sql
CREATE FUNCTION generate_policy_number(p_carrier_id UUID)
RETURNS TEXT AS $$
DECLARE
  carrier_code TEXT;
  seq_num INTEGER;
  date_part TEXT;
BEGIN
  SELECT UPPER(LEFT(name, 3)) INTO carrier_code FROM carriers WHERE id = p_carrier_id;
  date_part := TO_CHAR(now(), 'YYYYMM');
  SELECT COALESCE(MAX(
    CAST(SPLIT_PART(policy_number, '-', 4) AS INTEGER)
  ), 0) + 1
  INTO seq_num
  FROM policies
  WHERE policy_number LIKE 'RS-' || carrier_code || '-' || date_part || '-%';

  RETURN 'RS-' || carrier_code || '-' || date_part || '-' || LPAD(seq_num::TEXT, 5, '0');
END;
$$ LANGUAGE plpgsql;
```

---

## 6. Core User Flows

### 6.1 Onboarding Flow (The "60-Second Nucleus")

```
┌──────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────┐
│ Welcome  │────▶│  Phone OTP   │────▶│  Scan Cédula │────▶│  Confirm │
│ Screen   │     │  (Supabase   │     │  (Google ML  │     │  Data    │
│          │     │   Auth)      │     │   Kit OCR)   │     │          │
└──────────┘     └──────────────┘     └──────────────┘     └────┬─────┘
                                                                 │
┌──────────┐     ┌──────────────┐     ┌──────────────┐          │
│  Home    │◀────│  Policy      │◀────│  Scan Carnet │◀─────────┘
│  Screen  │     │  Selection   │     │  Circulación │
│          │     │  + Payment   │     │  (OCR)       │
└──────────┘     └──────────────┘     └──────────────┘
```

**Detailed Steps:**

1. **Welcome Screen** — Value proposition: "Seguro de moto en 60 segundos. Liquidación inmediata en caso de accidente." Two buttons: "Registrarme" / "Ya tengo cuenta".

2. **Phone OTP** — User enters Venezuelan phone number (+58). Supabase Auth sends OTP via SMS. User enters 6-digit code. JWT issued.

3. **Scan Cédula** — Camera opens with overlay guide. Google ML Kit extracts text on-device. Regex patterns extract: nombre, apellido, cédula number, fecha de nacimiento. User reviews and corrects if needed. Image uploaded to Supabase Storage, OCR data saved.

4. **Scan Carnet de Circulación** — Same flow. Extracts: placa, marca, modelo, año, serial motor, serial carrocería, color. User confirms.

5. **Policy Selection** — Shows available RCV plans from partner carriers. Price shown in both USD and VES (BCV rate fetched in real-time). User selects plan.

6. **Payment** — Shows Pago Móvil instructions: bank name, phone number, cédula of RuedaSeguro account, amount in VES. User makes P2P payment externally, returns to app, enters reference number. Payment record created as "pending."

7. **Policy Issued** — Once payment is verified (manually by admin for MVP), policy status changes to "active." Push notification sent. Digital policy card available. PDF generated and stored.

### 6.2 OCR Processing Pipeline

```
Camera Frame
     │
     ▼
Google ML Kit (on-device)
     │
     ▼
Raw Text Blocks
     │
     ▼
Field Extraction Engine (Dart)
     │  ├── Cédula Parser
     │  │   ├── RegExp: r'[VEJPvejp]-?\s*(\d{6,9})'  → id_number
     │  │   ├── Name heuristics (UPPERCASE blocks)     → first_name, last_name
     │  │   └── Date pattern: dd/MM/yyyy               → date_of_birth
     │  │
     │  └── Carnet Parser
     │      ├── Plate: r'[A-Z]{2,3}\d{2,3}[A-Z]{2,3}' → plate
     │      ├── Brand/Model (keyword matching)          → brand, model
     │      ├── Year: r'(19|20)\d{2}'                  → year
     │      └── Serial patterns                        → serial_motor, serial_carroceria
     │
     ▼
Confidence Score (0.0 - 1.0)
     │
     ├── confidence >= 0.8 → Auto-fill, user confirms
     └── confidence < 0.8  → Manual entry fallback with OCR suggestions
```

### 6.3 Payment Flow (MVP — Pago Móvil P2P)

```
App shows payment details          User makes Pago Móvil
(bank, phone, amount VES)          transfer externally
         │                                  │
         ▼                                  ▼
User returns to app ──────────▶ Enters reference number
                                          │
                                          ▼
                               Payment record created
                               (status: 'pending')
                                          │
                                          ▼
                               Admin portal notification
                               (Supabase Realtime)
                                          │
                                          ▼
                               Admin verifies payment
                               against bank statement
                                          │
                                          ▼
                               Payment → 'verified'
                               Policy → 'active'
                                          │
                                          ▼
                               Push notification to rider
                               "¡Tu póliza está activa!"
```

**Future C2P Flow (Phase 1.5):**
```
User taps "Pagar" → App requests 4-digit temp code from user →
App calls C2P API (AES/ECB encrypted) → Bank debits account →
Payment verified automatically → Policy activated instantly
```

### 6.4 Claims Flow (MVP)

```
Rider taps "Reportar Siniestro"
         │
         ▼
Incident form:
  - Date/time (pre-filled)
  - Location (GPS auto-detect)
  - Description (text)
  - Photos (camera or gallery)
         │
         ▼
Claim submitted (status: 'submitted')
         │
         ▼
Carrier admin reviews in portal
  - View photos, description
  - View policy details
  - Approve or reject
         │
         ▼
Rider notified of decision
```

**Future SLI Flow (Phase 2):**
```
9G impact detected → Post-Crash Protocol → Oracle verification →
Smart contract payout → Pago Móvil C2P → Funds in 15 minutes
```

### 6.5 BCV Exchange Rate Integration

```
Supabase Edge Function (cron: every 30 min)
         │
         ▼
Scrape BCV website or call community API
(github.com/jrafaaael/cbv or similar)
         │
         ▼
Parse official USD/VES rate
         │
         ▼
INSERT INTO exchange_rates (rate, fetched_at, source)
         │
         ▼
Flutter app fetches latest rate before any transaction
via: supabase.from('exchange_rates').select().order('fetched_at').limit(1)
```

---

## 7. Flutter App Architecture

### 7.1 Project Structure

```
lib/
├── main.dart                          # Entry point, Supabase init
├── app/
│   ├── app.dart                       # MaterialApp with theme + router
│   ├── router.dart                    # GoRouter configuration
│   └── theme.dart                     # RuedaSeguro design system
│
├── core/
│   ├── constants/
│   │   ├── app_constants.dart         # 9G threshold, BCV URL, etc.
│   │   └── supabase_constants.dart    # Table names, bucket names
│   ├── errors/
│   │   ├── failures.dart              # Failure classes
│   │   └── exceptions.dart            # Custom exceptions
│   ├── network/
│   │   ├── connectivity_service.dart  # connectivity_plus wrapper
│   │   └── api_client.dart            # Dio instance with interceptors
│   ├── services/
│   │   ├── supabase_service.dart      # Supabase client singleton
│   │   ├── local_storage_service.dart # SQLite + Hive wrapper
│   │   └── notification_service.dart  # FCM setup
│   ├── utils/
│   │   ├── hash_utils.dart            # SHA-256 helpers
│   │   ├── currency_utils.dart        # VES/USD formatting
│   │   ├── date_utils.dart            # ISO 8601 helpers
│   │   └── validators.dart            # Cédula, phone, plate validators
│   └── theme/
│       ├── colors.dart                # Off-black, off-white, accent colors
│       ├── typography.dart            # Display fonts, body fonts
│       └── spacing.dart               # 4px grid system
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository.dart
│   │   ├── domain/
│   │   │   └── auth_state.dart
│   │   └── presentation/
│   │       ├── login_screen.dart        # Phone input
│   │       ├── otp_screen.dart          # OTP verification
│   │       └── widgets/
│   │
│   ├── onboarding/
│   │   ├── data/
│   │   │   ├── ocr_repository.dart      # ML Kit + field extraction
│   │   │   └── profile_repository.dart
│   │   ├── domain/
│   │   │   ├── ocr_result.dart
│   │   │   ├── cedula_parser.dart       # Regex extraction for cédula
│   │   │   └── carnet_parser.dart       # Regex extraction for carnet
│   │   └── presentation/
│   │       ├── scan_cedula_screen.dart
│   │       ├── confirm_identity_screen.dart
│   │       ├── scan_carnet_screen.dart
│   │       ├── confirm_vehicle_screen.dart
│   │       └── widgets/
│   │           ├── camera_overlay.dart   # Document alignment guide
│   │           └── ocr_field_card.dart   # Editable OCR result field
│   │
│   ├── policy/
│   │   ├── data/
│   │   │   ├── policy_repository.dart
│   │   │   ├── policy_type_repository.dart
│   │   │   └── pdf_generator.dart       # Policy PDF creation
│   │   ├── domain/
│   │   │   ├── policy.dart
│   │   │   └── policy_type.dart
│   │   └── presentation/
│   │       ├── policy_list_screen.dart   # My policies
│   │       ├── policy_detail_screen.dart # Full policy view
│   │       ├── policy_card_widget.dart   # Shareable digital card
│   │       ├── select_plan_screen.dart   # Choose RCV plan
│   │       └── widgets/
│   │
│   ├── payment/
│   │   ├── data/
│   │   │   ├── payment_repository.dart
│   │   │   └── exchange_rate_repository.dart
│   │   ├── domain/
│   │   │   ├── payment.dart
│   │   │   └── exchange_rate.dart
│   │   └── presentation/
│   │       ├── payment_instructions_screen.dart  # Pago Móvil details
│   │       ├── enter_reference_screen.dart       # Reference input
│   │       ├── payment_status_screen.dart        # Pending/verified
│   │       └── widgets/
│   │
│   ├── claims/
│   │   ├── data/
│   │   │   └── claims_repository.dart
│   │   ├── domain/
│   │   │   └── claim.dart
│   │   └── presentation/
│   │       ├── submit_claim_screen.dart
│   │       ├── claim_detail_screen.dart
│   │       ├── claim_list_screen.dart
│   │       └── widgets/
│   │
│   ├── home/
│   │   └── presentation/
│   │       ├── home_screen.dart          # Dashboard with active policy
│   │       └── widgets/
│   │           ├── policy_summary_card.dart
│   │           ├── quick_actions.dart    # "Reportar siniestro", "Ver póliza"
│   │           └── rate_ticker.dart      # Live BCV rate
│   │
│   └── profile/
│       └── presentation/
│           ├── profile_screen.dart
│           ├── edit_profile_screen.dart
│           └── settings_screen.dart
│
└── shared/
    ├── widgets/
    │   ├── rs_button.dart               # Primary/secondary buttons
    │   ├── rs_text_field.dart           # Styled input fields
    │   ├── rs_card.dart                 # Bento-grid card component
    │   ├── rs_loading.dart              # Shimmer/skeleton loader
    │   ├── rs_error.dart                # Error state with retry
    │   ├── rs_empty.dart                # Empty state illustrations
    │   ├── offline_banner.dart          # "Sin conexión" banner
    │   └── amount_display.dart          # USD + VES dual display
    └── providers/
        ├── auth_provider.dart
        ├── connectivity_provider.dart
        └── exchange_rate_provider.dart
```

### 7.2 Offline Strategy

The app must work without internet for essential features:

| Feature | Offline Behavior |
|---|---|
| **View active policy** | Cached locally in SQLite. Always available. |
| **View policy card** | Cached. Can be shown to traffic officers offline. |
| **View profile/vehicle** | Cached locally. |
| **Submit claim** | Queued in SQLite. Synced when online (Store & Forward). |
| **Scan documents (OCR)** | Fully offline (Google ML Kit is on-device). |
| **Make payment** | Requires internet (external bank transfer). |
| **Purchase policy** | Requires internet. |
| **View BCV rate** | Last known rate cached with timestamp. |

Implementation: The `local_storage_service.dart` maintains a SQLite mirror of critical data. On each successful API response, data is cached. The `connectivity_provider` monitors network state via `connectivity_plus` and triggers sync when reconnected.

### 7.3 UI Design System

Following the UI/UX Architecture Guide (Document 6):

**Color Palette:**
- Primary: Deep blue (#1A237E) — trust, stability
- Accent: Amber (#FFB300) — urgency, action
- Success: Green (#2E7D32)
- Error: Red (#C62828)
- Background: Off-white (#FAFAFA) — avoids glare under sunlight
- Surface: Off-black (#212121) — high contrast for outdoor readability

**Typography:**
- Headings: Bold, display weight — immediately perceivable while moving
- Body: Medium weight, 16sp minimum — readable under vibration
- Numbers: Monospace for reference numbers and amounts

**Ergonomics:**
- All primary actions in the bottom third of screen ("Easy Zone" for thumb)
- Minimum tap target: 48x48dp (glove-friendly)
- High-contrast mode support
- One-handed navigation for all critical flows

**Emergency Mode (Future - Phase 2):**
- Red/flashing high-contrast dashboard
- Large buttons, minimal text
- Two-step confirmation for emergency actions
- Haptic feedback for confirmations

---

## 8. Admin Portal Architecture (B2B)

### 8.1 Tech Stack

- **Framework:** Next.js 15 (App Router)
- **UI:** shadcn/ui + Tailwind CSS
- **Auth:** Supabase Auth (email + password for carrier admins)
- **Data:** Supabase JS client with service role key for admin operations
- **Hosting:** Vercel (free tier)
- **Charts:** Recharts (lightweight charting)

### 8.2 Portal Pages

```
/login                    → Carrier admin login
/dashboard                → Overview: active policies, revenue, claims
/dashboard/policies       → Policy list with filters (status, date, vehicle)
/dashboard/policies/[id]  → Policy detail (rider info, vehicle, payment, PDF)
/dashboard/payments       → Payment verification queue
/dashboard/payments/[id]  → Verify/reject payment (with reference lookup)
/dashboard/claims         → Claims review queue
/dashboard/claims/[id]    → Claim detail with evidence, approve/reject
/dashboard/riders         → Rider directory
/dashboard/analytics      → Basic charts (policies/day, revenue, claims ratio)
/dashboard/settings       → Carrier profile, user management
```

### 8.3 Admin API (Supabase Edge Functions)

These Edge Functions bypass RLS and use the service role key:

| Function | Method | Purpose |
|---|---|---|
| `/functions/v1/admin/verify-payment` | POST | Verify a pending payment, activate policy |
| `/functions/v1/admin/reject-payment` | POST | Reject a payment with reason |
| `/functions/v1/admin/review-claim` | POST | Approve/reject a claim |
| `/functions/v1/admin/carrier-stats` | GET | Aggregate stats for carrier dashboard |
| `/functions/v1/bcv-rate` | GET | Fetch and cache latest BCV rate (cron) |
| `/functions/v1/generate-policy-pdf` | POST | Generate policy PDF server-side (optional) |

---

## 9. Supabase Edge Functions

### 9.1 BCV Exchange Rate Fetcher

```typescript
// supabase/functions/bcv-rate/index.ts
// Triggered every 30 minutes via cron or on-demand

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async () => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  // Fetch BCV rate (use community API or direct scrape)
  const response = await fetch("https://pydolarve.org/api/v2/dollar?monitor=bcv");
  const data = await response.json();
  const rate = data?.monitors?.usd?.price;

  if (!rate) {
    return new Response(JSON.stringify({ error: "Failed to fetch rate" }), {
      status: 500,
    });
  }

  const { error } = await supabase.from("exchange_rates").insert({
    currency_pair: "USD/VES",
    rate: rate,
    source: "BCV",
    fetched_at: new Date().toISOString(),
    is_official: true,
    raw_response: data,
  });

  return new Response(JSON.stringify({ rate, error }), {
    headers: { "Content-Type": "application/json" },
  });
});
```

### 9.2 Payment Verification

```typescript
// supabase/functions/admin/verify-payment/index.ts

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  const { payment_id, verified_by } = await req.json();

  // 1. Update payment status
  const { data: payment, error: payError } = await supabase
    .from("payments")
    .update({
      status: "verified",
      verified_at: new Date().toISOString(),
      verified_by,
    })
    .eq("id", payment_id)
    .select("policy_id")
    .single();

  if (payError) return new Response(JSON.stringify({ error: payError }), { status: 400 });

  // 2. Activate the policy
  const now = new Date();
  const { data: policyType } = await supabase
    .from("policies")
    .select("policy_type_id, policy_types(duration_days)")
    .eq("id", payment.policy_id)
    .single();

  const durationDays = policyType?.policy_types?.duration_days || 365;
  const coverageEnd = new Date(now.getTime() + durationDays * 24 * 60 * 60 * 1000);

  await supabase
    .from("policies")
    .update({
      status: "active",
      coverage_start: now.toISOString(),
      coverage_end: coverageEnd.toISOString(),
    })
    .eq("id", payment.policy_id);

  // 3. Log audit trail
  await supabase.from("audit_log").insert({
    table_name: "payments",
    record_id: payment_id,
    action: "VERIFY_PAYMENT",
    new_data: { status: "verified", policy_activated: true },
    performed_by: verified_by,
  });

  // 4. TODO: Send push notification to rider

  return new Response(JSON.stringify({ success: true }), {
    headers: { "Content-Type": "application/json" },
  });
});
```

---

## 10. Security Architecture

### 10.1 Authentication

| Layer | Mechanism |
|---|---|
| **Rider App** | Phone OTP via Supabase Auth → JWT (access + refresh tokens) |
| **Admin Portal** | Email + password via Supabase Auth → JWT + carrier_id verification |
| **API** | JWT verification on every request (Supabase handles this) |
| **Local** | Biometric unlock (local_auth) for app re-entry; tokens in flutter_secure_storage |

### 10.2 Data Protection

| Concern | Implementation |
|---|---|
| **Data in transit** | TLS 1.3 (Supabase default) |
| **Data at rest** | Supabase encrypts at rest (AES-256) |
| **Local data** | flutter_secure_storage for tokens; SQLite for non-sensitive cache |
| **Document hashes** | SHA-256 of every policy PDF stored alongside the document |
| **PII handling** | Minimal PII collection; OCR raw data stored for audit only |
| **Multi-tenancy** | Row Level Security (RLS) isolates data per user and per carrier |

### 10.3 Idempotency

Every payment and policy creation uses a client-generated **UUID v4 idempotency key**:
- Generated in Flutter before the request
- Stored as a UNIQUE column in the `payments` table
- If a duplicate key is received, the server returns the existing record instead of creating a new one
- Prevents double-charging during network retries

---

## 11. Deployment & Distribution

### 11.1 Infrastructure

| Component | Platform | Free Tier Limits |
|---|---|---|
| **Database + Auth + Storage** | Supabase | 500MB DB, 1GB storage, 50k MAU |
| **Edge Functions** | Supabase | 500k invocations/month |
| **Admin Portal** | Vercel | 100GB bandwidth, serverless functions |
| **Push Notifications** | Firebase Cloud Messaging | Unlimited |
| **Error Tracking** | Sentry | 5k events/month |
| **CI/CD** | GitHub Actions | 2000 min/month |

### 11.2 App Distribution

**Phase 0 (First 2 weeks):** Direct APK distribution
- Build signed APK via `flutter build apk --release`
- Distribute via WhatsApp / direct download link
- Fastest path to real users for testing

**Phase 1 (Week 3+):** Google Play Store
- Create Play Console listing ($25 one-time fee)
- Internal testing track first, then production
- Play Store provides auto-updates and trust

**iOS:** Deferred to after Android validation. When ready:
- TestFlight for beta users
- App Store submission

### 11.3 CI/CD Pipeline

```yaml
# .github/workflows/build.yml
name: Build & Deploy

on:
  push:
    branches: [main]

jobs:
  build-flutter:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      - run: flutter pub get
      - run: flutter test
      - run: flutter build apk --release
      - uses: actions/upload-artifact@v4
        with:
          name: release-apk
          path: build/app/outputs/flutter-apk/app-release.apk

  deploy-admin:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          working-directory: ./admin-portal
```

---

## 12. Migration Path: MVP → Scale → Enterprise

### Phase 1.5 — Growth (1k-10k policies)

| Component | Change | Trigger |
|---|---|---|
| **Payments** | Integrate Pago Móvil C2P API (Mercantil/Banesco) | When manual verification becomes bottleneck |
| **Blockchain** | Deploy Solidity smart contract to Polygon mainnet; mint policies as ERC-721 NFTs | When pitching trust/transparency to carriers |
| **OCR** | Add PaddleOCR server-side fallback for low-confidence scans | When on-device OCR accuracy is insufficient |
| **Notifications** | Add SMS fallback for push notifications (Venezuela has unreliable push) | When user engagement data shows missed notifications |
| **Database** | Upgrade Supabase plan (Pro: $25/month, 8GB DB, 100GB storage) | When approaching free tier limits |

### Phase 2 — Scale (10k-50k policies)

| Component | Change | Trigger |
|---|---|---|
| **Infrastructure** | Migrate to AWS: Aurora PostgreSQL (Graviton4) + S3 + Lambda | When Supabase performance limits are hit |
| **Telemetry** | Activate accelerometer/gyroscope in Flutter app; implement Store & Forward with anomaly_queue | When carrier partners want risk scoring |
| **Time-Series DB** | Add TimescaleDB extension (or standalone InfluxDB) for telemetry | When telemetry volume requires optimized storage |
| **SLI** | Implement Smart Liquidation System: 9G detection → Oracle verification → auto-payout | Core product differentiator for Phase 2 |
| **Assistance Oracles** | Integrate Venemergencias / Angeles de las Vías APIs | Required for SLI verification |
| **Admin Portal** | Add Grafana dashboards for real-time analytics | When carriers demand advanced analytics |
| **DR** | AWS Multi-AZ deployment + Elastic Disaster Recovery | When SLA commitments require it |

### Phase 3 — Enterprise (50k-150k policies)

| Component | Change | Trigger |
|---|---|---|
| **AI** | LLM-based liability determination; accident narrative analysis | When claims volume justifies AI investment |
| **Hybrid Payouts** | Parametric + Indemnity two-layer model | When product sophistication demands it |
| **Infrastructure** | Evaluate IBM PowerVS for transactional core (if Aurora bottlenecks) | Likely unnecessary with Aurora scaling |
| **Compliance** | Full ACORD Next-Gen API standards for B2B interoperability | When integrating with international reinsurers |
| **AIOps** | AI-driven monitoring, anomaly detection, capacity planning | When system complexity demands it |

---

## 13. Cost Analysis

### 13.1 Month 0-3 (MVP Launch)

| Item | Cost |
|---|---|
| Supabase (free tier) | $0 |
| Vercel (free tier) | $0 |
| Firebase FCM | $0 |
| Google ML Kit | $0 |
| GitHub Actions | $0 |
| Sentry (free tier) | $0 |
| Google Play Console | $25 (one-time) |
| Domain name (ruedaseguro.com) | ~$12/year |
| **Total** | **~$37 one-time + $1/month** |

### 13.2 Month 4-12 (Growth)

| Item | Cost |
|---|---|
| Supabase Pro | $25/month |
| Vercel Pro (if needed) | $20/month |
| SMS OTP costs (~1000 users) | ~$10/month |
| Polygon gas fees (~1000 NFTs) | ~$1/month |
| **Total** | **~$56/month** |

### 13.3 Year 2+ (Scale)

| Item | Cost |
|---|---|
| AWS Aurora + S3 + Lambda | ~$200-500/month |
| Dedicated SMS provider | ~$50/month |
| Monitoring (Datadog/Grafana) | ~$50/month |
| **Total** | **~$300-600/month** |

---

## 14. Development Phases & Timeline

### Sprint 0 — Project Setup (Days 1-3)
- [ ] Initialize Flutter project with folder structure
- [ ] Initialize Next.js admin portal
- [ ] Create Supabase project; apply database migrations
- [ ] Configure Supabase Auth (phone OTP)
- [ ] Set up GitHub repo + CI/CD
- [ ] Configure Supabase Storage buckets (documents, policies)
- [ ] Deploy admin portal shell to Vercel

### Sprint 1 — Authentication & Onboarding (Days 4-10)
- [ ] Phone OTP login/register flow
- [ ] Cédula OCR scanning with Google ML Kit
- [ ] Cédula field extraction (regex parser)
- [ ] Profile creation from OCR data
- [ ] Carnet de Circulación OCR scanning
- [ ] Vehicle creation from OCR data
- [ ] Document image upload to Supabase Storage
- [ ] Offline caching of profile + vehicle data

### Sprint 2 — Policy & Payment (Days 11-17)
- [ ] Policy type listing (fetch from Supabase)
- [ ] BCV exchange rate Edge Function + cron
- [ ] Price display in USD + VES
- [ ] Policy creation flow (select plan → create draft policy)
- [ ] Pago Móvil payment instructions screen
- [ ] Reference number entry + payment record creation
- [ ] Payment status tracking (pending → verified)
- [ ] Admin: payment verification queue + verify/reject actions

### Sprint 3 — Policy Card & Claims (Days 18-24)
- [ ] Policy PDF generation (Flutter `pdf` package)
- [ ] SHA-256 hash calculation and storage
- [ ] Digital policy card (shareable widget)
- [ ] Policy detail screen with status, dates, coverage
- [ ] Claims submission flow (form + photo upload)
- [ ] Admin: claims review queue
- [ ] Push notifications (payment verified, claim update)
- [ ] Offline: cache active policy for offline viewing

### Sprint 4 — Admin Portal & Polish (Days 25-30)
- [ ] Admin dashboard with key metrics
- [ ] Policy list with search and filters
- [ ] Rider directory
- [ ] Basic analytics (policies/day, revenue chart)
- [ ] App polish: loading states, error handling, empty states
- [ ] Offline banner and sync indicators
- [ ] Testing: unit tests for OCR parsers, payment flow
- [ ] Build signed APK for distribution

### Post-Launch Continuous
- [ ] User feedback collection and iteration
- [ ] Carrier onboarding workflow
- [ ] Payment reconciliation tools
- [ ] Policy renewal flow
- [ ] Performance monitoring and optimization

---

## 15. Repository Structure

```
RuedaSeguro/
├── README.md
├── MVP_ARCHITECTURE.md              # This document
├── research_docs/                    # 8 research documents
│
├── mobile/                           # Flutter app
│   ├── pubspec.yaml
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app/
│   │   ├── core/
│   │   ├── features/
│   │   └── shared/
│   ├── test/
│   ├── android/
│   └── ios/
│
├── admin-portal/                     # Next.js B2B dashboard
│   ├── package.json
│   ├── next.config.js
│   ├── src/
│   │   ├── app/
│   │   ├── components/
│   │   └── lib/
│   └── public/
│
├── supabase/                         # Supabase configuration
│   ├── config.toml
│   ├── migrations/                   # SQL migrations
│   │   ├── 001_initial_schema.sql
│   │   ├── 002_rls_policies.sql
│   │   └── 003_functions.sql
│   ├── functions/                    # Edge Functions
│   │   ├── bcv-rate/
│   │   │   └── index.ts
│   │   ├── admin/
│   │   │   ├── verify-payment/
│   │   │   │   └── index.ts
│   │   │   ├── reject-payment/
│   │   │   │   └── index.ts
│   │   │   └── review-claim/
│   │   │       └── index.ts
│   │   └── generate-policy-pdf/
│   │       └── index.ts
│   └── seed.sql                      # Test data
│
├── contracts/                        # Solidity (Phase 1.5)
│   ├── RuedaSeguroPolicy.sol         # ERC-721 + EIP-1523
│   ├── hardhat.config.js
│   └── test/
│
├── docs/                             # Additional documentation
│   ├── api-reference.md
│   ├── deployment-guide.md
│   └── carrier-onboarding.md
│
└── .github/
    └── workflows/
        ├── build-mobile.yml
        ├── deploy-admin.yml
        └── deploy-functions.yml
```

---

## 16. Key Metrics for MVP Success

| Metric | Target | Measurement |
|---|---|---|
| **Onboarding completion rate** | >70% | Users who complete OCR scan + profile creation |
| **Time to policy** | <3 minutes | From app open to policy created (excl. payment verification) |
| **OCR accuracy** | >80% auto-fill | Fields correctly extracted without manual correction |
| **Payment verification time** | <2 hours | Admin verifies Pago Móvil reference |
| **Active policies** | 100 in first month | Actual policies issued |
| **Carrier partners** | 1-2 signed | Insurance companies using the platform |
| **App crash rate** | <1% | Sentry error monitoring |
| **Offline resilience** | 100% policy viewing | Policy card always accessible offline |

---

## 17. Regulatory Compliance (MVP)

| Requirement | Implementation |
|---|---|
| **SUDEASEG Gaceta 6.835 — Simplified Contracts** | Policy PDFs use clear, non-technical Spanish. No legal jargon. |
| **"Alternative Channels" (Circular SAA-07-0491-2024)** | RuedaSeguro operates as a digital alternative channel for licensed carriers. |
| **Audit Trail** | Every state change logged in `audit_log` table. SHA-256 hashes for documents. |
| **Data Privacy** | Minimal data collection. OCR data stored for audit only. No GPS tracking in MVP. |
| **Consumer Protection** | Clear coverage terms displayed before purchase. Cancellation flow available. |

---

## 18. Risk Register

| Risk | Impact | Mitigation |
|---|---|---|
| OCR accuracy too low for Venezuelan documents | Users abandon onboarding | Manual entry fallback; iterative regex improvement; PaddleOCR server fallback |
| Pago Móvil reference verification is too slow | Users wait hours for policy activation | Hire dedicated payment verifier; prioritize C2P API integration |
| Supabase free tier limits reached early | Service degradation | Monitor usage; upgrade to Pro ($25/month) when at 80% capacity |
| Carrier partners slow to sign | No policies to sell | Start with 1 friendly carrier; use MVP demo to accelerate others |
| Regulatory pushback on digital-only model | Cannot operate legally | Engage SUDEASEG early; leverage "Alternative Channels" circular as legal basis |
| Network intermittency breaks critical flows | Data loss, failed payments | Offline-first design; Store & Forward; idempotency keys |
| Venezuelan banking API changes | Payment integration breaks | Abstract payment layer behind interface; support multiple banks |

---

*This document is the single source of truth for MVP implementation. All architectural decisions, data models, and feature scopes are defined here. Implementation begins with Sprint 0.*
