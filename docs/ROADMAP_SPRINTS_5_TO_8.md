# RuedaSeguro — Evaluación vs. Conceptualización & Roadmap Sprints 5–8+

**Fecha de análisis:** 2026-04-22
**Documentos analizados:**

- `docs/original_docs/Conceptualización del Modulo de Detección de Rueda Seguro.pdf` (28 pp.)
- `docs/progress_reports/PROGRESS_REPORT_SPRINTS_1_2A_2B.md`
- `docs/progress_reports/PROGRESS_REPORT_SPRINT_3.md`
- `docs/progress_reports/PROGRESS_REPORT_SPRINTS_4A_4B_4C_4D_4E.md`
- `docs/MEETING_ANALYSIS_30_03_2026.md`
- `docs/MEETING_PREP_10_04_2026.md`
- `docs/MVP_PLAN_v3.md`

---

## 1. Resumen Ejecutivo

La conceptualización describe un módulo de detección de accidentes de **10 etapas** que va desde la detección automática hasta la activación de gastos médicos e indemnización. El código actual cubre bien las etapas 1 (UI de alerta) y parcialmente las etapas 2 y 6 — pero las etapas 3–10 son inexistentes en la app. La detección automática es sólo demo (acelerómetro sin servicio de fondo real). Los datos de emergencia no se persisten en DB y no se envían comunicaciones reales.

**Lo crítico:** el producto no puede salir al mercado sin al menos: (a) detección real en background, (b) persistencia del caso de emergencia en DB, (c) comunicación real a contactos y proveedor de asistencia.

**Lo positivo:** nuestra arquitectura de onboarding (OCR + OTP por teléfono) es **superior** a lo especificado en el documento. El modelo de onboarding del doc es el flujo de activación por broker (póliza-primero), no onboarding directo. Ambos son válidos y deben coexistir.

---

## 2. Análisis de Brechas — Módulo de Detección (10 Etapas)

### Leyenda de estado

- ✅ **Completo** — cumple o supera el documento
- ⚠️ **Parcial** — UI/estructura existe, falta lógica real
- ❌ **Ausente** — no implementado
- 🔝 **Supera el doc** — nuestra implementación es mejor que lo especificado

| Etapa | Descripción (doc)                                                                      | Estado actual | Brecha                                                                 |
| ----- | -------------------------------------------------------------------------------------- | ------------- | ---------------------------------------------------------------------- |
| 1A    | Detección automática multi-señal (acelerómetro + giroscopio + GPS speed + inmovilidad) | ❌ Demo solo  | Sin background service, sin giroscopio, sin GPS speed, sin inmovilidad |
| 1B    | Pantalla full-screen + alarma audible + countdown                                      | ⚠️ Parcial    | Pantalla OK, countdown 15s (doc pide 30s), **sin alarma de audio**     |
| 1C    | 3 escenarios: "Estoy bien" / "Necesito ayuda" / Timeout auto                           | ⚠️ Parcial    | UI existe, timeout funciona, **sin persistencia en DB**                |
| 2A    | Payload estructurado de emergencia (nombre, edad, cédula, placa, GPS, contacto)        | ⚠️ Parcial    | Estructura parcial, falta GPS real, edad, cédula                       |
| 2B    | Envío a Centro de Control y proveedor de asistencia                                    | ❌ Ausente    | No hay envío real a ningún endpoint externo                            |
| 3A    | Llamada automática al proveedor (3 intentos)                                           | ❌ Ausente    | No implementado                                                        |
| 3B    | Triage médico remoto + decisión de ruta (Urgent Care / Hospital / Telemed)             | ❌ Ausente    | Thony/Venemergencia                                                    |
| 4     | Intentos de contacto saliente si no responde el asegurado                              | ❌ Ausente    | No implementado                                                        |
| 5     | Despacho de soporte en sitio                                                           | ❌ Ausente    | Depende de Venemergencia                                               |
| 6     | Notificación a contacto de emergencia (SMS + WhatsApp a los 5 min)                     | ❌ Ausente    | UI lista con nombres, **no se envía nada real**                        |
| 7     | Atención en Urgent Care + reporte al Centro de Control                                 | ❌ Ausente    | Venemergencia / Thony                                                  |
| 8     | Atención hospitalaria / escalación                                                     | ❌ Ausente    | Venemergencia / Thony                                                  |
| 9     | Activación de cobertura médica (60% inicial + 40% post-documentación)                  | ❌ Ausente    | Proceso de negocio interno                                             |
| 10    | Comunicación de pago al asegurado                                                      | ❌ Ausente    | Post-Stage 9                                                           |

