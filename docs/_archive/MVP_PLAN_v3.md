# RuedaSeguro — MVP Plan v3

> **Version:** 3.0 — 2026-03-26
> **Supersedes:** MVP_ARCHITECTURE.md (v2.0, 2026-03-21)
> **Based on:** Meeting 2026-03-24 (Diego, Fernando, Thony, Alex, William, Manuel) + ARCHITECTURE_FINDINGS_2026-03-24.md
> **AZ Capital** (company) · **RuedaSeguro** (product brand)

---

## 0. What Changed in v3

| Topic          | MVP v2                            | MVP v3                                                                                        |
| -------------- | --------------------------------- | --------------------------------------------------------------------------------------------- |
| Admin portal   | Build in Next.js (admin-portal/)  | **Skip entirely** — use Thony's platform                                                      |
| Backend        | Supabase throughout               | **Supabase for dev; design for GCP migration**                                                |
| Telemetry      | 100–200 Hz continuous (Phase 1.5) | **10–15 min circular buffer only** (Alex's spec)                                              |
| Carrier APIs   | Assumed single carrier            | **Acsel + Sirway** dual-system integration                                                    |
| Business model | Tech layer for insurer            | **Payment aggregator**: collect 100%, settle RCV to insurer                                   |
| Policy tiers   | Solo RCV / RCV + Grúa             | **Básica / Plus / Premium** (confirmed by Alex)                                               |
| Admin surface  | Next.js portal                    | **Flutter app designed to export all needed data to Thony's React platform**                  |
| New topics     | Not addressed                     | **Ticket management, admin workflows, call center routing, caching, metrics, data lifecycle** |

---

## 1. Product Vision (Confirmed)

**RuedaSeguro** is a **payment aggregator and coverage orchestrator** for Venezuelan motorcycle insurance. It is NOT just a tech layer — it collects 100% of the insurance premium from the rider, settles the mandatory RCV portion to the licensed insurer, and orchestrates medical coverage via Venemergencia.

```
Rider pays 100% of premium → RuedaSeguro (AZ Capital) gateway
  ├─ Settles $17 (RCV mandatory minimum) → Licensed insurer via Acsel/Sirway API
  ├─ Pays $2.71/motorist/month → Venemergencia (capitation, Plus/Premium only)
  └─ Retains: Technology margin + medical reserve + SLI buffer
```

**Three coverage products:**

| Tier        | Target Price | Coverage                           | On Accident                       |
| ----------- | ------------ | ---------------------------------- | --------------------------------- |
| **Básica**  | ~$17/yr      | RCV only (mandatory liability)     | Cash payout via Pago Móvil        |
| **Plus**    | ~$130–150/yr | RCV + Venemergencia network        | Ambulance dispatch + ER admission |
| **Premium** | ~$200–300/yr | RCV + full recovery + MMI tracking | Above + rehab + milestone payouts |

**Year 1 target:** 10,000 active riders
**ARR at 75,000 riders:** ~$2M (mixed tier distribution)

---

## 2. What Is "Local VZ PostgreSQL" and Do We Need It Now?

### What it means

"Local VZ PostgreSQL" = a PostgreSQL 16 server running on **physical hardware inside Venezuela** — either in a Venezuelan data center (e.g., NET.VEN, CANTV colocation), a local hosting provider, or at AZ Capital's own offices.

Venezuelan insurance regulations (SUDEASEG) require that financial and insurance transaction data reside on servers physically located in Venezuelan territory. No US or European cloud provider (AWS, GCP, Azure, Supabase) has a data center in Venezuela. This means:

- **In production**, the policy records, payment transactions, claims, and rider PII must live on a Venezuelan server
- **In development**, this does NOT apply — we can use any service

### Do we need it for development? No.

**Supabase is the right choice for all development and testing:**

- Free tier covers everything we need (500MB DB, 1GB storage, 50k monthly edge function invocations, 50k auth users)
- Managed PostgreSQL 15 — identical schema compatibility with PostgreSQL 16
- Built-in auth (Phone OTP), storage, edge functions, and realtime
- Zero server management overhead
- No GCP costs until production

### The production migration path

```
Phase 0 (Now – MVP):      Supabase free tier → develop, test, validate
Phase 1.5 (Post-launch):  Add Local VZ Server (PostgreSQL 16) for financial data
                           Supabase retained for: Phone OTP auth, Edge Functions, file storage
Phase 2 (Scale):          GCP Cloud SQL as async replica for DR
                           Local VZ = primary production DB
Phase 3 (Enterprise):     Evaluate Thony's GCP-hosted Quasar platform as backup
```

**Key principle:** Design the Supabase schema NOW as if it's already a standard PostgreSQL 16 database. Avoid Supabase-specific extensions. Use standard SQL, standard foreign keys, standard UUID v4 primary keys. When production time comes, `pg_dump | pg_restore` should be the entire migration.

### Local VZ Server specs (for when we need it)

A $200–400/month VPS from Venezuelan hosting providers (e.g., AbcHosting.ve, NetVirtual) running:

- Ubuntu 22.04 LTS
- PostgreSQL 16 + TimescaleDB extension
- Nginx reverse proxy
- Automated daily backups to GCP Cloud Storage

**No GCP costs during development. Supabase free tier covers everything.**

---

## 3. Decisions: Final (All 10 Resolved)

| #   | Decision             | Answer                                                                                                                            |
| --- | -------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Mobile app framework | **Flutter 3.x** — keep Sprint 0–1 work; Dart isolates superior for background sensors                                             |
| 2   | Backend platform     | **Supabase (dev) → PostgreSQL 16 (production)** — no GCP costs now                                                                |
| 3   | Admin portal         | **Skip Next.js admin-portal/** — use Thony's React platform (RuedaSeguro-branded); Flutter app designed to export all needed data |
| 4   | Infrastructure       | **Supabase free tier now; Local VZ + GCP DR when production**                                                                     |
| 5   | Telemetry scope      | **10–15 min circular buffer around accident** (Alex's explicit spec); feature flag for behavioral upgrade                         |
| 6   | Blockchain           | **SHA-256 in DB for MVP** → Polygon ERC-721 Phase 1.5 (TRON TBD — ask Alex)                                                       |
| 7   | Payments             | **Pago Móvil P2P (manual verify) for MVP** → GUIA PAY C2P Phase 1.5 (get docs from Alex)                                          |
| 8   | OCR                  | **Google ML Kit on-device** (Cédula + Carnet) → PaddleOCR server fallback Phase 1.5 (Factura)                                     |
| 9   | Naming               | **AZ Capital** = company; **RuedaSeguro** = product brand; Thony's engine = internal only, never exposed                          |
| 10  | Policy issuance      | **Dual channel**: real-time Acsel/Sirway API → provisional fallback if API down → reconciliation queue                            |

---

## 4. System Architecture (Current State)

```
┌───────────────────────────────────────────────────────┐
│                RUEDASEGURO MOBILE APP (Flutter)        │
│                                                        │
│  Auth: Phone OTP + Anonymous bypass (debug)           │
│  State: Riverpod StateNotifier + GoRouter             │
│  OCR: Google ML Kit on-device (Cédula + Carnet)      │
│  Onboarding: 7-screen wizard → OnboardingData         │
│  Tests: 7 files, 120 test cases                       │
│                                                        │
│  [Sprint 2 additions]:                                 │
│  Policy quoting → payment → issuance → PDF card       │
│  SQLite circular buffer (telemetry foundation)         │
│  MQTT client → Thony's backend event stream           │
└────────────────────┬──────────────────────────────────┘
                     │ supabase_flutter SDK + MQTT
                     ▼
┌───────────────────────────────────────────────────────┐
│              SUPABASE (Dev Backend)                   │
│                                                        │
│  Auth: Phone OTP (Twilio) + Anonymous               │
│  Database: PostgreSQL (20 tables + new additions)    │
│  Storage: documents, policies, receipts, public      │
│  Edge Functions: bcv-rate, send-otp, verify-otp      │
│                                                        │
│  [Sprint 2]: Add RLS policies, profile writes,        │
│  payment records, policy records, ticket table        │
└────────────────────┬──────────────────────────────────┘
                     │ Events (MQTT / webhooks)
                     ▼
┌───────────────────────────────────────────────────────┐
│          THONY'S PLATFORM (RuedaSeguro-branded)       │
│          React + Node.js + PostgreSQL + MQTT           │
│                                                        │
│  7 Role Portals (via Thony — NOT our code to build):  │
│  Admin Console · Ops Desk · Management · Insurer      │
│  Venemergencia Dispatch · Clinical Triage · Broker     │
│                                                        │
│  Our obligation: publish clean events for each portal  │
└───────────────────────────────────────────────────────┘
```

### 4.1 What We Build vs. What Thony Builds

| Surface                          | Who builds it              | Our role                                |
| -------------------------------- | -------------------------- | --------------------------------------- |
| Flutter mobile app               | Diego/Fernando             | Build everything                        |
| Supabase schema + Edge Functions | Diego/Fernando             | Build everything                        |
| Admin portal (7 portals)         | Thony                      | **We provide clean data + MQTT events** |
| Carrier API integration          | Diego/Fernando             | Build REST client for Acsel/Sirway      |
| GUIA PAY integration             | Diego/Fernando (Phase 1.5) | After Alex provides docs                |
| Venemergencia dispatch API       | Thony + Diego              | Shared responsibility                   |
| Blockchain minting (Phase 1.5)   | Diego/Fernando             | Polygon ERC-721 smart contract          |

### 4.2 Events We Must Publish for Thony's 7 Portals

Every significant action in the app must emit an **event** (via MQTT or Supabase Realtime) so Thony's platform can update its dashboards in real time.

| Portal (Thony's)       | Events we must emit                                                                |
| ---------------------- | ---------------------------------------------------------------------------------- |
| Management overview    | `policy.issued`, `payment.confirmed`, `incident.detected`, `subscriber.churned`    |
| Insurance Partner      | `policy.issued`, `policy.expired`, `incident.opened`, `clinical.handover`          |
| Venemergencia Dispatch | `incident.detected` (GPS, rider profile, impact data, blood type)                  |
| Clinical Care          | `ambulance.enroute`, `patient.arrived`, `insurance.verified`, `patient.discharged` |
| Broker Pipeline        | `policy.issued_via_broker`, `policy.expiring_soon`, `renewal.link.sent`            |
| Customer Ops Desk      | `ticket.created`, `ticket.updated`, `payment.failed`, `api.error`                  |
| Administration         | `subscriber.count_delta`, `pricebook.changed`, `partner.onboarded`                 |

---

## 5. Database Schema v3 (Supabase → PostgreSQL 16 compatible)

### 5.1 Existing Tables (Sprint 0–1, 20 tables)

```
B2B2C Network:     carriers, carrier_users, brokers, promoters, points_of_sale
Rider Identity:    profiles, vehicles, documents
Insurance Core:    policy_types, policies, payments, claims, claim_evidence
Finance:           exchange_rates
Compliance:        audit_log
```

**Current status:** Tables created; **RLS policies NOT yet applied** (Sprint 2 critical).

### 5.2 New Tables Required (Sprint 2+)

```sql
-- Telemetry foundation (Sprint 2)
telemetry_events (
  id UUID PK,
  rider_id UUID FK profiles,
  policy_id UUID FK policies,
  event_type TEXT,           -- 'heartbeat' | 'impact_detected' | 'emergency_mode' | 'cancelled'
  g_force NUMERIC,
  latitude NUMERIC, longitude NUMERIC,
  altitude NUMERIC,
  speed_kmh NUMERIC,
  recorded_at TIMESTAMPTZ,   -- device timestamp (ISO 8601)
  synced_at TIMESTAMPTZ,     -- backend receipt timestamp
  payload_json JSONB,        -- raw sensor window (15 min buffer)
  idempotency_key UUID UNIQUE  -- deduplication
)

-- Ticket system (Sprint 2)
tickets (
  id UUID PK,
  entity_type TEXT,          -- 'rider' | 'broker' | 'clinic' | 'insurer' | 'system'
  entity_id UUID,
  subject TEXT,
  description TEXT,
  priority TEXT,             -- 'critical' | 'high' | 'medium' | 'low'
  status TEXT,               -- 'open' | 'in_progress' | 'waiting_on_user' | 'waiting_on_partner' | 'resolved' | 'closed'
  assigned_agent TEXT,
  carrier_ref TEXT,          -- cross-reference to carrier ticket system if any
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  resolved_at TIMESTAMPTZ
)

ticket_comments (
  id UUID PK,
  ticket_id UUID FK tickets,
  author_type TEXT,          -- 'agent' | 'rider' | 'system'
  author_id UUID,
  body TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
)

-- Clinical handovers (Phase 1.5)
clinical_handovers (
  id UUID PK,
  incident_id UUID FK telemetry_events,
  rider_id UUID FK profiles,
  clinic_id UUID,            -- reference to ALTEHA partner network
  ambulance_unit TEXT,
  eta_minutes INT,
  insurance_verified_at TIMESTAMPTZ,
  admitted_at TIMESTAMPTZ,
  discharged_at TIMESTAMPTZ,
  status TEXT,               -- 'dispatched' | 'enroute' | 'arrived' | 'treating' | 'discharged'
  advance_cleared BOOLEAN DEFAULT false,
  advance_amount NUMERIC
)

-- Renewal management (Sprint 3)
renewal_links (
  id UUID PK,
  policy_id UUID FK policies,
  broker_id UUID FK brokers,
  pago_movil_link TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  sent_at TIMESTAMPTZ,
  clicked_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ    -- 30 days after creation
)

-- SLA configuration (Sprint 2)
sla_config (
  entity_type TEXT,
  priority TEXT,
  target_minutes INT,
  PRIMARY KEY (entity_type, priority)
)
```

### 5.3 New Columns on Existing Tables

```sql
-- policies: provisional fallback support (Decision 10)
ALTER TABLE policies ADD COLUMN
  issuance_status TEXT DEFAULT 'pending',  -- 'pending' | 'provisional' | 'confirmed' | 'rejected'
  carrier_policy_number TEXT,              -- from Acsel/Sirway API
  carrier_api_attempts INT DEFAULT 0,
  provisional_issued_at TIMESTAMPTZ,
  confirmed_at TIMESTAMPTZ;

-- policies: data lifecycle
ALTER TABLE policies ADD COLUMN
  archived_at TIMESTAMPTZ,
  retain_until DATE;  -- 7 years from issuance per SUDEASEG

-- payments: idempotency
ALTER TABLE payments ADD COLUMN
  idempotency_key UUID UNIQUE,
  pago_movil_reference TEXT,
  receipt_url TEXT,                        -- uploaded receipt image
  verified_by TEXT,                        -- agent who verified
  verified_at TIMESTAMPTZ;

-- profiles: emergency contact + blood type
ALTER TABLE profiles ADD COLUMN
  blood_type TEXT,
  emergency_contact_name TEXT,
  emergency_contact_phone TEXT,
  emergency_contact_relation TEXT;
```

---

## 6. Data Lifecycle & Retention Policy

From Day 1, all tables that contain retention-sensitive data must have `archived_at` and `retain_until` columns. This avoids schema migrations later when SUDEASEG compliance is enforced.

| Data Type                  | Active Storage                  | Retention                       | Archive           |
| -------------------------- | ------------------------------- | ------------------------------- | ----------------- |
| Active policies            | PostgreSQL hot                  | Forever (while active)          | —                 |
| Expired/cancelled policies | PostgreSQL → archive            | 7 years (Venezuelan civil code) | GCP Cloud Storage |
| Payment transactions       | PostgreSQL                      | 7 years (SENIAT)                | GCP Cloud Storage |
| Telemetry: impact window   | PostgreSQL                      | 5 years (claim evidence)        | Compressed JSONB  |
| Telemetry: heartbeats      | PostgreSQL (rolling)            | 30 days                         | Deleted           |
| OCR document images        | Supabase Storage → local        | 1 year post-policy-expiry       | GCP Archive       |
| SHA-256 policy hashes      | PostgreSQL                      | Indefinite (<1KB each)          | Never delete      |
| Tickets                    | PostgreSQL                      | 3 years                         | GCP Archive       |
| Broker commission records  | PostgreSQL                      | 7 years                         | GCP Archive       |
| BCV rate history           | PostgreSQL                      | 10 years                        | —                 |
| MQTT event stream          | 7-day buffer (Thony's platform) | Monthly aggregates              | —                 |
| Audit log                  | PostgreSQL (append-only)        | Indefinite                      | Never delete      |

---

## 7. Caching Strategy

### BCV Exchange Rate Cache

The BCV API is unreliable. Cache behavior:

```
┌─ Edge Function: bcv-rate ─────────────────────────────────┐
│  GET /functions/v1/bcv-rate                               │
│  1. Check exchange_rates table for latest entry           │
│  2. If entry age < 60 minutes → return cached rate        │
│  3. If stale → attempt BCV API call                       │
│  4. If BCV offline → return last known rate + flag:       │
│     { rate: 36.50, stale: true, last_updated: "..." }     │
│  5. Flutter shows "Tasa aproximada" amber badge if stale  │
└───────────────────────────────────────────────────────────┘
```

All payment records store: `usd_amount`, `ves_amount`, `bcv_rate_at_time`, `bcv_rate_timestamp` — so financial records are never dependent on live rates.

### Policy Validation Cache (for clinic QR scan)

When Thony's clinical portal scans a QR code:

- Redis (Upstash, Thony's platform) caches policy validity for 5 minutes
- Cache key: `policy:{policy_id}:valid`
- Cache invalidated on: policy cancelled, payment failed

### Flutter App Cache

- `OnboardingData`: in-memory Riverpod StateNotifier (device lifetime)
- Policy PDF: stored in Supabase Storage; local path cached in SharedPreferences
- BCV rate: cached in-memory for current session; re-fetched on app restart
- Auth token: handled by Supabase SDK automatically

### MQTT Deduplication

Events published by Flutter to Thony's MQTT broker:

- Each event carries a UUID `idempotency_key`
- Backend stores key in Redis with 60-second TTL
- Duplicate key within 60s → silently ignored
- Prevents double-counting on reconnect retries

---

## 8. Observability & Metrics

Metrics are collected in Supabase PostgreSQL and consumed by Thony's management portal.

### Business Metrics (materialized view, refresh every 15 min)

```sql
CREATE MATERIALIZED VIEW metrics_daily AS
SELECT
  DATE(created_at) AS date,
  COUNT(*) FILTER (WHERE status = 'confirmed') AS policies_issued,
  COUNT(*) FILTER (WHERE tier = 'basic') AS basic_count,
  COUNT(*) FILTER (WHERE tier = 'plus') AS plus_count,
  COUNT(*) FILTER (WHERE tier = 'premium') AS premium_count,
  SUM(premium_usd) AS gross_premium_usd,
  COUNT(DISTINCT broker_id) AS active_brokers
FROM policies
GROUP BY DATE(created_at);
```

### Operational Metrics (real-time, from audit_log)

| Metric               | Source                                         | Alert threshold       |
| -------------------- | ---------------------------------------------- | --------------------- |
| Open ticket count    | tickets WHERE status != 'closed'               | > 20 → notify ops     |
| SLA breach rate      | tickets WHERE resolved_at > SLA target         | > 10% → escalate      |
| API error rate       | audit_log WHERE event_type = 'api_error'       | > 5/min → alert       |
| Payment failure rate | payments WHERE status = 'failed'               | > 3% → notify finance |
| Policy issuance lag  | policies WHERE confirmed_at - created_at > 30s | Monitor only          |

### App Performance Metrics

Collected via Sentry (install in Sprint 3):

- Screen load times (target <500ms)
- OCR success rate (target >85% auto-parse)
- Payment flow completion rate (target >70% conversion)
- Crash rate (target <0.1%)

---

## 9. Admin Workflow Definitions

### 9.1 Policy Issuance

```
State machine: PENDING → API_SUBMITTED → CONFIRMED | PROVISIONAL | REJECTED

PENDING:        Payment verified by admin OR GuiaPay C2P confirmed
API_SUBMITTED:  Acsel/Sirway API called (max 3 attempts, 10s timeout each)
CONFIRMED:      Carrier returned policy number → PDF generated → sent to rider
PROVISIONAL:    API failed 3 times → provisional PDF issued (watermarked) →
                retry queue runs every 15 min → upgrades to CONFIRMED when API responds
REJECTED:       Carrier rejected (fraud flag, invalid data) → refund triggered
```

### 9.2 Claims Authorization

```
State machine: REPORTED → EVIDENCE_REVIEW → APPROVED | REJECTED → PAID

REPORTED:        Rider submits claim form + photos
EVIDENCE_REVIEW: Admin reviews; auto-approved if parametric trigger (Phase 1.5)
APPROVED:        Payment initiated via Pago Móvil P2P (MVP) or GuiaPay (Phase 1.5)
PAID:            Payment confirmed, policy marked as claimed
```

### 9.3 Payment Verification (MVP manual flow)

```
Rider selects Pago Móvil P2P → App shows payment details
Rider completes transfer in their bank app
Rider enters reference number in app (or uploads screenshot)
System: creates payment record with status = 'pending_verification'
Admin (Ops Desk): sees pending payment → clicks "Verify" → status = 'confirmed'
System: triggers policy issuance flow
```

---

## 10. Call Center / Client Service Routing

**MVP implementation: WhatsApp Business + in-app ticket creation**

### Contact Channels

| Channel                    | Technology              | Routing                                       |
| -------------------------- | ----------------------- | --------------------------------------------- |
| In-app "Reportar Problema" | Supabase → ticket table | Auto-creates ticket; shows ticket ID to rider |
| WhatsApp Business          | Twilio WhatsApp API     | Bot triage → human if needed                  |
| Broker portal issue        | Thony's platform        | Creates MEDIUM ticket with broker_id          |
| Clinic API timeout         | System auto-detected    | Creates HIGH ticket with error details        |

### Routing Logic (WhatsApp Bot, Phase 1.5)

```
Rider contacts RuedaSeguro WhatsApp
  ├─ "1. Mi pago no se procesó" → CRITICAL ticket → immediate agent
  ├─ "2. Tengo un accidente" → redirect to emergency 0800 + Venemergencia contact
  ├─ "3. Necesito mi póliza" → auto-reply with policy PDF link
  └─ "4. Otro" → creates MEDIUM ticket; agent responds in <8 hours
```

**MVP scope:** Only in-app ticket creation. WhatsApp bot in Phase 1.5 (requires Twilio WhatsApp Business agreement).

---

## 11. Current State (Sprint 0 + Sprint 1 — Complete)

### Built and Working

**Flutter Mobile App:**

- Auth: Phone OTP (with dev bypass) + anonymous session
- Navigation: GoRouter with 20 named routes across 3 access levels
- State: Riverpod StateNotifier, GoRouterRefreshStream
- Onboarding: 7 screens — cedula_scan → cedula_confirm → carnet_scan → vehicle_photo → vehicle_confirm → address_form → consent
- OCR: CedulaParser (V/E/CC), CarnetParser (VE/CO plates), CrossValidator, ImageValidator
- Design system: Navy #1A3A52 + Orange #FF6B35, Montserrat + Lato, 4px grid
- Tests: 7 files, 120 test cases (currency, hash, date, validators, parsers, cross-validator)

**Supabase Backend:**

- 20 tables with relationships (no RLS yet)
- 4 storage buckets
- 3 edge functions (bcv-rate, send-otp, verify-otp)
- Schema designed for PostgreSQL 16 compatibility

**Admin Portal (admin-portal/):**

- Sprint 0 scaffold exists in repo
- **Status: FROZEN — no further development. Will be replaced by Thony's platform.**

### Known Issues / Technical Debt

| Issue                       | Priority | Notes                                |
| --------------------------- | -------- | ------------------------------------ |
| RLS policies not applied    | CRITICAL | All 20 tables publicly readable      |
| Profile not written to DB   | CRITICAL | Consent screen stores only in memory |
| SMS OTP requires dev bypass | HIGH     | Twilio not configured                |
| `admin-portal/` in repo     | MEDIUM   | Freeze, document as deprecated       |
| No MQTT client in Flutter   | HIGH     | Needed for Thony's platform events   |

---

## 12. Sprint Plan

### Sprint 2 — Data Foundation & Policy Issuance

**Duration:** 2 weeks
**Goal:** Close the loop: rider completes onboarding → profile saved → policy quoted → payment submitted → policy PDF issued
**Does NOT include:** Carrier API, GUIA PAY, real SMS (still dev bypass), admin portal

#### Sprint 2A — Data Layer (Week 1)

| Ticket | Task                                                                                                                                                             | Priority |
| ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| RS-041 | Apply RLS policies to all 20 tables (multi-tenant isolation per carrier)                                                                                         | CRITICAL |
| RS-042 | Write profile to DB on consent screen submit (name, Cédula, DOB, address, blood type, emergency contact)                                                         | CRITICAL |
| RS-043 | Write vehicle to DB (plate, brand, model, year, carnet data)                                                                                                     | CRITICAL |
| RS-044 | Write documents to DB (OCR confidence scores, image URLs in Supabase Storage)                                                                                    | HIGH     |
| RS-045 | Add new schema: `telemetry_events`, `tickets`, `ticket_comments`, `renewal_links`, `sla_config`                                                                  | HIGH     |
| RS-046 | Add new columns: `policies.issuance_status`, `policies.carrier_policy_number`, `payments.idempotency_key`, `profiles.blood_type`, `profiles.emergency_contact_*` | HIGH     |
| RS-047 | Add `retain_until` and `archived_at` to all retention-critical tables                                                                                            | MEDIUM   |
| RS-048 | BCV rate edge function: implement 60-min cache + stale flag + fallback                                                                                           | HIGH     |

#### Sprint 2B — Policy & Payment Flow (Week 2)

| Ticket | Task                                                                                                                                                                                                         | Priority |
| ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------- |
| RS-049 | Product selection screen: fetch active `policy_types` from DB (not hardcoded)                                                                                                                                | CRITICAL |
| RS-050 | Quote summary screen: calculate premium in USD + VES using live BCV rate; show "Tasa aproximada" badge if stale                                                                                              | CRITICAL |
| RS-051 | Payment method screen: implement Pago Móvil P2P flow (show account details + reference input)                                                                                                                | CRITICAL |
| RS-052 | Payment record: create `payments` row with `status = pending_verification` + `idempotency_key`                                                                                                               | HIGH     |
| RS-053 | Policy PDF generation: `pdf` package — include policy number (provisional), rider name, plate, tier, validity dates, SHA-256 hash, QR code (URL to verification endpoint), AZ Capital / RuedaSeguro branding | HIGH     |
| RS-054 | Policy record: create `policies` row with `issuance_status = provisional` + SHA-256 hash + PDF URL                                                                                                           | HIGH     |
| RS-055 | Policy card screen: show digital policy card (tier badge, PDF download, QR code)                                                                                                                             | HIGH     |
| RS-056 | Home screen: show active policy summary (tier, expiry, status)                                                                                                                                               | MEDIUM   |
| RS-057 | Supabase materialized view `metrics_daily` (refresh every 15 min)                                                                                                                                            | MEDIUM   |
| RS-058 | Audit log: emit event for each state transition (profile_created, payment_submitted, policy_provisional, etc.)                                                                                               | MEDIUM   |
| RS-059 | MQTT client in Flutter (mqtt_client package): connect to Thony's broker; emit `policy.issued` event on policy creation                                                                                       | MEDIUM   |

#### Sprint 2 Exit Criteria

- [ ] A real rider can complete full onboarding → their profile is in Supabase DB
- [ ] A rider can select a policy tier → see USD + VES price (live BCV rate)
- [ ] A rider can enter a Pago Móvil reference → `payments` row created with `pending_verification`
- [ ] A provisional policy PDF is generated with SHA-256 hash and QR code
- [ ] Policy card screen shows the active policy
- [ ] All 20 original tables have RLS applied
- [ ] `metrics_daily` view is queryable by Thony's platform

---

### Sprint 3 — Policy Lifecycle & Carrier Integration

**Duration:** 2 weeks
**Goal:** Policies backed by real carrier policy numbers; renewal flow; claims form; Twilio SMS live

| Ticket | Task                                                                                                                | Priority     |
| ------ | ------------------------------------------------------------------------------------------------------------------- | ------------ | -------- |
| RS-060 | Acsel/Sirway API client: sandbox discovery with William (exact endpoint, auth, payload)                             | CRITICAL     |
| RS-061 | Policy issuance state machine: `PENDING → API_SUBMITTED → CONFIRMED                                                 | PROVISIONAL` | CRITICAL |
| RS-062 | Provisional fallback: retry queue (every 15 min, max 3 attempts over 1 hour)                                        | HIGH         |
| RS-063 | Real SMS OTP via Twilio: remove dev bypass in production build (keep in kDebugMode)                                 | HIGH         |
| RS-064 | Policy card screen: show PROVISIONAL watermark until carrier confirms                                               | HIGH         |
| RS-065 | Push notification on policy confirmation: "Tu póliza fue confirmada"                                                | HIGH         |
| RS-066 | Renewal reminder system: Edge Function that queries `policies` where `expiry < now() + 30 days` → push notification | HIGH         |
| RS-067 | Claims form: evidence upload (3 photos), description, location auto-filled, `claims` row created                    | HIGH         |
| RS-068 | Ticket creation in-app: "Reportar Problema" button → `tickets` row created → show ticket ID                         | MEDIUM       |
| RS-069 | Broker renewal link: Edge Function generates Pago Móvil deep-link for expiring policies → `renewal_links` row       | MEDIUM       |
| RS-070 | Sentry integration: crash reporting + performance monitoring                                                        | MEDIUM       |
| RS-071 | SQLite circular buffer (15-min window): implement `anomaly_queue` schema, no sensor activation yet                  | MEDIUM       |
| RS-072 | App performance: target <500ms screen load, <2s OCR parse                                                           | LOW          |
| RS-073 | Freeze admin-portal/ directory: add DEPRECATED.md, disable CI workflow                                              | LOW          |

#### Sprint 3 Exit Criteria

- [ ] Policy is issued with a real carrier policy number (from Acsel/Sirway sandbox)
- [ ] If carrier API fails: provisional PDF issued; retries work
- [ ] SMS OTP works without dev bypass in release builds
- [ ] Rider receives push notification on policy confirmation
- [ ] Rider can submit a basic claim with photo evidence
- [ ] Sentry error tracking is active

---

### Sprint 4 — Emergency Foundation & Phase 1.5 Kickoff

**Duration:** 2 weeks
**Goal:** Lay the sensor and emergency infrastructure; prepare GUIA PAY and Venemergencia integrations

| Ticket | Task                                                                                                 | Priority       |
| ------ | ---------------------------------------------------------------------------------------------------- | -------------- | ----------------- | ------ |
| RS-074 | Background service foundation: Dart isolate + `sensors_plus` activation + permission request         | CRITICAL       |
| RS-075 | 15-min SQLite circular buffer activation: start writing accelerometer data (x, y, z, g)              | CRITICAL       |
| RS-076 | 4G impact detection algorithm: Butterworth filter (high-pass 0.1 Hz + low-pass 50 Hz for smartphone) | CRITICAL       |
| RS-077 | Emergency Mode UI: 10-second countdown, "Estoy bien" cancel button, haptic feedback                  | HIGH           |
| RS-078 | Buffer flush on impact: serialize 15-min window → `telemetry_events` row (via MQTT + REST fallback)  | HIGH           |
| RS-079 | Emergency contact notification: Twilio WhatsApp message with rider name, GPS link, blood type        | HIGH           |
| RS-080 | PAS Protocol: notify Venemergencia webhook (POST rider profile + impact data + GPS)                  | HIGH           |
| RS-081 | GUIA PAY integration research: document API endpoints from Alex, test sandbox                        | HIGH           |
| RS-082 | Heartbeat event: publish `rider.alive` MQTT event every 5 minutes while app is in foreground         | MEDIUM         |
| RS-083 | `telemetry_mode` feature flag: `HEARTBEAT_ONLY`                                                      | `EVENT_WINDOW` | `FULL_BEHAVIORAL` | MEDIUM |
| RS-084 | MFCL validation scaffold: stub 6-check orchestration service (to be completed in Phase 1.5)          | LOW            |

#### Sprint 4 Exit Criteria

- [ ] App detects 4G impact in background without killing battery (test on physical device)
- [ ] Emergency countdown triggers automatically; can be cancelled by rider
- [ ] Impact flushes circular buffer to DB
- [ ] Emergency contact receives WhatsApp with GPS link
- [ ] GUIA PAY sandbox credentials obtained from Alex

---

### Phase 1.5 — SLI & Medical Network (Post-Sprint 4)

**~6 weeks after Sprint 4**

| Feature                        | Scope                                                                                |
| ------------------------------ | ------------------------------------------------------------------------------------ |
| GUIA PAY C2P integration       | Automated premium collection; 25% advance payout                                     |
| Venemergencia full integration | Dispatch terminal API; clinical handover events                                      |
| MFCL validation service        | 6 parallel checks: kinetic, OCR identity, DLT, GPS, clinical capacity, GUIA PAY node |
| Clinical handover API          | Admission token; "Quasar Validated" badge; discharge sync                            |
| Polygon ERC-721 (optional)     | NFT policy minting; EIP-1523 metadata                                                |
| PaddleOCR server fallback      | For Factura de Compra variable layouts                                               |
| WhatsApp bot routing           | Twilio WhatsApp Business; triage rules                                               |
| Domiciliación (auto-debit)     | Monthly payment plans                                                                |

---

## 13. What We Are NOT Building (Explicit Scope Boundaries)

| Item                                   | Reason                                                    |
| -------------------------------------- | --------------------------------------------------------- |
| `admin-portal/` Next.js portal         | Replaced by Thony's React platform                        |
| IBM Power9 infrastructure              | Phase 3+ only if PostgreSQL bottlenecks at 150k+ policies |
| Full 100–200 Hz behavioral telemetry   | Phase 2; Alex deferred it explicitly                      |
| TRON blockchain wallet                 | Unclear requirement; ask Alex                             |
| IVR / phone call center                | Phase 2; WhatsApp sufficient for MVP                      |
| LLM liability analysis                 | Phase 3+                                                  |
| Custom biometric identity verification | Phase 2; `local_auth` installed, not wired                |
| Factura de Compra OCR                  | Phase 1.5 with PaddleOCR                                  |
| InfluxDB 3.0 time-series               | Replaced by SQLite circular buffer + PostgreSQL           |
| Multiple insurer white-labeling        | Single carrier (Mercantil/Estar Seguro) for MVP           |

---

## 14. Tech Stack Summary

| Layer                | Technology                                                | Source of Truth                           |
| -------------------- | --------------------------------------------------------- | ----------------------------------------- |
| Mobile               | Flutter 3.x (Dart)                                        | Riverpod + GoRouter                       |
| Mobile sensors       | sensors_plus + geolocator + background_fetch              | Sprint 4                                  |
| Mobile telemetry     | SQLite circular buffer (15-min window)                    | Sprint 3 (schema) / Sprint 4 (activation) |
| Mobile MQTT          | mqtt_client package                                       | Sprint 2                                  |
| Auth (dev)           | Supabase Phone OTP + anonymous                            | Existing                                  |
| Auth (prod)          | Supabase Phone OTP (Twilio verified)                      | Sprint 3                                  |
| Database             | Supabase PostgreSQL (dev) → Local VZ PostgreSQL 16 (prod) | When production ready                     |
| File storage         | Supabase Storage (dev) → GCP Cloud Storage (prod)         | When production ready                     |
| Edge functions       | Supabase Edge Functions (Deno)                            | Existing + Sprint 2                       |
| OCR                  | Google ML Kit (on-device)                                 | Existing                                  |
| OCR fallback         | Self-hosted PaddleOCR                                     | Phase 1.5                                 |
| Payments MVP         | Pago Móvil P2P (manual verify)                            | Sprint 2                                  |
| Payments Phase 1.5   | GUIA PAY C2P                                              | After Alex provides docs                  |
| Blockchain MVP       | SHA-256 in PostgreSQL                                     | Sprint 2                                  |
| Blockchain Phase 1.5 | Polygon ERC-721 (EIP-1523)                                | Phase 1.5                                 |
| Push notifications   | Supabase → Firebase Cloud Messaging                       | Sprint 3                                  |
| Error tracking       | Sentry                                                    | Sprint 3                                  |
| MQTT broker          | Thony's platform                                          | Sprint 2 (client side)                    |
| Admin platform       | Thony's React (RuedaSeguro-branded)                       | External                                  |
| Carrier APIs         | Acsel + Sirway REST                                       | Sprint 3                                  |
| SMS (OTP)            | Twilio SMS via Supabase Edge Function                     | Sprint 3                                  |
| WhatsApp emergency   | Twilio WhatsApp API                                       | Sprint 4                                  |

---

## 15. Open Questions (Blocking Future Sprints)

| Question                                             | Blocker for          | Owner              |
| ---------------------------------------------------- | -------------------- | ------------------ |
| Acsel/Sirway API specs + sandbox access              | Sprint 3 (RS-060)    | William Porras     |
| SUDEASEG required audit log fields                   | Sprint 2 (RS-058)    | William Porras     |
| GUIA PAY API documentation                           | Phase 1.5            | Alex Sánchez       |
| TRON wallet requirement (yes/no)                     | Phase 1.5 blockchain | Alex Sánchez       |
| Venemergencia dispatch API format                    | Sprint 4 (RS-080)    | Thony + Alex       |
| Sensor threshold: 4G or 9G?                          | Sprint 4 (RS-076)    | Manuel (actuarial) |
| Tariff breakdown ($17 split: insurer vs. commission) | Revenue modeling     | Manuel             |
| SLI reserve fund structure                           | Phase 1.5            | Alex + Manuel      |
| ALTEHA clinic API (unified or per-clinic)            | Phase 1.5            | Alex               |
| MQTT broker URL (Thony's platform)                   | Sprint 2 (RS-059)    | Thony              |
| Equity structure finalization                        | Ongoing              | Diego + Alex       |

---

_Supersedes MVP_ARCHITECTURE.md (v2.0)_
_Next document: Sprint Issues (to be created from Section 12)_
_Update triggers: William/Manuel discovery session, GuiaPay docs from Alex, Thony's MQTT broker specs_
