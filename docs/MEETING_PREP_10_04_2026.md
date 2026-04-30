# Preparación Reunión — 2026-04-10

**Fecha:** Jueves 10 de abril de 2026
**Asistentes esperados:** Thony (Quasar Infotech), Alex, F. Ángeles (Vareca), otros TBD
**Objetivo:** Desbloquear integraciones reales tras completar Sprints 4A–4E. Alinear arquitectura GCP/Supabase y definir interactividad del dashboard.

---

## 1. Estado de los Sprints — Lo Construido vs. Lo Bloqueado

### Completado (Sprints 4A–4E, entregado al 09/04/2026)

| Funcionalidad                                        | Estado       | Notas                                              |
| ---------------------------------------------------- | ------------ | -------------------------------------------------- |
| Onboarding completo con OCR (cédula + certificado)   | ✅ Listo     | MLKit, parser con validación                       |
| Selección de plan (3 tiers desde Supabase)           | ✅ Listo     | Básica / Plus / Ampliada                           |
| Flujo de pago — Pago Móvil                           | ✅ Listo     | Conectado al flujo de emisión                      |
| Flujo de pago — Transferencia bancaria               | ✅ Listo     |                                                    |
| Flujo de pago — Débito Inmediato                     | ⚠️ Stub      | Badge "Próximamente", botón deshabilitado          |
| Emisión de póliza (registro provisional)             | ⚠️ Stub      | `CarrierApiClient` usa mock, Supabase OK           |
| QR Carnet Digital                                    | ✅ Listo     | `PolicyCarnetScreen`, share action                 |
| Entrega post-emisión (WhatsApp/share)                | ✅ Listo     | PDF + carnet                                       |
| Contactos de emergencia (multi-contacto, CRUD)       | ✅ Listo     | Wired a tabla real `emergency_contacts`            |
| Botón de emergencia — triage + lifecycle de despacho | ✅ Listo     |                                                    |
| Monitor de impacto (crash detection demo)            | ✅ Listo     | `CrashMonitorScreen`, gauge, payload preview       |
| IoT API client                                       | ⚠️ Stub      | Mapper listo, falta broker MQTT real               |
| Perfil — todos los datos en tiempo real              | ✅ Listo     |                                                    |
| Notificaciones push (FCM)                            | ❌ Bloqueado | Necesita Firebase project + `google-services.json` |

### Bloqueado — Dependencias Externas Sin Resolver

| Bloqueante                                                | Owner             | Urgencia               | Desde           |
| --------------------------------------------------------- | ----------------- | ---------------------- | --------------- |
| `kyc_document_id` — flujo KYC real                        | Thony             | 🔴 Sprint 5            | 30/03           |
| Credenciales API Quasar + URL base + docs (Swagger)       | Thony             | 🔴 Sprint 5            | 30/03           |
| Mapeo `plan_tier` (basica/plus/ampliada → códigos Quasar) | Thony             | 🔴 Sprint 5            | 30/03           |
| Generación de documentos (PDF + carnet) — ownership       | Thony             | 🔴 Decisión            | 30/03           |
| MQTT broker URL, protocolo, auth, topics, frecuencia      | Thony             | 🟠 Sprint 6            | 30/03           |
| API real Seguros Pirámide (William)                       | F. Ángeles        | 🟠 Sprint 6            | 30/03           |
| Débito Inmediato — contacto desarrollador + docs API      | F. Ángeles        | 🟠 Sprint 5            | 30/03           |
| Documento flujo de ventas punta a punta                   | F. Ángeles + Alex | 🟠 Referencia          | Prometido 01/04 |
| Reunión Venemergencia                                     | Alex              | 🟠 Plans Plus/Ampliada | 30/03           |
| Firebase project setup (push notifications)               | Alex              | 🟡 Sprint 5            | Pendiente       |

---

## 2. Checklist para Demo en Vivo

Tener la app corriendo en Chrome/Windows antes de la reunión. Recorrer en este orden:

- [ ] Welcome → Login → OTP (WhatsApp)
- [ ] Onboarding: selección de plan → cédula scan (OCR) → confirm → certificado scan → confirm → validación de propiedad → dirección → contactos de emergencia → consentimiento
- [ ] Quote summary → Pago Móvil → Emisión → pantalla de éxito
- [ ] Botón "Ver Carnet Digital" → `PolicyCarnetScreen` con QR + share
- [ ] Perfil → sección de contactos de emergencia (live desde DB)
- [ ] Tarjeta "Monitor de Impacto" en home → `CrashMonitorScreen` → gauge en tiempo real → payload MQTT preview → "Simular impacto fuerte" → flujo de emergencia

**Puntos a enfatizar:**

- El payload MQTT que se le mostrará a Thony en la pantalla es exactamente lo que su broker va a recibir
- El QR del carnet puede ser el endpoint `verify-policy` de Thony — o el nuestro — decisión pendiente

---

## 3. Preguntas para THONY (Mayor Prioridad)