### Cobertura por etapa:

- **Etapas 7–10**: 100% del lado de Thony/Venemergencia/Centro de Control. La app sólo necesita recibir notificaciones de estado.
- **Etapas 3–6**: Nuestra responsabilidad primaria en Sprint 5–6.
- **Etapas 1–2**: Necesitan completarse urgentemente (Sprint 5).

---

## 3. Análisis de Brechas — Otras Áreas del Documento

### 3.1 Onboarding (Flujo de Activación del Doc)

El documento describe: número de póliza + cédula → validar contra API → pre-llenar datos → crear credenciales (email/password) → OTP por SMS.

**Nuestra implementación:** OTP por teléfono → OCR cédula + certificado → form multi-paso → consentimiento.

**Veredicto: 🔝 Nuestra implementación supera el documento.**

| Criterio           | Documento                                    | Nuestra App                                  |
| ------------------ | -------------------------------------------- | -------------------------------------------- |
| Flujo primario     | Póliza-primero (broker crea, usuario activa) | App-primero (usuario compra directamente)    |
| Autenticación      | Email/password + OTP                         | OTP por WhatsApp (sin contraseña — mejor UX) |
| Captura de datos   | Manual (cédula + placa)                      | OCR automatizado                             |
| Validación cruzada | No especificada                              | `CrossValidator` entre documentos            |

**Acción:** El flujo del documento debe construirse como **canal de activación por broker** (Sprint 7: "activar póliza existente"). La OCR-first para canal directo se mantiene.

### 3.2 Configuración del Temporizador de Emergencia

| Aspecto            | Documento               | Actual                                                 |
| ------------------ | ----------------------- | ------------------------------------------------------ |
| Valor por defecto  | 30 segundos             | 15 segundos                                            |
| Rango configurable | 30 segundos – 3 minutos | 15s fijo (SharedPreferences guardado pero no UI claro) |
| Auto-caída         | +5s más que manual      | ✅ Implementado (+5s)                                  |

**Acción:** Cambiar default a 30s, UI de configuración en rango 30s–180s.

### 3.3 Contactos de Emergencia

| Aspecto            | Documento                                          | Actual                  |
| ------------------ | -------------------------------------------------- | ----------------------- |
| Mínimo obligatorio | 1                                                  | ✅ Compatible           |
| Máximo             | 3                                                  | ✅ Compatible           |
| Sistema de niveles | Nivel 1 (asegurado), 2 (familiar), 3 (corporativo) | Sin nivel — campo libre |
| Relación           | Requerida                                          | ✅ Campo existe         |

**Acción menor:** Agregar campo `level` (1/2/3) a `emergency_contacts` con select en UI.

### 3.4 Señales de Detección (Algoritmo)

El documento especifica combinación de señales:

| Señal                                            | Documento        | Actual                              |
| ------------------------------------------------ | ---------------- | ----------------------------------- |
| Acelerómetro (cambio violento orientación)       | ✅ Requerida     | ✅ sensors_plus, CrashMonitorScreen |
| Giroscopio (rotación)                            | ✅ Requerida     | ❌ No integrado                     |
| GPS speed (cambio abrupto de velocidad)          | ✅ Requerida     | ❌ No implementado                  |
| Inmovilidad posterior (>50s)                     | ✅ Requerida     | ❌ No implementado                  |
| Speed threshold (>80 km/h = exclusión cobertura) | Regla de negocio | ❌ No implementado                  |
| Buffer de velocidad (cada 30s, últimos 3 min)    | ✅ Requerido     | ⚠️ Buffer existe pero sin GPS speed |

### 3.5 Estado del Caso (State Machine)

El documento define 15+ estados específicos. La app sólo maneja estados de UI, sin persistencia:

| Estado (doc)                 | Existe en DB | Existe en UI          |
| ---------------------------- | ------------ | --------------------- |
| INCIDENTE_PROBABLE           | ❌           | ❌ (detección demo)   |
| ALERTA_ACTIVA                | ❌           | ✅                    |
| INCIDENTE_DESCARTADO         | ❌           | ✅ (cancelled view)   |
| ASISTENCIA_REQUERIDA         | ❌           | ✅                    |
| ASISTENCIA_AUTOMATICA        | ❌           | ⚠️ (timeout funciona) |
| CASO_ACTIVADO                | ❌           | ✅ (activated view)   |
| ESCALADO_A_CENTRO_DE_CONTROL | ❌           | ❌                    |

