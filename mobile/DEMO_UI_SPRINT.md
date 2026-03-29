# RuedaSeguro — Demo UI Sprint
**Date:** 23 Mar 2026
**Purpose:** Visual demo for leadership meeting — fully mocked, no backend required
**Build status:** ✅ Compiles clean (`flutter analyze` → 0 errors, 0 warnings)

---

## Overview

All post-onboarding screens were empty stubs. This sprint replaced every stub with a fully designed, animated screen using the existing design system (Navy Blue `#1A237E` + Orange `#FF6D00`, Montserrat + Lato, `flutter_animate`). All data is mocked — no Supabase calls are made.

---

## How to Enter Demo Mode

On the **Welcome screen** (debug builds only), a **"Ver demo completo"** button appears at the bottom. Tapping it:

1. Calls `ref.read(authProvider.notifier).enterDemoMode()`
2. Sets `AuthStatus.authenticatedWithProfile` without any Supabase session
3. GoRouter redirects immediately to `/home`

> **Note:** The button only appears in `kDebugMode`. It will not show in release/production builds.

---

## New & Modified Files

### New Files

| File | Purpose |
|------|---------|
| `mobile/lib/core/data/mock_data.dart` | Centralized mock data: rider profile, vehicle, policy, 3 insurance plans, claims history, payment history, BCV exchange rate |
| `mobile/lib/features/payment/presentation/screens/payment_success_screen.dart` | Payment confirmation with elastic checkmark animation and payment summary |
| `mobile/lib/features/emergency/presentation/screens/emergency_screen.dart` | Emergency SOS screen with pulsing animated countdown, cancel flow, and activated state |

### Modified Files

| File | What changed |
|------|-------------|
| `mobile/lib/shared/providers/auth_provider.dart` | Added `enterDemoMode()` — sets `authenticatedWithProfile` without Supabase |
| `mobile/lib/features/auth/presentation/screens/welcome_screen.dart` | Added "Ver demo completo" button (debug only) |
| `mobile/lib/features/home/presentation/screens/home_screen.dart` | Full rewrite: `BottomNavigationBar` shell with 4 tabs (Inicio, Mi Póliza, Asistencia, Perfil), rich home dashboard, claims tab |
| `mobile/lib/features/policy/presentation/screens/product_selection_screen.dart` | Full rewrite: 3 plan cards (Básica $17 / Plus $31 / Ampliada $110) with coverage lists, USD + VES pricing, recommended badge |
| `mobile/lib/features/policy/presentation/screens/quote_summary_screen.dart` | Full rewrite: plan header, vehicle summary, holder info, coverage list, dual-currency price breakdown |
| `mobile/lib/features/policy/presentation/screens/policy_detail_screen.dart` | Full rewrite: digital policy card with gradient, QR placeholder, SHA-256 integrity badge, coverage chips, download/share/renew actions. Added `isTab` param to suppress back button when used as a tab |
| `mobile/lib/features/payment/presentation/screens/payment_method_screen.dart` | Full rewrite: animated method selector (Pago Móvil / Transferencia bancaria), bank data display, receipt upload slot, reference field |
| `mobile/lib/features/claims/presentation/screens/new_claim_screen.dart` | Full rewrite: progress steps, active policy banner, 4 incident type cards, date/time, location + map placeholder, description, 3 photo slots, injuries toggle |
| `mobile/lib/features/profile/presentation/screens/profile_screen.dart` | Full rewrite: avatar with verified badge, active policy summary, personal data, vehicle info, emergency contact, payment history, settings toggles (notifications, biometric), sign-out with confirmation dialog |
| `mobile/lib/app/router.dart` | Added `/payment/success` and `/emergency` routes; passes `InsurancePlan` via `extra`; emergency accessible in debug without auth guard |

---

## Screen Inventory

### 1. Home Dashboard (`/home` — Tab 1: Inicio)
- Greeting header with initials avatar, notification bell with dot
- **Active policy card** — dark navy gradient, tier badge, vehicle chip, date chip, progress bar
- **Emergency SOS button** — red gradient, navigates to `/emergency`
- **Quick actions grid** — Cotizar / Ver Póliza / Reportar Siniestro / Pagos (4 icons)
- **BCV exchange rate banner** — 1 USD = 78.50 VES
- **Recent activity feed** — póliza renovada, pago confirmado, reclamo en revisión
- All elements enter with staggered `fadeIn + slideY` via `flutter_animate`

### 2. Mi Póliza (`/home` — Tab 2)
- Full **digital policy card** — dark navy gradient with decorative circles, QR code placeholder, holder name, cédula, vehicle row with plate chip, validity dates, policy number, ACTIVA status badge
- Coverage chips row — horizontal scroll (Daños a terceros, Grúa 24/7, Defensa legal, Gastos médicos)
- Vehicle section card
- Policy details section card (N° póliza with copy button, aseguradora, correduría, fechas, prima)
- **SHA-256 integrity card** — green verified badge, truncated hash
- Download PDF button + Renovar póliza button

### 3. Asistencia (`/home` — Tab 3)
- **Emergency CTA card** — red gradient, links to `/emergency`
- "Reportar nuevo siniestro" secondary button
- Claims history list:
  - `SIN-2026-0042` — Colisión menor, En revisión (amber badge)
  - `SIN-2025-0187` — Daño a tercero, Liquidado (green badge)

