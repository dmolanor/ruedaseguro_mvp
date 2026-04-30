# RuedaSeguro — Reset Plan

**Fecha:** 2026-04-27
**Autor:** Engineering (Diego)
**Estado:** Propuesta — pendiente de aprobación del equipo
**Supersede:** Ninguno (este documento es el primer plan post-acuerdo Mercantil)
**Vigencia:** El plan se ejecuta en 4–6 semanas. Después se archiva en `docs/_archive/` y se sustituye por `PRODUCT_PLAN_2026.md` como fuente única de verdad.

---

## 0. Por qué este reset

El acuerdo de exclusividad con Mercantil Seguros es un cambio cualitativo, no cuantitativo, en lo que tiene que ser RuedaSeguro. El producto ahora respalda su credibilidad en una corporación regulada — y eso obliga a estándares de ingeniería que hasta hoy no han sido sistemáticos.

Lo que ya funciona (Sprints 0–4E, ~6 meses de trabajo, 321 tests verdes, 9 pantallas de onboarding, OCR validado, carnet QR, demo de detección de impacto a 50 Hz) **se preserva**. Lo que se reinicia es:

1. **La disciplina operacional** — cómo trabajamos cada sesión, cada commit, cada PR.
2. **La documentación** — consolidar 30+ archivos en una fuente única de verdad.
3. **El alcance del repo** — eliminar código y assets que ya no construimos (admin portal, contratos blockchain, planes legacy).
4. **Las migraciones de DB** — pasar de 24 archivos iterativos a un baseline limpio.
5. **El rigor de ingeniería** — Sentry, Sonar, branch protection, environments, integration tests, observabilidad — antes de Sprint 5.

El reset **no toca el código de features**. No reescribimos la app. La app está bien.

---

## 1. Principios que guían este reset

| Principio                                   | Qué significa                                                                                                                                           |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Nada ships sin DB**                       | Si una pantalla recolecta datos del usuario, esos datos se persisten en Supabase antes de mergear. Sin excepciones.                                     |
| **Nada ships sin tests**                    | Cada PR aumenta o mantiene cobertura. PRs que la bajan se devuelven.                                                                                    |
| **Nada ships sin observabilidad**           | Cada feature crítico emite eventos que podemos medir en Sentry/logs/métricas. Si no podemos verlo, no existe.                                           |
| **Una sola fuente de verdad por área**      | Un plan de producto. Una arquitectura. Un changelog. No tres versiones del mismo documento.                                                             |
| **Decisión > especulación**                 | Los docs registran decisiones tomadas, no hipótesis aspiracionales. Si una decisión está abierta, va al `DECISIONS_LOG.md` con dueño y fecha de cierre. |
| **Bloqueantes externos no bloquean código** | Cada integración externa tiene su stub + interface. El código avanza; el partner se enchufa cuando llega.                                               |

---

## 2. Estructura del reset (5 fases en orden)

| #   | Fase                                                  | Duración            | Objetivo                                                                 |
| --- | ----------------------------------------------------- | ------------------- | ------------------------------------------------------------------------ |
| 1   | Disciplina operacional (CLAUDE.md + GitHub + tooling) | Semana 1            | Codificar prácticas que se aplican a partir del primer commit post-reset |
| 2   | Consolidación documental                              | Semana 2            | Una fuente de verdad por área; archivo del resto                         |
| 3   | Limpieza de código                                    | Semana 2 (paralelo) | Borrar `admin-portal/`, `contracts/`, mockups, planes legacy             |
| 4   | Consolidación de migraciones                          | Semana 3            | Baseline único; renumeración futura limpia                               |
| 5   | Rigor de ingeniería                                   | Semana 3–4          | Sentry, Sonar, environments, E2E tests — listo antes de Sprint 5         |

Cada fase tiene una sección detallada abajo con checklists ejecutables.

---

## 3. FASE 1 — Disciplina operacional

**Objetivo:** Que `CLAUDE.md` y la configuración de GitHub establezcan reglas no-negociables que se apliquen a cada commit, PR y sesión a partir del 2026-05-XX.

### 3.1 Reescritura de `RuedaSeguroMVP/CLAUDE.md`

El `CLAUDE.md` actual describe arquitectura. Va a sumar **prácticas operacionales** y **routing de tooling**. Estructura propuesta:

```
1. Project Overview                       (existente, mantener)
2. Commands                               (existente, mantener)
3. Architecture                           (existente, condensar)
   3.1 Mermaid Diagrams                   (NUEVO: Esquema DB y Pipeline Telemetría)
4. ▶ Engineering Practices (NUEVO)
   4.1 Git workflow
   4.2 Commit conventions
   4.3 Pull request rules
   4.4 Code review checklist
   4.5 Migration rules
   4.6 Secret handling
   4.7 Definition of Done
5. ▶ AI Agent Rules (NUEVO)
   5.1 Reglas para Claude Code en este repo
   5.2 Cuándo pedir confirmación
   5.3 Qué no hacer
6. ▶ Skill / Tooling Routing (NUEVO)
   6.1 Skill routing global (copia tal cual del CLAUDE.md raíz — gstack)
   6.2 Mapeo de skills a fases de nuestro proceso (ver Sección 8 de este plan)
   6.3 Skills obligatorias vs recomendadas vs opcionales para este repo
7. Environment Variables                  (existente, expandir con dev/staging/prod)
8. Testing                                (existente, expandir con E2E e integration)
```

**Novedades 2026 para CLAUDE.md:**

- **Visual Logic:** Incluir diagramas Mermaid para el pipeline de sensores y el flujo de autenticación para que el agente "visualice" la lógica antes de editarla.
- **Hierarchical Context:** El `CLAUDE.md` raíz servirá de base, pero cada módulo mayor (e.g., `mobile/`) podrá tener su propio `CLAUDE.md` local para reglas específicas de UI/Riverpod.

### 3.2 Creación de `RuedaSeguroMVP/GEMINI.md` (NUEVO)

Como el equipo utiliza Gemini CLI como agente interactivo principal, se creará un `GEMINI.md` que optimice la "Harness Engineering" (diseño del entorno del agente).

**Estructura del GEMINI.md:**

- **Role Definition:** "Senior Full-Stack Engineer & Architect specializing in Flutter/Supabase".
- **Tech Stack & Constraints:** Versiones exactas y dependencias críticas (e.g., "Always use Riverpod Notifiers, never ChangeNotifiers").
- **Verification Loop:** Instrucción explícita de correr `flutter analyze` y `flutter test` tras cada cambio antes de dar por terminada una tarea.
- **Hierarchical Memory:** Uso de carpetas `.gemini/` para almacenar "JIT Context" (contexto Just-In-Time) sobre módulos complejos como el OCR o el pipeline de MQTT.
- **Mermaid Mapping:** Copia de los esquemas Mermaid del `CLAUDE.md` para asegurar consistencia visual en ambos agentes.
- **Skill Integration:** Mapeo de comandos shell personalizados a "Skills" del agente para automatizar tareas repetitivas (e.g., generar boilerplate de un nuevo feature).