**Acción crítica:** Crear tabla `incidents` en Supabase con state machine completa.

### 3.6 Límite de Eventos por Póliza

El documento establece: 3 eventos por período anual de póliza (1 con indemnización, 2 sólo asistencia).

**Estado:** ❌ No rastreado. Ni la tabla `policies` ni `claims` cuentan eventos de emergencia.

---

## 4. Lo Que Tenemos Que Supera el Documento

Estas son decisiones técnicas nuestras que son **superiores** a lo especificado y se deben **mantener**:

| Área                    | Doc especifica                         | Nuestra implementación                           | Por qué es mejor                                                                            |
| ----------------------- | -------------------------------------- | ------------------------------------------------ | ------------------------------------------------------------------------------------------- |
| Autenticación           | Email/password + OTP SMS               | OTP WhatsApp sin contraseña                      | Menos fricción; no hay contraseñas que olvidar; WhatsApp es el canal dominante en Venezuela |
| Captura de datos        | Entrada manual (póliza + cédula)       | OCR automatizado                                 | Reduce errores, más rápido, mejor UX                                                        |
| Urgency triage          | Sin clasificación de urgencia          | 3 niveles (lesiones / sin lesiones / asistencia) | Permite dispatch más preciso y diferencia respuesta médica vs. mecánica                     |
| Contactos de emergencia | 1-3, sin niveles funcionales           | CRUD completo, contacto primario, relación       | Más flexible y completo                                                                     |
| Digital Carnet          | No mencionado (el doc cubre detección) | QR Carnet implementado (Sprint 4D)               | Valor agregado para el usuario y policía de tránsito                                        |
| IoT payload mapper      | No especificado                        | `IotPayloadMapper` normalizado                   | Listo para Thony sin cambios en el formato                                                  |
| Telemetry buffer        | 30s/3min para velocidad                | 15-min SQLite ring buffer                        | Más contexto para análisis post-incidente                                                   |

---

## 5. Evaluación de Bloqueantes Externos (Estado al 2026-04-22)

| Bloqueante                        | Para qué                    | Urgencia    | Estado                                                                               |
| --------------------------------- | --------------------------- | ----------- | ------------------------------------------------------------------------------------ |
| Credenciales API Quasar (Thony)   | Emisión de póliza real      | 🔴 Sprint 5 | Pendiente desde 30/03                                                                |
| MQTT broker URL/auth (Thony)      | Telemetría real             | 🟠 Sprint 6 | Pendiente desde 30/03                                                                |
| Débito Inmediato API (F. Ángeles) | Pago automático             | 🟠 Sprint 5 | Pendiente                                                                            |
| Venemergencia API (Alex)          | Despacho real Plus/Ampliada | 🔴 Sprint 5 | Reunión realizada (2026-04-22) — detalles técnicos a confirmar en reunión 2026-04-23 |
| Firebase project (Alex)           | Push notifications          | 🟡 Sprint 5 | Pendiente                                                                            |
| API Seguros Pirámide/William      | Carrier real                | 🟠 Sprint 6 | Pendiente                                                                            |

**Estrategia:** Sprint 5 se diseña para avanzar el 100% de lo que podemos construir sin estos bloqueantes (estructura DB, estado persistido, GPS real, giroscopio, alarma de audio, configuración de timers). Los stubs se reemplazan en Sprint 6 cuando lleguen las credenciales.

---

## 6. Roadmap — Sprints 5 al 8+

### SPRINT 5 — Core del Módulo de Detección (Prioridad 1)

**Objetivo:** El módulo de detección funciona end-to-end en modo real, con un stub de proveedor pero con datos reales enviados a Supabase.
**Duración estimada:** 3–4 semanas
**Sin dependencias de bloqueantes externos.**

#### 5.1 — Infraestructura de Background Service (RS-085 a RS-090)

