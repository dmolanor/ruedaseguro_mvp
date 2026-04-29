# Changelog

All notable changes to RuedaSeguro are documented here.
Format: `[version] YYYY-MM-DD — description`.

---

## [0.5.0] 2026-04-29 — Reset baseline (post Sprints 0–4E)

### Estado del producto

- 321 tests passing
- 9 pantallas de onboarding completas
- OCR de cédula validado (ML Kit)
- Carnet QR generado y compartible
- Demo de detección de impacto a 50 Hz
- Autenticación por OTP vía WhatsApp (Meta Business Cloud API)
- Emisión de póliza RCV con pago móvil P2P
- Acuerdo de exclusividad con Mercantil Seguros activo

### Disciplina operacional (Phase 1 Reset)

- `CLAUDE.md` reescrito con Engineering Practices, AI Agent Rules, Skill Routing
- `GEMINI.md` creado para Gemini CLI
- Pre-commit hooks: gitleaks, flutter format, flutter analyze, prettier
- PR template con checklist gstack
- Issue templates (bug, feature)
- CI workflows: flutter-ci, quality (coverage), security (gitleaks)
- GitHub Environments: Develop, Staging, Production

### Stack

- Flutter 3.41.x / Dart
- Supabase (PostgreSQL + RLS + Deno Edge Functions)
- Riverpod (Notifier/AsyncNotifier)
- GoRouter
- ML Kit (document scanner)
- Sentry (instalado, pendiente de activar en release — Sprint 5)

---

## Próximo: [0.6.0] Sprint 5

- Background foreground service (sensor pipeline continuo)
- Tabla `incidents` + persistencia de emergencias
- Observabilidad: Sentry firing en release
- Environments separados Supabase dev / staging
