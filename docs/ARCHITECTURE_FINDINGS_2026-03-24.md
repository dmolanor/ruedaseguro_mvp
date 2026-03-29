# RuedaSeguro — Architecture Findings & Strategic Realignment

**Version:** 2026-03-24 | Post-Meeting + Full Document Analysis
**Sources:** Meeting transcript (Diego, Fernando, Thony, Alex, William, Manuel) · 28 original documents · 7 dashboard mockups · MVP_ARCHITECTURE.md · TECHNICAL_PROGRESS.md · 7 architect docs
**Prepared by:** Claude Code analysis session

---

## 0. Executive Summary

Three critical discoveries emerged from this analysis cycle:

1. **The business model is fundamentally different from what the MVP assumed.** RuedaSeguro is not just a tech layer — it is a **payment aggregator and coverage orchestrator**. It collects 100% of the insurance premium, settles the RCV portion ($17) to the licensed insurer, and retains the health coverage premium to pay Venemergencia's capitation ($2.71/motorist/month) and fund the technology margin. This changes financial flows, regulatory obligations, and settlement architecture.

2. **Thony already has a running platform ("Quasar Portal")** built in React + Node.js + PostgreSQL + MQTT, already supporting 4,000 IoT assets in Google Cloud, and already mockupped for 7 role-specific admin portals (admin console, customer service desk, management overview, insurer view, Venemergencia dispatch terminal, clinical triage, broker pipeline). This platform is commercially priced at $15/asset/month in Abu Dhabi. The current Next.js admin portal is potentially duplicating this work.