| Ticket | Tarea                                                                                                                                               | Prioridad |
| ------ | --------------------------------------------------------------------------------------------------------------------------------------------------- | --------- |
| RS-085 | Background isolate en Android con `flutter_foreground_task`: mantener app viva, sensor permissions, notificación persistente "Protección activa"    | CRÍTICO   |
| RS-086 | Giroscopio integrado via `sensors_plus`: combinar G-force + angular velocity en score de detección                                                  | CRÍTICO   |
| RS-087 | GPS speed tracking: `geolocator` muestreo cada 30s, ring buffer de 3 min (6 muestras), detección de desaceleración abrupta (>20 km/h en <2s)        | CRÍTICO   |
| RS-088 | Inmovilidad detection: si posición GPS no cambia >5m por 50s después de un spike → confirmar incidente                                              | CRÍTICO   |
| RS-089 | Detection score engine: puntaje compuesto (acelerómetro + giroscopio + GPS speed + inmovilidad) → INCIDENTE_PROBABLE si score ≥ umbral configurable | ALTO      |
| RS-090 | Speed >80 km/h flag: si velocidad en el momento del incidente excede 80 km/h → marcar `coverage_risk: true` en el evento                            | ALTO      |

#### 5.2 — Tabla de Incidentes en DB (RS-091 a RS-092)

