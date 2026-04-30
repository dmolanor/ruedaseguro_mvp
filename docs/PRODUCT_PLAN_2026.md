# PRODUCT_PLAN_2026.md

> **Version:** 1.0 — 2026-04-30
> **Status:** Active
> **Supersedes:** `MVP_PLAN_v3.md`, `ROADMAP_SPRINTS_5_TO_8.md`, `ARCHITECTURE_FINDINGS_2026-03-24.md` > **Decisions reference:** `DECISIONS_LOG.md`

---

## 0. State of This Document

This is the single source of truth for what RuedaSeguro is building and why. Update it when:

- A blocker is resolved or changes owner
- A sprint ships (update status table)
- A product decision from `DECISIONS_LOG.md` is closed

Sections marked `⚠️ NEEDS INPUT` require a decision from the team before Sprint 5 starts.

---

## 1. Vision

**RuedaSeguro** is a B2B2C payment aggregator and coverage orchestrator for Venezuelan motorcycle insurance (RCV — Responsabilidad Civil Vehicular), backed by Mercantil Seguros.

- Rider pays 100% of premium → RuedaSeguro collects
- RuedaSeguro settles RCV portion to Mercantil, orchestrates medical coverage via Venemergencia
- Centro de Control (Quasar/Thony) handles incident operations

**We are NOT building:** admin portal, IBM-grade IoT infrastructure, Centro de Control, full behavioral telemetry, chatbot (post-MVP).

---

## 2. Business Model

```
Rider pays 100% of premium → RuedaSeguro (AZ Capital) gateway
  ├─ Settles RCV minimum → Mercantil Seguros via carrier API
  ├─ Pays capitation fee → Venemergencia (Plus/Premium only)
  └─ Retains: technology margin + medical reserve + buffer
```

**Coverage tiers:**

| Tier        | Target price | Coverage                        | On accident                       |
| ----------- | ------------ | ------------------------------- | --------------------------------- |
| **Básica**  | ~$17/yr      | RCV mandatory liability only    | Cash payout via Pago Móvil        |
| **Plus**    | ~$130–150/yr | RCV + Venemergencia network     | Ambulance dispatch + ER admission |
| **Premium** | ~$200–300/yr | RCV + full recovery + telemetry | Above + rehab + milestone payouts |

> ⚠️ NEEDS INPUT (D-014): Eligibility questions / pre-quote screening — Fernando + Mercantil legal.
> ⚠️ NEEDS INPUT (D-015): Final payment method split (Pago Móvil / Débito Inmediato / GuiaPay) — Fernando.

**Year 1 target:** 10,000 active riders
**ARR at 75,000 riders:** ~$2M (mixed tier)

---

## 3. Scope — What We Build

| Layer                                          | Owner                  |
| ---------------------------------------------- | ---------------------- |
| Flutter mobile app (end-user, Android + iOS)   | RuedaSeguro team       |
| Supabase backend (DB, Auth, Edge Functions)    | RuedaSeguro team       |
| Mercantil carrier API integration              | RuedaSeguro team       |
| Venemergencia API integration                  | RuedaSeguro team       |
| GuiaPay / Débito Inmediato payment integration | RuedaSeguro team       |
| Centro de Control dashboard                    | Quasar / Thony         |
| Incident operations and triage                 | Venemergencia + Quasar |

---

## 4. Closed Decisions

| Decision                       | Summary                                              | Log entry |
| ------------------------------ | ---------------------------------------------------- | --------- |
| Flutter mobile                 | Single codebase Android + iOS                        | D-001     |
| Supabase backend               | Dev/staging on Supabase; prod on Local VZ PostgreSQL | D-002     |
| Mercantil exclusive            | No Acsel/Sirway                                      | D-003     |
| No admin portal                | Quasar handles Centro de Control                     | D-004     |
| Telemetry: 15-min buffer       | Flush on impact only                                 | D-005     |
| Aggregator payment model       | Collect 100%, settle RCV                             | D-006     |
| Riverpod state management      | Notifier / AsyncNotifier                             | D-007     |
| OTP via WhatsApp (MessageBird) | No password auth                                     | D-008     |
| Venemergencia: direct API      | Not via Quasar                                       | D-009     |

---

## 5. Roadmap

### Sprint 5 — Background service + incident persistence (May 2026)

**Goal:** The app detects real accidents in background and persists them in DB.