### 4. Perfil (`/home` — Tab 4)
- Avatar (initials + verified dot), full name, phone, "Asegurado activo" status chip
- Edit icon
- Active policy summary banner
- **Datos personales** — Nombre, Cédula, Teléfono, Fecha de nacimiento, Ciudad
- **Mi vehículo** — Marca/Modelo, Año, Placa, Color, N° Motor
- **Contacto de emergencia** — Nombre, Teléfono, Relación
- **Historial de pagos** — 2 payments (Pago Móvil 2026, Transferencia 2025)
- **Configuración** — Notificaciones toggle, Biometría toggle, Centro de ayuda, Política de privacidad
- Sign-out button with confirmation `AlertDialog`

### 5. Seleccionar Plan (`/policy/select`)
- Vehicle banner (brand/model/year + plate chip)
- 3 plan cards, staggered slide-in:
  - **Básica** $17 USD — Solo RCV, indigo accent, 3 coverages + 3 excluded (with ✗ markers)
  - **Plus** $31 USD — RCV + Grúa + Medical, orange accent, "Recomendado" badge, highlighted border + shadow
  - **Ampliada** $110 USD — Full coverage + Red ALTEHA, navy accent, 8 coverages
- Each shows USD + VES price, "Seleccionar" button → pushes to `/policy/quote`
- BCV rate footer

### 6. Resumen de Cotización (`/policy/quote`)
- Plan header card (gradient matching plan accent color, price, "★ Popular" badge)
- Vehicle summary card
- Titular card
- Coverages card (green checkmarks)
- **Price breakdown card** — prima, bolívares, tasa BCV, vigencia, aseguradora, **Total a pagar** highlighted box
- "Proceder al pago" → `/payment/method`
- Legal disclaimer

### 7. Método de Pago (`/payment/method`)
- **Amount summary** — navy card with USD amount large, VES secondary, plan name chip
- Animated method selector (Pago Móvil / Transferencia bancaria) — border + color transitions
- **Pago Móvil details** — teléfono, banco, cédula, concepto + amber info banner
- **Transferencia details** — banco, cuenta corriente, beneficiario, RIF, referencia
- Receipt upload slot — tap to "upload" → animates to green confirmed state
- Reference number text field
- "Confirmar pago" → 2s mock delay → `/payment/success`

### 8. Pago Exitoso (`/payment/success`)
- Green circle with elastic scale animation (`Curves.elasticOut`)
- "¡Pago registrado!" headline
- Explanation text
- Payment summary card (reference, plan, amount, method, date, status "⏳ En revisión")
- "Ver mi póliza" + "Volver al inicio" buttons

### 9. Reportar Siniestro (`/claims/new`)
- 3-step progress indicator
- Active policy banner (blue, verified)
- Incident type 2×2 grid (Colisión / Daño a tercero / Robo / Lesiones) — animated selection with color per type
- Date + Time pickers (tappable tiles)
- Location field + map placeholder
- Multi-line description field
- 3 photo slots (tap to "add" → green confirmed state)
- Injuries toggle (activates red color + "asistencia médica inmediata" copy)
- "Enviar reporte" → 2s mock → SnackBar with claim number → pop

### 10. Detalle de Póliza (`/policy/:id`)
Same as Tab 2, but as a push route with back button enabled.

### 11. Modo Emergencia (`/emergency`)
- **Dark screen** (`#0D0D0D`)
- **Pulsing SOS ring** — 4 concentric animated circles in red, breathing animation
- 10-second countdown timer
- Status indicators (GPS activo ✓, Contacto notificado ◯, Asistencia en camino ◯)
- GPS coordinates banner (mock Caracas coordinates)
- **"ESTOY BIEN"** large white pill button → cancels
- On countdown reaching 0 → **Activated state**: SOS icon, contact list (family + Venemergencias + Grupo Nueve Once), GPS sent, ambulance in progress
- Cancel → **Cancelled state**: green checkmark + "Nos alegra que estés bien"

---

## Mock Data Reference (`core/data/mock_data.dart`)

```
MockRider       — Juan Carlos Rodríguez, V-12.345.678, +58 424-1234567, Caracas
MockVehicle     — Honda CBF 150, 2022, Rojo, ABC-123-DE
MockPolicy      — RS-2026-001234, RCV Plus, Activa, 23 Mar 2026 – 23 Mar 2027, $31 USD
MockPlans       — Básica ($17), Plus ($31, isRecommended), Ampliada ($110)
MockClaims      — SIN-2026-0042 (En revisión), SIN-2025-0187 (Liquidado)
MockPayments    — PAG-2026-001234 (Pago Móvil $31), PAG-2025-004521 (Transferencia $28)
MockExchangeRate — 1 USD = 78.50 VES (BCV, 23 Mar 2026 09:30 AM)
```

---

## Design System Used

| Token | Value |
|-------|-------|
| Primary | `#1A237E` (Navy Blue) |
| Accent | `#FF6D00` (Orange) |
| Success | `#2E7D32` |
| Error | `#C62828` |
| Heading font | Montserrat (700/600) |
| Body font | Lato (400/500) |
| Base spacing | 4px grid (xs=4, sm=8, md=16, lg=24, xl=32, xxl=48) |
| Animations | `flutter_animate` — fadeIn, slideY, slideX, scale, elasticOut |

---

## What This Is NOT

- ❌ Not connected to Supabase
- ❌ No real OCR, no camera, no file uploads
- ❌ No payment processing (Pago Móvil / GUIA PAY)
- ❌ No crash detection sensors (Phase 1.5)
- ❌ No blockchain / NFT minting
- ❌ The "Ver demo completo" button will not appear in production builds

All engineering-mode work (real backend integration, OCR, payments) resumes after the meeting.