### 3.3 GitHub repository hardening

- [ ] **Branch protection en `main`:**
  - Requerir 1 PR review aprobado
  - Requerir status checks: `flutter-ci`, `admin-ci` (mientras exista), futuro `sonar`, futuro `dependency-scan`
  - No permitir force-push
  - No permitir deletions
  - Requerir branches actualizadas antes de merge
- [ ] **Settings:**
  - Squash merge habilitado, merge commit y rebase deshabilitados
  - Auto-delete head branches al mergear
  - Conversations resolution required
- [ ] **Secrets management:**
  - Mover credenciales de `.env` a GitHub Secrets para CI
  - Rotar `SUPABASE_SERVICE_ROLE_KEY` (si está expuesto en algún commit, audit con `gitleaks`)
- [ ] **Issue templates:**
  - `.github/ISSUE_TEMPLATE/bug.yml` — repro steps, expected/actual, environment
  - `.github/ISSUE_TEMPLATE/feature.yml` — user story, acceptance criteria, blockers

### 3.3 Pre-commit hooks (local)

Crear `.pre-commit-config.yaml` con:

- [ ] `dart format --set-exit-if-changed` sobre archivos `.dart` modificados
- [ ] `flutter analyze --no-fatal-warnings` sobre el módulo afectado
- [ ] `gitleaks` para detectar secretos
- [ ] `prettier` sobre `.md` y `.json`
- [ ] Validación de conventional commit en `commit-msg`

Documentar instalación: `brew install pre-commit && pre-commit install` (o equivalente Windows).

### 3.4 CI workflows expandidos

`.github/workflows/` actual: solo `flutter-ci.yml` y `admin-ci.yml`.

**Añadir:**

- [ ] `quality.yml` — corre en cada PR: SonarCloud / SonarQube scan, coverage report a Codecov
- [ ] `security.yml` — corre en cada PR + nightly: `gitleaks`, `dependabot` revisión, `trufflehog`
- [ ] `e2e.yml` — corre nightly o en PR a `main`: tests E2E con Patrol contra Supabase staging
- [ ] `release.yml` — corre en tag `v*`: build APK release, sube a Play Console internal track, sube símbolos a Sentry

**Eliminar:** `admin-ci.yml` (ver Fase 3).

### 3.6 Entregables de Fase 1

| Archivo                              | Acción                                                                                                    |
| ------------------------------------ | --------------------------------------------------------------------------------------------------------- |
| `RuedaSeguroMVP/CLAUDE.md`           | Reescribir con secciones 4, 5 y 6 nuevas (Engineering Practices + AI Agent Rules + Skill/Tooling Routing) |
| `RuedaSeguroMVP/GEMINI.md`           | Crear con especificaciones de Harness Engineering, Verification Loops y JIT Context                       |
| `RuedaSeguroMVP/CHANGELOG.md`        | Crear; arrancar desde versión actual                                                                      |
| `.github/pull_request_template.md`   | Crear                                                                                                     |
| `.github/ISSUE_TEMPLATE/bug.yml`     | Crear                                                                                                     |
| `.github/ISSUE_TEMPLATE/feature.yml` | Crear                                                                                                     |
| `.pre-commit-config.yaml`            | Crear                                                                                                     |
| `.github/workflows/quality.yml`      | Crear (placeholder funcional, Sonar real en Fase 5)                                                       |
| `.github/workflows/security.yml`     | Crear                                                                                                     |
| Branch protection                    | Configurar vía Settings o `gh api`                                                                        |

---

## 4. FASE 2 — Consolidación documental

**Objetivo:** Después de esta fase, hay 5–6 documentos canónicos en `docs/` y todo lo demás está archivado o eliminado.

### 4.1 Auditoría completa de `docs/`

Estado actual (~30 archivos + 4 subcarpetas relevantes):

