# ⚠️ DEPRECATED — admin-portal/

**Status:** Frozen. No further development.
**Decision made:** 2026-03-24 (Diego, Fernando, Thony, Alex, William, Manuel)
**Superseded by:** Thony's React + Node.js platform (RuedaSeguro-branded)

---

## Why this exists

The `admin-portal/` directory contains a Next.js scaffold built during Sprint 0 as a placeholder for a carrier/broker dashboard. As of **MVP Plan v3** (2026-03-26), the decision was made to **skip building our own admin portal** entirely.

## What replaces it

Thony's platform provides 7 purpose-built portals, all RuedaSeguro-branded:

| Portal | Audience |
|--------|----------|
| Management Overview | Executive / founders |
| Insurance Partner | Seguros Pirámide ops team |
| Venemergencia Dispatch | Ambulance coordination |
| Clinical Care | Triage + discharge tracking |
| Broker Pipeline | Corredores de Seguros |
| Customer Ops Desk | Call center / support agents |
| Administration | System configuration |

## Our obligation

The Flutter mobile app and Supabase backend publish **clean events** (via Supabase Realtime / MQTT) that Thony's platform consumes. Refer to **Section 4.2 of `docs/MVP_PLAN_v3.md`** for the event contract.

## What to do with this directory

- **Do not delete** — the git history may be referenced in future audits.
- **Do not run** — no CI/CD workflow points here.
- **Do not update** — treat as read-only archaeological artifact.

If you are a future developer wondering whether to revive this: read `docs/MVP_PLAN_v3.md` section 3 (Decision #3) before proceeding.
