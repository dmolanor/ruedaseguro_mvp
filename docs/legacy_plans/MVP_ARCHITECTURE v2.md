# RuedaSeguro MVP — Architectural Blueprint

> **Version:** 2.0 — March 21, 2026
> **Status:** Updated — incorporates strategic directives from project leadership and original source documents
> **Target:** Production-grade MVP for pitching to insurance carriers and onboarding real riders
> **Changelog v2.0:** Local server infrastructure mandate (Venezuelan law), B2B2C sales network, 3-document + vehicle photo onboarding, multi-tier policy products, GUIA PAY upgrade path, Venemergencia partnership integration, crash detection elevated to Phase 1.5

---

## 1. Executive Summary

RuedaSeguro is a **B2B2C InsurTech platform** that enables Venezuelan motorcycle riders to purchase mandatory RCV insurance in under 6 minutes and — in future phases — receive parametric "Stabilization Payments" within 15 minutes of a verified crash. The platform operates through a physical sales network of **Corredores de Seguros** (insurance brokers) and **Promotores** (motorized sales allies at gas stations, workshops, and motorcycle events), connecting riders with licensed carriers such as Seguros Pirámide.

This document defines the **MVP architecture** — a production-ready first version that delivers real value to riders and insurance carriers, leverages **Supabase for initial development and testing**, and establishes a clear migration path to **locally-hosted Venezuelan server infrastructure** (mandated by data sovereignty regulations) with **GCP as cloud backup/DR**.

**MVP Scope:** 8-step onboarding via OCR (Cédula, Carnet de Circulación, vehicle rear photo), multi-tier RCV policy issuance with configurable products (Solo RCV / RCV + Grúa / Plus), Pago Móvil and bank transfer payment collection, digital policy card + PDF with SHA-256 hash, BCV exchange rate integration, manual claims submission, B2B admin portal with broker/promoter hierarchy.

**Cost Target:** $0/month for infrastructure during initial development (Supabase free tier), scaling as the platform grows.

---

## 2. MVP Philosophy

### 2.1 Guiding Principles

1. **Ship fast, iterate faster.** The MVP must be deployable within weeks, not months. Every architectural decision optimizes for speed-to-market without sacrificing the ability to scale.
2. **Free-tier first, pay later.** Use services with generous free tiers (Supabase, Vercel, Google ML Kit) for development and testing. When traffic demands it, upgrade — never before.
3. **Data sovereignty by design.** Venezuelan law requires data residency. The architecture is designed from Day 1 to migrate to local server infrastructure, with GCP as an authorized cloud backup. Supabase serves the initial development and testing iterations.
4. **Real value from day one.** The app must issue a real, compliant digital insurance policy that a rider can show to a traffic officer. Everything else is secondary.
5. **B2B2C from the start.** The sales network (Corredores → Promotores → Riders) is not a future add-on; it's the core distribution model. The data model and admin portal support it from Sprint 0.
6. **Offline-resilient by default.** Venezuela has intermittent connectivity. The app must function offline for core features (viewing policy, caching data).

### 2.2 What "MVP" Means for RuedaSeguro

| Category | In MVP | Phase 1.5 (Near-Term) | Phase 2+ (Deferred) |
|---|---|---|---|
| **Onboarding** | 8-step flow: OCR scan of Cédula + Carnet + Vehicle rear photo | Factura de Compra OCR (cascaded strategy) | Biometric identity verification |
| **Policy Issuance** | Multi-tier RCV digital policy with PDF + SHA-256 hash | NFT minting on Polygon (ERC-721) | AI-driven underwriting |
| **Payments** | Pago Móvil P2P + Bank transfer (receipt upload) | GUIA PAY C2P pull-based API | Tokenized card, Domiciliación |
| **Claims** | Manual claims submission with photo evidence | Crash detection + Emergency Mode + SLI | Full oracle-validated autonomous claims |
| **Telemetry** | None | Accelerometer/gyroscope background monitoring | Full IoT with Butterworth filtering |
| **Medical Network** | None (data model ready) | Venemergencia Urgent Care integration | Full PAS protocol + Red ALTEHA triage |
| **Blockchain** | SHA-256 hash of policy stored in DB | ERC-721 NFT on Polygon; 25% Cash-Out smart contract | Full smart contract liquidation |
| **AI** | None | None | LLM liability analysis (Phase 3) |
| **B2B Portal** | Multi-tenant dashboard: carriers, brokers, promoters | Commission calculation, quota tracking | Grafana-level analytics |
| **Sales Network** | Broker/promoter/POS hierarchy in DB + basic admin views | Referral codes, real-time quota dashboards | Geo-based promoter routing |
| **Infrastructure** | Supabase free tier (dev/testing) | Local Venezuelan server + GCP backup | Scaled local infra + enterprise DR |

---

## 3. Tension Resolutions

The 8 architect research documents and the new strategic directives from project leadership surfaced several architectural tensions. Here is the definitive resolution for each:

### 3.1 Infrastructure: IBM Power vs. AWS vs. Supabase vs. Local Server

**Decision: Supabase (dev/testing) → Local Venezuelan Server (PostgreSQL) + GCP Cloud Backup → Scale local infrastructure**

- **Venezuelan law mandates data sovereignty.** Insurance transaction data must reside on servers within Venezuela. This overrides the previous MVP plan of Supabase → AWS and the enterprise plan of IBM Power9.
- **Supabase remains viable for initial development and testing.** The project leader explicitly authorizes its use for early iterations. It provides $0/month hosting, managed PostgreSQL, Auth, Storage, Edge Functions, and Realtime — everything needed to build and validate the product.
- **The migration target is a local Venezuelan server** running standard PostgreSQL (not necessarily IBM Power9, which is an enterprise-scale aspiration). A standard Linux server with PostgreSQL 16, configured for high availability, satisfies the regulatory requirement.
- **GCP is the authorized cloud backup.** GCP Cloud SQL (PostgreSQL-compatible) provides disaster recovery and data replication. This is legally permitted as a backup/DR layer while the primary data resides in Venezuela.
- **IBM Power9 remains a long-term option** if transactional volumes ever justify the investment (150k+ policies). For realistic MVP and growth stages, standard PostgreSQL on local servers handles the load.

**Migration path:**
```
Phase 0 (Now):     Supabase free tier → Build, test, validate product
Phase 1.5 (~3mo):  Local VZ server (PostgreSQL 16) + GCP Cloud SQL replica
                    Supabase retained for Auth edge + Edge Functions
Phase 2 (~6-12mo): Scaled local infra + full GCP DR
Phase 3 (if ever): IBM Power9 evaluation (only if Aurora/PostgreSQL bottlenecks)
```

### 3.2 OCR Strategy: ML Kit vs. Textract vs. PaddleOCR

**Decision: Google ML Kit (on-device) for standardized documents → Server-side OCR upgrade for variable documents (Phase 1.5)**

- **Google ML Kit** runs on-device, is free, works offline, and handles standardized Venezuelan documents (Cédula, Carnet de Circulación) well with post-processing regex patterns.
- **The Factura de Compra** (purchase invoice), if required by certain carriers, presents a challenge: highly variable layouts, degraded print quality, diverse typography. ML Kit + regex is insufficient for these. This document is **deferred to Phase 1.5** with a cascaded OCR strategy: on-device ML Kit for image quality/boundary detection, then server-side PaddleOCR or AWS Textract for actual data extraction.
- **For MVP, the Factura is not required** per the most refined UX specification (Flujo App RCV document). The 3 required documents are: Cédula, Carnet de Circulación, and rear vehicle photo with visible plate. Carriers that require the Factura can be supported in Phase 1.5.
- **Anti-fraud image validation** is included from MVP: sharpness detection to reject photos taken of digital screens.

### 3.3 Database: IBM DB2 vs. PostgreSQL

**Decision: Supabase PostgreSQL (free) → Local PostgreSQL 16 + GCP Cloud SQL replica. Skip DB2.**

- All data models are relational and map cleanly to PostgreSQL. No DB2-specific feature justifies vendor lock-in.
- Supabase PostgreSQL supports JSON/JSONB, full-text search, and Row Level Security for multi-tenant B2B2C isolation.
- The local Venezuelan server runs PostgreSQL 16 — same engine, seamless migration from Supabase.
- Time-series telemetry data (Phase 1.5+) will use **TimescaleDB** (a PostgreSQL extension) rather than a separate InfluxDB instance.

### 3.4 Blockchain: Polygon NFT from Day 1 vs. Deferred

**Decision: SHA-256 policy hashes stored in PostgreSQL now → Polygon ERC-721 minting in Phase 1.5**

- Blockchain provides trust/immutability, but the MVP needs to prove product-market fit first. A SHA-256 hash of the policy PDF, stored in the database and printed on the digital policy card, provides verifiable document integrity without blockchain complexity.
- The data model includes all EIP-1523 metadata fields from day one. When we add Polygon minting, it's a matter of calling a smart contract with data that already exists.
- The 25% Cash-Out smart contract (automatic advance upon oracle validation) is a Phase 1.5 deliverable, not MVP. It requires GUIA PAY integration and Venemergencia oracle validation — both of which are Phase 1.5 dependencies.

### 3.5 Payments: Manual Verification vs. GUIA PAY vs. C2P