| Documento / carpeta                                                           | Decisión                                                                                                                  | Razón                                                                                                                            |
| ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `MVP_ARCHITECTURE.md`                                                         | **Archivar** → `_archive/`                                                                                                | Superseded por `MVP_PLAN_v3.md`. Mantener solo por historia.                                                                     |
| `MVP_PLAN_v3.md`                                                              | **Fusionar** en `PRODUCT_PLAN_2026.md`                                                                                    | Sigue siendo válido pero no incorpora exclusividad Mercantil ni decisión sobre Centro de Control.                                |
| `ARCHITECTURE_FINDINGS_2026-03-24.md`                                         | **Archivar** → `_archive/`                                                                                                | Su contenido vivo ya migró a `MVP_PLAN_v3.md`. Útil como historia de razonamiento.                                               |
| `ROADMAP_SPRINTS_5_TO_8.md`                                                   | **Fusionar** en `PRODUCT_PLAN_2026.md` (sección Sprints)                                                                  | Es el roadmap activo; vive como sección, no como archivo separado.                                                               |
| `TECHNICAL_PROGRESS.md`                                                       | **Archivar** → `_archive/`                                                                                                | Reemplazado por progress reports detallados.                                                                                     |
| `MEETING_ANALYSIS_30_03_2026.md`                                              | **Mover** → `meeting_history/`                                                                                            | Mantener como histórico de decisiones.                                                                                           |
| `MEETING_PREP_10_04_2026.md`                                                  | **Mover** → `meeting_history/`                                                                                            | Idem.                                                                                                                            |
| `REUNION_PREGUNTAS_EQUIPO.html`                                               | **Mantener en root de `docs/`** hasta 2026-04-23                                                                          | Después de la reunión, mover a `meeting_history/` con sus respuestas integradas en `DECISIONS_LOG.md`.                           |
| `MQTT_INTEGRATION_GUIDE.md`                                                   | **Mover** → `integrations/mqtt.md`                                                                                        | Documentación técnica de integración; vive en su propia carpeta.                                                                 |
| `SPRINT_ISSUES.md`                                                            | **Archivar** → `_archive/`                                                                                                | Backlog de Sprint 0–1 ya completado.                                                                                             |
| `Rueda Seguro Plan Review.md`                                                 | **Eliminar**                                                                                                              | LLM-generated, contenido aspiracional irrelevante (IBM Power9, etc.). Cero valor presente.                                       |
| `pantallas_app_v1.zip`                                                        | **Mover** → `assets/mockups/` o eliminar si los screenshots ya cubren                                                     | Audit visual rápido.                                                                                                             |
| `architects/overview.md`                                                      | **Eliminar**                                                                                                              | Aspiracional, IBM Power9, LLM liability. Cero valor para Mercantil-only.                                                         |
| `architects/software_app_arch.md`                                             | **Eliminar**                                                                                                              | Idem.                                                                                                                            |
| `architects/infrastructure_arch.md`                                           | **Eliminar**                                                                                                              | Idem.                                                                                                                            |
| `architects/enterprise_arch.md`                                               | **Eliminar**                                                                                                              | Idem.                                                                                                                            |
| `architects/business_arch.md`                                                 | **Extraer KPIs y modelo financiero** → `PRODUCT_PLAN_2026.md` sección Negocio. Después eliminar.                          | Tiene fragmentos útiles enterrados en LLM-text.                                                                                  |
| `architects/data_arch.md`                                                     | **Extraer schema decisions** → `ARCHITECTURE.md`. Después eliminar.                                                       | Idem.                                                                                                                            |
| `architects/ui_ux_arch.md`                                                    | **Auditar** — si tiene decisiones de design system no documentadas en `mobile/lib/core/theme/`, extraer. Si no, eliminar. |                                                                                                                                  |
| `architects/competition_analysis_1.md`                                        | **Mover** → `_archive/competition.md` o root `competition.md` (ya existe). Reconciliar.                                   |                                                                                                                                  |
| `legacy_plans/MVP_ARCHITECTURE - copia.md`                                    | **Eliminar**                                                                                                              | Copia.                                                                                                                           |
| `legacy_plans/MVP_ARCHITECTURE v2.md`                                         | **Eliminar**                                                                                                              | Versión anterior.                                                                                                                |
| `legacy_plans/SPRINT_ISSUES - copia.md`                                       | **Eliminar**                                                                                                              | Copia.                                                                                                                           |
| `legacy_plans/` (carpeta)                                                     | **Eliminar** después de vaciar                                                                                            |                                                                                                                                  |
| `original_docs/Conceptualización del Modulo de Detección de Rueda Seguro.pdf` | **Mantener** — fuente de verdad del módulo                                                                                | Mover a `original_docs/` permanente.                                                                                             |
| `original_docs/Proceso RCV Rueda seguro.pdf`                                  | **Mantener**                                                                                                              | Idem.                                                                                                                            |
| `original_docs/01_regulatory` a `10_media`                                    | **Auditar carpeta por carpeta**                                                                                           | Al menos 4 carpetas son fuentes regulatorias y de partners — mantener. Las de marketing/media probablemente moverse a `assets/`. |
| `original_docs/ORGANIZATION_GUIDE.md`                                         | **Auditar**                                                                                                               | Si describe la org de original_docs, mantener.                                                                                   |
| `progress_reports/PROGRESS_REPORT_*`                                          | **Mantener** en `progress_reports/`                                                                                       | Histórico de ejecución por sprint.                                                                                               |
| `meeting_transcripts/*.md`                                                    | **Mantener** en `meeting_transcripts/`                                                                                    | Histórico raw.                                                                                                                   |
| `screenshots/*.png`                                                           | **Mantener** en `screenshots/`                                                                                            | Referencia visual del producto.                                                                                                  |
| `guide_scanned_docs/*`                                                        | **Mantener** en `assets/test_documents/`                                                                                  | Documentos de prueba para OCR — son testing fixtures.                                                                            |

### 4.2 Documentos canónicos nuevos (a crear)

```
docs/
├── PRODUCT_PLAN_2026.md          ← Único plan de producto vivo
├── ARCHITECTURE.md               ← Arquitectura actual + ADRs
├── OPERATIONS.md                 ← Cómo se trabaja: branching, tests, deploys, oncall
├── PARTNERS.md                   ← Estado de cada integración externa (Mercantil, Quasar, Venemergencia, GuiaPay, FCM)
├── DECISIONS_LOG.md              ← ADRs ligeros — una decisión por entrada con fecha, contexto, opciones, decisión
├── CHANGELOG.md                  ← Cambios por release (mobile + supabase)
├── integrations/
│   ├── mqtt.md
│   ├── mercantil_carrier.md      ← cuando llegue
│   ├── quasar_iot.md             ← cuando llegue
│   └── venemergencia.md          ← cuando llegue
├── meeting_history/              ← Transcripts + análisis + prep
├── progress_reports/             ← Histórico de sprints (mantener)
├── original_docs/                ← Fuentes externas (PDFs, regulatorios)
├── assets/
│   ├── test_documents/           ← Sample cédulas, certificados (de guide_scanned_docs)
│   ├── mockups/                  ← (de pantallas_app_v1.zip si aplica)
│   └── screenshots/              ← (de docs/screenshots)
└── _archive/                     ← Documentos retirados pero conservados por historia
```

### 4.3 Contenido mínimo del `PRODUCT_PLAN_2026.md`

- **0. Estado:** vigente desde fecha X, supersede `MVP_PLAN_v3.md`, `ARCHITECTURE_FINDINGS_*`, `ROADMAP_SPRINTS_5_TO_8.md`.
- **1. Visión:** Mercantil-only B2B2C InsurTech para motociclistas Venezuela → LATAM.
- **2. Modelo de negocio:** RuedaSeguro como agregador de pagos, Mercantil como carrier exclusivo, Venemergencia como red médica, planes Básica/Plus/Ampliada.
- **3. Alcance del producto:** **Solo app móvil end-to-end + Supabase + integraciones**. Centro de Control NO se construye (responsabilidad de Quasar/Thony).
- **4. Decisiones cerradas (10 áreas):** Flutter, Supabase dev, Pago Móvil P2P → Débito Inmediato/GuiaPay, Mercantil único carrier, etc. Cada una con link a entrada en `DECISIONS_LOG.md`.
- **5. Roadmap:** Sprint 5 (background service + incidents DB + observabilidad), Sprint 6 (comunicaciones reales + Mercantil API), Sprint 7 (broker activation flow + MQTT real), Sprint 8 (medical expenses + KPIs).
- **6. Bloqueantes vivos:** tabla con dueño, fecha de check-in, alternativa si no llega.
- **7. KPIs del producto y de ingeniería.**
- **8. Lo que NO hacemos:** lista explícita (admin portal, IBM Power, full behavioral telemetry, TRON, Centro de Control...).

### 4.4 Contenido mínimo del `ARCHITECTURE.md`

- Diagrama actual del sistema (mobile + Supabase + integraciones)
- Decisiones arquitectónicas vigentes (resumen — el detalle vive en ADRs)
- Estructura de carpetas (`features/*/data,domain,presentation,services`)
- State management (Riverpod patterns)
- Routing (GoRouter, auth guards)
- Background services (foreground task + sensor pipeline) — esta sección crece en Sprint 5
- Telemetry pipeline (SQLite buffer + MQTT + Supabase)
- Database schema overview (entidades + RLS posture)
- Observability (Sentry, logs estructurados, métricas)
- Security posture (auth, RLS, encryption at rest, secret handling)

