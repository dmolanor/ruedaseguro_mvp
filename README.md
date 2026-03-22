# RuedaSeguro

**B2B2C InsurTech platform** for Venezuelan motorcycle riders — mandatory RCV insurance in under 6 minutes.

## Architecture

See [`research_docs/MVP_ARCHITECTURE.md`](research_docs/MVP_ARCHITECTURE.md) for the full architectural blueprint.

## Monorepo Structure

```
RuedaSeguro/
├── mobile/                 # Flutter app (riders)
├── admin-portal/           # Next.js 15 + shadcn/ui (carrier admins, brokers)
├── supabase/
│   ├── migrations/         # SQL migration files
│   └── functions/          # Edge Functions (Deno)
├── contracts/              # Solidity smart contracts (Phase 1.5)
├── supabase_queries/       # Ad-hoc SQL queries for Supabase
├── docs/                   # Project documentation
├── research_docs/          # Architecture research & planning
│   ├── Architects/         # Architect research documents
│   └── original_docs/      # Original source documents
└── .github/workflows/      # CI/CD pipelines
```

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile | Flutter 3.x, Riverpod, GoRouter, Google ML Kit |
| Backend | Supabase (PostgreSQL, Auth, Storage, Edge Functions) |
| Admin | Next.js 15, shadcn/ui, Tailwind CSS |
| Hosting | Supabase (dev) → Local VZ Server + GCP (prod) |

## Setup

```bash
# Flutter app
cd mobile && flutter pub get && flutter run

# Admin portal
cd admin-portal && npm install && npm run dev

# Supabase local dev
supabase start
```

## Branching Convention

- `feat/RS-XXX-short-description`
- `fix/RS-XXX-short-description`
- `chore/RS-XXX-short-description`

## Commit Convention

```
type(scope): message
```

Examples: `feat(auth): add OTP verification screen`, `fix(ocr): handle rotated cédula images`
