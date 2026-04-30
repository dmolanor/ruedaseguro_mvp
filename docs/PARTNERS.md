# PARTNERS.md

Status of every external integration and partnership. Updated at each sprint boundary.

> Last updated: 2026-04-30

---

## Mercantil Seguros — Insurance Carrier

| Field                 | Value                                                                  |
| --------------------- | ---------------------------------------------------------------------- |
| **Role**              | Sole RCV carrier for V1                                                |
| **What they provide** | Policy issuance API, RCV coverage ($17/yr minimum)                     |
| **What we provide**   | Policy creation requests, rider data, premium collection               |
| **Status**            | API specification expected this week (2026-04-30)                      |
| **Contact**           | Alex (account owner)                                                   |
| **Decision**          | D-003: Mercantil is exclusive carrier, no Acsel/Sirway                 |
| **Risk**              | API delivery delayed → Sprint 6 policy emission blocked                |
| **Mitigation**        | Use mock/stub API in Sprint 5; build carrier client against spec draft |

---

## Venemergencia — Emergency Medical Network

| Field                 | Value                                                                            |
| --------------------- | -------------------------------------------------------------------------------- |
| **Role**              | Emergency dispatch and medical assistance for Plus/Premium plans                 |
| **What they provide** | Ambulance dispatch, ER admission, triage routing                                 |
| **What we provide**   | Emergency payload (rider location, injury data, policy tier) via direct API call |
| **Status**            | Proposal accepted (D-009: direct integration confirmed April 2026)               |
| **Contact**           | Alex                                                                             |
| **Decision**          | D-009: Direct API, not via Quasar                                                |
| **Risk**              | API availability / latency in emergency scenarios                                |
| **Mitigation**        | Fallback to WhatsApp notification if API unreachable                             |
| **Docs**              | `original_docs/03_partners/venemergencia/`                                       |

---

## Quasar / Thony — Centro de Control

| Field                 | Value                                                             |
| --------------------- | ----------------------------------------------------------------- |
| **Role**              | Dashboard and operations platform (Centro de Control)             |
| **What they provide** | React-based operations UI, incident tracking, broker management   |
| **What we provide**   | Structured incident payloads via MQTT / Supabase Realtime         |
| **Status**            | Integration design in progress; Sprint 7 target                   |
| **Contact**           | Thony                                                             |
| **Decision**          | D-004: RuedaSeguro does NOT build admin portal                    |
| **Risk**              | Payload format mismatch discovered late                           |
| **Mitigation**        | MQTT payload spec locked before Sprint 7 (`integrations/mqtt.md`) |
| **Docs**              | `docs/thony.md`, `integrations/mqtt.md`                           |

---

## GuiaPay — Digital Payment Gateway

| Field                 | Value                                                    |
| --------------------- | -------------------------------------------------------- |
| **Role**              | Payment gateway for Débito Inmediato (instant debit)     |
| **What they provide** | Débito Inmediato API, transaction processing             |
| **What we provide**   | Payment requests, policy reference, rider bank data      |
| **Status**            | Access meeting pending (D-015: payment map open)         |
| **Contact**           | Fernando                                                 |
| **Decision**          | D-015 open: final payment method split TBD               |
| **Risk**              | API access delayed → Sprint 5 payment flow blocked       |
| **Mitigation**        | Pago Móvil P2P as fallback (already implemented in mock) |
| **Docs**              | `original_docs/09_infrastructure/GuiaPay (9).pdf`        |

---

## MessageBird — WhatsApp OTP Provider

| Field                 | Value                                                                   |
| --------------------- | ----------------------------------------------------------------------- |
| **Role**              | Phone OTP delivery via WhatsApp for auth                                |
| **What they provide** | WhatsApp Business API, SMS fallback                                     |
| **What we provide**   | OTP requests via Supabase Phone Auth provider                           |
| **Status**            | Active — configured in Supabase Auth dashboard                          |
| **Contact**           | Diego (technical)                                                       |
| **Config**            | `MESSAGE_BIRD_API_KEY` in Supabase Dashboard → Auth → Providers → Phone |
| **Risk**              | WhatsApp delivery rate in VZ (carrier blocking)                         |
| **Mitigation**        | SMS fallback enabled in MessageBird                                     |

---

## Supabase — Backend Platform (Dev/Staging)

| Field               | Value                                                                             |
| ------------------- | --------------------------------------------------------------------------------- |
| **Role**            | PostgreSQL, Auth, Storage, Edge Functions, Realtime                               |
| **Status**          | Active — dev and staging environments                                             |
| **Plan**            | Free tier (dev), Pro (staging/prod)                                               |
| **Production path** | Migrate to Local VZ PostgreSQL per SUDEASEG; retain Supabase for Auth + Functions |
| **Decision**        | D-002                                                                             |