### 4.5 Contenido mínimo del `PARTNERS.md`

Tabla por partner con: estado del acuerdo, contacto, qué nos entregan, qué les damos, fecha de check-in, riesgo, plan de mitigación si no responden.

### 4.6 Entregables de Fase 2

| Acción                              | Cantidad                                                                      |
| ----------------------------------- | ----------------------------------------------------------------------------- |
| Documentos a crear                  | 5 (`PRODUCT_PLAN`, `ARCHITECTURE`, `OPERATIONS`, `PARTNERS`, `DECISIONS_LOG`) |
| Documentos a archivar (`_archive/`) | ~5                                                                            |
| Documentos a eliminar               | ~7 (LLM-aspiracionales + copias)                                              |
| Carpetas a crear                    | `integrations/`, `meeting_history/`, `assets/test_documents/`, `_archive/`    |
| Carpetas a eliminar                 | `legacy_plans/`, `architects/` (después de extraer valor)                     |

---

## 5. FASE 3 — Limpieza de código

**Objetivo:** Reducir el repo a lo que efectivamente construimos y mantenemos.

### 5.1 Eliminar `admin-portal/`

**Decisión:** El centro de control lo construye Quasar/Thony. Nuestro `admin-portal/` Next.js no se usa.

- [ ] Verificar que ninguna config de CI/CD ni script lo necesita
- [ ] `git mv admin-portal/ _archive/admin-portal-snapshot/` para preservar como rama si alguien quiere recuperar — alternativa: `git rm -r admin-portal/` y confiar en la historia
- [ ] Eliminar `.github/workflows/admin-ci.yml`
- [ ] Actualizar `CLAUDE.md`: quitar sección de Admin Portal, referencias a Next.js
- [ ] Actualizar `README.md` del root si menciona admin portal

### 5.2 Eliminar `contracts/`

**Decisión:** Polygon ERC-721 es Phase 1.5+. El scaffolding actual es placeholder vacío.

- [ ] `git rm -r contracts/`
- [ ] Cuando Phase 1.5 active blockchain, se crea como repo separado o submódulo

### 5.3 Eliminar archivos sueltos del root

| Archivo                                          | Acción                                                                                                  |
| ------------------------------------------------ | ------------------------------------------------------------------------------------------------------- |
| `RuedaSeguroMVP/telemetry_mockup_for_thony.json` | Mover → `docs/integrations/mqtt_payload_sample.json`                                                    |
| `RuedaSeguroMVP/mbird_codes.txt`                 | Auditar — si son códigos MessageBird de prueba, mover a `docs/integrations/` o eliminar si ya no se usa |
| `RuedaSeguroMVP/competition.md`                  | Mover → `docs/competition.md` (consolidar con `competition_analysis_1.md`)                              |
| `RuedaSeguroMVP/requirements.txt`                | Auditar — si es de Python para OCR/scripts ad-hoc, documentar propósito o eliminar                      |
| `RuedaSeguroMVP/venv/`                           | **Eliminar y agregar a `.gitignore`** si está commited (virtualenv no debe estar en git)                |

### 5.4 Auditoría de dependencias

**Mobile (`mobile/pubspec.yaml`):**

- [ ] Identificar dependencias instaladas pero no importadas (ejemplo: `local_auth` está pero no wired)
- [ ] Decidir por dependencia: usar en próximo sprint, eliminar, o documentar en `ARCHITECTURE.md` como "instalada para Phase 1.5"
- [ ] Comando útil: `dart pub deps` + grep manual; o `dart_code_metrics` con `unused_files`

**Admin (al eliminarse, no aplica).**

### 5.5 Auditoría de features sin DB persistence

Revisión file-by-file: ¿qué pantallas recolectan datos que nunca llegan a Supabase?

Conocidos:

- [ ] `EmergencyScreen` — recolecta urgency, GPS, dispatch phase. Persistencia: 0%. **Sprint 5 lo arregla.**
- [ ] `EmergencySetupScreen` — guarda timers en SharedPreferences pero no en DB. **Decidir:** ¿necesitamos sincronizarlos cross-device?
- [ ] `CrashMonitorScreen` — emite payload mock a UI, no persiste. **OK para demo, Sprint 5 lo conecta.**

Producto del audit: lista priorizada con tickets RS-XXX para Sprint 5/6.

### 5.6 Entregables de Fase 3

| Acción                            | Resultado                                    |
| --------------------------------- | -------------------------------------------- |
| `admin-portal/`                   | Eliminado o archivado                        |
| `contracts/`                      | Eliminado                                    |
| `venv/`                           | Eliminado del repo + agregado a `.gitignore` |
| Archivos sueltos del root         | Reorganizados o eliminados                   |
| Dependencias no usadas            | Documentadas o eliminadas                    |
| Lista de features sin persistence | Tickets creados para Sprint 5                |

---

## 6. FASE 4 — Consolidación de migraciones

**Objetivo:** Las 24 migraciones actuales (`RS-007_*` … `RS-DIAG_*`) se compactan en un baseline único. A partir de ahí, todas las migraciones futuras son aditivas y siguen un naming estricto.

### 6.1 Estrategia: baseline + history archive

**Por qué baseline y no rebase de migraciones:** rescribir la historia de migraciones rompe entornos existentes. Un baseline preserva la historia y simplifica para nuevos contributors.

**Pasos:**

- [ ] **Confirmar estado de prod/staging:** ningún ambiente externo depende del orden actual (fácil — solo desarrollamos en local + Supabase dev).
- [ ] **Hacer dump del schema actual** desde Supabase de desarrollo:
  ```bash
  supabase db dump --schema public --schema-only > supabase/migrations/000_baseline_schema.sql
  supabase db dump --schema public --data-only --table policy_types --table sla_config > supabase/migrations/001_baseline_seed.sql
  ```
- [ ] **Validar:** crear DB en blanco + aplicar `000_baseline_schema.sql` + `001_baseline_seed.sql` → debe quedar idéntica a la actual.
- [ ] **Archivar antiguas:** mover todas las `RS-007_*` a `RS-DIAG_*` (incluyendo `RS-018_bcv_rate_edge_function.ts`) a `supabase/migrations/_archive/`.
- [ ] **Arrancar nuevo numbering:** próxima migration nueva es `RS-200_<nombre>.sql`. Los IDs <200 quedan como históricos archivados.
- [ ] **Edge Functions:** ya viven en `supabase/functions/`. Confirmar que `RS-018_bcv_rate_edge_function.ts` está en su lugar correcto (functions/, no migrations/).

