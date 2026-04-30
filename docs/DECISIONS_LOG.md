# DECISIONS_LOG.md

Architecture and product decisions. One entry per decision — date, context, options considered, final call, and owner.

> Format: D-XXX | Date | Status | Owner

---

## D-001 — Flutter as mobile framework

**Date:** 2025-12 (Sprint 1)
**Status:** Closed
**Owner:** Diego

**Decision:** Use Flutter (Dart) for the end-user mobile app.

**Context:** Need single codebase for Android + iOS. Team has Flutter experience. Supabase has a first-class Flutter SDK.

**Options:** React Native, Flutter, native Android-first.

**Choice:** Flutter — best fit for the team, Supabase SDK quality, and Venezuelan Android-dominant market (iOS can come later with zero code duplication).

---

## D-002 — Supabase as backend (dev → staging → prod path)

**Date:** 2026-03 (MVP v3)
**Status:** Closed
**Owner:** Diego

**Decision:** Use Supabase for all development and staging. Design for pg_dump migration to Local VZ PostgreSQL at production.

**Context:** SUDEASEG regulations require financial/insurance data on Venezuelan servers. No major cloud has VZ data centers.

**Options:** Full GCP from day one, Supabase-only, Supabase dev + Local VZ prod.

**Choice:** Supabase dev + Local VZ prod path. Use standard SQL (no Supabase-specific extensions) so `pg_dump | pg_restore` is the migration.

---

## D-003 — Mercantil as sole insurance carrier

**Date:** 2026-04-22
**Status:** Closed
**Owner:** Alex

**Decision:** Mercantil Seguros is the exclusive RCV carrier for V1. No Acsel/Sirway dual integration.

**Context:** MVP v3 assumed Acsel + Sirway dual-system. April meeting confirmed Mercantil has committed exclusively.

**Impact:** Sprint 5/6 API integration is Mercantil-only. `RS-200` migrations will reflect Mercantil's schema.

---

## D-004 — Admin portal delegated to Quasar/Thony

**Date:** 2026-03 (MVP v3)
**Status:** Closed
**Owner:** Diego + Thony

**Decision:** RuedaSeguro does NOT build an admin portal. Thony's Quasar platform (React) is the Centro de Control.

**Context:** MVP v2 had `admin-portal/` in Next.js. Zero business value to rebuild Thony's existing tooling.

**Impact:** `admin-portal/` folder deleted. Flutter app exports data Thony's platform needs.

---

## D-005 — Telemetry: 15-minute circular buffer only

**Date:** 2026-03 (MVP v3, Alex spec)
**Status:** Closed
**Owner:** Alex

**Decision:** Telemetry buffer holds 15 minutes of sensor data. Flush only on impact detection.

**Context:** MVP v2 planned 100–200 Hz continuous telemetry. Battery/data cost was prohibitive.

**Impact:** `TelemetryBufferService` with 15-min window. No continuous cloud upload.

---

## D-006 — Payment model: RuedaSeguro as aggregator

**Date:** 2026-03 (MVP v3)
**Status:** Closed
**Owner:** Fernando

**Decision:** RuedaSeguro collects 100% of premium, settles RCV portion to Mercantil, retains tech margin.

**Context:** Original model was "tech layer" passing payments through. Aggregator model gives better unit economics and payment flexibility.

**Impact:** GuiaPay / Débito Inmediato integration for collection. Settlement logic in Edge Functions.

---

## D-007 — Riverpod as state management

**Date:** 2025-12 (Sprint 1)
**Status:** Closed
**Owner:** Diego

**Decision:** flutter_riverpod with `Notifier` / `AsyncNotifier` pattern. No `ChangeNotifier`, no BLoC.

**Context:** Need testable, composable state. Riverpod code generation keeps providers type-safe.

---

## D-008 — OTP via WhatsApp (phone-first auth)

**Date:** 2026-01 (Sprint 2)
**Status:** Closed
**Owner:** Diego

**Decision:** Auth is phone-number only. OTP delivered via WhatsApp through MessageBird. No email/password.

**Context:** Venezuelan users have high WhatsApp penetration. Email-based auth has high drop-off.

**Impact:** Supabase Phone OTP provider (MessageBird). No password reset flow needed.

---

## D-009 — Venemergencia API: direct integration

**Date:** 2026-04-22
**Status:** Closed
**Owner:** Alex

**Decision:** RuedaSeguro calls Venemergencia API directly (not via Quasar).

**Context:** Two options in D4: direct vs. routed through Quasar. April meeting resolved in favor of direct — simpler, fewer points of failure.

---

## Open decisions (require resolution before Sprint 5/6)

| #     | Decision                                                     | Blocks          | Owner                      | Target            |
| ----- | ------------------------------------------------------------ | --------------- | -------------------------- | ----------------- |
| D-010 | Audio alarm in background: foreground service vs. silent     | Sprint 5 RS-094 | Diego                      | Sprint 5 kickoff  |
| D-011 | Speed >80 km/h: block app vs. flag only                      | Sprint 5 RS-090 | Alex + legal/Mercantil     | Sprint 5 kickoff  |
| D-012 | Broker activation: separate onboarding screen vs. bypass OCR | Sprint 7 RS-112 | Alex + Fernando            | Sprint 7 planning |
| D-013 | Acompañante coverage: included vs. separate product          | Sprint 5 RS-098 | Alex + legal/Mercantil     | Sprint 5 kickoff  |
| D-014 | Pre-quote eligibility questions                              | Sprint 5/6      | Fernando + Mercantil legal | Sprint 6 planning |
| D-015 | Payment map: Pago Móvil / Débito Inmediato / GuiaPay split   | Sprint 5 + 7    | Fernando                   | Sprint 5 kickoff  |
| D-016 | Chatbot in emergency flow                                    | Post-Sprint 8   | Alex                       | Post-MVP          |