```sql
CREATE TABLE incidents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  policy_id UUID REFERENCES policies(id),
  rider_id UUID REFERENCES profiles(id),
  -- Detection
  detection_timestamp TIMESTAMPTZ NOT NULL,
  detection_signals JSONB, -- {g_force, angular_velocity, speed_kmh, was_immobile}
  detection_score NUMERIC,
  speed_at_incident_kmh NUMERIC,
  coverage_risk BOOLEAN DEFAULT false,
  -- GPS
  latitude NUMERIC,
  longitude NUMERIC,
  gps_accuracy_m NUMERIC,
  -- State machine
  status TEXT NOT NULL DEFAULT 'alerta_activa',
  -- 'alerta_activa' | 'incidente_descartado' | 'asistencia_requerida' |
  -- 'asistencia_automatica' | 'caso_activado' | 'contacto_efectivo' |
  -- 'asegurado_no_contactado' | 'escalado_control' | 'cerrado'
  urgency_level TEXT, -- 'accidente_con_lesiones' | 'accidente_sin_lesiones' | 'solo_asistencia'
  activation_type TEXT, -- 'manual' | 'auto_fall' | 'timeout'
  -- Provider
  provider_case_id TEXT,           -- Venemergencia/Quasar case ID
  provider_notified_at TIMESTAMPTZ,
  provider_contact_attempts INT DEFAULT 0,
  -- Contacts
  contacts_notified_at TIMESTAMPTZ,
  contacts_notified_count INT DEFAULT 0,
  -- Lifecycle
  user_responded_at TIMESTAMPTZ,
  user_response TEXT,              -- 'ok' | 'needs_help'
  closed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Policy event counter
ALTER TABLE policies ADD COLUMN emergency_events_count INT DEFAULT 0;
ALTER TABLE policies ADD COLUMN emergency_events_with_indemnification INT DEFAULT 0;

-- Audit trail per incident
CREATE TABLE incident_status_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_id UUID REFERENCES incidents(id),
  from_status TEXT,
  to_status TEXT,
  changed_by TEXT,  -- 'user' | 'system' | 'provider' | 'control_center'
  payload JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

| Ticket | Tarea                                                                                  | Prioridad |
| ------ | -------------------------------------------------------------------------------------- | --------- |
| RS-091 | Migración Supabase: crear `incidents` + `incident_status_log` + columnas en `policies` | CRÍTICO   |
| RS-092 | `IncidentRepository`: crear, actualizar estado, fetch by policy, fetch active          | CRÍTICO   |

#### 5.3 — Emergency Screen: Correcciones del Documento (RS-093 a RS-097)

| Ticket | Tarea                                                                                                                                                                                         | Prioridad |
| ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- |
| RS-093 | Cambiar countdown default a 30s (era 15s). Pantalla de settings `/settings/emergency` con slider 30–180s                                                                                      | ALTO      |
| RS-094 | Alarma de audio: `audioplayers` package. Activar loop de alta intensidad en `_startCountdown()`, detener en `_cancel()` o `_dispatch()`                                                       | ALTO      |
| RS-095 | GPS real en EmergencyScreen: `geolocator.getCurrentPosition()` durante countdown → mostrar coordenadas reales en `_GpsRow`, no "Obteniendo..." estático                                       | CRÍTICO   |
| RS-096 | Persistir incidente en DB: al iniciar countdown → crear fila `incidents` con `status='alerta_activa'`. Al cancelar → `status='incidente_descartado'`. Al despachar → `status='caso_activado'` | CRÍTICO   |
| RS-097 | Botón "Ver estado del caso" → nueva `IncidentStatusScreen(incidentId)` con timeline real desde `incident_status_log`                                                                          | MEDIO     |

#### 5.4 — Emergency Payload Completo (RS-098)

El payload estructurado según el documento (Stage 2):

```dart
class EmergencyPayload {
  final String riderId;
  final String riderName;
  final int riderAge;
  final String cedulaNumber;
  final String phone;
  final String motorcyclePlate;
  final String policyNumber;
  final String policyStatus;
  final double latitude;
  final double longitude;
  final DateTime incidentDate;
  final String urgencyLevel;
  final double speedAtIncidentKmh;
  final bool coverageRisk;       // true si speed > 80 km/h
  final List<EmergencyContactPayload> emergencyContacts;
  final double detectionScore;
  final Map<String, dynamic> detectionSignals;
}
```

| Ticket | Tarea                                                                                                                                            | Prioridad |
| ------ | ------------------------------------------------------------------------------------------------------------------------------------------------ | --------- |
| RS-098 | `EmergencyPayloadBuilder`: obtener datos de `profileProvider`, `activePolicySummaryProvider`, GPS, telemetry buffer → construir payload completo | CRÍTICO   |

#### 5.5 — Contact Level System (RS-099)

| Ticket | Tarea                                                                                                                        | Prioridad |
| ------ | ---------------------------------------------------------------------------------------------------------------------------- | --------- |
| RS-099 | Agregar campo `level` (1/2/3) a `emergency_contacts`. Migration Supabase + UI con DropdownButton "Familiar / Empresa / Otro" | BAJO      |

---

### SPRINT 6 — Comunicaciones de Emergencia (Prioridad 2)

**Objetivo:** Las notificaciones reales llegan a contactos y al proveedor. El caso es trazable end-to-end.
**Duración estimada:** 3 semanas
**Dependencias:** Twilio configurado (ya existe para OTP), Venemergencia meeting (Alex), Firebase (Alex).

#### 6.1 — WhatsApp / SMS a Contactos (RS-100 a RS-101)

El documento especifica notificación a los 5 minutos de activación. El mensaje debe incluir: nombre del asegurado, confirmación de incidente, estado del caso, link GPS.

| Ticket | Tarea                                                                                                                                                                                                                                                                                 | Prioridad |
| ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- |
| RS-100 | Edge Function `notify-emergency-contacts`: acepta `{incident_id}`, lee contacts de DB, envía WhatsApp via Twilio con template: "Se detectó un posible accidente de [Nombre]. Protocolo activado. Ubicación: [Google Maps link]". Reintentar 2x si falla. Log en `incident_status_log` | CRÍTICO   |
| RS-101 | EmergencyScreen trigger: 5 minutos después de `_dispatch()`, invocar `notify-emergency-contacts` via Supabase Functions. Si app está cerrada → cron Edge Function que revisa incidents con `provider_notified_at` sin `contacts_notified_at` después de 5 min                         | CRÍTICO   |

#### 6.2 — Venemergencia Webhook (RS-102 a RS-103)

| Ticket | Tarea                                                                                                                                                                              | Prioridad |
| ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- |
| RS-102 | `IotApiClient.notifyIncident(EmergencyPayload)`: stub logs localmente → reemplazar con `VenemergenciaClient` cuando Alex entregue API docs. Interfaz ya definida en `IotApiClient` | CRÍTICO   |
| RS-103 | Retry logic: 3 intentos con 10s timeout cada uno. Al fallar los 3 → `status='asegurado_no_contactado'` + ticket `HIGH` automático en tabla `tickets`                               | ALTO      |

#### 6.3 — Firebase Push Notifications (RS-104)

| Ticket | Tarea                                                                                                                                                         | Prioridad |
| ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- |
| RS-104 | Integrar FCM: `firebase_messaging`, `google-services.json` (Alex entrega). Push para: póliza confirmada, incidente activado, caso cerrado, renovación próxima | ALTO      |

#### 6.4 — Monitoreo GPS Post-Incidente (RS-105)

El documento pide: si el asegurado cambia de ubicación post-incidente → reenviar ubicación cada 10 minutos.

| Ticket | Tarea                                                                                                                                                                                               | Prioridad |
| ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- |
| RS-105 | Location watcher post-dispatch: si `distance > 100m` vs. punto inicial → Edge Function `update-incident-location(incident_id, lat, lng)` → notificar proveedor + contactos. Frecuencia: cada 10 min | MEDIO     |

#### 6.5 — IncidentStatusScreen (RS-106)

| Ticket | Tarea                                                                                                                                                                                                                                    | Prioridad |
| ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- |
| RS-106 | `IncidentStatusScreen`: timeline visual del caso con `incident_status_log`. Estados: detección → alerta → despacho → contacto notificado → proveedor confirmado → cerrado. Accesible desde Home (historial) y post-emergency (inmediato) | MEDIO     |

#### 6.6 — Conteo de Eventos por Póliza (RS-107)

| Ticket | Tarea                                                                                                                                                                                                                            | Prioridad |
| ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- |
| RS-107 | Al crear incident con `status='caso_activado'` → incrementar `policies.emergency_events_count`. Si `count ≥ 3` → bloquear nuevas activaciones + mostrar banner "Has alcanzado el límite de 3 eventos de asistencia este período" | MEDIO     |

---

### SPRINT 7 — Integraciones Carrier + Broker Portal (Prioridad 3)

**Objetivo:** Primera póliza real emitida end-to-end. Canal de activación para brokers.
**Duración estimada:** 3–4 semanas
**Dependencias:** Credenciales Quasar (Thony), Débito Inmediato docs (F. Ángeles).

#### 7.1 — Carrier API Real (RS-108 a RS-110)

| Ticket | Tarea                                                                                                                                    | Prioridad |
| ------ | ---------------------------------------------------------------------------------------------------------------------------------------- | --------- |
| RS-108 | Reemplazar `StubCarrierClient` con `QuasarInfotechClient`: `issuePolicy()` con auth real, URL base de staging, `kyc_document_id` flow    | CRÍTICO   |
| RS-109 | KYC document upload: `POST /kyc/documents` antes de `issue_policy`. Subir imagen de cédula + certificado desde Supabase Storage a Quasar | CRÍTICO   |
| RS-110 | Plan tier mapping confirmado con Thony: `basica → basic`, `plus → comprehensive_plus`, `ampliada → premium`                              | ALTO      |

#### 7.2 — Débito Inmediato (RS-111)

| Ticket | Tarea                                                                                                                                | Prioridad |
| ------ | ------------------------------------------------------------------------------------------------------------------------------------ | --------- |
| RS-111 | Reemplazar stub "Próximamente" en `PaymentMethodScreen` con integración real una vez que F. Ángeles entregue documentación de la API | ALTO      |

#### 7.3 — Broker Activation Flow (RS-112 a RS-113)

Este es el "flujo del documento" — usuario activa app con póliza ya creada por broker.

| Ticket | Tarea                                                                                                                                                       | Prioridad |
| ------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- |
| RS-112 | Nueva pantalla `PolicyActivationScreen`: campo "Número de póliza" + cédula → validar vs. Quasar API → pre-llenar datos de perfil → saltar OCR de onboarding | ALTO      |
| RS-113 | Router: nueva ruta `/activate-policy` accesible desde `WelcomeScreen` como botón secundario "Tengo una póliza de mi corredor"                               | ALTO      |

#### 7.4 — MQTT Real (RS-114)

| Ticket | Tarea                                                                                                                                                   | Prioridad |
| ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- |
| RS-114 | Reemplazar MQTT stub con broker real de Thony: URL, auth, topics. El payload de `CrashMonitorScreen` ya es el formato correcto — solo cambia el destino | ALTO      |

---

### SPRINT 8 — Claims Post-Accidente + Cobertura Médica (Prioridad 4)

**Objetivo:** El flujo emergencia → siniestro → cobertura médica es trazable de punta a punta.
**Duración estimada:** 2–3 semanas

#### 8.1 — Claim Pre-llenado desde Incidente (RS-115)

| Ticket | Tarea                                                                                                                                                                                                            | Prioridad |
| ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- |
| RS-115 | `NewClaimScreen`: si recibe `incidentId` como `state.extra`, pre-llenar fecha/hora (del incidente), tipo (del urgency_level), GPS location. Botón "Reportar este accidente" visible desde `IncidentStatusScreen` | CRÍTICO   |

#### 8.2 — Módulo de Gastos Médicos (RS-116 a RS-118)

Según el documento: 60% inicial (activado por proveedor en <24h) + 40% restante post-documentación.

| Ticket | Tarea                                                                                                                                                                                                                            | Prioridad |
| ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- |
| RS-116 | Nueva tabla `medical_expenses`: `incident_id`, `claim_id`, `initial_amount_60pct`, `remaining_amount_40pct`, `initial_paid_at`, `status` ('pending_initial' / 'initial_paid' / 'documents_received' / 'fully_paid' / 'rejected') | ALTO      |
| RS-117 | UI "Documentación Post-Accidente": recolectar informe policial, fotos moto (placa, serial, frente, ambos lados), declaración de hechos. Subir a Supabase Storage, referenciar en `medical_expenses`                              | ALTO      |
| RS-118 | Banner en `IncidentStatusScreen` cuando `medical_expenses.status = 'initial_paid'`: "Pago inicial procesado. Para el 40% restante, sube los documentos requeridos." con CTA a RS-117                                             | ALTO      |

#### 8.3 — KPIs del Módulo de Detección (RS-119)

El documento especifica 20 indicadores de performance. Estos alimentan el dashboard de Thony.

| Ticket | Tarea                                                                                                                                                                                                                                      | Prioridad |
| ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------- |
| RS-119 | Edge Function `detection-kpis` o materialized view: % incidentes respondidos en <30s, % falsos positivos descartados, tiempo promedio detección→despacho, % casos con contacto efectivo. Consumible por Thony vía Supabase Realtime o REST | MEDIO     |

---

## 7. Tabla de Prioridad Global (Vista Ejecutiva)

### P0 — Antes del Primer Usuario Real (Sprint 5)

1. **Background service real** (RS-085–090): sin esto, el producto de detección no existe
2. **Tabla `incidents` + state machine en DB** (RS-091–092): trazabilidad del caso
3. **GPS real en EmergencyScreen** (RS-095): el payload sin GPS real es inútil operativamente
4. **Persistir incidente en DB** (RS-096): sin esto, nada es auditable
5. **Countdown 30s + alarma de audio** (RS-093–094): especificado en el documento
6. **EmergencyPayloadBuilder completo** (RS-098): datos estructurados para proveedor y centro de control

### P1 — Antes del Primer Cliente de Pago (Sprint 6)

7. **Notificación real a contactos** (RS-100–101): diferenciador del producto
8. **Venemergencia webhook** (RS-102–103): activa la asistencia real en planes Plus/Ampliada
9. **Firebase push notifications** (RS-104): crítico para alertas en background
10. **Carrier API real Quasar** (RS-108–109): póliza confirmada ≠ provisional

### P2 — Escala y Canales (Sprint 7)

11. **Débito Inmediato** (RS-111)
12. **Broker activation flow** (RS-112–113)
13. **MQTT real** (RS-114)
14. **Conteo de eventos por póliza** (RS-107)

### P3 — Completitud del Producto (Sprint 8)

15. **Claims pre-llenados desde incidente** (RS-115)
16. **Módulo de gastos médicos 60/40** (RS-116–118)
17. **KPI dashboard data** (RS-119)
18. **Location watcher post-incidente** (RS-105)

---

## 8. Archivos Clave a Modificar

| Archivo                                                                    | Sprint | Cambio                                                              |
| -------------------------------------------------------------------------- | ------ | ------------------------------------------------------------------- |
| `mobile/lib/features/emergency/presentation/screens/emergency_screen.dart` | 5      | Countdown 30s, GPS real, audio alarm, persist to DB                 |
| `mobile/lib/features/emergency/data/emergency_contact_repository.dart`     | 5      | Add level field                                                     |
| `supabase/migrations/`                                                     | 5      | Tabla `incidents`, `incident_status_log`, columnas en `policies`    |
| `mobile/lib/features/telemetry/` (nuevo módulo)                            | 5      | Background service, gyroscope, GPS speed tracking, detection engine |
| `supabase/functions/notify-emergency-contacts/` (nueva función)            | 6      | Twilio WhatsApp dispatch a contactos                                |
| `supabase/functions/update-incident-location/` (nueva función)             | 6      | Location resend post-incidente                                      |
| `mobile/lib/features/policy/data/carrier_api_client.dart`                  | 7      | QuasarInfotechClient real                                           |
| `mobile/lib/features/auth/presentation/screens/welcome_screen.dart`        | 7      | Botón "Activar póliza de corredor"                                  |
| `mobile/lib/features/claims/presentation/screens/new_claim_screen.dart`    | 8      | Pre-fill desde `incidentId`                                         |

---

## 9. Decisiones de Diseño Pendientes (Requieren Respuesta del Equipo)

| #   | Decisión                                   | Opciones                                                                                                                                                           | Impacto                                                                  |
| --- | ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------ |
| D1  | **Alarma de audio en background**          | (a) Solo mientras app está en foreground · (b) Background audio con `flutter_foreground_task` notification sound                                                   | Sprint 5 — Android requiere foreground service para audio en background  |
| D2  | **Speed threshold 80 km/h**                | (a) Bloquear activación de cobertura en app · (b) Solo marcar flag y dejar decisión al Centro de Control                                                           | Recomendamos (b) — la app marca, humano decide                           |
| D3  | **Activación broker vs. OCR**              | (a) Pantalla separada `/activate-policy` · (b) Mismo onboarding con bypass OCR                                                                                     | Recomendamos (a) — flujos diferentes merecen UX diferentes               |
| D4  | **Venemergencia vs. Quasar para despacho** | ¿Quasar maneja el despacho o Venemergencia tiene API directa?                                                                                                      | A confirmar en reunión 2026-04-23 (meeting con Venemergencia ya ocurrió) |
| D5  | **Chatbot en emergencia**                  | El doc lo marca como "opcional" — ¿lo priorizamos?                                                                                                                 | Recomendamos: post-Sprint 8, baja prioridad                              |
| D6  | **Cobertura del acompañante/pasajero**     | El PDF no menciona pasajeros. ¿La póliza cubre a un acompañante? ¿El EmergencyPayload debe incluir datos del pasajero? ¿Se activan gastos médicos para ambos?      | Bloquea diseño del payload Sprint 5 — requiere decisión de negocio       |
| D7  | **Asignación de carrier al usuario**       | ¿El cliente elige la aseguradora (Pirámide / Caracas / Mercantil)? ¿O el sistema asigna automáticamente por tier? ¿Se muestra el carrier en la pantalla de planes? | Impacta `ProductSelectionScreen` y arquitectura multi-carrier            |
| D8  | **Preguntas de pre-cotización**            | ¿Existen preguntas de elegibilidad obligatorias antes de mostrar los planes? (uso, materiales peligrosos, siniestros previos, licencia vigente)                    | Si existen, requiere pantalla nueva antes de `ProductSelectionScreen`    |
| D9  | **Mapa definitivo de medios de pago**      | Pago Móvil P2P = cobro de prima (impl.) · Débito Inmediato = prima recurrente · GuiaPay = indemnizaciones al asegurado (no cobro de prima) · Biopago = POS físico  | Aclarar en reunión 2026-04-23 — Fernando Ángeles                         |

---

## 10. Tests Requeridos

| Área                    | Tests a agregar                                                    | Archivo sugerido                                         |
| ----------------------- | ------------------------------------------------------------------ | -------------------------------------------------------- |
| Detection engine        | Score calculation con señales conocidas; threshold; falso positivo | `test/features/telemetry/detection_engine_test.dart`     |
| IncidentRepository      | CRUD, state transitions, conteo por póliza                         | `test/features/emergency/incident_repository_test.dart`  |
| EmergencyPayloadBuilder | Payload completo vs. datos parciales (GPS nulo, sin póliza activa) | `test/features/emergency/emergency_payload_test.dart`    |
| Background service      | Unit test del algoritmo de inmovilidad (sin hardware)              | `test/features/telemetry/immobility_detection_test.dart` |
| Countdown timer         | 30s default, rango 30–180s, autoFall +5s                           | `test/features/emergency/countdown_test.dart`            |

---

## 11. Riesgos

| Riesgo                                               | Probabilidad | Impacto | Mitigación                                                                                        |
| ---------------------------------------------------- | ------------ | ------- | ------------------------------------------------------------------------------------------------- |
| Thony no entrega credenciales API Quasar             | Media        | Alto    | Sprint 5 diseñado para funcionar 100% sin ello; Sprint 7 los consume                              |
| Android mata background service en MIUI/EMUI         | Alta         | Alto    | `flutter_foreground_task` con notificación persistente; guía de exclusión de batería para usuario |
| Twilio WhatsApp rate limits en emergencias múltiples | Baja         | Medio   | Queue en Edge Function, no envío directo en loop                                                  |
| GPS impreciso en Venezuela (señal urbana débil)      | Media        | Medio   | Enviar best available + flag de precisión; fallback a última ubicación conocida                   |
| Venemergencia no tiene API REST lista                | Media        | Alto    | Usar webhook simple (POST JSON) como contrato mínimo; Thony puede actuar de proxy                 |