### 6.2 Naming convention futuro

```
supabase/migrations/
├── 000_baseline_schema.sql
├── 001_baseline_seed.sql
├── RS-200_incidents_table.sql           ← Sprint 5
├── RS-201_incident_status_log.sql       ← Sprint 5
├── RS-202_policies_emergency_count.sql  ← Sprint 5
└── _archive/
    ├── RS-007_01_enum_updates.sql       ← histórico
    ├── ...
    └── RS-DIAG_policies_columns.sql
```

Reglas:

- ID prefix `RS-XXX` ascending desde 200 (nunca reusar IDs)
- Nombre descriptivo en snake_case
- Una migración = un cambio lógico. No mezclar tabla nueva con ALTER de otra tabla en el mismo archivo.
- Toda migration tiene su `DOWN` documentado en comentario al inicio (no necesariamente reversible, pero documentado)

### 6.3 Migration review process

A partir de Fase 4, toda PR que agrega migration:

- [ ] Ejecuta en CI contra Supabase staging
- [ ] Tiene checklist en PR template:
  - ¿Es aditiva? (si no, justificar)
  - ¿Tiene RLS si toca tabla con datos de usuario?
  - ¿Tiene índices apropiados?
  - ¿Toca columnas críticas (PII, financial)? Doble review
  - ¿Plan de rollback?

### 6.4 Entregables de Fase 4

| Acción                          | Resultado                      |
| ------------------------------- | ------------------------------ |
| `000_baseline_schema.sql`       | Creado y validado              |
| `001_baseline_seed.sql`         | Creado                         |
| `supabase/migrations/_archive/` | 24 archivos antiguos movidos   |
| Migration naming convention     | Documentado en `OPERATIONS.md` |
| Migration PR checklist          | Agregado al PR template        |

---

## 7. FASE 5 — Rigor de ingeniería

**Objetivo:** Antes de empezar Sprint 5 (que construye el background service + incidents), tener firing los siguientes mecanismos.

### 7.1 Sentry funcionando en producción

Estado actual: instalado, **deshabilitado en debug** por threading issues en MIUI. En release: no confirmado que esté firing.

- [ ] Confirmar `SENTRY_DSN` en `.env.production` y que `EnvConfig.sentryDsn` se lee correctamente
- [ ] Crear release builds con `--dart-define-from-file=.env.production`
- [ ] Capturar: errores no manejados, breadcrumbs de navegación, performance traces de operaciones críticas (issuance, payment, emergency dispatch)
- [ ] Agregar `Sentry.captureMessage` en eventos de negocio que necesitamos rastrear (no solo errores): policy issued, emergency activated, OCR fail
- [ ] Sentry release tracking integrado con `release.yml`: cada release sube símbolos
- [ ] Alerts configurados: error rate >1% → Slack, performance regression >2x → Slack
- [ ] **No incluir PII en breadcrumbs ni events** (cédula, nombres, plates) — scrubbing rules

### 7.2 SonarCloud / SonarQube

- [ ] Crear proyecto en SonarCloud (free para repos públicos; SonarQube self-hosted si privado)
- [ ] Token en GitHub Secrets
- [ ] `quality.yml` corre Sonar scan en cada PR
- [ ] Quality Gate: 0 vulnerabilidades nuevas, 0 bugs nuevos críticos, cobertura >70% en código nuevo, duplicación <5%
- [ ] Configurar exclusions: tests, generated code, ML Kit wrappers

### 7.3 Environments separados (dev / staging / prod)

Estado actual: solo "dev" (Supabase local + remote), sin staging.

- [ ] **Crear proyecto Supabase staging** (puede ser otro free tier, separado del dev)
- [ ] **Crear proyecto Supabase prod** (cuando llegue el momento del primer cliente real)
- [ ] **Variables por environment:**
  - `mobile/.env.dev` → Supabase dev project + dev BCV mock
  - `mobile/.env.staging` → Supabase staging + Mercantil/Quasar sandbox
  - `mobile/.env.production` → Supabase prod + APIs reales
- [ ] **Build flavors en Flutter:** `flutter build apk --flavor dev` / `staging` / `production`
- [ ] **Migración de datos de prueba:** seeds versionados que se aplican a staging
- [ ] **Documentar en `OPERATIONS.md`:** qué environment usa cada quien, cómo cambiar, cómo no leakear credenciales

### 7.4 Tests de integración + E2E

Estado actual: 321 unit tests; 1 widget smoke test failing por timeout de Supabase init.

- [ ] **Integration tests** con Supabase de test (proyecto staging o local con `supabase start`):
  - Onboarding completo end-to-end → perfil persistido
  - Plan selection + payment + policy issuance → policies row creada
  - Emergency activation → incidents row creada (cuando exista la tabla)