**Decision: Pago Móvil P2P + Bank Transfer (MVP) → GUIA PAY C2P (Phase 1.5) → Full payment suite (Phase 2)**

- **MVP supports two methods:** (1) Pago Móvil P2P — rider makes standard transfer, enters reference number, admin verifies. (2) Bank transfer — rider receives account details, uploads proof of payment (PDF/image), admin verifies. Both are well-understood flows in Venezuela.
- **GUIA PAY** replaces manual verification in Phase 1.5 — enables C2P pull-based payments (instant collection) and serves as the outbound financial rail for the 25% Cash-Out stabilization payment.
- **Tokenized card payments** require PCI-DSS compliance infrastructure — deferred to Phase 2.
- **Domiciliación (auto-debit)** is required for monthly payment plans per the Flujo document. This is deferred to Phase 1.5 as it requires bank agreements.
- **For MVP, all policies are annual payment only** (single upfront payment). Monthly plans arrive with domiciliación in Phase 1.5.

### 3.6 Crash Detection & SLI: Day-One vs. Deferred

**Decision: Manual claims in MVP → Crash detection + Emergency Mode in Phase 1.5 → Full SLI in Phase 2**

- The strategic documents position the "Agente Digital de Siniestros" as a day-one deliverable. However, the MVP's primary mission is to prove that riders will buy digital RCV policies through the app. Crash detection requires background sensor polling, battery optimization, Venemergencia webhook integration, and GUIA PAY — all significant dependencies.
- **Elevated from Phase 2 to Phase 1.5:** Crash detection is now the immediate post-MVP priority, not a distant future feature. The Flutter app architecture includes the necessary background service infrastructure from Day 1 (folder structure, permission declarations), but the actual sensor polling logic ships in Phase 1.5.
- The `telemetry_events` table is designed in the schema but created only when telemetry activates.
- The 10-second Emergency Mode countdown, PAS protocol notifications, and oracle validation are Phase 1.5 deliverables.

### 3.7 AI Integration Depth: 5-Layer Architecture vs. No AI

**Decision: No AI in MVP. Design the architecture to accommodate AI at each layer in the future.**

- The 5-layer model (NeMo Guardrails, AIOps, 93% automated liability) describes a Year 3-5 vision. Building AI into a product with 0 users generates zero value.
- The MVP architecture uses clean separation of concerns (Edge → API → Logic → Storage → Compute) that naturally maps to the 5-layer model.

### 3.8 Naming: "Quasarhub" vs. "RuedaSeguro"

**Decision: RuedaSeguro is the brand.** Quasarhub was an earlier working name used in the competitive analysis.

### 3.9 Required Documents: Reconciling Sources

**Decision: MVP requires 3 items: Cédula + Carnet de Circulación + Rear vehicle photo. Factura de Compra is optional per carrier.**

- The **Flujo App RCV** document (the most refined UX specification) requires: Cédula, Carnet de Circulación, and rear vehicle photo with visible plate.
- The **Ecosistema Digital** document adds: Factura de Compra de la motocicleta.
- The Factura de Compra may be a regulatory or carrier-specific requirement. The schema supports it as an optional document type. The OCR pipeline for Facturas requires cascaded server-side processing (Phase 1.5) due to highly variable layouts.
- **Anti-fraud validation** applies to all documents: image sharpness detection, rejection of photos-of-screens.

### 3.10 Policy Tiers: Reconciling Three Naming Schemes

**Decision: The schema supports configurable multi-tier products. Carrier determines the exact offering.**

- **Flujo doc:** "Solo RCV" vs "RCV + Grúa" (simplest, most consumer-friendly)
- **Ecosistema doc:** Básica ($17) / Plus ($31) / Ampliada ($110) with 70/30/5% distribution targets
- **Agentes Digitales doc:** RCV+APOF / RCV+AP 24/7 / RCV Plus
- These represent evolving product definitions. The `policy_types` table is flexible — carriers configure their own tiers with custom names, prices, and coverage amounts. The UI presents whatever tiers the partner carrier (Seguros Pirámide) defines.
- **For MVP launch:** Start with 2 tiers per the Flujo document (Solo RCV / RCV + Grúa). Add upsell options (grúa ~$5, funeral ~$10) at the quote summary screen.

### 3.11 Encryption Standards

**Decision: AES-256-GCM for all application data. AES/ECB/PKCS5Padding only for GUIA PAY/C2P bank API (mandated by Venezuelan banks).**

- ECB mode is cryptographically weak but is mandated by the bank API specification. We comply with the bank's requirement but do NOT use ECB for any other purpose.
- All other encryption (data at rest, data in transit, document hashing) uses modern standards: AES-256-GCM, TLS 1.3, SHA-256.

### 3.12 Onboarding Flow: Reconciling the 60-Second Claim vs. 6-Minute Reality

**Decision: Target <6 minutes for full onboarding (registration to payment). The "60-second" claim applies to OCR data extraction, not the complete flow.**

- The Flujo App RCV document defines an 8-step flow targeting <6 minutes total.
- OCR scanning and data extraction takes ~60 seconds across all documents.
- The remaining time covers OTP verification, data review, consent, product selection, and payment.

---

## 4. Tech Stack

### 4.1 Stack Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENTS                                  │
│  ┌──────────────────┐    ┌──────────────────────────────────┐   │
│  │  Flutter Mobile   │    │  Next.js Admin Portal (B2B2C)    │   │
│  │  (Android + iOS)  │    │  Carriers, Brokers, Promoters    │   │
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
│  │  │          │ │ B2B2C    │ │ Invoices │ │           │  │    │
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
│  │  │ BCV API  │ │ Pago Móvil   │ │ Polygon (Ph 1.5)   │  │    │
│  │  │ Exchange │ │ P2P (MVP)    │ │ ERC-721 NFT Mint   │  │    │
│  │  │ Rate     │ │ GUIA PAY     │ │                    │  │    │
│  │  │          │ │  (Ph 1.5)    │ │                    │  │    │
│  │  └──────────┘ └──────────────┘ └────────────────────┘  │    │
│  │                                                         │    │
│  │  ┌──────────────┐  ┌────────────────────────────────┐   │    │
│  │  │ Venemergencia│  │  GCP Cloud SQL (Ph 1.5)        │   │    │
│  │  │ API (Ph 1.5) │  │  Backup/DR + Local VZ Server   │   │    │
│  │  └──────────────┘  └────────────────────────────────┘   │    │
│  └─────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────┘
```

### 4.2 Component Selection

| Component | MVP Choice | Cost (MVP) | Upgrade Path | Rationale |
|---|---|---|---|---|
| **Mobile App** | Flutter 3.x | Free | Same | Cross-platform, single codebase |
| **State Management** | Riverpod | Free | Same | Compile-safe, testable, scales well |
| **Local DB** | SQLite (sqflite) | Free | Same | ACID-compliant, Store & Forward ready |
| **OCR** | Google ML Kit | Free | PaddleOCR → Textract | On-device, zero API cost, offline |
| **Backend (Dev/Test)** | Supabase | Free tier | Local VZ Server + GCP | PostgreSQL-based, auth + storage included |
| **Backend (Production)** | Local Venezuelan PostgreSQL 16 | Server cost | Scaled local infra | Data sovereignty compliance |
| **Cloud Backup/DR** | GCP Cloud SQL | Free tier* | Scaled GCP | Authorized cloud backup |
| **Database** | PostgreSQL 16 | Free (Supabase) | Same engine locally | RLS, JSONB, consistent across environments |
| **Auth** | Supabase Auth (GoTrue) | Free (50k MAU) | Retained as edge auth | Phone OTP, JWT-based |
| **File Storage** | Supabase Storage | Free (1GB) | Local storage + GCP | S3-compatible API |
| **Edge Functions** | Supabase Edge Functions (Deno) | Free (500k inv) | Same or Cloud Functions | BCV rate, payment webhooks |
| **Admin Portal** | Next.js 15 + shadcn/ui | Free | Same | Fast to build dashboards |
| **Admin Hosting** | Vercel | Free tier | Same | Zero-config deploys |
| **PDF Generation** | Flutter `pdf` package | Free | Server-side (Deno) | Client-side generation |
| **Push Notifications** | Firebase Cloud Messaging | Free | Same | Industry standard |
| **SMS/WhatsApp** | Supabase Auth (OTP) | Free | Twilio (Phase 1.5) | Sufficient for auth OTP |
| **Exchange Rate** | BCV scraping (Edge Function) | Free | Dedicated API | Community libraries exist |
| **CI/CD** | GitHub Actions | Free (2000 min) | Same | Standard, well-supported |
| **Monitoring** | Supabase Dashboard + Sentry | Free | Datadog/Grafana | Sufficient for MVP |

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

  # Phase 1.5 (prepared but not activated in MVP)
  # sensors_plus: ^4.x           # Accelerometer/gyroscope
  # background_fetch: ^1.x       # Background execution
  # geolocator: ^11.x            # GPS location
  # flutter_background_service: ^5.x  # Persistent background service
```

---

## 5. Data Model

### 5.1 Entity Relationship Overview