| Ticket | Description                                 | Status  |
| ------ | ------------------------------------------- | ------- |
| RS-094 | Foreground service for accident detection   | Planned |
| RS-090 | Speed limit flag (>80 km/h)                 | Planned |
| RS-095 | Incident record in DB (incidents table)     | Planned |
| RS-096 | Emergency payload: GPS + cédula + tier      | Planned |
| RS-097 | WhatsApp notification to emergency contacts | Planned |
| RS-098 | Acompañante coverage payload design         | Planned |

> ⚠️ NEEDS INPUT before kickoff:
>
> - D-010: Audio alarm — foreground service vs. silent (Diego)
> - D-011: Speed >80 km/h behavior (Alex + legal/Mercantil)
> - D-013: Acompañante coverage scope (Alex + legal/Mercantil)
> - D-015: Payment method map (Fernando)

### Sprint 6 — Mercantil API + real payments (June 2026)

**Goal:** End-to-end policy emission with real Mercantil API and real payment processing.

**Unblocked by:** Mercantil API spec delivery + GuiaPay access meeting.

| Ticket  | Description                                              | Status              |
| ------- | -------------------------------------------------------- | ------------------- |
| RS-200+ | `policies_mercantil` migration (schema TBD by Mercantil) | Blocked on API spec |
| RS-110  | Mercantil carrier API client                             | Blocked on API spec |
| RS-111  | Real payment flow (GuiaPay / Débito Inmediato)           | Blocked on D-015    |
| RS-112  | Policy PDF generation (carrier PDF)                      | Planned             |

### Sprint 7 — Broker activation + MQTT real (July 2026)

**Goal:** Broker-originated policy activations and live MQTT to Centro de Control.

| Ticket | Description                                        | Status  |
| ------ | -------------------------------------------------- | ------- |
| RS-112 | Broker activation screen (póliza-first onboarding) | Planned |
| RS-113 | MQTT production integration (Quasar handshake)     | Planned |
| RS-114 | Incident reporting to Centro de Control            | Planned |

> ⚠️ NEEDS INPUT before Sprint 7 planning: D-012 (broker activation design — Alex + Fernando).

### Sprint 8 — Medical expenses + KPIs (August 2026)

| Ticket | Description                                | Status  |
| ------ | ------------------------------------------ | ------- |
| RS-120 | Medical expense activation (60%/40% split) | Planned |
| RS-121 | KPI dashboard data (Supabase analytics)    | Planned |
| RS-122 | Premium product: rehab + milestone payouts | Planned |

---

## 6. Active Blockers

| Blocker            | Blocks                  | Owner    | Check-in         | Alternative if stale                                  |
| ------------------ | ----------------------- | -------- | ---------------- | ----------------------------------------------------- |
| Mercantil API spec | Sprint 6 RS-110, RS-200 | Alex     | 2026-05-07       | Build against spec draft; swap impl when spec arrives |
| GuiaPay API access | Sprint 6 RS-111         | Fernando | 2026-05-07       | Pago Móvil mock already in place                      |
| D-010 audio alarm  | Sprint 5 RS-094         | Diego    | Sprint 5 kickoff | Default to silent + vibration                         |
| D-011 speed flag   | Sprint 5 RS-090         | Alex     | Sprint 5 kickoff | Default to flag-only (no block)                       |
| D-013 acompañante  | Sprint 5 RS-098         | Alex     | Sprint 5 kickoff | Exclude from Sprint 5 payload                         |

---

## 7. Engineering KPIs

| Metric                      | Target | Current               |
| --------------------------- | ------ | --------------------- |
| Test coverage (new code)    | ≥70%   | ~65% (improving)      |
| Flutter analyze errors      | 0      | 0                     |
| Crash-free rate (Sentry)    | ≥99%   | TBD (Sentry Sprint 5) |
| Onboarding completion rate  | ≥80%   | TBD                   |
| Policy emission p95 latency | <3s    | TBD                   |

---

## 8. What We Do NOT Build

- Admin portal / Centro de Control (Quasar)
- IBM Power9 or on-prem IoT infrastructure
- Full 100–200 Hz continuous behavioral telemetry
- TRON blockchain integration
- Chatbot in emergency (post-Sprint 8 at earliest)
- iOS production release (Android-first; iOS follows with same codebase)
- Competing carrier integrations (Mercantil exclusive per D-003)