- [ ] **E2E tests** con [Patrol](https://patrol.leancode.co/):
  - Golden path completo desde welcome hasta policy issued
  - Re-emergency dispatch flow
  - Offline → online flow
- [ ] **CI:** `e2e.yml` corre nightly contra staging + en PR a `main`
- [ ] Fix del widget smoke test failing (probablemente mock de Supabase init)

### 7.5 Dependency + secret scanning

- [ ] **Dependabot** habilitado (`.github/dependabot.yml`): pub.dev (Flutter), Actions (workflows). Updates semanales, autoclose si tests fallan.
- [ ] **Gitleaks** en `security.yml`: corre en cada PR, falla si encuentra secret pattern
- [ ] **TruffleHog** nightly: scan de toda la historia de commits (puede que tengamos secrets vergonzosos en commits viejos — hay que rotarlos)
- [ ] Auditoría manual de `.env*`: confirmar que ninguno está commited; si lo está, rotar credenciales y agregarlo a `.gitignore`

### 7.6 Observabilidad estructurada

Más allá de Sentry: necesitamos saber qué está pasando en el negocio, no solo en errores.

- [ ] **Audit log** ya existe (`audit_log` table). Confirmar que estamos escribiendo a él en eventos críticos.
- [ ] **Materialized view `metrics_daily`** (creada en Sprint 2 según roadmap). Confirmar que se refresca y que se puede consultar.
- [ ] **Dashboard simple en Supabase** (Reports tab) o Metabase/Grafana sobre Postgres: KPIs básicos — emisiones del día, payments pending, errores de OCR, incidents.
- [ ] **Logs estructurados:** todos los Edge Functions emiten JSON con `level`, `event_type`, `context_id`. No logs en texto libre.

### 7.7 Performance baselines

- [ ] Medir tiempos actuales: cold start, screen-to-screen navigation, OCR parse time, policy issuance round-trip
- [ ] Documentar en `OPERATIONS.md` como SLOs internos
- [ ] Sentry Performance Monitoring habilitado para tracking continuo
- [ ] Alert si regresión >50% en cualquier transacción crítica

### 7.8 Entregables de Fase 5

| Sistema                 | Estado meta                                      |
| ----------------------- | ------------------------------------------------ |
| Sentry                  | Firing en release con scrubbing PII y alerts     |
| SonarCloud              | Quality gate bloqueando merges con regresiones   |
| Environments            | dev / staging / prod separados con build flavors |
| E2E tests               | Patrol corriendo en CI nightly                   |
| Dependabot              | Habilitado, auto-PR weekly                       |
| Gitleaks/TruffleHog     | Bloqueando secrets en PRs                        |
| Observability dashboard | KPIs visibles para el equipo                     |
| Performance SLOs        | Documentados, monitoreados                       |

---

## 8. Integración con gstack tooling

**Contexto.** [gstack](https://github.com/garrytan/gstack) es un set de skills (slash commands) para Claude Code, creado por Garry Tan, que convierte al agente en un equipo de ingeniería virtual: CEO, eng manager, designer, security officer, release engineer, QA. **Investigación 2026-04-28:** gstack es totalmente compatible con **Gemini CLI** a través de la especificación compartida de "Agent Skills". Lo adoptamos como capa operacional encima de las prácticas de Fase 1 — no reemplaza el proceso, lo acelera.

**Filosofía de adopción.** No todas las skills aplican a un proyecto Flutter + Supabase + Mercantil. Las skills orientadas a navegador (`/qa`, `/browse`, `/design-html`, `/design-review`) están pensadas para web apps; las adaptamos o sustituimos. Las skills de planning, review, security y release son aplicables tal cual en ambos agentes (Claude y Gemini).

**Tres niveles de uso:**

- **OBLIGATORIA** — debe ejecutarse antes de mergear/avanzar; bloquea progreso si se omite.
- **RECOMENDADA** — se ejecuta por default; se puede omitir si el cambio es trivial y se justifica en la PR.
- **OPCIONAL** — disponible cuando el caso lo amerita; no se exige.

### 8.1 Mapeo por fase del proceso de desarrollo

#### Fase A — Ideación / Scoping (antes de planear sprint)

| Skill              | Nivel       | Cuándo                                                                                         | Qué produce                                       |
| ------------------ | ----------- | ---------------------------------------------------------------------------------------------- | ------------------------------------------------- |
| `/office-hours`    | RECOMENDADA | Cualquier feature nueva no trivial (ej. activación por broker, módulo de gastos médicos 60/40) | Design doc con problema, wedge, alcance reducido  |
| `/plan-ceo-review` | OBLIGATORIA | Decisiones de scope (qué entra/sale del MVP, qué se difiere a Phase 1.5)                       | Plan revisado con scope explícito                 |
| `/autoplan`        | OPCIONAL    | Épicas grandes (Sprint 5 background service, Sprint 8 medical expenses)                        | Cadena CEO → Eng → Design completa con un comando |

#### Fase B — Arquitectura / Diseño (antes de coding)

| Skill                  | Nivel       | Cuándo                                                                                                                       | Qué produce                                        |
| ---------------------- | ----------- | ---------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------- |
| `/plan-eng-review`     | OBLIGATORIA | Antes de cualquier cambio arquitectónico: nueva tabla, nuevo servicio, nueva integración externa, cambio de state management | Diagrama ASCII + edge cases + test plan            |
| `/plan-design-review`  | RECOMENDADA | Plans con UI nueva o refactor visual significativo                                                                           | Audit de design plan calificado 0–10 por dimensión |
| `/plan-devex-review`   | OPCIONAL    | Cambios en herramientas que tocan al equipo (CLAUDE.md, OPERATIONS.md, CI workflows)                                         | DX scorecard                                       |
| `/design-consultation` | OPCIONAL    | Refinar el design system existente o agregar tema oscuro                                                                     | Sistema de diseño completo, mockups HTML           |

**Regla:** Toda PR que crea tabla nueva o cliente de API externo debe incluir el output de `/plan-eng-review` (link al doc o pegado en la descripción de la PR).

#### Fase C — Implementación (durante coding)

| Skill            | Nivel       | Cuándo                                                                                                                              | Qué produce                                     |
| ---------------- | ----------- | ----------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| `/freeze <path>` | RECOMENDADA | Sesiones largas en un módulo específico (ej. `mobile/lib/features/emergency/`) — evita que el agente toque archivos no relacionados | Sandbox de directorio para la sesión            |
| `/learn`         | OPCIONAL    | Cuando se sospecha que ya hay un patrón establecido para algo similar                                                               | Lista de patrones aprendidos                    |
| `/careful`       | OBLIGATORIA | Cualquier sesión que pueda ejecutar `rm -rf`, `DROP TABLE`, `git reset --hard`, `supabase db reset`                                 | Confirmaciones explícitas antes de destructivos |
| `/guard`         | RECOMENDADA | Combo de `/careful` + `/freeze` cuando se debuggea cerca de código sensible                                                         | Ambas barreras activas                          |
| `/investigate`   | OBLIGATORIA | Para debugging real (no "fix this") — bugs reproducibles, errores en producción, regresiones                                        | Causa raíz documentada antes de cualquier fix   |
| `/cso`           | RECOMENDADA | Antes de tocar auth, payments, encryption, RLS, Edge Functions                                                                      | Audit OWASP/STRIDE del módulo                   |

#### Fase D — Pre-commit / Calidad local

| Skill     | Nivel       | Cuándo                                                                                                                  | Qué produce                                             |
| --------- | ----------- | ----------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------- |
| `/review` | OBLIGATORIA | Antes de abrir cualquier PR — corre sobre el diff actual                                                                | Lista de bugs sutiles, N+1, race conditions, fixes auto |
| `/codex`  | RECOMENDADA | Código crítico Mercantil-facing: carrier API client, payment encryption, KYC, emergency dispatch, RLS de tablas con PII | Segunda opinión de OpenAI Codex (adversarial o review)  |
| `/health` | OPCIONAL    | Snapshot semanal de calidad                                                                                             | Dashboard 0–10 con tendencias                           |

#### Fase E — Pull Request / Pre-merge

| Skill                 | Nivel       | Cuándo                                                                  | Qué produce                           |
| --------------------- | ----------- | ----------------------------------------------------------------------- | ------------------------------------- |
| `/ship`               | RECOMENDADA | Para abrir la PR (sync con main, tests, push, abrir PR con descripción) | PR creado con CHANGELOG/VERSION bumps |
| `/cso`                | OBLIGATORIA | PRs que tocan auth, payments, encryption, RLS, secrets, Edge Functions  | Security gate                         |
| `/devex-review`       | OPCIONAL    | PRs que cambian la superficie del developer (CLAUDE.md, scripts, docs)  | DX audit                              |
| `/plan-design-review` | OPCIONAL    | PRs visuales (referencia para revisor humano)                           |                                       |

#### Fase F — Post-merge / Deploy

| Skill               | Nivel       | Cuándo                                                                         | Qué produce                                                                                                                                                                                                                        | Notas para nuestro stack |
| ------------------- | ----------- | ------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------ |
| `/land-and-deploy`  | OPCIONAL    | Para mergear PR aprobada, esperar CI, verificar prod                           | gstack está orientado a Vercel/Render/Fly. **Adaptar:** nuestro deploy de mobile es a Play Console interno; el de Supabase es `supabase functions deploy` + `supabase db push`. Documentar comando equivalente en `OPERATIONS.md`. |
| `/canary`           | OPCIONAL    | Monitorear backend después de deploy de Edge Functions                         | gstack es web-first; lo usamos para monitorear endpoints de Supabase, no UI mobile                                                                                                                                                 |
| `/benchmark`        | OPCIONAL    | Detectar regresiones de performance                                            | gstack mide Core Web Vitals — para mobile usamos Sentry Performance Monitoring (Fase 5.7), no `/benchmark`                                                                                                                         |
| `/document-release` | RECOMENDADA | Después de mergear, sincronizar `CHANGELOG.md`, `ARCHITECTURE.md`, `README.md` | Aplica directamente                                                                                                                                                                                                                |

#### Fase G — Operaciones / Retrospectiva

| Skill     | Nivel       | Cuándo                                                    | Qué produce                                                             |
| --------- | ----------- | --------------------------------------------------------- | ----------------------------------------------------------------------- |
| `/retro`  | RECOMENDADA | Cada viernes (semanal)                                    | Análisis de commits, contribuciones, métricas, growth areas por persona |
| `/learn`  | OPCIONAL    | Mensual o cuando el equipo quiere ver patrones acumulados | Listado de patrones, decisiones, preferencias                           |
| `/health` | OPCIONAL    | Mensual                                                   | Trend de calidad                                                        |

#### Fase H — Manejo de sesión (cross-cutting)

| Skill              | Nivel       | Cuándo                                                                       |
| ------------------ | ----------- | ---------------------------------------------------------------------------- |
| `/context-save`    | RECOMENDADA | Al final de cualquier sesión >2h o antes de un context switch                |
| `/context-restore` | RECOMENDADA | Al empezar una sesión que continúa trabajo pasado                            |
| `/setup-gbrain`    | OPCIONAL    | Una vez al inicio del proyecto post-reset, para memoria global cross-machine |
| `/gstack-upgrade`  | OPCIONAL    | Mensual o cuando salgan releases relevantes                                  |
| `/pair-agent`      | OPCIONAL    | Si algún miembro del equipo usa Codex/Cursor en paralelo y quiere coordinar  |

### 8.2 Skills que NO usamos (y por qué)

| Skill                    | Por qué no                                                                                                             |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------------- |
| `/qa` / `/qa-only`       | Diseñadas para web apps con navegador. Para nuestro Flutter app usamos Patrol (E2E) y manual testing en device.        |
| `/browse`                | Idem — navegador no aplica a Flutter mobile.                                                                           |
| `/open-gstack-browser`   | Idem.                                                                                                                  |
| `/setup-browser-cookies` | Idem.                                                                                                                  |
| `/design-html`           | Genera HTML/CSS de producción. Nuestro UI es Flutter widgets — no aplica.                                              |
| `/design-review`         | Auditoría visual con navegador en vivo. Para Flutter usamos screenshots + revisión humana en device.                   |
| `/design-shotgun`        | Genera variantes visuales web. Para Flutter, exploración visual se hace en Figma o screenshots manuales.               |
| `/setup-deploy`          | Detecta Vercel/Render/Heroku. Nuestro deploy es Play Console + Supabase CLI — configuración manual en `OPERATIONS.md`. |

**Implicación:** ~8 de las 23 skills no se usan. Las 15 restantes cubren todas las fases críticas.

### 8.3 Reglas de uso obligatorio (resumen)

A partir del fin del reset (semana 5), una PR no se mergea sin:

1. ✅ `/plan-eng-review` ejecutado si hay cambio arquitectónico (link en descripción)
2. ✅ `/review` ejecutado en el diff (output adjunto o resumen en PR)
3. ✅ `/cso` ejecutado si toca auth/payments/encryption/RLS/secrets
4. ✅ `/investigate` documentado si la PR es un bugfix (causa raíz, no solo síntoma)
5. ✅ Tests pasan + cobertura no baja (ya en Fase 5)
6. ✅ Sentry/Sonar gates verdes (ya en Fase 5)

Lo demás es recomendado pero no bloquea.

### 8.4 Entregables de Fase 1 ampliados

A los entregables ya listados en Sección 3.6 se agregan:

| Archivo                                | Acción                                                                                                                                                   |
| -------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `RuedaSeguroMVP/CLAUDE.md` sección 6.1 | Pegar tal cual el "Skill routing" del `RuedaSeguro/CLAUDE.md` (las 30+ entradas de `Key routing rules`)                                                  |
| `RuedaSeguroMVP/CLAUDE.md` sección 6.2 | Referencia a esta Sección 8 con el mapeo por fase                                                                                                        |
| `RuedaSeguroMVP/CLAUDE.md` sección 6.3 | Tabla resumen de obligatorias/recomendadas/opcionales para este repo (ver 8.3)                                                                           |
| `RuedaSeguroMVP/GEMINI.md`             | Sincronizar esquemas Mermaid y skill mapping con CLAUDE.md                                                                                               |
| `OPERATIONS.md` (creado en Fase 2)     | Sección "Tooling" con: cómo instalar gstack (Claude Code vs Gemini CLI), comando equivalente para `/land-and-deploy` adaptado, política de uso de skills |
| `.github/pull_request_template.md`     | Checkboxes para `/plan-eng-review`, `/review`, `/cso`, `/investigate` cuando aplican                                                                     |

### 8.5 Riesgos de la adopción

| Riesgo                                                                           | Mitigación                                                                          |
| -------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| El equipo usa skills de forma performativa (correr `/review` sin leer el output) | Code review humano sigue siendo obligatorio; skills son aceleradores, no sustitutos |
| `/codex` requiere cuenta de OpenAI con billing                                   | Documentar en `OPERATIONS.md`; skill es OPCIONAL en la mayoría de casos             |
| Bloqueos por web-only skills que no aplican                                      | Sección 8.2 documenta sustitutos explícitos                                         |
| Sobrecarga cognitiva de 15 skills nuevas                                         | Empezar con las 4 obligatorias (Sección 8.3), expandir con uso                      |

---

## 9. Decisiones que necesitamos cerrar (D1–D9 del ROADMAP, vigentes)

Estas siguen abiertas y deben resolverse en la reunión 2026-04-23 o inmediatamente después. Migrar todas a `DECISIONS_LOG.md` con dueño y fecha.

| #   | Decisión                                             | Bloquea                          | Dueño                            |
| --- | ---------------------------------------------------- | -------------------------------- | -------------------------------- |
| D1  | Audio alarm en background (foreground service vs no) | Sprint 5 RS-094                  | Diego                            |
| D2  | Speed >80 km/h: bloquear vs marcar flag              | Sprint 5 RS-090                  | Alex (legal/Mercantil)           |
| D3  | Activación broker: pantalla separada vs bypass OCR   | Sprint 7 RS-112                  | Alex + Fernando                  |
| D4  | Venemergencia API: directa o vía Quasar              | Sprint 5/6                       | Alex (resuelto en reunión 04-22) |
| D5  | Chatbot en emergencia                                | Post-Sprint 8                    | Alex                             |
| D6  | Cobertura del acompañante                            | Sprint 5 RS-098 (payload design) | Alex (legal Mercantil)           |
| D7  | Asignación de carrier al usuario                     | Resuelto: Mercantil único        | Cerrado — registrar en log       |
| D8  | Preguntas de pre-cotización (elegibilidad)           | Sprint 5/6                       | Fernando + Mercantil legal       |
| D9  | Mapa definitivo de pagos                             | Sprint 5 + 7                     | Fernando                         |

---

## 10. Cronograma propuesto

```
Semana 1 (2026-04-28 → 05-04):
  Lun-Mar: Fase 1 — CLAUDE.md + GitHub hardening + pre-commit + PR template
  Mié-Jue: Fase 1 — CI workflows expandidos (placeholders funcionales)
  Vie:     Revisión y push del Fase 1; equipo adopta nuevas reglas

Semana 2 (2026-05-05 → 05-11):
  Lun-Mar: Fase 2 — Auditoría docs + crear PRODUCT_PLAN, ARCHITECTURE, etc.
  Mié-Jue: Fase 2 — Migrar contenido + archivar/eliminar
  Vie:     Fase 3 — Eliminar admin-portal/, contracts/, venv/

Semana 3 (2026-05-12 → 05-18):
  Lun:     Fase 3 — Auditoría dependencias + features sin persistence
  Mar-Mié: Fase 4 — Baseline migrations + archive
  Jue-Vie: Fase 5 inicio — Sentry firing + Sonar setup

Semana 4 (2026-05-19 → 05-25):
  Lun-Mar: Fase 5 — Environments separados + build flavors
  Mié-Jue: Fase 5 — Integration tests + E2E con Patrol
  Vie:     Fase 5 — Dependabot + gitleaks + observability dashboard

Semana 5+ (2026-05-26 →):
  Sprint 5 arranca con todo el rigor en su lugar.
```

Total: 4 semanas para reset completo. Sprint 5 (background service + incidents) arranca en semana 5 con cero deuda operacional.

---

## 11. Riesgos del reset

| Riesgo                                            | Probabilidad | Impacto | Mitigación                                                                                                                  |
| ------------------------------------------------- | ------------ | ------- | --------------------------------------------------------------------------------------------------------------------------- |
| Equipo percibe el reset como "delay" del producto | Media        | Alto    | Comunicar: 4 semanas de reset = 0 retrabajo en sprints siguientes. Mostrar a Alex/Mercantil como inversión en credibilidad. |
| Romper algo al consolidar migraciones             | Media        | Alto    | Validación obligatoria con DB en blanco antes de archivar; staging environment para probar                                  |
| Descubrir secrets en historia                     | Alta         | Crítico | TruffleHog en Fase 5 lo detecta. Plan de rotación inmediata. No force-push: rotar credenciales y seguir adelante.           |
| Sentry/Sonar requieren cuentas/billing            | Baja         | Medio   | SonarCloud free para repos abiertos; Sentry tiene free tier de 5k events/mes — suficiente para staging                      |
| Patrol E2E es nuevo para el equipo                | Alta         | Bajo    | Empezar con 2 escenarios, expandir; alternativa: `flutter_driver` legacy si Patrol bloquea                                  |
| Branch protection bloquea hotfixes urgentes       | Baja         | Medio   | Documentar bypass procedure en `OPERATIONS.md` (admin override + post-mortem)                                               |

---

## 12. Métricas de éxito del reset

Al terminar las 4 semanas, debe ser cierto:

- [ ] `docs/` tiene ≤6 archivos `.md` en root + carpetas semánticas (no >30 archivos sueltos)
- [ ] No hay `admin-portal/`, `contracts/`, `venv/`, `legacy_plans/` en el repo
- [ ] `supabase/migrations/` tiene `000_baseline` + `001_seed` + las migraciones nuevas (≤3) + `_archive/` con ≥24 archivos
- [ ] `flutter test` y `npm test` pasan al 100% en CI; coverage ≥70% en código nuevo
- [ ] Branch protection en `main` activa
- [ ] Sentry recibe events de un crash de prueba en build release
- [ ] Sonar Quality Gate verde en `main`
- [ ] PR template fuerza checklist antes de mergear
- [ ] Pre-commit hooks instalados localmente (verificable con un commit dummy)
- [ ] `DECISIONS_LOG.md` tiene ≥10 entradas de decisiones cerradas
- [ ] `PARTNERS.md` documenta los 5 partners con estado y fecha de check-in

---

## 13. Lo que este plan NO hace (explícito)

- No reescribe código de features. La app móvil no se toca a nivel de UI/business logic.
- No cambia stack: Flutter + Riverpod + GoRouter + Supabase quedan.
- No introduce nuevas integraciones. Solo formaliza las existentes.
- No empieza Sprint 5. Sprint 5 arranca después del reset.
- No resuelve los bloqueantes externos (Quasar, Mercantil, Venemergencia, Firebase). Solo formaliza su seguimiento.

---

## 14. Próximos pasos inmediatos (esta semana)

1. **Revisar y aprobar este plan** con Alex/Fernando antes de ejecutar
2. **Bloquear 4 semanas en calendario** para el reset (no entrelazar con feature work)
3. **Crear branch `chore/reset-2026-04`** y empezar Fase 1
4. **Comunicar a Mercantil** que pre-Sprint 5 hay un endurecimiento de prácticas — 2 semanas de inversión que da confianza para producción

---

_Este documento es operacional, no aspiracional. Cada checkbox tiene dueño y fecha. Cuando todos los checkboxes están marcados, el reset terminó y el documento se mueve a `_archive/`._