```
carriers (B2B insurance companies — e.g., Seguros Pirámide)
  │
  ├── carrier_users (admin portal users for carrier)
  │
  ├── policy_types (configurable tiers: Solo RCV, RCV + Grúa, Plus, etc.)
  │
  └── policies ────── policy_types
        │
        ├── payments
        │
        └── claims
              │
              └── claim_evidence (photos, docs)

brokers (Corredores de Seguros — manage promoter networks)
  │
  └── promoters (Promotores — motorized sales allies)
        │
        └── points_of_sale (gas stations, workshops, events)

profiles (riders) ──── vehicles
  │
  ├── documents (scanned IDs, registrations, vehicle photos)
  │
  └── policies (linked to broker/promoter who sold it)

exchange_rates (BCV rate cache)

audit_log (all state changes for SUDEASEG compliance)
```

### 5.2 Database Schema (PostgreSQL / Supabase)

```sql
-- ============================================================
-- ENUMS
-- ============================================================

CREATE TYPE policy_status AS ENUM (
  'draft',            -- Policy created but not paid
  'pending_payment',  -- Awaiting payment verification
  'pending_emission', -- Payment verified, waiting carrier system response
  'active',           -- Paid, emitted, and active
  'observed',         -- Carrier flagged fields to correct (Observada)
  'rejected_emission',-- Carrier rejected emission (Rechazada)
  'expired',          -- Past coverage_end date
  'claimed',          -- Claim has been filed and settled
  'cancelled'         -- Manually cancelled
);

CREATE TYPE payment_status AS ENUM (
  'pending',          -- Payment submitted, awaiting verification
  'verified',         -- Payment confirmed by admin
  'rejected',         -- Payment rejected (invalid reference, etc.)
  'refunded'          -- Payment reversed
);

CREATE TYPE payment_method AS ENUM (
  'pago_movil_p2p',   -- Standard Pago Móvil P2P transfer
  'bank_transfer',    -- Bank transfer with receipt upload
  'guia_pay_c2p',     -- GUIA PAY pull-based (Phase 1.5)
  'card_tokenized',   -- Tokenized card (Phase 2)
  'domiciliacion'     -- Auto-debit standing order (Phase 1.5)
);

CREATE TYPE claim_status AS ENUM (
  'submitted',        -- Claim filed by rider
  'under_review',     -- Being reviewed by carrier
  'approved',         -- Claim approved, payout pending
  'paid',             -- Payout completed
  'rejected',         -- Claim denied
  'withdrawn'         -- Withdrawn by rider
);

CREATE TYPE document_type AS ENUM (
  'cedula',               -- National ID
  'carnet_circulacion',   -- Vehicle registration / Título de propiedad
  'vehicle_photo',        -- Rear photo with visible plate
  'factura_compra',       -- Purchase invoice (optional per carrier)
  'payment_receipt',      -- Bank transfer proof of payment
  'license',              -- Driver's license
  'policy_pdf',           -- Generated policy document
  'rcv_certificate',      -- RCV certificate PDF
  'claim_photo',          -- Claim evidence photo
  'claim_document'        -- Claim supporting document
);

CREATE TYPE id_type AS ENUM ('V', 'E', 'J', 'P', 'G');

CREATE TYPE broker_status AS ENUM ('active', 'inactive', 'suspended');
CREATE TYPE promoter_status AS ENUM ('active', 'inactive', 'suspended');

-- ============================================================
-- CARRIERS (B2B Insurance Companies)
-- ============================================================

CREATE TABLE carriers (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            TEXT NOT NULL,                     -- e.g., "Seguros Pirámide"
  rif             TEXT UNIQUE NOT NULL,              -- Venezuelan tax ID (RIF)
  contact_email   TEXT NOT NULL,
  contact_phone   TEXT,
  logo_url        TEXT,
  is_active       BOOLEAN DEFAULT true,
  -- Carrier-specific configuration
  config          JSONB DEFAULT '{}',                -- API keys, emission endpoint, etc.
  required_documents JSONB DEFAULT '["cedula","carnet_circulacion","vehicle_photo"]',
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
  role            TEXT NOT NULL DEFAULT 'viewer',     -- 'super_admin', 'admin', 'manager', 'viewer'
  full_name       TEXT NOT NULL,
  email           TEXT NOT NULL,
  is_active       BOOLEAN DEFAULT true,
  created_at      TIMESTAMPTZ DEFAULT now(),
  UNIQUE(auth_user_id, carrier_id)
);

-- ============================================================
-- BROKERS (Corredores de Seguros — Insurance Brokers)
-- ============================================================

CREATE TABLE brokers (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_user_id    UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  carrier_id      UUID REFERENCES carriers(id) ON DELETE CASCADE,
  -- Broker identity
  full_name       TEXT NOT NULL,
  rif             TEXT,                              -- Broker's RIF
  email           TEXT NOT NULL,
  phone           TEXT NOT NULL,
  -- Quota and performance
  policy_quota    INTEGER DEFAULT 800,               -- Target policies per broker
  status          broker_status DEFAULT 'active',
  -- Commission configuration (per carrier agreement)
  commission_rate DECIMAL(5,4) DEFAULT 0.25,         -- 25% default
  -- Metadata
  config          JSONB DEFAULT '{}',
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- PROMOTERS (Promotores — Motorized Sales Allies)
-- ============================================================

CREATE TABLE promoters (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_user_id    UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  broker_id       UUID REFERENCES brokers(id) ON DELETE CASCADE,
  -- Promoter identity
  full_name       TEXT NOT NULL,
  id_number       TEXT NOT NULL,                     -- Cédula
  phone           TEXT NOT NULL,
  email           TEXT,
  -- Referral tracking
  referral_code   TEXT UNIQUE NOT NULL,              -- Unique code for tracking sales
  status          promoter_status DEFAULT 'active',
  -- Metadata
  config          JSONB DEFAULT '{}',
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- POINTS OF SALE (Physical locations — gas stations, workshops)
-- ============================================================

CREATE TABLE points_of_sale (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  broker_id       UUID REFERENCES brokers(id),
  name            TEXT NOT NULL,                     -- e.g., "Estación Caracas Centro"
  type            TEXT NOT NULL,                     -- 'gas_station', 'workshop', 'parts_shop', 'event', 'other'
  address         TEXT,
  city            TEXT,
  state           TEXT,
  latitude        DECIMAL(10,7),
  longitude       DECIMAL(10,7),
  is_active       BOOLEAN DEFAULT true,
  created_at      TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- PROFILES (Riders / Policyholders)
-- ============================================================

CREATE TABLE profiles (
  id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  id_type         id_type NOT NULL DEFAULT 'V',
  id_number       TEXT NOT NULL,                     -- Cédula number
  first_name      TEXT NOT NULL,
  last_name       TEXT NOT NULL,
  phone           TEXT NOT NULL,                     -- Verified phone (from auth)
  email           TEXT,
  date_of_birth   DATE,
  nationality     TEXT,
  sex             TEXT,                              -- 'M', 'F' (from Cédula OCR)
  -- Address (manual entry per Flujo doc)
  urbanizacion    TEXT,
  ciudad          TEXT,
  municipio       TEXT,
  estado          TEXT,
  codigo_postal   TEXT,
  -- Emergency contact
  emergency_name  TEXT,
  emergency_phone TEXT,
  emergency_relation TEXT,
  -- OCR metadata
  ocr_confidence  REAL,                              -- OCR extraction confidence score
  ocr_raw_data    JSONB,                             -- Raw OCR extraction for audit
  -- Referral tracking (who sold this rider their policy)
  referred_by_promoter UUID REFERENCES promoters(id),
  referred_by_code TEXT,                             -- Promoter referral code used
  --
  avatar_url      TEXT,
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
  brand           TEXT NOT NULL,                     -- e.g., Bera, Empire, Honda
  model           TEXT NOT NULL,
  year            INTEGER NOT NULL,
  color           TEXT,
  serial_motor    TEXT,                              -- Engine serial number
  serial_carroceria TEXT,                            -- Chassis/VIN
  vehicle_type    TEXT DEFAULT 'motorcycle',
  vehicle_use     TEXT DEFAULT 'particular',         -- 'particular', 'cargo'
  -- Vehicle photo
  rear_photo_url  TEXT,                              -- Rear photo with visible plate
  -- OCR metadata
  ocr_confidence  REAL,
  ocr_raw_data    JSONB,
  --
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- POLICY TYPES (Configurable insurance products per carrier)
-- ============================================================

CREATE TABLE policy_types (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  carrier_id      UUID REFERENCES carriers(id) ON DELETE CASCADE,
  code            TEXT NOT NULL,                      -- 'RCV_BASICA', 'RCV_GRUA', 'RCV_PLUS', etc.
  name            TEXT NOT NULL,                      -- Display name: "Solo RCV", "RCV + Grúa"
  description     TEXT,
  tier            TEXT NOT NULL DEFAULT 'basica',     -- 'basica', 'plus', 'ampliada' (for analytics)
  price_usd       DECIMAL(10,2) NOT NULL,             -- Price in USD (stable reference)
  coverage_amount_usd DECIMAL(10,2) NOT NULL,         -- Coverage limit in USD
  -- Coverage breakdown (per SUDEASEG requirements)
  coverage_details JSONB DEFAULT '{}',                -- { "danos_cosas": 5000, "danos_personas": 10000, "asistencia_legal": true }
  duration_days   INTEGER NOT NULL DEFAULT 365,       -- Coverage duration
  payment_frequency TEXT DEFAULT 'annual',            -- 'annual', 'monthly' (monthly requires domiciliación)
  terms_url       TEXT,                               -- Link to terms & conditions
  -- Upsell options
  upsell_options  JSONB DEFAULT '[]',                 -- [{ "name": "Grúa", "price_usd": 5 }, { "name": "Funeral", "price_usd": 10 }]
  is_active       BOOLEAN DEFAULT true,
  -- Distribution target
  target_percentage DECIMAL(5,2),                     -- 70%, 30%, 5% etc.
  config          JSONB DEFAULT '{}',
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now(),
  UNIQUE(carrier_id, code)
);

-- ============================================================
-- POLICIES (Issued insurance policies)
-- ============================================================

CREATE TABLE policies (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  policy_number   TEXT UNIQUE NOT NULL,               -- Human-readable: RS-{CARRIER}-{YYYYMM}-{SEQ}
  profile_id      UUID REFERENCES profiles(id),
  vehicle_id      UUID REFERENCES vehicles(id),
  policy_type_id  UUID REFERENCES policy_types(id),
  carrier_id      UUID REFERENCES carriers(id),
  -- Sales network tracking
  broker_id       UUID REFERENCES brokers(id),
  promoter_id     UUID REFERENCES promoters(id),
  point_of_sale_id UUID REFERENCES points_of_sale(id),
  referral_code   TEXT,                               -- Code used at purchase
  -- Coverage details
  status          policy_status NOT NULL DEFAULT 'draft',
  price_usd       DECIMAL(10,2) NOT NULL,
  price_ves       DECIMAL(20,2) NOT NULL,
  exchange_rate   DECIMAL(20,6) NOT NULL,             -- BCV rate at issuance
  rate_timestamp  TIMESTAMPTZ NOT NULL,
  coverage_start  TIMESTAMPTZ,
  coverage_end    TIMESTAMPTZ,
  -- Selected upsells
  upsells         JSONB DEFAULT '[]',                 -- Selected upsell options
  -- Legal consent (SUDEASEG compliance)
  accepted_terms  BOOLEAN DEFAULT false,
  accepted_data_truthfulness BOOLEAN DEFAULT false,
  accepted_antifraud BOOLEAN DEFAULT false,
  accepted_privacy BOOLEAN DEFAULT false,
  consent_timestamp TIMESTAMPTZ,
  -- Document integrity (future blockchain-ready)
  pdf_url         TEXT,                               -- Supabase Storage URL
  certificate_url TEXT,                               -- RCV certificate PDF URL
  document_hash   TEXT,                               -- SHA-256 hash of the policy PDF
  -- EIP-1523 ready fields (for future NFT minting)
  holder_address  TEXT,                               -- Ethereum address (when available)
  token_id        BIGINT,                             -- NFT token ID (when minted)
  tx_hash         TEXT,                               -- Polygon transaction hash (when minted)
  -- Emission response from carrier
  emission_response JSONB,                            -- Carrier API response (Éxito/Observada/Rechazada)
  emission_notes  TEXT,                               -- Observation notes if status = 'observed'
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
  idempotency_key UUID UNIQUE NOT NULL,               -- Prevents duplicate payments
  amount_usd      DECIMAL(10,2) NOT NULL,
  amount_ves      DECIMAL(20,2) NOT NULL,
  exchange_rate   DECIMAL(20,6) NOT NULL,
  rate_timestamp  TIMESTAMPTZ NOT NULL,
  -- Payment method fields
  method          payment_method NOT NULL DEFAULT 'pago_movil_p2p',
  bank_code       TEXT,                               -- 4-digit bank code
  phone_number    TEXT,                               -- Payer phone
  reference       TEXT,                               -- Pago Móvil reference number
  receipt_url     TEXT,                               -- Bank transfer proof image/PDF URL
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
  settlement_tx_hash TEXT,                            -- Blockchain tx (Phase 1.5)
  -- Review
  reviewer_id     UUID REFERENCES carrier_users(id),
  review_notes    TEXT,
  reviewed_at     TIMESTAMPTZ,
  -- Telemetry data (Phase 1.5 — elevated from Phase 2)
  impact_magnitude REAL,                              -- 9G threshold data
  telemetry_data  JSONB,                              -- Sensor snapshot
  -- Oracle validation (Phase 1.5)
  oracle_validated BOOLEAN DEFAULT false,
  oracle_validation_token TEXT,
  oracle_validated_at TIMESTAMPTZ,
  oracle_provider TEXT,                               -- 'venemergencia', 'nueve_once', 'angeles'
  -- Triage classification (Phase 1.5)
  triage_level    TEXT,                               -- 'emergencia', 'urgencia', 'leve'
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
  file_type       TEXT NOT NULL,                      -- 'image/jpeg', 'application/pdf'
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
  file_url        TEXT NOT NULL,                      -- Supabase Storage URL
  file_hash       TEXT,                               -- SHA-256 hash
  ocr_extracted   JSONB,                              -- Raw OCR output
  ocr_confidence  REAL,
  -- Anti-fraud metadata
  sharpness_score REAL,                               -- Image sharpness for fraud detection
  is_screen_photo BOOLEAN DEFAULT false,              -- Detected as photo-of-screen
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
-- AUDIT LOG (All state changes for SUDEASEG compliance)
-- ============================================================

CREATE TABLE audit_log (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  table_name      TEXT NOT NULL,
  record_id       UUID NOT NULL,
  action          TEXT NOT NULL,                      -- 'INSERT', 'UPDATE', 'DELETE', 'VERIFY_PAYMENT', etc.
  old_data        JSONB,
  new_data        JSONB,
  performed_by    UUID,                               -- auth.users.id
  performed_at    TIMESTAMPTZ DEFAULT now(),
  ip_address      TEXT,
  user_agent      TEXT
);

CREATE INDEX idx_audit_log_table ON audit_log(table_name, record_id);
CREATE INDEX idx_audit_log_time ON audit_log(performed_at DESC);

-- ============================================================
-- INDEXES for performance
-- ============================================================

CREATE INDEX idx_policies_carrier ON policies(carrier_id);
CREATE INDEX idx_policies_broker ON policies(broker_id);
CREATE INDEX idx_policies_promoter ON policies(promoter_id);
CREATE INDEX idx_policies_status ON policies(status);
CREATE INDEX idx_policies_profile ON policies(profile_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_promoters_broker ON promoters(broker_id);
CREATE INDEX idx_promoters_referral ON promoters(referral_code);
CREATE INDEX idx_profiles_referred ON profiles(referred_by_promoter);

-- ============================================================
-- FUTURE: TELEMETRY (Phase 1.5 — elevated from Phase 2)
-- ============================================================
-- This table is designed but NOT created in MVP.
-- It implements the anomaly_queue from the Data Architecture doc.
-- Created when crash detection is activated in Phase 1.5.
--
-- CREATE TABLE telemetry_events (
--   id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--   profile_id      UUID REFERENCES profiles(id),
--   policy_id       UUID REFERENCES policies(id),
--   event_type      TEXT NOT NULL,                   -- 'IMPACT', 'BRAKE', 'ACCELERATION', 'EMERGENCY_MODE'
--   timestamp       TIMESTAMPTZ NOT NULL,            -- ISO 8601 from device
--   magnitude       REAL NOT NULL,                   -- Vector magnitude (9G threshold)
--   raw_x           REAL,
--   raw_y           REAL,
--   raw_z           REAL,
--   raw_data_blob   BYTEA,                           -- 3-second sensor window
--   gps_lat         DECIMAL(10,7),
--   gps_lng         DECIMAL(10,7),
--   gps_speed       REAL,
--   bcv_rate        DECIMAL(20,6),
--   device_model    TEXT,
--   sync_lag_ms     INTEGER,                         -- Time between event and server receipt
--   -- Emergency Mode state
--   emergency_countdown_started BOOLEAN DEFAULT false,
--   emergency_cancelled BOOLEAN DEFAULT false,
--   emergency_contacts_notified BOOLEAN DEFAULT false,
--   oracle_dispatched BOOLEAN DEFAULT false,
--   created_at      TIMESTAMPTZ DEFAULT now()
-- );

-- ============================================================
-- MATERIALIZED VIEW: Broker Performance (refreshed periodically)
-- ============================================================

-- CREATE MATERIALIZED VIEW broker_performance AS
-- SELECT
--   b.id AS broker_id,
--   b.full_name,
--   b.policy_quota,
--   COUNT(p.id) AS total_policies,
--   COUNT(p.id) FILTER (WHERE pt.tier = 'basica') AS basica_count,
--   COUNT(p.id) FILTER (WHERE pt.tier = 'plus') AS plus_count,
--   COUNT(p.id) FILTER (WHERE pt.tier = 'ampliada') AS ampliada_count,
--   SUM(p.price_usd) AS total_revenue_usd,
--   ROUND(COUNT(p.id)::DECIMAL / NULLIF(b.policy_quota, 0) * 100, 1) AS quota_pct
-- FROM brokers b
-- LEFT JOIN policies p ON p.broker_id = b.id AND p.status = 'active'
-- LEFT JOIN policy_types pt ON p.policy_type_id = pt.id
-- GROUP BY b.id, b.full_name, b.policy_quota;
-- Note: REFRESH MATERIALIZED VIEW broker_performance; — run via cron or admin action

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
ALTER TABLE brokers ENABLE ROW LEVEL SECURITY;
ALTER TABLE promoters ENABLE ROW LEVEL SECURITY;
ALTER TABLE points_of_sale ENABLE ROW LEVEL SECURITY;

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

-- Brokers can see their own data and their promoters' data
CREATE POLICY "Brokers can view own broker record"
  ON brokers FOR SELECT USING (auth.uid() = auth_user_id);

CREATE POLICY "Brokers can view their promoters"
  ON promoters FOR SELECT
  USING (broker_id IN (SELECT id FROM brokers WHERE auth_user_id = auth.uid()));

-- Promoters can see their own record
CREATE POLICY "Promoters can view own record"
  ON promoters FOR SELECT USING (auth.uid() = auth_user_id);

-- Points of sale are viewable by associated broker
CREATE POLICY "Brokers can view their points of sale"
  ON points_of_sale FOR SELECT
  USING (broker_id IN (SELECT id FROM brokers WHERE auth_user_id = auth.uid()));

-- Policy types are public (readable by all authenticated users)
ALTER TABLE policy_types ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Policy types are viewable by all"
  ON policy_types FOR SELECT USING (is_active = true);

-- Exchange rates are public
ALTER TABLE exchange_rates ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Exchange rates are viewable by all"
  ON exchange_rates FOR SELECT USING (true);

-- Carrier users: access via carrier_id through admin portal API (service role key)
-- Admin operations bypass RLS using the service role key in Edge Functions
```