### A. Arquitectura GCP / Supabase

1. Confirmado que el backend de Quasar corre en GCP. ¿Cómo se comparten datos con la app?
   - ¿La app llama directamente a tus endpoints REST?
   - ¿Escribes tú a nuestra base Supabase, o viceversa, o sólo via webhooks?
2. A futuro: ¿tiene sentido centralizar deployments y DBs en una sola infraestructura? ¿O mejor mantener GCP (tuyo) + Supabase (nuestro) con contratos de API bien definidos?
3. ¿Tu plataforma tiene staging/sandbox separado de producción?

### B. KYC — `kyc_document_id` (BLOQUEANTE)

1. ¿Existe un endpoint `POST /kyc/documents` al que llamamos antes de `issue_policy`?
2. ¿Qué documentos hay que subir — cédula, certificado, o ambos?
3. ¿Tu plataforma valida los documentos o sólo los almacena?
4. ¿Es obligatorio `kyc_document_id` para que `issue_policy` responda con éxito?
5. ¿Hay un estado intermedio (ej. `kyc_pending`) mientras se valida?

### C. Credenciales y Documentación API

1. ¿Podemos obtener URL base + API key de staging hoy? (Sin esto no podemos reemplazar los stubs)
2. ¿Existe documentación Swagger/OpenAPI?
3. ¿Cuál es el formato de autenticación — Bearer token, API key header, OAuth?

### D. Generación de Documentos (PDF + Carnet)

1. ¿Tu plataforma genera el PDF de la póliza y el carnet digital?
2. Si es así, ¿los documentos incluyen QR policial (verificación por URL pública)?
3. ¿Las URLs de los documentos (`digital_id_card_url`, `full_policy_pdf_url`) son permanentes o tienen expiración?
4. **Decisión requerida:** ¿Usamos tus documentos como fuente primaria y los nuestros como fallback? ¿O al revés?

### E. Mapeo de Planes

1. Confirmar: `basica` → `basic`, `plus` → `comprehensive_plus`, `ampliada` → `premium`?
2. ¿Hay campos adicionales por plan en el payload de `issue_policy`?

### F. MQTT Telemetría (Sprint 6 — definir ahora)

> La app ya genera el payload exacto. El `CrashMonitorScreen` lo muestra en tiempo real. Sólo falta el destino.

| Parámetro                                                | Estado       |
| -------------------------------------------------------- | ------------ |
| Broker URL + puerto                                      | ⏳ Pendiente |
| Protocolo (MQTT/TLS o WebSocket)                         | ⏳ Pendiente |
| Método de autenticación                                  | ⏳ Pendiente |
| Estructura de topics                                     | ⏳ Pendiente |
| Frecuencia de reporte (cada X segundos)                  | ⏳ Pendiente |
| Thresholds de crash detection (patrones de acelerómetro) | ⏳ Pendiente |
| ¿Broker de staging separado de producción?               | ⏳ Pendiente |

### G. Dashboard Quasar — Interactividad por Rol

_Ver Sección 9 para el análisis completo. Presentar como sugerencias de colaboración, no críticas._

**Preguntas clave:**

1. ¿Cuál es el roadmap de interactividad? ¿Ya está planificado o está en diseño?
2. Para el módulo **First Responders Dispatch** — ¿hay integración de mapa planificada (Google Maps/Mapbox)?
3. Para el módulo **Broker/Sales (CRM)** — ¿los brokers emiten pólizas desde ahí, o sólo consultan? (Esto determina si construimos el portal Next.js por separado)
4. ¿Quién construye las vistas interactivas de **Medical/Clinics** y **Financial Treasury**? ¿Podemos colaborar?

---

## 4. Preguntas para ALEX

1. **Venemergencia:** ¿Se agendó la reunión? Sin esto, los planes Plus y Ampliada no tienen asistencia médica real — el mayor gap de producto.
2. **Sprint 5 — prioridad:**
   - ¿(a) Portal broker (para que Vareca empiece a vender) o
   - (b) Integración real con carrier (para que las pólizas sean confirmadas por Seguros Pirámide)?
3. **GuiaPay:** ¿Sigue relevante o Débito Inmediato lo reemplaza definitivamente?
4. **Decisiones de producto abiertas:**
   - Precios finales (actualmente en DB: $17 / $31 / $110)
   - Cobertura de acompañante — ¿sólo titular o titular + acompañante?
   - ¿Preguntas pre-cotización requeridas por el asegurador?
5. **Firebase:** ¿Quién crea el proyecto Firebase y entrega `google-services.json`?

---

## 5. Preguntas para F. ÁNGELES (si está presente)

1. **Débito Inmediato:** ¿Se concretó el contacto con el desarrollador? ¿Podemos obtener docs de la API?
2. **William (Seguros Pirámide):** ¿Hay avance en docs/sandbox de la API real del carrier?
3. **Documento flujo de ventas:** ¿Se entregó? (Prometido para 01/04)
4. **Demo Vareca:** ¿Podemos obtener login demo para entender el flujo real de emisión?