3. **Ten architectural decision points have no consensus** across the existing documents, the meeting, and the new engineering materials. Each is documented below with full path analysis. Several decisions (notably: Flutter vs React, Next.js vs Thony's React, blockchain activation timing, infrastructure provider) must be resolved before Sprint 2 can begin in earnest.

**Immediate next steps:**
- Schedule discovery session with William Porras (process flows) + Manuel (tariffs) → see Section 8
- Resolve Decision 1 and Decision 3 (app framework + admin portal) as a team — these block everything
- Get GuiaPay commercial agreement status from Alex

---

## 1. Meeting Findings (2026-03-24)

**Participants:** Diego, Fernando, Thony (Abu Dhabi), Alex Sánchez Pupo, William Porras, Manuel

### 1.1 Business Model Clarification (Critical)

The business model confirmed in the meeting is **fundamentally more integrated** than the MVP plan assumed:

> *"La pasarela de pagos es de nosotros y está pegada a la aplicación. Nosotros recaudamos el cien por ciento de la póliza y le liquidamos a la aseguradora su parte."* — Alex

**Financial flow (confirmed):**
```
Rider pays 100% of premium → RuedaSeguro payment gateway
  ├─ Settles $17 (RCV regulatory minimum) → Insurer (Acsel/Sirway API)
  ├─ Pays $2.71/month capitation → Venemergencia (per active policy on Plus/Premium)
  └─ Retains: Technology fee + health coverage margin + SLI reserve fund
```

**Three coverage products (confirmed by Alex):**
| Tier | Price (est.) | What it covers | On accident |
|------|-------------|----------------|-------------|
| Básica | $17/yr | RCV only (mandatory liability) | Cash indemnization via Pago Móvil |
| Plus | ~$130–150/yr | RCV + Venemergencia medical | Ambulance dispatch + ER admission |
| Ampliada/Premium | ~$200–300/yr | RCV + full recovery journey | ER → rehabilitation → MMI tracking |

**Regulatory note:** RuedaSeguro operates under an approved **Insurtech license** (SUDEASEG). This allows collection and service provision without being a licensed insurer. Full insurance carrier license is in process (est. 12 months). During this period, the insurer partners (Mercantil, Estar Seguro, etc.) bear the risk; RuedaSeguro manages the technology layer.

### 1.2 Thony's "Quasar Portal" — Existing Platform

Thony has a commercially deployable IoT data platform ("Quasar Portal") with:
- **Stack:** React + Node.js + PostgreSQL + MQTT/AMQP
- **Current capacity:** 4,000 assets in Google Cloud
- **Architecture:** Modular "plugin" model — RuedaSeguro would be an "Insurtech Plugin"
- **Commercial price:** $15/asset/month (Abu Dhabi demo); equivalent platform costs $10/asset/month commercially
- **Labor equivalent:** $250,000 in engineering hours to rebuild from scratch
- **Already built:** 7 admin portal screens (see Section 3), IoT ingestion, PostgreSQL ledger, analytics, workorder events

**Key constraint from layers.jpeg:**
- Tier 2 (Fundacion de Datos): React + Node + PostgreSQL + MQTT — data ingestion, insurance API bridges, blockchain, analytics, 1-year persistence
- Tier 3 (App-Movil): Flutter — onboarding wizard, events, collections, payments; 5-minute polling intervals; 15-second atypical-event detection window

### 1.3 Commercial & Partnership Structure

- Alex is seeking **equity partners**, not vendors: *"yo no necesito proveedores. Yo tengo ya gente técnica que me lo pudiera hacer"*
- Founders to define: Fernando + Thony + Diego (contributing technology) + Alex's team (William, Manuel, Leticia — contributing domain, process, and actuarial expertise)
- **Valuation discussion:** ~$2M ARR at 75,000 riders; equity split tied to contribution type (technology vs domain expertise)
- Decision needed: cash contribution vs. hours-as-equity model

### 1.4 Confirmed Technical Specs

| Item | Spec Confirmed |
|------|----------------|
| Telemetry window | 10–15 min circular buffer around accident |
| Continuous behavioral tracking | Deferred ("otro tema") |
| Policy verification on traffic stop | QR code + PDF sent to rider's phone |
| Carrier systems | Acsel (primary) + Sirway (secondary) via REST API |
| Payment gateway | GUIA PAY for automated C2P; Pago Móvil P2P for MVP |
| Medical partner | Venemergencia; $2.71/motorist/month capitation (to be negotiated) |
| Sensor threshold | >4G for event detection (not 9G as some docs state) |
| Triage: Basic claims | Parametric cash payout via smart contract / payment API |
| Triage: Plus claims | Venemergencia dispatch + ER admission |
| Triage: Premium claims | Above + full rehabilitation tracking to MMI |

> **Note on threshold discrepancy:** The "Agentes Digitales" document and Thony's dispatch terminal use **4G** as the impact threshold. The architecture documents (enterprise_arch, data_arch, competition_analysis) cite **9G**. The 4G threshold is from the most recent domain document; use 4G as working spec until William/Manuel clarify actuarial basis.

### 1.5 Discovery Agenda (Pending — William + Manuel)

See Section 8 for full agenda. Key open items:
- Acsel/Sirway API specs, availability SLAs, sandbox environments
- SUDEASEG required data fields for policy records and audit logs
- Actuarial basis for 4G vs 9G sensor threshold
- Tariff structure breakdown (how Manuel's calculations are structured)
- Claims flow: who approves each step? What is the human-in-the-loop requirement?

---

## 2. New Documents: Key Contributions

### 2.1 Informe Maestro de Ingeniería (2026)

**Contribution:** Establishes the "MFCL" (Critical Liquidation Factors Matrix) — six dimensions evaluated in milliseconds before any payout:

1. **Kinetic Verity** — Sensor fusion >4G + deceleration curve
2. **OCR Identity** — Facial biometric + carnet match
3. **DLT Validity** — Immutable blockchain policy status check
4. **GPS Geolocation** — Geofencing + proximity to ALTEHA clinic network
5. **Clinical Capacity** — Available trauma-shock slot confirmation via ALTEHA API
6. **GUIA PAY Node** — Immediate dispersion channel selection

**Implication for architecture:** The six MFCL checks imply a **validation orchestration service** — not a simple webhook — that coordinates async responses from IoT sensor data, blockchain, GPS, ALTEHA API, and GUIA PAY before executing payment. This is the core of the SLI (Smart Liquidation System).

### 2.2 Agentes Digitales (Digital Claims Agent)

**Contribution:** Defines the three-agent autonomous pipeline:
```
Detection Agent → Oracle Validator Agent → Financial Dispersion Agent
```

**PAS Protocol (Protect, Alert, Assist):**
- P: Emergency contact notified via WhatsApp/SMS with GPS coordinates
- A: Venemergencia + Grupo Nueve Once dispatched with patient profile + impact severity
- S: Highway incidents trigger Angels de las Autopistas for perimeter security

**Triage classification:**
| Level | Condition | Destination | Financial Trigger |
|-------|-----------|-------------|-------------------|
| Emergencia | Vital risk | Hospital ER | Advance + full coverage |
| Urgencia | Stable, needs rapid care | Nueve Once Urgent Care | Advance + recovery |
| Siniestro Leve | Minor | Telemedicine | Parametric cash payout |
| Recuperación | Post-treatment | Venefarmacia home delivery | MMI milestone payments |

### 2.3 Venemergencia Proposal (March 2026)

**Key commercial terms:**
- Capitation: **$2.71/motorist/month** per active Plus/Premium policy (not per incident)
- Scope: Stabilization only at 6 owned Venemergencia centers + allied network
- 15-minute response time SLA for urban Caracas
- Does NOT include: advanced surgery, extended hospitalization, medication
- Medication delivery: Venefarmacia + Farmahogar (separate agreements needed)

**Implication:** At 10,000 riders with 30% on Plus/Premium = 3,000 policies × $2.71 = **$8,130/month** in capitation costs. This is a fixed cost regardless of how many accidents occur — important for financial modeling.

### 2.4 Hardware Validation (OEM IMU Sensors)

**Contribution:** Documents 4 viable OEM sensor options if RuedaSeguro ever moves beyond smartphone-only detection:

| OEM | Model | Type | Price |
|-----|-------|------|-------|
| Bosch Sensortec | SMI230/BMI088 | 6-axis High Precision | $18–28 |
| STMicroelectronics | ISM330DHCX | Automotive Inertial | $7.50–14.50 |
| TDK InvenSense | IAM-20680 | Motion Tracking | $12–22 |
| Murata | SCHA63T | Industrial 6-DOF | $85–125 |

**Current MVP decision:** Smartphone sensors only (sensors_plus in Flutter). Hardware IoT is Phase 3+. The STMicro ISM330DHCX at $7.50–14.50 is most viable if hardware path chosen.

### 2.5 GuiaPay (Payment Gateway)

**Contribution:** GuiaPay enables:
- **C2P (Cobro a Personas):** Pull payment directly from rider's bank account using phone + bank code + 4-digit auth token
- **BCV Rate Integration:** Real-time Bolívar/USD conversion for premium calculation
- **Outbound disbursement:** SLI stabilization payments to rider wallet or clinic account

**Technical requirements:**
- AES/ECB/PKCS5Padding encryption (legacy Venezuelan banking mandate)
- ClientID passed as HTTP header `X-IBM-Client-Id`
- Idempotency required: same transaction UUID must not produce double-charge on network retry
- 4-digit bank authorization token with ~60-second expiry window

**Integration status:** Commercial agreement with GuiaPay not yet signed (discovery item for Alex).

---

## 3. Thony's Dashboard Mockups: Architecture Implied

### 3.1 Seven Role Portals (Screen Inventory)

**Portal 1 — Administration Console** (`/admin`)
- Role: RuedaSeguro internal ops
- Key data: partner registry, blockchain wallets (TRON treasury + Polygon payouts), dynamic pricebook, subscriber operations
- Key actions: add/suspend/remove partners, commit pricing changes, manual subscriber overrides
- Data requirements: `partners`, `blockchain_wallets`, `policy_tiers`, `global_config`, `subscribers`

**Portal 2 — Customer Operations Desk** (`/customer-ops`)
- Role: internal support agents
- Key data: open ticket queue, escalations count, avg resolution time, multi-entity tickets
- Key actions: claim case, open desk, assign agent, escalate, close ticket
- Ticket entity types observed: Rider App, Broker Group, Hospital/Clinic
- Ticket statuses: OPEN, IN_PROGRESS, WAITING_ON_USER, CLOSED
- Priority levels: CRITICAL, HIGH, MEDIUM, LOW
- Data requirements: `tickets`, `ticket_entities`, `agents`, `escalation_rules`

**Portal 3 — Quasar Management (Executive Overview)** (`/management`)
- Role: RuedaSeguro leadership
- Key data: total subscribers, expiring subscriptions, active incidents, YTD payouts, regional breakdown, live financial ledger, incident triage board
- Data requirements: `subscribers` (aggregated), `incidents`, `payouts`, `geographic_distribution`, `live_ledger`

**Portal 4 — Insurance Partner API View** (`/insurer`)
- Role: carrier partner (Mercantil, Estar Seguro, etc.)
- Key data: portfolio risk, acquisition velocity, active handovers, portfolio distribution (60/30/10%), live liability stream
- Data requirements: `policies` (by carrier), `incidents` (by carrier), `clinical_handovers`

**Portal 5 — Venemergencia Dispatch Terminal** (`/dispatch`)
- Role: Venemergencia operator
- Key data: live emergency dispatch feed — crash confidence, coordinates, rider name, blood type, ETA status
- Key action: "Acknowledge & Dispatch" → triggers ambulance + creates clinical handover record
- Data requirements: `events` (real-time MQTT), `rider_profiles` (blood type, emergency contact), `dispatch_units`

**Portal 6 — Clinical Care ER Triage** (`/clinical`)
- Role: ALTEHA clinic / Venemergencia facility
- Key data: incoming ER patients (ambulance ETA), internal triage table (insurance verification, status, actions)
- Insurance badge: "Quasar Validated (15% Advance Clearing)" — payment pre-authorized
- Key action: "Mark Discharged" → triggers final claims settlement
- Data requirements: `clinical_handovers`, `insurance_verifications`, `discharge_events`

**Portal 7 — Insurance Broker Pipeline** (`/broker`)
- Role: corredor de seguros
- Key data: total portfolio size, renewal opportunities expiring in <10 days
- Key action: "Send Pago Movil Link" → generates renewal payment deep-link for broker to send to client
- Data requirements: `broker_portfolios`, `expiring_policies`, `renewal_links`

### 3.2 Data Model Implied by Dashboards

The 7 portals collectively imply the following core entities (beyond the 20 tables in current schema):

```
tickets              (id, entity_type, entity_id, subject, priority, status, agent_id, created_at, resolved_at)
dispatch_events      (id, incident_id, confidence_pct, coordinates, rider_id, blood_type, acknowledged_at, unit_id)
clinical_handovers   (id, incident_id, clinic_id, ambulance_unit, eta_minutes, status, insurance_verified, discharged_at)
broker_portfolios    (id, broker_id, subscriber_count, renewal_pipeline_count)
renewal_links        (id, policy_id, pago_movil_link, sent_at, completed_at)
blockchain_wallets   (id, type ENUM(tron_treasury, polygon_payouts), address, sync_status)
global_config        (key, value, last_committed_by, committed_at)
```

### 3.3 Workflow Gaps Visible in UX

Gaps visible in dashboards that have **no backend spec yet:**
1. Ticket escalation rules (what auto-escalates? what SLA triggers CRITICAL?)
2. Dispatch acknowledgment → ambulance routing (is this manual or API call to Venemergencia's system?)
3. Insurance verification at clinical reception (is it a DB lookup or real-time API call?)
4. "Mark Discharged" → what financial settlement does this trigger?
5. Renewal link generation (deep-link format for Pago Móvil?)
6. Pricebook "Commit Change" → does this require approval workflow?

---

## 4. Decision Matrix — Every Architectural Fork

For each decision: **Context | Path A | Path B | Path C (if any) | Recommendation | Changed From Original Plan**

---

### DECISION 1 — Mobile App Framework: Flutter vs React Native vs Web-only

**Context:** Sprint 0–1 produced a Flutter app (Dart, Riverpod, GoRouter) with 0 errors, full onboarding flow, 7 unit test files, ~120 test cases, and a complete visual demo. Thony's platform is React + Node.js. A question arises: should the mobile app migrate to React Native to unify the JavaScript ecosystem?

**Path A — Keep Flutter (Current)**
- Pros: Sprint 0–1 work preserved (OCR parsers, auth, onboarding, 7 screens); Dart isolates provide true background thread for sensor polling; `sensors_plus`, `geolocator`, `background_fetch` packages are mature; better offline-first architecture; single codebase (iOS + Android)
- Cons: Dart is a separate language from Thony's React/Node.js stack; no code sharing between app and admin
- Timeline: Continue Sprint 2 immediately; zero rewrite cost
- Risk: Low. The mobile app's core requirement (crash detection background service) is **best served by Flutter's Dart isolates** — React Native's background execution is more constrained (especially on iOS)

**Path B — Rewrite in React Native**
- Pros: Unified JS/TS language across app + admin; easier onboarding for React developers; code sharing possible for validation logic
- Cons: Full rewrite of Sprint 0–1 (6–10 weeks); React Native background execution is worse than Flutter for sustained sensor polling; `expo-sensors` is less reliable than Flutter's `sensors_plus` for high-frequency IMU data; iOS background execution requires VOIP push notification hacks
- Timeline: 3–6 months delay before regaining current functionality
- Risk: High. **The crash detection sensor pipeline is the core product differentiator.** React Native is not the right tool for sustained background IMU processing.

**Path C — Web-only (PWA)**
- Pros: No app store, instant updates
- Cons: PWA cannot access IMU sensors in background on iOS; cannot do crash detection at all; cannot function offline
- Risk: Eliminates the core product.

**✅ Recommendation: Keep Flutter.**
**Changed from original plan:** No change — MVP always specified Flutter. Reconfirmed.

---

### DECISION 2 — Backend Platform: Supabase only vs Thony's Node+PostgreSQL vs Hybrid

**Context:** Current dev uses Supabase (managed PostgreSQL + GoTrue Auth + Storage + Edge Functions). Thony's platform is React + Node.js + PostgreSQL + MQTT. Venezuelan data sovereignty requires production data on local servers. Both can run on PostgreSQL.

**Path A — Supabase only**
- Pros: Fastest dev iteration; managed auth (Phone OTP), RLS, storage, edge functions already set up; Sprint 0 schema exists
- Cons: Cannot run on-premises in Venezuela (Supabase is cloud-only); no MQTT event bus; no IoT ingestion pipeline; cannot support real-time MQTT events from mobile
- Risk: Production deployment violates data sovereignty mandate. Cannot be the final architecture.

**Path B — Thony's Node+PostgreSQL only (replace Supabase)**
- Pros: Production-tested; supports MQTT; sovereign-capable; already has the admin dashboards; insurance business logic can live here
- Cons: Must rebuild phone OTP auth; must rebuild file storage; must migrate Sprint 0 schema; Thony's team bandwidth is limited
- Timeline: 6–10 weeks migration + rebuild of auth + storage

**Path C — Hybrid (Recommended)**
- Supabase: rider auth (Phone OTP), document file storage (Cédula scans, PDFs), admin portal SSR sessions during dev phase
- Thony's Node+PostgreSQL: business logic (policy issuance, claims, payments, SLI), MQTT telemetry events, insurer API integration, broker commission calculation
- Migration path: Supabase JWT → validated by Node middleware as unified identity token
- Data sovereignty: Thony's PostgreSQL migrates to local VZ server for production; Supabase retained for auth/storage only (documents are less sensitive than financial ledger)
- Pros: Use best tool for each concern; preserve Sprint 0 auth work; gain IoT pipeline; progressive migration
- Cons: Two backend systems to maintain during transition; JWT bridge adds complexity

**✅ Recommendation: Hybrid.** Auth + file storage = Supabase (dev) / migrate auth to Node JWT for production. Business logic + telemetry = Thony's Node+PostgreSQL+MQTT.
**Changed from original plan:** MVP assumed Supabase throughout. Now: Supabase is the dev scaffold, not the production backbone.

---

### DECISION 3 — Admin Portal: Next.js vs Thony's React vs Merge

**Context:** The repo has `admin-portal/` (Next.js 16, App Router, shadcn/ui, Supabase SSR). Thony has 7 complete dashboard screens (React, Quasar Portal brand). Both are React. They serve the same users.

**Path A — Keep Next.js (current admin-portal/)**
- Pros: Already structured with carrier/broker route groups; shadcn/ui components; Supabase SSR auth; Vercel deployment
- Cons: Duplicates Thony's dashboard work; misses the 7 portal screens Thony has designed; no MQTT real-time data; separate React tree from Thony's
- Risk: Team builds the same portal twice. Thony's portal is more advanced and already has live data connections.

**Path B — Deprecate Next.js, adopt Thony's React platform**
- Pros: Thony's portal already has 7 screens, live MQTT, PostgreSQL connection, clinical + dispatch portals
- Cons: Need to rebuild Supabase SSR auth integration; lose Next.js App Router (server components for SEO + initial load); Vercel deployment pipeline disrupted; no server-side rendering
- Timeline: 4–6 weeks to migrate auth + deploy

**Path C — Merge (Recommended)**
- Adopt Thony's React platform as the admin layer foundation
- Port the Next.js carrier/broker views into Thony's React app
- Replace "Quasar Portal" branding with "RuedaSeguro" branding (see Decision 9)
- Deploy both on the same infrastructure (Node.js + React, not Next.js + Vercel)
- Pros: Single admin app; Thony's 7 screens free; live MQTT data; no duplication
- Cons: Lose Vercel's edge deployment for admin; need to build own SSR or switch to SPA + API
- For admin portals (B2B, not public-facing), SSR is less critical. SPA + API is acceptable.

**✅ Recommendation: Merge into Thony's platform.** Keep Next.js only if the public-facing rider acquisition site (marketing) needs SSR/SEO. For admin portals: adopt Thony's React.
**Changed from original plan:** MVP built `admin-portal/` with Next.js. Now: admin is Thony's React platform; Next.js may survive as a public acquisition/marketing site only.

---

### DECISION 4 — Infrastructure: GCP (current) vs AWS Graviton4 vs IBM Power9

**Context:** Thony's platform runs on GCP. MVP plan targets local VZ server + GCP backup. Architecture docs debate IBM Power9. Venezuelan data sovereignty mandates local storage.

**Path A — GCP only (Thony's current)**
- Pros: Already running, familiar, 4,000 assets already managed
- Cons: GCP has no Caracas data center; data sovereignty mandate not met; latency from nearest region (Colombia or Brazil); cloud-only, no sovereign path
- Risk: SUDEASEG audit failure if production financial data never touches Venezuelan infrastructure.

**Path B — AWS Graviton4 + Aurora PostgreSQL**
- Pros: 40% better price-performance vs x86; Aurora scales to 150k policies without re-architecting; multi-AZ resilience; Graviton4 R8g instances for DB workloads
- Cons: Migration from GCP; still no VZ region (same sovereignty issue); more complex than continuing GCP
- Risk: Sovereignty issue not solved; adds migration cost vs. just continuing GCP.

**Path C — IBM Power9 (from architecture docs)**
- Pros: 3.7x faster than x86 for OLTP; sovereign deployment possible; reference architecture for financial-grade systems; DLT-ready
- Cons: $250,000+ in labor alone; requires specialized expertise; massive upfront cost for a startup at 10,000 riders/year
- The meeting confirmed no one on the current team has IBM Power9 operational experience.
- Risk: Over-engineered for MVP. This is a Year 2–3 decision.

**Path D (Recommended) — GCP + Local VZ PostgreSQL (data sovereignty)**
- Continue on GCP for compute (Cloud Run, Cloud Functions)
- Add local Venezuelan PostgreSQL 16 instance for the financial ledger (policies, payments, claims) — this satisfies the data sovereignty mandate
- GCP Cloud SQL configured as async replica for DR
- Pros: Fastest path to sovereignty compliance; no migration from GCP; preserves Thony's existing infrastructure
- Cons: Requires someone in Venezuela to manage the physical server; hybrid connectivity needed

**✅ Recommendation: GCP + Local VZ PostgreSQL.** IBM Power9 is a Phase 3 option only if Aurora/GCP bottlenecks at 90k+ riders. Do not let "aspirational infrastructure" documents drive premature investment.
**Changed from original plan:** MVP plan already specified local VZ + GCP. Reconfirmed. IBM Power9 firmly deferred.

---

### DECISION 5 — Telemetry Scope: Full 100–200 Hz behavioral vs 10–15 min event window

**Context:** Architecture docs specified full behavioral telemetry at 100–200 Hz with InfluxDB 3.0 time-series storage. Alex in the meeting explicitly said: *"guarda una memoria temporal de 10, 15 minutos porque si después de eso si un accidente pasa, para no llenarnos de tanta información. Más adelante si queremos medir conducta y otras cosas, es otro tema."*
Thony's layers.jpeg confirms: 5-minute polling (normal), 15-second detection window (atypical event).

**Path A — Full behavioral 100–200 Hz (architecture docs)**
- Pros: Enables "pay-how-you-drive" in Phase 2; richer forensic data; competitive with Progressive Snapshot
- Cons: ~10 MB/hr/device battery drain; at 10,000 devices = 100 GB/hr of telemetry ingestion; InfluxDB 3.0 infrastructure cost; continuous background polling kills battery on delivery riders
- Alex explicitly ruled this out for the current scope.
- Risk: Massive infra cost before product-market fit is proven; battery complaints from riders.

**Path B — 10–15 min circular buffer (Alex's spec) ← Recommended**
- Architecture: SQLite circular buffer stores last 15 minutes of accelerometer data locally
- On 4G impact detected → flush buffer + real-time stream to backend → backend stores forensic window
- Normal operation: 5-minute heartbeat (GPS coordinates + alive signal) only
- Event window: 15-second high-frequency capture around the moment of impact
- Pros: Minimal battery impact; small data footprint; sufficient for parametric trigger and forensic proof; matches Alex's requirements; matches Thony's layers diagram
- Cons: No behavioral risk scoring until Phase 2 feature flag enables continuous capture

**Design principle for both paths:** Build the Store & Forward architecture (SQLite circular buffer) now. Add a `telemetry_mode` feature flag in app config: `HEARTBEAT_ONLY` (MVP) → `EVENT_WINDOW_15S` (Phase 1.5) → `FULL_BEHAVIORAL` (Phase 2). The architecture supports all three modes; only the feature flag changes.

**✅ Recommendation: 10–15 min event window with circular buffer. Design for upgrade via feature flag.**
**Changed from original plan:** MVP arch specified 100–200 Hz as Phase 1.5 target. Now: event window only per Alex's explicit spec. Full behavioral is Phase 2.

---

### DECISION 6 — Blockchain: SHA-256 only vs Polygon ERC-721 vs TRON + Polygon dual

**Context:** MVP plan: SHA-256 hashes in DB (MVP) → Polygon ERC-721 (Phase 1.5). Thony's dashboard shows: Treasury Cold Wallet (TRON) + Automated Payouts (Polygon). Architecture docs reference TRON nowhere — only Polygon.

**Path A — SHA-256 only (MVP approach)**
- Pros: Zero gas fees; zero wallet management; no smart contract risk; policies backed by PostgreSQL hash; provably immutable via append-only table
- Cons: No public ledger; auditor cannot verify without DB access; no smart contract for automated SLI payout
- Sufficient for: MVP, first 12 months, SUDEASEG audit via internal DB

**Path B — Polygon ERC-721 (Phase 1.5 plan)**
- Pros: NFT policy card (EIP-1523); public auditable ledger; smart contract executes 25% cash-out without human intervention; fractions of a cent per transaction; SUDEASEG can verify without DB access
- Cons: Requires wallet management infrastructure; gas price volatility (minimal on Polygon but still); smart contract audit needed before financial payouts
- Practical: ~$0.001 per policy mint; ~$0.0005 per payout execution

**Path C — TRON + Polygon dual (Thony's dashboard)**
- TRON: treasury cold wallet for internal fund reserves
- Polygon: automated payouts to riders/clinics
- Pros: TRON has near-zero fees and high throughput; Polygon for EVM-compatible smart contracts
- Cons: Two blockchain integrations; TRON wallet infrastructure is separate from Polygon; TRON not mentioned in any other architecture document — its inclusion in Thony's mockup needs clarification from Alex
- Risk: Complexity without clear benefit vs. Polygon alone. TRON may be Thony's preference from a prior project.

**✅ Recommendation: SHA-256 for MVP. Polygon only for Phase 1.5 (SLI + NFT policy). Clarify TRON necessity with Alex before any TRON integration.**
**Changed from original plan:** No change for MVP phase. Phase 1.5 Polygon confirmed. TRON is a new discovery needing explicit sign-off.

---

### DECISION 7 — Payment Rail: Pago Móvil P2P (manual) vs GUIA PAY C2P vs Hybrid

**Context:** Current MVP uses Pago Móvil P2P (rider initiates bank transfer; admin verifies reference number). Target is GUIA PAY C2P (automated pull). Thony's broker dashboard shows "Send Pago Movil Link" for renewals. GuiaPay commercial agreement not yet signed.

**Path A — Pago Móvil P2P only (current)**
- Pros: Zero API integration; works on Day 1; familiar to Venezuelan riders; no commercial agreement needed
- Cons: Manual admin verification of every payment; no automated settlement; admin bottleneck at scale; cannot support automated SLI payouts
- Feasibility at scale: 10,000 riders = potentially 10,000 manual verifications/year → not sustainable

**Path B — GUIA PAY C2P only**
- Pros: Fully automated premium collection; idempotent; supports automated SLI outbound payments
- Cons: Commercial agreement required (Alex needs to sign); complex 4-digit bank auth token flow; AES/ECB encryption; 60-second token window = retry logic complexity
- Timeline: Minimum 4–6 weeks after commercial agreement to integrate + test

**Path C — Hybrid (Recommended)**
- MVP: Pago Móvil P2P for new subscriptions (admin verifies) + reference upload by rider
- Phase 1.5: GUIA PAY C2P for new subscriptions (automated)
- Always: Pago Móvil deep-link for broker renewals ("Send Pago Movil Link") — this is a UX feature for brokers, not a technical limitation
- Outbound SLI payouts: GUIA PAY C2P as soon as agreement is signed

**✅ Recommendation: Hybrid.** MVP = P2P manual. Phase 1.5 = GUIA PAY C2P. Broker renewal = Pago Móvil link permanently.
**Changed from original plan:** No change for MVP. Phase 1.5 confirmed. Broker renewal link is a new workflow not in original plan.

---

### DECISION 8 — OCR Engine: Google ML Kit vs PaddleOCR vs AWS Textract

**Context:** Current implementation uses Google ML Kit (on-device, Dart, Sprint 1). This covers Venezuelan Cédula (V/E) + Colombian CC + Carnet de Circulación. The Factura de Compra (motorcycle purchase invoice) has variable layouts across dealerships.

**Path A — Google ML Kit only (current)**
- Covers: Cédula (V/E/CC), Carnet de Circulación — both standardized; current parsers pass 120 test cases
- Fails: Factura de Compra (highly variable layout, degraded print, no standard format)
- Cost: Free; on-device; no network round-trip; works offline
- Risk: High failure rate on Factura de Compra → user drop-off during onboarding

**Path B — PaddleOCR (self-hosted server fallback)**
- Covers: Variable-layout financial documents; trained on diverse document types
- Cost: ~$0.09/1,000 pages (vs. $1.50 for Textract) — 167x cost reduction
- Deployment: On-prem (Docker container on GCP Cloud Run or local VZ server)
- Latency: ~200–500ms per image on CPU; ~50ms on GPU
- Risk: Requires server maintenance; GPU hosting cost for acceptable performance

**Path C — AWS Textract cascade**
- Covers: Best-in-class for variable financial documents (Factura de Compra)
- Cost: $1.50/1,000 pages → at 10,000 policies/year with 1 invoice each = $15/year total — negligible
- Latency: 1–3 seconds per image (cloud call)
- Risk: AWS dependency; data leaves device for cloud processing (privacy concern for ID docs)

**✅ Recommendation: Cascaded approach.** ML Kit on-device for Cédula + Carnet (no network, free, works offline). If ML Kit confidence <0.85 on Factura de Compra → fallback to PaddleOCR self-hosted. Textract only if PaddleOCR fails QA threshold above 10% failure rate.
**Changed from original plan:** No change — matches MVP plan exactly. Re-confirmed.

---

### DECISION 9 — Platform Naming: "Quasar Portal" vs "RuedaSeguro" vs White-label Engine

**Context:** Thony's platform is branded "Quasar Portal" in all 7 dashboard screenshots. However, the B2B2C partners (insurers, brokers, clinics) will interact with RuedaSeguro's branded platform. Thony is also commercializing Quasar independently for industrial IoT at $15/asset/month.

**Path A — Quasar Portal branding for all**
- Implies: RuedaSeguro is a "plugin" running on Quasar; partner-facing screens say "Quasar"; brand confusion for Alex's client-facing product
- Risk: Undermines RuedaSeguro product identity; partners may wonder who they're working with

**Path B — RuedaSeguro branding for all, retire Quasar name**
- Implies: Thony's platform is white-labelled exclusively for RuedaSeguro; cannot be sold to other industries
- Risk: Limits Thony's commercial opportunity; he explicitly intends to sell the platform independently

**Path C — White-label architecture (Recommended)**
- The admin engine is "Quasar" internally and in Thony's commercial context (industrial IoT, Abu Dhabi clients)
- RuedaSeguro deploys an "Insurtech Plugin" on Quasar, branded as "RuedaSeguro" to all external parties
- This matches the layers.jpeg architecture exactly: the middle tier is labeled "AZ Capital's Fundacion de Datos" with a separate "Insurtech Plugin" module
- Thony's platform remains commercially independent; RuedaSeguro is a paying/equity client

**✅ Recommendation: White-label.** Quasar is the engine. RuedaSeguro is the brand for all partner-facing surfaces. Admin dashboards show "RuedaSeguro" logo. Code repository may reference Quasar internally.
**Changed from original plan:** Not addressed in MVP. New discovery from Thony's platform.

---

### DECISION 10 — Policy Issuance: API-first vs Aggregator-first vs Dual channel

**Context:** RuedaSeguro must issue a policy backed by a licensed insurer (Mercantil, Estar Seguro). The insurer's core systems are Acsel and Sirway. The policy number is required on the PDF card for traffic stop verification.

**Path A — API-first (real-time call to insurer)**
- Flow: Rider completes onboarding → payment verified → RuedaSeguro calls Acsel/Sirway API → insurer issues policy number → PDF generated with official policy number
- Pros: Legally clean; policy is insurer-backed from second 1; no regulatory risk
- Cons: If Acsel/Sirway API is down → no policy issuance; insurer SLAs become a dependency
- Risk: Single point of failure; Venezuelan banking/carrier API reliability is uncertain

**Path B — Aggregator-first (RuedaSeguro issues token, reconciles later)**
- Flow: Payment verified → RuedaSeguro generates blockchain policy token → PDF issued immediately → batch settlement with insurer at end of day
- Pros: Decoupled from insurer uptime; faster issuance
- Cons: Policy is backed by RuedaSeguro, not a licensed insurer, at time of issuance → regulatory risk under SUDEASEG; if insurer rejects in batch reconciliation, policy is invalid retroactively
- Risk: High regulatory risk. RuedaSeguro does not yet have carrier license.

**Path C — Dual channel with fallback (Recommended)**
- Primary: Real-time API call to Acsel/Sirway (Path A)
- Fallback: If API call times out or fails → issue "Provisional Policy" token with RuedaSeguro digital signature + hash → queue insurer API call for retry (max 3 attempts in 15 minutes) → if confirmed, upgrade token to full policy; if insurer permanently rejects, refund rider
- Policy PDF shows "PROVISIONAL" watermark until insurer confirms
- Pros: Resilient; legally transparent; rider knows status; regulatory risk acknowledged
- Cons: UX complexity around provisional status; need William to confirm SUDEASEG accepts provisional model

**✅ Recommendation: Dual channel.** Real-time API first. Provisional fallback with clear UX status. Must be confirmed with William (SUDEASEG compliance).
**Changed from original plan:** MVP assumed real-time API call only. Provisional fallback is new — required for Venezuelan infrastructure reliability.

---

## 5. Gaps Not Discussed in Meeting

### 5.1 Ticket Management System

**Evidence from dashboards:** Portal 2 (Customer Operations Desk) shows a full ticket queue system with 24 open escalations, 2.4hr avg resolution, multi-agent assignment, and entity-specific ticket types.

**Required specs:**

**Entity types that can submit tickets:**
- Rider (via mobile app "Help" flow)
- Broker (via broker portal)
- Clinic / Hospital (via clinical portal or API callback)
- Insurer (via API error notifications)
- Internal (system-generated: payment failed, API timeout)

**Ticket lifecycle:**
```
OPEN → IN_PROGRESS → WAITING_ON_USER / WAITING_ON_PARTNER → RESOLVED → CLOSED
```

**Escalation rules (to be confirmed with William):**
- CRITICAL: Payment charged but policy not issued → auto-assign; SLA 30 min
- HIGH: API integration failure (clinic, insurer) → SLA 2 hours
- MEDIUM: Commission dispute → SLA 8 hours
- LOW: General inquiry → SLA 24 hours

**Metrics to track:**
- Open escalation count (real-time KPI)
- Avg resolution time (rolling 7-day)
- Tickets by entity type (pie chart)
- SLA breach rate (% resolved within SLA)

**Integration points:**
- Payment events → auto-ticket if payment confirmed but policy issuance fails
- Clinical handover events → auto-ticket if discharge synchronization times out
- Rider app → "Report a Problem" screen → ticket API call

**Schema additions needed:**
```sql
tickets (id UUID PK, entity_type, entity_id, subject, description, priority, status,
          assigned_agent_id, carrier_ref, created_at, updated_at, resolved_at)
ticket_comments (id, ticket_id, author_id, body, created_at)
sla_config (entity_type, priority, target_minutes)
```

---

### 5.2 Admin Workflows & Approval Chains

**Gap:** No approval chains are defined for any multi-step business operation. Below are the critical workflows that need human-in-the-loop steps:

**Workflow 1: Policy Issuance**
```
Rider payment confirmed
  → Automatic: Acsel/Sirway API call
  → Auto-issue if API returns policy number in <30s
  → Manual review if: API fails 3x, rider flagged for fraud, Cédula OCR confidence <0.75
  → Admin action: "Approve Provisional" / "Reject & Refund"
```

**Workflow 2: Claims Authorization (SLI Cash-Out)**
```
Impact detected (>4G) → 10s countdown → Emergency mode activated
  → Automatic MFCL validation (6 checks in parallel)
  → If all 6 pass → automatic 25% cash-out (no human needed)
  → If any check fails → flag for manual review
  → Admin action: "Override & Authorize" / "Reject & Record"
```

**Workflow 3: Broker Commission Settlement**
```
Monthly batch: count policies issued per broker
  → Calculate commission (rate × policy count)
  → Generate settlement report
  → Broker reviews in portal
  → Finance approves → GUIA PAY outbound transfer
  → Broker action: "Acknowledge" / "Dispute"
  → Dispute → creates MEDIUM ticket automatically
```

**Workflow 4: Partner Onboarding (Insurer/Clinic)**
```
Admin Portal: Add Entity (insurer/clinic/broker)
  → System validates API credentials (ping test)
  → Senior admin approves
  → Partner receives credentials
  → Status: ACTIVE
```

**Workflow 5: Pricebook Change**
```
Admin updates BASIC/PLUS/PREMIUM prices
  → "Commit Change" button requires second-factor confirmation
  → Change logged with: who, when, old value, new value
  → Effective on: next renewal cycle (not retroactive)
```

---

### 5.3 Client Service / Call Center Routing

**Gap:** Thony's dashboard shows "Customer Service Desk" as a navigation item but routing logic is undefined.

**Inbound contact channels (to design):**
- **In-app support:** "Reportar Problema" screen → creates ticket directly
- **WhatsApp:** Venezuelan users heavily prefer WhatsApp → WhatsApp Business API → bot triage → human escalation
- **Phone:** Venezuelan norm for urgent issues → IVR with claim type detection → route to available agent
- **Broker portal:** Built-in messaging for commission/portfolio questions

**Routing logic (proposed):**
```
Contact received
  ├─ Rider issue + payment problem → Customer Ops (CRITICAL tier)
  ├─ Rider issue + policy question → Customer Ops (MEDIUM tier)
  ├─ Clinic issue + API timeout → Technical (HIGH tier) → auto-ticket
  ├─ Broker issue + commission → Finance queue (MEDIUM tier)
  └─ Emergency during active incident → Redirect to Venemergencia dispatch (bypass ticket)
```

**Technology options:**
- WhatsApp: Twilio WhatsApp API or Meta Business API
- IVR: Twilio Programmable Voice or Vonage
- Ticket routing: Custom (PostgreSQL + Node.js rules engine) or Freshdesk/Zendesk embed

**Recommendation:** For MVP, WhatsApp + in-app report (no IVR). Build custom ticket routing in Node.js. IVR in Phase 2 when call volume justifies.

---

### 5.4 Caching Strategy

**Gap:** No caching architecture is defined. Key caching requirements:

**BCV Exchange Rate Cache:**
- BCV API is unreliable (rate limits, Venezuelan government uptime)
- Cache TTL: 60 minutes for active sessions; daily snapshot for billing records
- Fallback: use last known rate + amber warning in UI ("Tasa aproximada")
- Store: Redis (Upstash) or PostgreSQL table with `bcv_rates (timestamp, usd_ves_rate)`

**Policy Validation Cache (at clinic reception):**
- When clinic scans QR code → look up policy validity
- Cache TTL: 5 minutes (policy status rarely changes mid-treatment)
- Cache layer: Redis or in-memory Node.js LRU cache
- Invalidate on: policy cancelled, payment failed, SLI triggered

**Rider Session Cache:**
- GoRouter auth state + OnboardingData held in Flutter StateNotifier (in-memory, device)
- No server session cache needed if stateless JWT tokens used

**MQTT Message Deduplication:**
- Mobile can publish same telemetry event multiple times (retry on reconnect)
- Cache: Redis SETNX with event UUID (60-second TTL) to deduplicate at ingestion layer

**OCR Result Cache:**
- Don't re-process same document image if already parsed
- Cache key: SHA-256 of image bytes → cache parsed result for 24 hours

**CDN / Static Cache:**
- Policy PDFs: stored in cloud storage (GCP Cloud Storage / Supabase Storage)
- Carrier logos + brand assets: CDN with 30-day TTL

---

### 5.5 Metrics Recording & Observability

**Gap:** No metrics or observability plan exists. The executive dashboard (Portal 3) implies rich metrics but their collection is undefined.

**Critical metrics by role:**

**RuedaSeguro Management:**
- Active subscribers (daily delta)
- Subscription revenue by tier (daily)
- SLI events: total, % auto-resolved, % escalated
- Payout velocity: avg minutes from impact to cash-out
- Capitation cost vs. SLI payout (cost per incident by tier)
- Churn rate (non-renewed policies)

**Operations:**
- Ticket queue depth (real-time)
- SLA breach rate (daily)
- API error rate by partner (carrier, Venemergencia, GuiaPay, ALTEHA)
- Payment processing success rate

**Insurance Partners:**
- Portfolio risk by region
- Active handovers to clinics
- Settlement reconciliation status (insurer payment queue)

**Brokers:**
- Renewal pipeline (policies expiring <30 days)
- Commission earned MTD
- Portfolio growth velocity

**Tech stack for observability:**
- Application logs: structured JSON → Google Cloud Logging (already on GCP)
- Metrics: PostgreSQL materialized views for business metrics (refresh every 15 min)
- Real-time events: MQTT → Node.js → PostgreSQL `events` table (for dashboard live feeds)
- Error tracking: Sentry (already referenced in software_arch.md for Phase 2+)
- Alerting: Google Cloud Monitoring + email/WhatsApp notifications for SLA breaches

---

### 5.6 Data Lifecycle & Retention (Time of Life)

**Gap:** Thony's layers diagram specifies "1-year persistence" for the Fundacion de Datos. No granular retention policy exists.

**Retention policy by data type:**

| Data Type | Retention | Justification |
|-----------|-----------|---------------|
| Active policy records | Indefinite (archived after 7 years) | SUDEASEG audit compliance |
| Expired/cancelled policies | 7 years | Venezuelan civil code statute of limitations (Art. 1.977) |
| Payment transactions | 7 years | SENIAT tax compliance |
| Telemetry events (accident) | 5 years | Evidence for disputed claims |
| Telemetry heartbeats (non-event) | 30 days | No regulatory value; storage cost |
| OCR document images | 1 year after policy expiry | Privacy + storage cost |
| SHA-256 hashes | Indefinite (< 1KB each) | Immutable proof |
| Ticket records | 3 years | Customer service audit trail |
| Broker commission records | 7 years | Financial records |
| BCV rate history | 10 years | Financial audits |
| MQTT raw event stream | 7 days (buffer) → aggregate monthly summaries | Cost vs. regulatory value |

**Archiving strategy:**
- Hot storage (PostgreSQL): last 90 days of active data
- Warm storage (GCP Cloud Storage): 90 days – 7 years (compressed JSON exports)
- Cold storage (GCP Archive): 7+ years (for regulatory compliance only)
- Deletion: SUDEASEG must approve retention policy before implementation

**GDPR-equivalent concern:** Venezuela's privacy law (Ley de Protección de Datos) requires rider consent for location and biometric data. Rider must be able to request deletion of personal data (Cédula image, address, biometrics). Policy NOT data (cannot be deleted while claim risk exists).

---

## 6. Proposed Unified Architecture (2026 Baseline)

### 6.1 System Map

```
┌─────────────────────────────────────────────────────────────────────┐
│                    RIDER MOBILE APP (Flutter)                        │
│  Onboarding Wizard → Policy Purchase → Background Telemetry         │
│  15-min circular buffer (SQLite) → Heartbeat every 5 min            │
│  Emergency Mode (4G trigger) → PAS Protocol                         │
└──────────────────────┬──────────────────────────────────────────────┘
                       │ MQTT (events) + REST (CRUD)
                       ▼
┌─────────────────────────────────────────────────────────────────────┐
│          THONY'S "QUASAR" FUNDACION DE DATOS (Node.js)              │
│  MQTT Ingestion → Event Bus → PostgreSQL Business Ledger             │
│  Insurtech Plugin: Policy Engine · SLI Orchestrator · Broker Mgmt  │
│  REST APIs: /policies · /claims · /events · /payments · /dispatch   │
│  Background jobs: BCV rate sync · Renewal reminders · Settlement    │
└──────┬──────────────────────────────────────────────┬───────────────┘
       │ Auth (JWT)              │ File Storage        │ Business Data
       ▼                         ▼                     ▼
┌──────────────┐    ┌────────────────────────┐   ┌─────────────────┐
│  SUPABASE    │    │  CLOUD STORAGE         │   │  LOCAL VZ       │
│  Phone OTP   │    │  (GCP / Supabase)      │   │  POSTGRESQL 16  │
│  Auth tokens │    │  Policy PDFs           │   │  (Sovereign)    │
│  (dev)       │    │  Cédula/Carnet scans   │   │  Financial ledger│
└──────────────┘    └────────────────────────┘   └─────────────────┘

       │ External APIs
       ▼
┌──────────────────────────────────────────────────────────────────┐
│  EXTERNAL INTEGRATIONS                                            │
│  ├─ Acsel/Sirway API      → Policy issuance + validation          │
│  ├─ GUIA PAY C2P          → Premium collection + SLI payouts      │
│  ├─ Venemergencia API     → Dispatch terminal (MQTT/webhook)      │
│  ├─ ALTEHA API            → Clinical capacity + admission token    │
│  ├─ BCV API               → Exchange rate (cached 60 min)         │
│  ├─ Twilio/WhatsApp       → Emergency contact notifications        │
│  └─ Polygon (Phase 1.5)   → NFT policy minting + SLI smart contract│
└──────────────────────────────────────────────────────────────────┘

       │ Admin Surfaces
       ▼
┌──────────────────────────────────────────────────────────────────┐
│  RUEDASEGURO ADMIN PORTAL (Thony's React, white-labeled)          │
│  7 Role Portals: Admin · Ops Desk · Management · Insurer         │
│                  Dispatch (Venemergencia) · Clinical · Broker      │
└──────────────────────────────────────────────────────────────────┘
```

### 6.2 Data Flow — Policy Issuance

```
1. Rider completes onboarding (Flutter) → OCR data + payment method
2. App calls POST /policies/quote → returns price in USD + VES (BCV rate)
3. Rider pays via Pago Móvil P2P → uploads receipt reference
4. Admin verifies reference → calls POST /policies/issue
5. Backend calls Acsel/Sirway API → gets policy number (or fallback: provisional)
6. Blockchain SHA-256 hash stored (MVP) / ERC-721 minted (Phase 1.5)
7. PDF generated (policy number + QR code + SHA-256 integrity badge)
8. PDF sent to rider (push notification + stored in cloud storage)
9. Event: policy_issued published to MQTT bus → admin dashboards update
```

### 6.3 Data Flow — Accident / SLI

```
1. Impact >4G detected on device → 10s countdown begins
2. If not cancelled: 15-min telemetry buffer flushed via MQTT
3. PAS triggered simultaneously:
   a. Emergency contact notified (WhatsApp/SMS via Twilio)
   b. POST /dispatch/venemergencia (rider profile + impact data + GPS)
   c. If highway GPS: Angels de las Autopistas notified
4. Venemergencia operator acknowledges in dispatch terminal
5. MFCL validation runs (6 parallel checks)
6. All checks pass → GUIA PAY C2P: 25% advance disbursed (<15 min target)
7. Ambulance en route → clinical handover record created
8. Rider admitted → "Quasar Validated" badge appears in clinic ER triage portal
9. Treatment → Mark Discharged → final settlement triggers remaining 75%
10. All events → append-only audit log (SUDEASEG compliance)
```

### 6.4 Recommended Tech Stack (Decision Summary)

| Layer | Technology | Status |
|-------|-----------|--------|
| Mobile app | Flutter 3.x + Dart (Riverpod, GoRouter) | ✅ Continue |
| Mobile state | Riverpod StateNotifier | ✅ Continue |
| Mobile sensors | sensors_plus + geolocator + background_fetch | ⚙️ Sprint 2 |
| Mobile telemetry | SQLite circular buffer (15 min) | ⚙️ Sprint 2 |
| Backend engine | Thony's Node.js + PostgreSQL + MQTT | 🔀 Adopt & integrate |
| Auth (dev) | Supabase Phone OTP | ✅ Continue |
| Auth (prod) | JWT via Node.js middleware | 🔮 Phase 1 |
| File storage | Supabase Storage → GCP Cloud Storage | ✅ Continue / migrate |
| Business DB | PostgreSQL 16 (GCP → Local VZ server) | 🔀 Migration needed |
| Admin portal | Thony's React (white-labeled as RuedaSeguro) | 🔀 Replace Next.js admin |
| OCR | ML Kit (on-device) + PaddleOCR (server) | ⚙️ ML Kit now / Paddle Phase 1.5 |
| Payments MVP | Pago Móvil P2P (manual verify) | ✅ Continue |
| Payments Phase 1.5 | GUIA PAY C2P | 🔮 Phase 1.5 |
| Blockchain MVP | SHA-256 hashes in PostgreSQL | ✅ Continue |
| Blockchain Phase 1.5 | Polygon ERC-721 (EIP-1523) | 🔮 Phase 1.5 |
| Observability | Sentry + GCP Cloud Logging + pg materialized views | ⚙️ Sprint 2 |
| Caching | Redis (Upstash) for BCV rate + MQTT dedup | 🔮 Phase 1 |
| Infrastructure | GCP + Local VZ PostgreSQL 16 | 🔀 Add VZ server |

---

## 7. Sprint Priorities — Return to Engineering Mode

Ranked by: blocking dependencies, business value, and decision resolutions needed.

### Pre-Sprint 2 (This Week — Decisions Required)
- [ ] **Team decision**: Confirm Flutter stays (Decision 1) → unblocks sensor work
- [ ] **Team decision**: Confirm Next.js admin deprecation → Adopt Thony's React (Decision 3)
- [ ] **Alex**: Confirm GUIA PAY agreement status
- [ ] **Alex**: Confirm TRON wallet requirement (Decision 6)
- [ ] **Schedule**: Discovery session with William + Manuel (Section 8)

### Sprint 2 — Core Platform (Weeks 1–4)
- [ ] Supabase RLS policies (all 20 tables currently unprotected)
- [ ] Profile write to DB on consent screen submit
- [ ] BCV rate fetching from Edge Function → policy quote screen
- [ ] SQLite circular buffer (15-min telemetry window) + `anomaly_queue` schema
- [ ] Background service foundation: `sensors_plus` activation + Dart isolate setup
- [ ] MQTT client in Flutter → connect to Thony's Node.js backend
- [ ] Policy PDF generation (pdf package, SHA-256 hash on card)
- [ ] Admin portal: begin migration to Thony's React (or build new screens in it)

### Sprint 3 — Business Logic (Weeks 5–8)
- [ ] Acsel/Sirway API integration (sandbox test)
- [ ] Full policy issuance flow (real API → PDF → push notification)
- [ ] Carrier/broker commission calculation + settlement report
- [ ] Ticket management schema + Customer Ops Desk portal
- [ ] Renewal reminder system (7-day and 1-day before expiry)
- [ ] Pago Móvil deep-link generator for broker renewal workflow
- [ ] Provisional policy fallback + reconciliation queue

### Sprint 4 — Emergency & SLI (Phase 1.5 Kickoff)
- [ ] 4G impact detection algorithm (Butterworth filter + threshold)
- [ ] Emergency Mode UI refinement (existing screen is MVP-only visual)
- [ ] PAS protocol: Twilio WhatsApp + Venemergencia webhook
- [ ] MFCL validation orchestrator (6 parallel async checks)
- [ ] Dispatch terminal (Portal 5) backend integration
- [ ] Clinical handover API (Portal 6 backend)
- [ ] GUIA PAY C2P integration (pending commercial agreement)

---

## 8. Open Questions & Discovery Agenda

**Schedule:** Discovery session with William Porras + Manuel
**Goal:** Resolve all open questions below before Sprint 3 begins

### 8.1 Process & Regulatory (William)

1. **Acsel/Sirway APIs:**
   - Is there a sandbox/test environment available?
   - What is the typical response SLA? (target <5 seconds for policy issuance)
   - What data fields are required per policy issuance request?
   - How are policy cancellations handled via API?

2. **SUDEASEG Compliance:**
   - What are the required fields in the audit log for each policy event?
   - Is a "Provisional Policy" (fallback model) acceptable under current regulations?
   - What is the minimum data retention period for policy records?
   - How often does SUDEASEG request audit access?

3. **Claims workflow:**
   - Who approves a cash-out authorization? (automated only, or human sign-off required below threshold?)
   - Is there a maximum claim amount before mandatory human review?
   - What documentation is required for a claim to be legally valid?

4. **Venemergencia integration:**
   - What data format does Venemergencia's system accept for dispatch events?
   - Is their API REST or some other protocol?
   - What is their system uptime SLA?

### 8.2 Actuarial & Financial (Manuel)

5. **Sensor threshold:**
   - What is the actuarial basis for the impact detection threshold? 4G? 9G?
   - Has the 99.7% false-positive discrimination claim been empirically tested?

6. **Tariff structure:**
   - What is the full breakdown of the $17 RCV premium (what goes to insurer vs. commission)?
   - What is the expected claims frequency (% of riders who file a claim per year)?
   - At what rider volume does the capitation model break even?

7. **SLI reserve fund:**
   - How is the 25% advance funded? (from collected premiums? separate reserve?)
   - What is the maximum exposure per incident?

8. **GUIA PAY:**
   - Has the commercial agreement been initiated? Timeline to activation?
   - What is the per-transaction fee structure?

### 8.3 Platform & Partnership (Alex / Thony)

9. **TRON wallet:** Why TRON in addition to Polygon? Is this a requirement or a prototype artifact?
10. **Quasar codebase:** Can Diego access Thony's Node.js + React platform codebase? Where is it hosted?
11. **Equity structure:** What is the proposed equity split across founders?
12. **ALTEHA network integration:** Do the 350+ clinics have a unified API, or must each be onboarded manually?

---

*Document maintained in: `docs/ARCHITECTURE_FINDINGS_2026-03-24.md`*
*Next review: After William + Manuel discovery session*
*Update trigger: Any new carrier API specs, GuiaPay agreement, or SUDEASEG regulatory clarification*