### 5.3 Policy Number Generation

Policy numbers follow the format: `RS-{CARRIER_CODE}-{YEAR}{MONTH}-{SEQUENCE}`

Example: `RS-PIR-202604-00001` (RuedaSeguro, Seguros Pirámide, April 2026, policy #1)

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

### 5.4 Referral Code Generation

```sql
CREATE FUNCTION generate_referral_code(p_promoter_name TEXT)
RETURNS TEXT AS $$
DECLARE
  name_prefix TEXT;
  random_suffix TEXT;
BEGIN
  name_prefix := UPPER(LEFT(REGEXP_REPLACE(p_promoter_name, '[^a-zA-Z]', '', 'g'), 4));
  random_suffix := LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');
  RETURN 'RS-' || name_prefix || '-' || random_suffix;
END;
$$ LANGUAGE plpgsql;
```

---

## 6. Core User Flows

### 6.1 Complete Onboarding Flow (8-Step — Target <6 minutes)

Based on the Flujo App RCV specification:

```
Step 1           Step 2            Step 3          Step 4
┌──────────┐    ┌──────────────┐  ┌────────────┐  ┌──────────┐
│ Welcome  │───▶│  Registro    │─▶│  OTP       │─▶│  Home    │
│ Screen   │    │  Nuevo       │  │  Verify    │  │  Screen  │
│          │    │  Usuario     │  │  (6-digit) │  │          │
│ [Crear   │    │              │  │            │  │ [Cotizar │
│  cuenta] │    │ Name, CI,    │  │ SMS/WA     │  │  ahora]  │
│ [Ingresar│    │ Phone, Email,│  │ 60s resend │  │          │
│         ]│    │ Password     │  │ counter    │  │          │
└──────────┘    └──────────────┘  └────────────┘  └────┬─────┘
                                                       │
Step 8c          Step 8b          Step 8a          Step 5
┌──────────┐    ┌──────────────┐  ┌────────────┐  ┌──────────┐
│ Confirm  │◀───│  Payment     │◀─│  Emission   │◀─│ Product  │
│ & Descarga│   │  Selection   │  │  Request   │  │ Selection│
│          │    │              │  │            │  │          │
│ [Descargar│   │ P2P / Trans. │  │ ✓ Éxito   │  │ Solo RCV │
│  Póliza] │    │ Method +     │  │ ⚠ Observada│  │ RCV+Grúa │
│ [Certif. │    │ Amount VES   │  │ ✗ Rechazada│  │          │
│   RCV]   │    │              │  │            │  │ + upsells│
└──────────┘    └──────────────┘  └────────────┘  └────┬─────┘
                                                       │
                                                  Step 6 & 7
                                                  ┌──────────┐
                                                  │ Document │
                                                  │ Upload + │
                                                  │ OCR +    │
                                                  │ Review + │
                                                  │ Consent  │
                                                  └──────────┘
```

**Detailed Steps:**

1. **Welcome Screen** — Logo, tagline: "Asegura tu vehículo en minutos." Two buttons: [Crear cuenta] / [Ingresar].

2. **Registration** — Fields: Nombres, Apellidos, Cédula (V/E-########), Teléfono móvil (+58), Email (optional), Contraseña, Confirmar contraseña. Validations: CI format, age ≥ 18, Venezuelan phone, password ≥ 8 chars with number. CTA: [Crear cuenta]. Triggers OTP.

3. **OTP Verification** — 6-digit code via SMS or WhatsApp. 60-second resend counter. Option to switch channel. Error: "Código inválido/expirado."

4. **Home Screen** — Greeting with verified identity status. Hero card: "Cotizar, emitir y pagar RCV" with [Cotizar ahora]. Quick menu: [Cotizar] [Mis pólizas] [Pagos] [Soporte]. Policy status list (vigentes, por pagar, vencidas).

5. **Product Selection (Cotización)** — Two product cards: "Solo RCV" and "RCV + Grúa". Each shows annual premium in USD and VES. Info icon with conditions (monthly only with domiciliación; 12-month validity). CTA: [Continuar].

6. **Document Upload (OCR)** — Three upload blocks:
   - Cédula de Identidad (upload / take photo)
   - Carnet de Circulación / Título de Propiedad (upload / take photo)
   - Rear vehicle photo with plate visible (upload / take photo)
   - Photo tips: good lighting, no reflections, complete edges
   - Progress indicator per document
   - Validations: JPG/PNG/PDF, ≤10MB, OCR ≥90% readability, anti-fraud sharpness check

7. **Data Review & Consent** — Auto-populated fields from OCR: names, CI, DOB, nationality, plate, type/use, make, model, year, color, serials. Validation: name/CI must match between Cédula and Carnet. If mismatch: red banner with [Subir nueva cédula] / [Soy representante legal]. Incomplete fields marked in amber. Manual fields: urbanización/sector, ciudad, municipio, código postal. Mandatory checkboxes:
   - ☐ Acepto las Condiciones Generales del RCV (link to PDF)
   - ☐ Declaro la veracidad de los datos suministrados
   - ☐ Autorizo la consulta y verificación antifraude
   - ☐ Acepto la política de privacidad
   - CTA: [Confirmar datos]

   **Quote Summary Screen** — Coverage detail breakdown (daños a cosas, daños a personas, asistencia legal, exceso de límite). Payment frequency selection: Annual / Monthly (monthly greyed out with note: "Solo con domiciliación"). Upsell promotions (grúa ~$5, funeral ~$10). CTA: [Solicitar emisión].

8. **Emission → Payment → Confirmation:**
   - **8a. Emission:** Loading: "Estamos emitiendo tu póliza..." Results:
     - ✓ **Éxito** → Proceed to payment
     - ⚠ **Observada** → Fields to correct, [Editar datos]
     - ✗ **Rechazada** → Reason + [Contactar soporte]
   - **8b. Payment:** Select method (Pago Móvil P2P / Transferencia bancaria). Payment summary with tax breakdown. CTA: [Pagar ahora]. For P2P: shows bank details, rider pays externally, enters reference. For transfer: shows account details, rider uploads receipt.
   - **8c. Confirmation:** "¡Tu póliza RCV está activa!" (or "Pendiente de verificación" for manual methods). Policy number, validity dates, product, payment method, amount. Buttons: [Descargar Póliza PDF] [Descargar Certificado RCV] [Enviar por email/WhatsApp] [Imprimir]. Secondary: [Ver en Mis pólizas].

### 6.2 OCR Processing Pipeline

```
Camera Frame
     │
     ▼
Image Quality Check (Dart)
     │  ├── Sharpness score (Laplacian variance)
     │  ├── Brightness check
     │  └── Screen-photo detection (moiré patterns, pixel grid)
     │
     ├── Quality FAIL → "Retoma la foto: [iluminación / enfoque / sin reflejo]"
     │
     ▼ Quality PASS
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
     │  │   ├── Date pattern: dd/MM/yyyy               → date_of_birth
     │  │   ├── Nationality extraction                 → nationality
     │  │   └── Sex extraction                         → sex
     │  │
     │  └── Carnet Parser
     │      ├── Plate: r'[A-Z]{2,3}\d{2,3}[A-Z]{2,3}' → plate
     │      ├── Brand/Model (keyword matching)          → brand, model
     │      ├── Year: r'(19|20)\d{2}'                  → year
     │      ├── Type/Use: 'PARTICULAR', 'CARGA'        → vehicle_use
     │      └── Serial patterns                        → serial_motor, serial_carroceria
     │
     ▼
Confidence Score (0.0 - 1.0)
     │
     ├── confidence >= 0.9 → Auto-fill, user confirms (green indicators)
     ├── confidence 0.5-0.9 → Auto-fill with amber "verify" indicators
     └── confidence < 0.5 → Manual entry fallback with OCR suggestions
     │
     ▼
Cross-Validation
     │
     ├── CI name ↔ Carnet owner name match check
     └── Mismatch → Red banner: [Subir nueva cédula] / [Soy representante legal]
```

### 6.3 Payment Flow (MVP)

```
Step 8b: User selects payment method
         │
         ├── PAGO MÓVIL P2P                    TRANSFERENCIA BANCARIA
         │                                      │
         ▼                                      ▼
App shows payment details              App shows bank account details
(bank, phone, CI, amount VES)          (bank, account number, amount VES)
         │                                      │
         ▼                                      ▼
User makes Pago Móvil                  User makes bank transfer
transfer externally                    and captures receipt
         │                                      │
         ▼                                      ▼
Returns to app                         Returns to app
Enters reference number                Uploads receipt (PDF/image)
         │                                      │
         └──────────────┬───────────────────────┘
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
              against bank statement/receipt
                        │
                        ▼
              Payment → 'verified'
              Policy → 'active'
                        │
                        ▼
              Push notification to rider
              "¡Tu póliza RCV está activa!"
              + PDF and certificate available
```

**Future GUIA PAY Flow (Phase 1.5):**
```
User taps "Pagar" → GUIA PAY C2P pull request →
Bank debits account instantly → Payment verified automatically →
Policy activated in real-time → No admin intervention needed
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

**Future Crash Detection + SLI Flow (Phase 1.5):**
```
Accelerometer detects 9G+ impact → Emergency Mode activated →
10-second countdown → Rider doesn't cancel → System assumes incapacity →
Oracle dispatched (Venemergencia/Nueve Once) → GPS + telemetry sent →
Emergency contacts notified (SMS/WhatsApp) →
Oracle validates crash on-site → Cryptographic validation webhook →
Smart contract executes 25% Cash-Out → GUIA PAY disburses →
Rider/clinic receives funds within 15 minutes
```

### 6.5 BCV Exchange Rate Integration

```
Supabase Edge Function (cron: every 30 min)
         │
         ▼
Scrape BCV website or call community API
(pydolarve.org or similar)
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
│   │   ├── validators.dart            # Cédula, phone, plate validators
│   │   └── image_quality_utils.dart   # Sharpness, screen-photo detection
│   └── theme/
│       ├── colors.dart                # Navy blue (#1A237E), Orange accent
│       ├── typography.dart            # Montserrat + Lato (stress-readable)
│       └── spacing.dart               # 4px grid system
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository.dart
│   │   ├── domain/
│   │   │   └── auth_state.dart
│   │   └── presentation/
│   │       ├── welcome_screen.dart       # Step 1: Logo + [Crear cuenta]/[Ingresar]
│   │       ├── register_screen.dart      # Step 2: Full registration form
│   │       ├── login_screen.dart         # Existing user login
│   │       ├── otp_screen.dart           # Step 3: OTP verification
│   │       └── widgets/
│   │
│   ├── onboarding/
│   │   ├── data/
│   │   │   ├── ocr_repository.dart       # ML Kit + field extraction
│   │   │   └── profile_repository.dart
│   │   ├── domain/
│   │   │   ├── ocr_result.dart
│   │   │   ├── cedula_parser.dart        # Regex extraction for cédula
│   │   │   ├── carnet_parser.dart        # Regex extraction for carnet
│   │   │   └── image_validator.dart      # Anti-fraud quality checks
│   │   └── presentation/
│   │       ├── scan_cedula_screen.dart    # Step 6a: Cédula OCR
│   │       ├── scan_carnet_screen.dart    # Step 6b: Carnet OCR
│   │       ├── vehicle_photo_screen.dart  # Step 6c: Rear vehicle photo
│   │       ├── review_data_screen.dart    # Step 7: Auto-filled data review
│   │       ├── address_form_screen.dart   # Step 7: Manual address fields
│   │       ├── consent_screen.dart        # Step 7: Legal checkboxes
│   │       ├── quote_summary_screen.dart  # Step 7.5: Coverage + upsells
│   │       └── widgets/
│   │           ├── camera_overlay.dart    # Document alignment guide
│   │           ├── ocr_field_card.dart    # Editable OCR result field
│   │           ├── quality_indicator.dart # Image quality feedback
│   │           └── mismatch_banner.dart   # CI/name mismatch warning
│   │
│   ├── policy/
│   │   ├── data/
│   │   │   ├── policy_repository.dart
│   │   │   ├── policy_type_repository.dart
│   │   │   └── pdf_generator.dart        # Policy PDF + RCV certificate
│   │   ├── domain/
│   │   │   ├── policy.dart
│   │   │   └── policy_type.dart
│   │   └── presentation/
│   │       ├── policy_list_screen.dart    # Mis pólizas (active, pending, expired)
│   │       ├── policy_detail_screen.dart  # Full policy view + downloads
│   │       ├── policy_card_widget.dart    # Shareable digital card
│   │       ├── select_plan_screen.dart    # Step 5: Product selection
│   │       ├── emission_screen.dart       # Step 8a: Loading + result
│   │       ├── confirmation_screen.dart   # Step 8c: Success + downloads
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
│   │       ├── payment_method_screen.dart     # Step 8b: Method selection
│   │       ├── pago_movil_screen.dart         # P2P instructions + reference
│   │       ├── bank_transfer_screen.dart      # Account details + receipt upload
│   │       ├── payment_status_screen.dart     # Pending/verified
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
│   │       ├── home_screen.dart           # Step 4: Dashboard with hero card
│   │       └── widgets/
│   │           ├── policy_summary_card.dart
│   │           ├── quick_actions.dart     # Cotizar, Mis pólizas, Pagos, Soporte
│   │           └── rate_ticker.dart       # Live BCV rate
│   │
│   └── profile/
│       └── presentation/
│           ├── profile_screen.dart
│           ├── edit_profile_screen.dart
│           └── settings_screen.dart
│
└── shared/
    ├── widgets/
    │   ├── rs_button.dart                # Primary/secondary buttons
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

| Feature | Offline Behavior |
|---|---|
| **View active policy** | Cached locally in SQLite. Always available. |
| **View policy card** | Cached. Can be shown to traffic officers offline. |
| **View RCV certificate** | Cached PDF. Always available. |
| **View profile/vehicle** | Cached locally. |
| **Submit claim** | Queued in SQLite. Synced when online (Store & Forward). |
| **Scan documents (OCR)** | Fully offline (Google ML Kit is on-device). |
| **Make payment** | Requires internet (external bank transfer). |
| **Purchase policy** | Requires internet. |
| **View BCV rate** | Last known rate cached with timestamp. |

### 7.3 UI Design System

Following the UI/UX Architecture Guide and the Agentes Digitales branding:

**Color Palette:**
- Primary: Navy Blue (#1A237E) — protection, trust
- Accent: Orange (#FF6D00) — alert, urgency, action
- Success: Green (#2E7D32)
- Error: Red (#C62828)
- Warning: Amber (#FFB300) — used for "Observada" status, incomplete fields
- Background: Off-white (#FAFAFA) — avoids glare under sunlight
- Surface: Off-black (#212121) — high contrast for outdoor readability

**Typography:**
- Headings: **Montserrat** Bold — immediately perceivable while moving
- Body: **Lato** Medium, 16sp minimum — readable under vibration (stress-readable)
- Numbers: Monospace for reference numbers, amounts, and policy numbers

**Ergonomics:**
- All primary actions in the bottom third of screen ("Easy Zone" for thumb)
- Minimum tap target: 48x48dp (glove-friendly)
- High-contrast mode support
- One-handed navigation for all critical flows
- Short, guiding phrases (conversational UX)

**Brand Promise:** "Si te caes, no estás solo" ("If you fall, you are not alone")

**Emergency Mode UI (Phase 1.5):**
- Red/flashing high-contrast dashboard
- Large countdown timer (10 seconds)
- Single large [ESTOY BIEN] cancel button
- Haptic feedback for confirmations
- Minimal text, maximum clarity

---

## 8. Admin Portal Architecture (B2B2C)

### 8.1 Tech Stack

- **Framework:** Next.js 15 (App Router)
- **UI:** shadcn/ui + Tailwind CSS
- **Auth:** Supabase Auth (email + password for admin users)
- **Data:** Supabase JS client with service role key for admin operations
- **Hosting:** Vercel (free tier)
- **Charts:** Recharts (lightweight charting)

### 8.2 Portal Pages

```
/login                        → Admin/Broker login

# Carrier Admin Dashboard
/dashboard                    → Overview: active policies, revenue, claims, tier distribution
/dashboard/policies           → Policy list with filters (status, date, tier, broker)
/dashboard/policies/[id]      → Policy detail (rider, vehicle, payment, PDF, certificate)
/dashboard/payments           → Payment verification queue
/dashboard/payments/[id]      → Verify/reject payment (reference lookup, receipt view)
/dashboard/claims             → Claims review queue
/dashboard/claims/[id]        → Claim detail with evidence, approve/reject
/dashboard/riders             → Rider directory
/dashboard/analytics          → Charts: policies/day, revenue, tier mix, claims ratio

# B2B2C Sales Network Management
/dashboard/brokers            → Broker list with quota progress
/dashboard/brokers/[id]       → Broker detail: promoters, policies, commission
/dashboard/promoters          → Promoter directory with referral codes
/dashboard/promoters/[id]     → Promoter detail: sales, referral tracking
/dashboard/points-of-sale     → POS locations (gas stations, workshops)

# Settings
/dashboard/settings           → Carrier profile, user management, policy types config

# Broker-specific Dashboard (role-based view)
/broker/dashboard             → Broker's own quota, promoters, commission
/broker/promoters             → Manage their promoter network
/broker/policies              → Policies sold through their network
```

### 8.3 Admin API (Supabase Edge Functions)

| Function | Method | Purpose |
|---|---|---|
| `/functions/v1/admin/verify-payment` | POST | Verify a pending payment, activate policy |
| `/functions/v1/admin/reject-payment` | POST | Reject a payment with reason |
| `/functions/v1/admin/review-claim` | POST | Approve/reject a claim |
| `/functions/v1/admin/carrier-stats` | GET | Aggregate stats for carrier dashboard |
| `/functions/v1/admin/broker-stats` | GET | Broker performance + quota tracking |
| `/functions/v1/admin/promoter-stats` | GET | Promoter sales + referral tracking |
| `/functions/v1/admin/tier-distribution` | GET | Policy mix by tier (Básica/Plus/Ampliada %) |
| `/functions/v1/bcv-rate` | GET | Fetch and cache latest BCV rate (cron) |
| `/functions/v1/generate-policy-pdf` | POST | Generate policy PDF + RCV certificate |

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
| **Admin Portal** | Email + password via Supabase Auth → JWT + role verification (carrier_user/broker) |
| **Broker Portal** | Email + password → JWT + broker_id verification |
| **API** | JWT verification on every request (Supabase handles this) |
| **Local** | Biometric unlock (local_auth) for app re-entry; tokens in flutter_secure_storage |

### 10.2 Data Protection

| Concern | Implementation |
|---|---|
| **Data in transit** | TLS 1.3 (Supabase default) |
| **Data at rest** | Supabase encrypts at rest (AES-256); local server: LUKS encryption |
| **Local data** | flutter_secure_storage for tokens; SQLite for non-sensitive cache |
| **Document hashes** | SHA-256 of every policy PDF stored alongside the document |
| **PII handling** | Minimal PII collection. OCR raw data stored for audit only. |
| **Multi-tenancy** | Row Level Security (RLS) isolates data per user, per carrier, per broker |
| **Data sovereignty** | Primary data on Venezuelan servers (Phase 1.5); GCP as authorized backup |

### 10.3 Anti-Fraud (Document Upload)

| Check | Implementation |
|---|---|
| **Image sharpness** | Laplacian variance calculation; reject blurry images |
| **Screen-photo detection** | Moiré pattern analysis to reject photos of digital screens |
| **OCR confidence threshold** | ≥90% readability required; below triggers guided retake |
| **CI/Name cross-validation** | Cédula name must match Carnet de Circulación owner |
| **Duplicate detection** | SHA-256 hash of uploaded images checked against existing documents |

### 10.4 Idempotency

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
| **Database + Auth + Storage** | Supabase (dev/testing) | 500MB DB, 1GB storage, 50k MAU |
| **Edge Functions** | Supabase | 500k invocations/month |
| **Admin Portal** | Vercel | 100GB bandwidth, serverless functions |
| **Push Notifications** | Firebase Cloud Messaging | Unlimited |
| **Error Tracking** | Sentry | 5k events/month |
| **CI/CD** | GitHub Actions | 2000 min/month |
| **Cloud Backup (Phase 1.5)** | GCP Cloud SQL | Free tier (1 f1-micro instance) |
| **Local Server (Phase 1.5)** | Venezuelan data center | TBD based on provider |

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

## 12. Migration Path: MVP → Local Infrastructure → Enterprise

### Phase 1.5 — Local Server + Key Integrations (~3 months post-MVP)

| Component | Change | Trigger |
|---|---|---|
| **Infrastructure** | Deploy PostgreSQL 16 on local Venezuelan server; configure GCP Cloud SQL as replica | Regulatory compliance deadline |
| **Data Migration** | Migrate Supabase PostgreSQL data to local server; retain Supabase for Auth edge + Edge Functions | When local server is provisioned |
| **Payments** | Integrate GUIA PAY C2P API (replaces manual Pago Móvil verification) | When manual verification becomes bottleneck |
| **Crash Detection** | Activate accelerometer/gyroscope in Flutter; implement Emergency Mode + 10-second countdown | Core differentiator — immediate post-MVP |
| **Telemetry** | Implement Store & Forward (SQLite anomaly_queue); create telemetry_events table | Paired with crash detection |
| **Blockchain** | Deploy ERC-721 smart contract on Polygon testnet; mint policies as NFTs | When pitching trust/transparency |
| **OCR Upgrade** | Add PaddleOCR server-side fallback for low-confidence scans and Factura de Compra | When carriers require Factura |
| **Medical Network** | Integrate Venemergencia Urgent Care API; affiliate enrollment data export | When contractual agreement is formalized |
| **Notifications** | Add Twilio SMS/WhatsApp for emergency contact notifications (PAS protocol) | Required for crash detection flow |
| **Database** | Upgrade Supabase plan (Pro: $25/month) or transition primary workload to local server | When approaching free tier limits |

### Phase 2 — Scale + Full SLI (~6-12 months)

| Component | Change | Trigger |
|---|---|---|
| **SLI** | Implement Smart Liquidation System: crash detection → oracle validation → 25% Cash-Out → GUIA PAY payout | Core product differentiator |
| **Oracle Integration** | Full bi-directional webhooks with Venemergencia, Nueve Once, Angeles de las Autopistas | Required for SLI |
| **Triage System** | Implement medical triage routing (Emergencia/Urgencia/Leve) with Red ALTEHA clinic integration | When oracle validation is live |
| **Time-Series DB** | Add TimescaleDB extension for telemetry optimization | When telemetry volume requires it |
| **Payments** | Add tokenized card (PCI-DSS), domiciliación (monthly plans) | When bank agreements are signed |
| **Admin Portal** | Commission calculation engine, real-time broker quota dashboards, materialized views | When sales network scales |
| **DR** | Full GCP DR with automated failover from local server | When SLA commitments require it |

### Phase 3 — Enterprise (~12-24 months)

| Component | Change | Trigger |
|---|---|---|
| **AI** | LLM-based liability determination; accident narrative analysis | When claims volume justifies it |
| **Hybrid Payouts** | Parametric + Indemnity two-layer model | When product sophistication demands it |
| **Infrastructure** | Evaluate IBM PowerVS for transactional core (if PostgreSQL bottlenecks) | Likely unnecessary at projected scale |
| **Post-Hospitalization** | Venefarmacia/Farmahogar medication delivery; MMI tracking; rehabilitation coordination | When medical oracle is mature |
| **Compliance** | Full ACORD Next-Gen API standards for B2B interoperability | When integrating with international reinsurers |
| **AIOps** | AI-driven monitoring, anomaly detection, capacity planning | When system complexity demands it |

---

## 13. Cost Analysis

### 13.1 Month 0-3 (MVP Development & Testing)

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

### 13.2 Month 4-8 (Growth + Local Server Transition)

| Item | Cost |
|---|---|
| Supabase Pro (retained for auth/edge) | $25/month |
| Local Venezuelan server (PostgreSQL) | ~$100-300/month (TBD by provider) |
| GCP Cloud SQL (backup/DR, e2-micro) | $0-30/month |
| Vercel Pro (if needed) | $20/month |
| SMS OTP costs (~1000 users) | ~$10/month |
| Twilio (emergency notifications) | ~$20/month |
| Polygon gas fees (~1000 NFTs) | ~$1/month |
| **Total** | **~$176-406/month** |

### 13.3 Year 2+ (Scale + Full SLI)

| Item | Cost |
|---|---|
| Local server infrastructure (scaled) | ~$500-1000/month |
| GCP Cloud SQL (full DR) | ~$100/month |
| GUIA PAY transaction fees | Variable (per-transaction) |
| Venemergencia ($2.75/person/month) | Variable (per-policy, Plus/Ampliada tiers only) |
| Dedicated SMS/WhatsApp provider | ~$50/month |
| Monitoring (Datadog/Grafana) | ~$50/month |
| **Total** | **~$700-1200/month + variable** |

---

## 14. Development Phases & Timeline

### Sprint 0 — Project Setup (Days 1-3)
- [ ] Initialize Flutter project with folder structure
- [ ] Initialize Next.js admin portal with B2B2C routing
- [ ] Create Supabase project; apply database migrations (all tables including brokers, promoters, POS)
- [ ] Configure Supabase Auth (phone OTP + email/password for admins)
- [ ] Set up GitHub repo + CI/CD
- [ ] Configure Supabase Storage buckets (documents, policies, receipts)
- [ ] Deploy admin portal shell to Vercel
- [ ] Seed initial data (carrier, policy types, test broker/promoter)

### Sprint 1 — Authentication & Onboarding (Days 4-10)
- [ ] Welcome screen (Step 1) + registration form (Step 2)
- [ ] Phone OTP login/register flow (Step 3)
- [ ] Home screen with hero card (Step 4)
- [ ] Cédula OCR scanning + field extraction (Step 6a)
- [ ] Carnet de Circulación OCR + field extraction (Step 6b)
- [ ] Vehicle rear photo capture (Step 6c)
- [ ] Image quality validation (sharpness, screen-photo detection)
- [ ] Data review screen with cross-validation (Step 7)
- [ ] Address form (manual fields)
- [ ] Legal consent checkboxes (SUDEASEG compliance)
- [ ] Profile + vehicle creation from OCR data
- [ ] Document image upload to Supabase Storage

### Sprint 2 — Policy & Payment (Days 11-17)
- [ ] Product selection screen with configurable tiers (Step 5)
- [ ] BCV exchange rate Edge Function + cron
- [ ] Quote summary with coverage breakdown + upsells (Step 7.5)
- [ ] Policy emission flow with status handling (Éxito/Observada/Rechazada) (Step 8a)
- [ ] Payment method selection (Pago Móvil P2P + Bank Transfer) (Step 8b)
- [ ] Pago Móvil reference entry
- [ ] Bank transfer receipt upload
- [ ] Confirmation screen with downloads (Step 8c)
- [ ] Admin: payment verification queue + verify/reject actions
- [ ] Payment status tracking (pending → verified)

### Sprint 3 — Policy Card, Claims & Admin (Days 18-24)
- [ ] Policy PDF generation + RCV certificate (Flutter `pdf` package)
- [ ] SHA-256 hash calculation and storage
- [ ] Digital policy card (shareable widget)
- [ ] Policy detail screen with status, dates, coverage, downloads
- [ ] "Mis pólizas" list (vigentes, por pagar, vencidas)
- [ ] Claims submission flow (form + photo upload)
- [ ] Admin: claims review queue
- [ ] Push notifications (payment verified, claim update, policy expired)
- [ ] Offline: cache active policy + certificate for offline viewing

### Sprint 4 — Sales Network, Admin Portal & Polish (Days 25-30)
- [ ] Admin dashboard with key metrics + tier distribution chart
- [ ] Broker management (list, detail, quota progress)
- [ ] Promoter management (list, referral codes)
- [ ] Policy list with search and filters (status, tier, broker, date)
- [ ] Rider directory
- [ ] Referral code tracking (policy → promoter → broker attribution)
- [ ] App polish: loading states, error handling, empty states
- [ ] Offline banner and sync indicators
- [ ] Testing: unit tests for OCR parsers, payment flow, cross-validation
- [ ] Build signed APK for distribution

### Post-Launch Continuous
- [ ] User feedback collection and iteration
- [ ] Carrier onboarding workflow
- [ ] Payment reconciliation tools
- [ ] Policy renewal flow
- [ ] Broker/promoter commission calculation
- [ ] Performance monitoring and optimization
- [ ] Local server procurement and migration planning

---

## 15. Repository Structure

```
RuedaSeguro/
├── README.md
├── research_docs/
│   ├── Architects/                  # 8 research documents
│   ├── original_docs/               # Source documents (PDFs, DOCX, images)
│   ├── MVP_ARCHITECTURE.md          # This document
│   ├── SPRINT_ISSUES.md             # Sprint issues (to be updated)
│   └── Rueda Seguro Plan Review.md  # Strategic realignment report
│
├── mobile/                          # Flutter app
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
├── admin-portal/                    # Next.js B2B2C dashboard
│   ├── package.json
│   ├── next.config.js
│   ├── src/
│   │   ├── app/
│   │   ├── components/
│   │   └── lib/
│   └── public/
│
├── supabase/                        # Supabase configuration
│   ├── config.toml
│   ├── migrations/                  # SQL migrations
│   │   ├── 001_initial_schema.sql   # Core tables (carriers, profiles, vehicles, policies, payments)
│   │   ├── 002_b2b2c_network.sql   # Brokers, promoters, points of sale
│   │   ├── 003_rls_policies.sql     # Row Level Security
│   │   └── 004_functions.sql        # Policy number gen, referral codes
│   ├── functions/                   # Edge Functions
│   │   ├── bcv-rate/
│   │   │   └── index.ts
│   │   ├── admin/
│   │   │   ├── verify-payment/
│   │   │   │   └── index.ts
│   │   │   ├── reject-payment/
│   │   │   │   └── index.ts
│   │   │   ├── review-claim/
│   │   │   │   └── index.ts
│   │   │   ├── carrier-stats/
│   │   │   │   └── index.ts
│   │   │   └── broker-stats/
│   │   │       └── index.ts
│   │   └── generate-policy-pdf/
│   │       └── index.ts
│   └── seed.sql                     # Test data (carrier, policy types, broker, promoter)
│
├── contracts/                       # Solidity (Phase 1.5)
│   ├── RuedaSeguroPolicy.sol        # ERC-721 + EIP-1523
│   ├── hardhat.config.js
│   └── test/
│
├── docs/                            # Additional documentation
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
| **Onboarding completion rate** | >70% | Users who complete all 8 steps to policy issuance |
| **Time to policy** | <6 minutes | From app open to policy emitted (excl. payment verification) |
| **OCR accuracy** | >90% auto-fill | Fields correctly extracted without manual correction |
| **Image quality pass rate** | >85% | First-attempt photos passing sharpness/fraud checks |
| **Payment verification time** | <2 hours | Admin verifies Pago Móvil reference or transfer receipt |
| **Active policies** | 100 in first month | Actual policies issued |
| **Tier distribution** | 70/30 Básica/Plus | Alignment with target product mix |
| **Carrier partners** | 1-2 signed | Insurance companies using the platform |
| **Broker activation** | 5+ active brokers | Brokers with at least 1 policy sold |
| **App crash rate** | <1% | Sentry error monitoring |
| **Offline resilience** | 100% policy viewing | Policy card + certificate always accessible offline |

---

## 17. Regulatory Compliance (MVP)

| Requirement | Implementation |
|---|---|
| **SUDEASEG Gaceta 6.835 — Simplified Contracts** | Policy PDFs use clear, non-technical Spanish. No legal jargon. |
| **"Alternative Channels" (Circular SAA-07-0491-2024)** | RuedaSeguro operates as a digital alternative channel for licensed carriers. |
| **Data Sovereignty** | MVP uses Supabase (cloud) for dev/testing; production migrates to local Venezuelan server (Phase 1.5). GCP authorized as backup. |
| **SUDEASEG Identification Requirements** | Full policyholder and vehicle identification via OCR + manual verification. |
| **Consent & Evidence Conservation** | 4 mandatory consent checkboxes (terms, data truthfulness, anti-fraud, privacy). Timestamps stored. |
| **Audit Trail** | Every state change logged in `audit_log` table. SHA-256 hashes for documents. |
| **Data Privacy** | Minimal PII collection. OCR raw data stored for audit only. No GPS tracking in MVP. |
| **Anti-Fraud** | Image sharpness validation, screen-photo detection, CI/name cross-validation. |
| **PCI-DSS** | No card data stored in MVP (manual payment methods only). PCI compliance deferred to Phase 2 tokenized card. |

---

## 18. Risk Register

| Risk | Impact | Mitigation |
|---|---|---|
| OCR accuracy too low for Venezuelan documents | Users abandon onboarding | Manual entry fallback; iterative regex improvement; PaddleOCR server fallback (Phase 1.5) |
| Pago Móvil reference verification too slow | Users wait hours for policy activation | Hire dedicated payment verifier; prioritize GUIA PAY integration |
| Supabase free tier limits reached early | Service degradation | Monitor usage; upgrade to Pro ($25/month) when at 80% capacity |
| Local server procurement delays | Cannot meet data sovereignty deadline | Continue on Supabase (authorized for dev/testing); accelerate procurement in parallel |
| Carrier partners slow to sign | No policies to sell | Start with Seguros Pirámide (strategic partner); use MVP demo to accelerate others |
| Regulatory pushback on cloud-based dev/testing | Cannot operate legally | Leverage explicit authorization for dev/testing phase; accelerate local server timeline |
| Venemergencia contract not finalized | Cannot launch Plus/Ampliada tiers with medical coverage | Launch with Solo RCV and RCV + Grúa first; add medical tiers when contract is signed |
| Network intermittency breaks critical flows | Data loss, failed payments | Offline-first design; Store & Forward; idempotency keys |
| Venezuelan banking API changes | Payment integration breaks | Abstract payment layer behind interface; support multiple methods |
| Factura de Compra OCR too complex for ML Kit | Onboarding friction for carriers that require it | Defer Factura to Phase 1.5 with server-side OCR; manual entry as fallback |
| Sales network hierarchy adds admin complexity | Slower admin portal development | Start with basic broker/promoter views; commission engine in Phase 2 |

---

*This document is the single source of truth for MVP implementation. All architectural decisions, data models, and feature scopes are defined here. Implementation begins with Sprint 0. Version 2.0 incorporates strategic directives from project leadership regarding data sovereignty, B2B2C sales network, and accelerated Phase 1.5 roadmap.*