---

## 6. Preguntas para EL GRUPO

1. **Ownership del portal broker:**

   - ¿Thony lo construye como parte del módulo "Broker/Sales" de su dashboard?
   - ¿O lo construimos nosotros como Next.js app separada (`admin-portal/`)?
   - Este es el mayor riesgo de duplicación de trabajo. Necesitamos decisión clara.

2. **Fecha de primera póliza real:** ¿Cuándo esperamos la primera emisión real de punta a punta (app → API Quasar → confirmación carrier)? Esto define qué hay que priorizar.

3. **Email transaccional:** ¿Qué proveedor usamos para envío automático post-emisión? (Resend, SendGrid, AWS SES)

---

## 7. Análisis del Dashboard Quasar — Gaps por Rol

_Basado en revisión de la plataforma. Presentar como input colaborativo para priorización conjunta._

El dashboard actual es sólido visualmente y segmenta bien los datos por actor. La siguiente iteración necesita transicionar de "portal de monitoreo" a "portal de gestión" con capacidades CRUD por rol.

### 7.1 Operations Command

- **Falta:** Clic en tarjeta de incidente para ver detalle completo
- **Falta:** Botón de actualización manual de estado (cuando el trigger automático falla)
- **Falta:** Filtro activos vs. dados de alta

### 7.2 Underwriting & Actuarial

- **Falta:** Drill-down en póliza específica (contrato, historial de claims, historial del vehículo)
- **Falta:** Mecanismo para marcar, suspender o enviar a revisión manual una póliza de alto riesgo

### 7.3 First Responders Dispatch _(más urgente)_

- **Falta:** Botón "Asignar unidad" en alertas con estado `Pending Dispatch`
- **Falta:** Inputs para que el respondedor actualice ETA, confirme llegada o cancele falsa alarma
- **Falta crítica:** Integración de mapa — leer coordenadas lat/lon como texto no es usable en respuesta rápida
- **Sugerencia:** Google Maps/Mapbox embed con pin de accidente + ubicación de unidades

### 7.4 Medical / Clinics

- **Falta:** Área de texto/formulario para que médicos agreguen entradas al "Registro de Incidente"
- **Falta:** Botón de "Reclamar / Verificar" el anticipo médico autorizado (para el área de facturación)

### 7.5 Broker / Sales (CRM)

- **Falta:** Botón "Nuevo Cliente" / "Generar Cotización" — sin esto no es un CRM, es solo un reporte
- **Falta:** Clic en cliente → ver info de contacto, fechas de renovación, historial de pagos
- **Pregunta:** ¿Esto duplica lo que vamos a construir en `admin-portal/`?

### 7.6 Financial Treasury

- **Falta:** Botón "Reintentar transferencia" cuando falla un Pago Móvil (timeout bancario)
- **Falta:** Generación de reportes de reconciliación por rango de fechas

### 7.7 System Diagnostics

- **Falta:** Búsqueda por `SIM-DEVICE-ID` o User ID para troubleshooting de datos faltantes
- **Falta:** Gráfica visual de curva G-force en el tiempo (los logs raw de texto no son digeribles)

---

## 8. Decisiones Estratégicas — Hacer en Esta Reunión

| #   | Decisión                        | Opciones                                                                                | Owner         |
| --- | ------------------------------- | --------------------------------------------------------------------------------------- | ------------- |
| 1   | **Arquitectura GCP + Supabase** | (a) Co-existencia con API contracts claros · (b) Centralizar a futuro en una sola infra | Thony + Alex  |
| 2   | **Dashboard interactividad**    | ¿Quién construye los módulos CRUD? ¿Thony solo, o colaboramos?                          | Thony + Diego |
| 3   | **Broker portal ownership**     | (a) Módulo 5 del dashboard de Thony · (b) Next.js `admin-portal/` de Diego              | Todos         |
| 4   | **Generación de documentos**    | (a) Thony primario, Diego fallback · (b) Diego primario (ya construido)                 | Thony + Diego |
| 5   | **Venemergencia**               | ¿Se agenda reunión esta semana? Sin esto, Plus/Ampliada no tienen diferenciador real    | Alex          |
| 6   | **Primera póliza real**         | ¿Fecha objetivo? Define todo el Sprint 5                                                | Alex + Thony  |

---

## 9. Acciones de Seguimiento (Post-Reunión)

- [ ] Actualizar `docs/MEETING_ANALYSIS_30_03_2026.md` Sección 10 con nuevos estados
- [ ] Crear `docs/MEETING_ANALYSIS_10_04_2026.md` con decisiones tomadas
- [ ] Si se obtienen credenciales API Quasar → Sprint 5: reemplazar `QuasarInfotechClient` stub
- [ ] Si se aclara broker portal ownership → ajustar scope de `admin-portal/`
- [ ] Actualizar memoria con nuevas decisiones y asignaciones
- [ ] Repriorizar tickets Sprint 5 según qué bloqueantes se levantaron
