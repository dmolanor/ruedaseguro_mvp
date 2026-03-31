# Análisis de Implicaciones: Reunión 30/03/2026 — RuedaSeguro
**Fecha de reunión:** 30 de marzo de 2026
**Última actualización:** 30 de marzo de 2026 — Simplificación de onboarding (2 escaneos)
**Participantes:** F. Angles (Vareca), Alex, Thony (IoT), Diego (Dev), Fer Molano, Arturo
**Preparado por:** Engineering
**Referencia técnica:** `PROGRESS_REPORT_SPRINT_3.md`, `PROGRESS_REPORT_SPRINTS_1_2A_2B.md`
**Documentos de referencia OCR:** `docs/guide_scanned_docs/certificado_circulacion_2.jpeg`, `docs/guide_scanned_docs/certificado_circulacion_antiguo.jpeg`

---

## Tabla de Contenidos

1. [Resumen Ejecutivo](#1-resumen-ejecutivo)
2. [Hallazgos Clave por Tema](#2-hallazgos-clave-por-tema)
3. [Implicaciones en la Aplicación Móvil](#3-implicaciones-en-la-aplicación-móvil)
4. [Implicaciones en la Arquitectura del Sistema](#4-implicaciones-en-la-arquitectura-del-sistema)
5. [Implicaciones en el Modelo de Datos](#5-implicaciones-en-el-modelo-de-datos)
6. [Implicaciones en el Flujo de Emisión de Pólizas](#6-implicaciones-en-el-flujo-de-emisión-de-pólizas)
7. [Nuevos Componentes a Desarrollar](#7-nuevos-componentes-a-desarrollar)
8. [Decisiones de Negocio Pendientes](#8-decisiones-de-negocio-pendientes)
9. [Priorización Propuesta para Sprint 4+](#9-priorización-propuesta-para-sprint-4)
10. [Dependencias Externas Identificadas](#10-dependencias-externas-identificadas)

---

## 1. Resumen Ejecutivo

La reunión del 30/03 trajo claridad fundamental sobre el modelo de negocio y el flujo operativo de RuedaSeguro. Se confirmaron decisiones arquitectónicas clave (separación total app móvil / portal broker), se descubrieron campos de datos obligatorios faltantes, y se abrieron tres nuevas integraciones técnicas (débito inmediato, Venemergencia, segundo carné con QR).

El hallazgo más crítico es la **separación de canales de venta en tres sistemas distintos**, lo que implica que la app móvil queda definitivamente acotada al cliente final y requiere la creación de un portal web independiente para brokers. Adicionalmente, el flujo de onboarding y emisión necesita ajustes puntuales que están al alcance del Sprint 4.

**Actualización post-reunión — Simplificación del Onboarding:** El flujo de escaneos se reduce de 3 documentos a 2. El Certificado de Circulación reemplaza la combinación Licencia + Carnet de Circulación. Ver sección 2.13 y sección 3.1 para el detalle completo.

---

## 2. Hallazgos Clave por Tema

### 2.1 Modelo de Emisión de la Póliza RCV

**Lo que se confirmó:**
- RuedaSeguro posee delegación formal de la aseguradora para emitir pólizas RCV de forma autónoma.
- El proceso actual es por lotes (batch al cierre del día): se reporta a la aseguradora la lista de pólizas emitidas junto con foto de cédula y carnet de circulación.
- La meta es migrar a emisión vía API en tiempo real (ya modelado en `CarrierApiClient` en Sprint 3).
- Cada aseguradora tendrá su propia API; la abstracción `CarrierApiClient` es el enfoque correcto.

**Empresas aseguradoras mencionadas con API:**
- Seguros Pirámide (stub ya en `carrier_api_config`)
- Seguros Caracas (API disponible)
- Seguros Mercantil (API disponible)

**Implicación técnica:** El diseño multi-carrier de Sprint 3 es correcto. Se deben crear `AcselSirwayClient`, `SegurosCaracasClient` y `SeguroseMercantilClient` cuando estén disponibles los contratos de cada API.

---

### 2.2 Documento de Póliza: PDF + Carnet con QR

F. Angles compartió en reunión los documentos reales que genera el sistema Vareca:
1. **Póliza PDF completa** (ya generada en Sprint 2B por `PolicyPdfService`)
2. **Carnet físico** (tarjeta pequeña) — **NO implementado aún** — contiene:
   - Datos resumidos del titular, vehículo y vigencia
   - **Código QR** que la policía de tránsito escanea para verificar validez

**Implicación crítica:** El carnet con QR es un documento legal. El QR debe codificar información verificable de la póliza. Se necesita:
- Generación del carnet como segundo documento (A8 o similar, separado del PDF completo)
- Un endpoint público de verificación (GET `/verify/{policyToken}`) para que el QR sea funcional
- Entrega automática de ambos documentos (PDF + carnet) al cliente tras la emisión

**Canales de entrega exigidos:**
- Visualización en la app (ya existe para PDF)
- Descarga / compartir por WhatsApp
- Envío automático al correo electrónico registrado

---

### 2.3 Tres Canales de Venta — Implicación Arquitectónica Mayor

La reunión confirmó de forma explícita **tres canales de venta totalmente separados**:

| Canal | Actor | Sistema | Estado |
|-------|-------|---------|--------|
| **App Móvil** | Cliente final (motorizado) | App Flutter (RuedaSeguro) | Implementado (Sprint 1-3) |
| **Portal Broker/Vendedor** | Broker + vendedores con código SUDEASEG | Web app separada | **NO existe aún** |
| **POS (Puntos de Venta)** | Cajeros en 30.000+ negocios (farmacias, supermercados) | Sistema de Biopago / terminales POS | **NO existe aún** |

**Decisión confirmada:** La app móvil es **exclusivamente** para el cliente final. No debe tener ninguna opción de "entrar como broker" ni flujo de emisión por parte de terceros.

**Flujo del canal broker (a desarrollar en portal web separado):**
```
Broker abre portal web
    → Ingresa datos del motorizado (o los carga por OCR)
    → Sistema emite póliza
    → Portal genera link de descarga/activación
    → Broker envía link al cliente por WhatsApp
    → Cliente descarga la app
    → OTP con su número → ya tiene la póliza asociada
    → Cliente configura botón de pánico, contactos de emergencia
```

---

### 2.4 Estructura Multinivel de Brokers

**Jerarquía confirmada:**
```
Compañía de Seguros
    └── RuedaSeguro (Insurtech, intermediario tecnológico)
            └── Brokers (con código SUDEASEG, ej: Vareca)
                    └── Vendedores individuales (también deben tener código)
                            └── Cliente final (motorizado)
```

- Todo vendedor debe estar registrado ante la Superintendencia de Seguros y tener **código oficial**
- Los vendedores no pueden operar de forma independiente; todos van bajo un broker
- Los **POS** son un canal alternativo habilitado por ley (no son brokers, pero pueden emitir)
- El broker no vende directamente; activa a sus vendedores y les da herramientas

**Implicación para el portal broker:** Debe implementar estructura multinivel (broker → vendedores), con registro y validación de código SUDEASEG.

---

### 2.5 Campos de Datos Adicionales en el Flujo de Emisión

El sistema Vareca de F. Angles revela campos obligatorios que el flujo actual de la app no captura explícitamente o no pasa correctamente a la aseguradora:

#### 2.5.1 Campos actualmente faltantes o no verificados

| Campo | ¿En DB? | ¿En CarrierSubmissionPayload? | Acción requerida |
|-------|---------|-------------------------------|------------------|
| `date_of_birth` | ✅ `profiles.date_of_birth` (OCR) | ❌ **No está en payload** | Agregar a `CarrierSubmissionPayload` |
| `email` | ✅ recolectado | ❌ No verificado si se pasa | Verificar y agregar |
| `emergency_contact_name` | ✅ `profiles.emergency_contact_name` | ❌ No en payload | Campo a enfatizar en UI |
| `emergency_contact_phone` | ✅ `profiles.emergency_contact_phone` | ❌ No en payload | Ídem |
| Conductor frecuente ≠ titular | ❌ No modelado | ❌ No en payload | Nuevo campo / nueva pantalla |
| Dirección por geolocalización | ❌ Solo texto manual | N/A | Reemplazar con GPS |
| Serial del motor | ✅ OCR del carnet de circulación | ✅ (vía `vehiclePlate`) | Verificar campo específico |
| Serial de carrocería | ✅ OCR | No aplica directamente | Verificar extracción |
| Uso del vehículo | ✅ `vehicleUse` en carnet OCR | No explícito en payload | Verificar si aseguradora lo requiere |

#### 2.5.2 "Conductor frecuente" — campo nuevo

En el sistema Vareca existe una pregunta clave: **¿Quién es el conductor frecuente del vehículo?**
- Opciones: el tomador (dueño), el titular o **una tercera persona**
- Si es tercera persona: deben capturarse sus datos completos (nombre, cédula)
- La póliza de ley exige que el conductor frecuente esté identificado si es diferente al dueño

**Implicación:** Agregar una pantalla/sección en el flujo de emisión post-OCR que haga esta pregunta. Si la respuesta es "otra persona", mostrar campos de captura adicionales.

---

### 2.6 Dirección por Geolocalización

**Lo dicho:** F. Angles fue claro: la geolocalización debe reemplazar el formulario de dirección manual para simplificar el proceso de venta.

**Estado actual:** El flujo de onboarding tiene `AddressFormScreen` con campos manuales (urbanización, ciudad, municipio, estado, código postal).

**Cambio requerido:**
- En la pantalla de dirección: botón "Usar mi ubicación actual" que rellene los campos automáticamente
- Guardar `latitude` y `longitude` en la tabla `profiles` (nuevas columnas)
- Los campos de texto deben seguir editables como fallback (para casos sin GPS)
- La API de la aseguradora espera estado/municipio — necesitamos reverse geocoding para mapear coordenadas a divisiones administrativas venezolanas

---

### 2.7 Contactos de Emergencia — Múltiples, No Uno Solo

**Lo dicho por F. Angles:** El usuario debe poder agregar **múltiples personas** a notificar en caso de emergencia. Ejemplo: mamá, papá, abuelo, novia.

**Estado actual:** La tabla `profiles` tiene tres campos planos: `emergency_contact_name`, `emergency_contact_phone`, `emergency_contact_relation` — solo un contacto.

**Cambio requerido:**
- Nueva tabla `emergency_contacts` (muchos-a-uno con `profiles`)
- UI en el perfil: lista de contactos con add/edit/delete
- El botón de pánico dispara notificaciones a **todos** los contactos de la lista

---

### 2.8 Integración de Pagos: Débito Inmediato

**Lo dicho:** Además de Pago Móvil, el sistema debe soportar **débito inmediato**. Hay un desarrollador externo que tiene este módulo ya construido (incluye notificación cuando llega el dinero).

**Estado actual:** Los métodos de pago implementados son Pago Móvil P2P y Transferencia Bancaria (Sprint 2A).

**Cambio requerido:**
- Agregar tercer tab/método en `PaymentMethodScreen`: Débito Inmediato
- Integrar API del desarrollador externo (pendiente contacto/documentación)
- El módulo confirma el pago en tiempo real (webhook o polling)
- `payment_method` ENUM ya incluye `guia_pay_c2p` y `domiciliacion`; verificar si alguno mapea a débito inmediato o si se necesita un valor nuevo

**Nota:** GuíaPay fue descartado explícitamente como prioridad actual. Débito inmediato es distinto.

---

### 2.9 Biopago (POS)

- Sistema de pago con huella dactilar en terminales POS
- Aplica **solo al canal POS** (portal web), no a la app móvil
- No requiere trabajo en la app Flutter

---

### 2.10 Integración con Venemergencia

**Lo dicho:** Ninguno de los equipos ha hablado aún con Venemergencia. Se necesita una reunión para definir el canal de integración (puede ser API, webhook, email, SMS).

**Estado actual:** Los planes Plus y Ampliada listan "Venemergencia" como beneficio, pero no hay integración real.

**Implicación:** La integración es parte del servicio core del producto y debe desarrollarse antes de lanzamiento del plan Plus. El canal de comunicación definirá el diseño técnico. El evento disparador es el botón de pánico / detección de accidente por sensores.

**Acción inmediata:** Concertar reunión con Venemergencia (Alex se comprometió a gestionar el contacto).

---

### 2.11 Telemetría y Sensores

**Alcance Phase 1 (actual):** `TelemetryBufferService` con buffer SQLite de 15 minutos — datos locales sin subir.

**Alcance Phase 1.5 (próximo):**
- Activar sensores del teléfono (giroscopio, acelerómetro, GPS)
- Definir frecuencia de reporte al IoT de Thony
- Thony's platform recibe la data y analiza comportamiento

**Decisión de negocio de Alex:** En el primer año la prioridad es **volumen de suscriptores**, no penalizar la conducta. La detección de "reckless driving" es Phase 2. El botón de pánico y la detección de accidente (caída a velocidad de impacto + sin cancelación manual) sí son Phase 1.

**Pendiente de definir con Thony:**
- Frecuencia de envío de telemetría (cada X segundos / minutos)
- Formato del payload a enviar (JSON, MQTT, Supabase Realtime)
- Umbral de velocidad / patrón de movimiento para activar alerta automática

---

### 2.12 Dashboard / Plataforma Administrativa

**Decisión confirmada:** El admin-portal Next.js fue deprecado correctamente. Thony construye la plataforma IoT que incluye dashboards para:
- Aseguradoras
- First Responders (Venemergencia, etc.)
- Clinical Care (hospitales)
- Brokers (sus vendedores y pólizas)

**Para la plataforma de Thony — dato a proveer:**
- F. Angles pidió agregar sección de "Compañías" para el manejo multi-aseguradora
- El sistema debe mostrar pólizas segregadas por compañía de seguros

---

### 2.13 Simplificación del Onboarding — 2 Escaneos en Lugar de 4

**Cambio:** El flujo de onboarding se simplifica radicalmente. En lugar de escanear tres documentos distintos (Cédula, Licencia de Conducir, Carnet de Circulación), el nuevo flujo requiere **solo dos**:

```
ANTES (Sprint 1):
  Cédula Scan → Cédula Confirm
  → Licencia Scan → Licencia Confirm
  → Carnet de Circulación Scan
  → Address Form
  → Consent Screen
  (3 documentos, ~7 pantallas)

DESPUÉS (Sprint 4):
  Cédula Scan → Cédula Confirm
  → Certificado de Circulación Scan → Certificado Confirm
  → Address Form (o geolocalización automática)
  → Consent Screen
  (2 documentos, ~4-5 pantallas)
```

**Documento eliminado:** Licencia de Conducir — los datos que aportaba (número de licencia, categorías, tipo de sangre, fecha de vencimiento) **no son necesarios** para la emisión de la póliza RCV ni para las coberturas adicionales en el flujo inicial.

---

#### 2.13.1 Campos a Extraer del Certificado de Circulación

El Certificado de Circulación es emitido por el INTT (Instituto Nacional de Transporte Terrestre) y existe en **dos formatos** (ver imágenes de referencia). El parser debe manejar ambos.

| Campo | Obligatorio | Regex / Heurística de extracción |
|-------|-------------|----------------------------------|
| Nombre completo del propietario | ✅ | Bloque en mayúsculas, primeras 1-2 líneas del área central |
| Número de cédula (V/E prefix) | ✅ | `^[VEve]-?\d{7,9}$` o `V\d{7,8}` |
| Placa del vehículo | ✅ | Formato nuevo: `[A-Z]{2,3}\d{2,3}[A-Z]{1,2}` · Formato viejo: `[A-Z]{2,3}\d{3}` |
| Tipo de vehículo (clase) | ✅ | Keyword: `MOTO PARTICULAR`, `AUTOMOVIL PARTICULAR`, `CAMION`, etc. |
| Tipo/carrocería de la moto | ✅ | Keyword post-clase: `RACING`, `SPORT`, `SCOOTER`, `DEPORTIVA`, `TOURING` |
| Serial NIV | ✅ | Etiqueta `Serial N.I.V.` o `(Serial NIV)` seguida de `[A-Z0-9]{8,20}` |
| Número de puestos | ✅ | Número seguido de `PTOS.` o `PTOS` en la línea de especificaciones |
| Año del vehículo | ✅ | Formato `YYYY` o `YYYY/YYYY` (año fabricación/modelo) en el bloque central |
| Marca | ✅ | Diccionario de marcas (SUZUKI, YAMAHA, HONDA, KAWASAKI, BAJAJ, etc.) |
| Modelo | ⚠️ Deseable | Texto libre después de la marca; puede ser difícil de delimitar |
| Fecha de expedición | ⚠️ Deseable | No siempre visible en los formatos actuales; puede no estar impresa en el documento |
| Color | ❌ **No requerido** | Dato cosmético, no relevante para la póliza ni para la aseguradora |
| Peso (KGS) | ❌ **No requerido** | No relevante para el producto de seguros |
| Número de ejes | ❌ **No requerido** | No relevante para el producto de seguros |
| ID de trámite largo (formato antiguo) | ❌ **Ignorar** | Cadena tipo `32349842907U1Z542672` — identificador interno del INTT, sin valor para la póliza |

> **Nota sobre fecha de expedición:** En las imágenes de referencia no aparece explícitamente una fecha de expedición impresa como campo visible. El número largo de trámite (`32349842907U1Z542672` en el formato antiguo) puede contener información de fecha codificada. Se requiere verificar con más ejemplos si existe un campo de fecha legible. Por ahora marcar como "deseable si está disponible".

---

#### 2.13.2 Análisis de los Dos Formatos del Certificado

##### Formato Reciente (`certificado_circulacion_2.jpeg`)

- **Título:** "Certificado de Circulación" en borde derecho, rotado 90°, acompañado de escudo nacional.
- **Fondo:** Guilloché + marca de agua difuminada del mapa de Venezuela. Borde tricolor venezolano en borde inferior e izquierdo.
- **Estructura de datos:**
  - Datos del propietario y vehículo: sin etiquetas, bloques de texto en MAYÚSCULAS en la zona central-izquierda
  - La placa está en el cuadrante superior-derecho, bajo la etiqueta `Placa`
  - El año del vehículo es un campo flotante en la zona inferior-derecha sin etiqueta
  - La línea inferior contiene: PESO + `EJES` + COLOR + `PTOS.` tabulados horizontalmente
  - El Serial NIV se presenta como `Serial N.I.V. (S. Carroceria)` seguido del valor en la misma línea
- **Reto OCR:** El texto del Serial NIV cruza sobre la marca de agua amarilla/azul del mapa de fondo. Aplicar binarización adaptativa en preprocesamiento.

##### Formato Antiguo (`certificado_circulacion_antiguo.jpeg`)

- **Título:** `CERTIFICADO DE CIRCULACIÓN` en cabecera horizontal. Logos INTT en esquinas. Fondo con patrón `INTT` repetido.
- **Diferencia estructural crítica:** La **placa** (`AH3V83A`) está en la esquina superior-derecha, NOT junto a la etiqueta `Placa:` del cuerpo (que aparece vacía). El parser debe ignorar la etiqueta `Placa:` con texto vacío a su derecha y buscar el valor por posición y formato.
- **Otro campo engañoso:** `Serial N.I.V.:` en la esquina inferior-izquierda aparece vacío; el valor real del serial (`81ADR8U29CM000804`) está en el bloque central precedido por `(Serial NIV)`.
- **Número de trámite largo:** La cadena `32349842907U1Z542672` en la parte superior es el ID del trámite, NO la placa ni el serial del vehículo.

---

#### 2.13.3 Implicaciones para el `CarnetParser` Existente

El parser actual (`CarnetParser`) fue diseñado para el "Carnet de Circulación" (versión simplificada). El Certificado de Circulación es el documento oficial completo del INTT y contiene más campos y formatos distintos.

**Cambios requeridos al parser:**

| Cambio | Descripción |
|--------|-------------|
| Renombrar | `CarnetParser` → `CertificadoCirculacionParser` (o mantener como alias) |
| Detección de formato | Identificar si es formato reciente o antiguo (buscar presencia de "CERTIFICADO DE CIRCULACIÓN" en cabecera o rotado en lateral) |
| Placa en formato antiguo | Extraer placa desde la zona superior-derecha si el campo `Placa:` está vacío |
| Serial NIV | Buscar tanto `Serial N.I.V. (S. Carroceria)` como `(Serial NIV)` como patrones de etiqueta |
| Tipo de vehículo | Extraer clase (`MOTO PARTICULAR`) y tipo de carrocería (`RACING`) como campos separados |
| Puestos | Extraer número de `X PTOS.` o `X PTOS` |
| Número de trámite (antiguo) | Ignorar cadena larga alfanumérica tipo `32349842907U1Z542672` (no es dato de negocio) |
| Cross-validation | Comparar nombre del propietario + cédula del certificado con datos de la cédula escaneada |

---

#### 2.13.4 Impacto en `OnboardingData` (Dart)

**Campos a eliminar** (ya no se capturan):
```dart
// ELIMINADOS del flujo de onboarding:
String? licenciaNumber;
String? bloodType;
List<String>? drivingCategories;
DateTime? licenciaExpiry;
```

**Campos a agregar o ajustar** (del Certificado de Circulación):
```dart
// NUEVOS o PRECISADOS:
String? vehicleType;         // 'MOTO PARTICULAR' | 'AUTOMOVIL PARTICULAR'
String? vehicleBodyType;     // 'RACING' | 'SPORT' | 'SCOOTER' | 'SEDAN' etc.
String? serialNiv;           // Serial NIV (equivale a serialCarroceria + motor en algunos casos)
int?    vehicleSeats;        // Número de puestos (2 PTOS. para motos)
String? vehicleWeight;       // '140 KGS' — deseable para aseguradora
```

> **Nota:** `serialMotor` y `serialCarroceria` pueden unificarse en `serialNiv` ya que en los certificados reales el Serial NIV es el identificador único del chasis/carrocería. Verificar con F. Angles si la aseguradora requiere estos dos campos separados o solo el NIV.

---

#### 2.13.5 Impacto en la Tabla `vehicles` (Supabase)

```sql
-- Agregar columnas nuevas del Certificado de Circulación:
ALTER TABLE vehicles
  ADD COLUMN IF NOT EXISTS vehicle_type       TEXT,     -- 'MOTO PARTICULAR', 'AUTOMOVIL PARTICULAR'
  ADD COLUMN IF NOT EXISTS vehicle_body_type  TEXT,     -- 'RACING', 'SPORT', 'SCOOTER', 'SEDAN'
  ADD COLUMN IF NOT EXISTS serial_niv         TEXT,     -- Serial NIV oficial del INTT
  ADD COLUMN IF NOT EXISTS seats              SMALLINT; -- 2 PTOS. para motos

-- NO agregar: color, weight_kg, axles — no son relevantes para la póliza
-- La columna serial_carroceria existente puede unificarse con serial_niv
-- Columna color: si ya existe en la tabla, se puede mantener como nullable sin obligatoriedad
```

---

#### 2.13.6 Validaciones de Cross-Reference

El nuevo flujo tiene solo dos documentos, por lo que la cross-validation debe cubrir:

| Validación | Fuente 1 | Fuente 2 | Acción si falla |
|------------|----------|----------|----------------|
| Nombre propietario | Cédula (nombre extraído) | Certificado (propietario) | Advertencia amber — usuario confirma |
| Número de cédula | Cédula (número) | Certificado (cédula del propietario) | Bloquear — mismatch indica documentos de personas distintas |
| Tipo de vehículo | Certificado (`MOTO PARTICULAR`) | Lógica de negocio (solo motos) | Bloquear — la app es solo para motos |

---

### 2.14 OCR de la Cédula de Identidad Venezolana — Análisis de Documentos de Referencia

**Archivos de referencia:** `docs/guide_scanned_docs/cc_venezuela_1.png`, `cc_venezuela_2.png`, `cc_venezuela_3.jpeg`

La cédula venezolana tiene estructura más estandarizada que el Certificado de Circulación, pero presenta **variaciones de layout según el lote/año de emisión** que son el principal reto de OCR. Los tres documentos analizados representan al menos dos generaciones de formato.

---

#### 2.14.1 Campos a Extraer de la Cédula

| Campo | Obligatorio | Zona en el documento |
|-------|-------------|----------------------|
| Tipo de ID (`V` / `E`) | ✅ | Bloque central superior, precediendo el número |
| Número de cédula | ✅ | Bloque central superior, junto al tipo |
| Apellidos | ✅ | Bloque izquierdo, etiqueta `APELLIDOS` |
| Nombres | ✅ | Bloque izquierdo, bajo `APELLIDOS`, etiqueta `NOMBRES` |
| Fecha de nacimiento | ✅ | Zona central inferior (sobre escudo), etiqueta `F. NACIMIENTO` |
| Fecha de expedición | ✅ | Zona central inferior (sobre escudo), etiqueta `F. EXPEDICION` |
| Fecha de vencimiento | ⚠️ Deseable | Zona central inferior, etiqueta `F. VENCIMIENTO` |
| Estado civil | ⚠️ Deseable | Zona central inferior, etiqueta `EDO. CIVIL` o `EDO CIVIL` |
| Nacionalidad | ⚪ Verificación | Texto grande en zona inferior: `VENEZOLANO` / `VENEZOLANA` |

---

#### 2.14.2 Zonas de Anclaje para Detección de Orientación

Antes de parsear, el pipeline debe detectar la orientación de la imagen (la imagen 3 estaba rotada 90°). Los textos de cabecera son los mejores anchors:

1. `REPUBLICA BOLIVARIANA DE VENEZUELA` — franja azul, texto blanco, parte superior
2. `CEDULA DE IDENTIDAD` — franja blanca bajo el tricolor, texto negro

Si alguno de estos textos se detecta en orientación vertical o invertida → aplicar rotación automática antes del OCR.

---

#### 2.14.3 El Número de Cédula — Variaciones de Formato

El número de cédula puede aparecer con tres formatos de separador distintos:

| Formato | Ejemplo | Regex de detección |
|---------|---------|-------------------|
| Sin separadores | `21174913` | `[VEve]\s*\d{6,8}` |
| Punto como separador de miles | `21.174.913` | `[VEve]\s*\d{1,2}\.\d{3}\.\d{3}` |
| Mixto parcial | `20.000000` | Variante entre los dos anteriores |

**Regex unificado para extracción:**
```
/^[VEve]\s*[-.]?\s*(\d{1,2}[.,]?\d{3}[.,]?\d{3})$/
```
Después de extraer, normalizar eliminando puntos/comas → número entero limpio.

---

#### 2.14.4 Zona Crítica: Fechas y Estado Civil (Dos Formatos de Layout)

Esta zona se imprime sobre el escudo nacional (fondo amarillo-dorado), lo que interfiere con el OCR. Existe además una variación de **posición relativa etiqueta-valor** entre lotes:

**Formato A — Etiqueta ARRIBA del valor** (generación reciente, ej. `cc_venezuela_1.png`):
```
Línea 1: F. NACIMIENTO    EDO. CIVIL      F. EXPEDICION    F. VENCIMIENTO
Línea 2: 14/06/1993       SOLTERA         15/03/2018       14/06/2028
```

**Formato B — Etiqueta ABAJO del valor** (generación anterior, ej. `cc_venezuela_2.png` y `cc_venezuela_3.jpeg`):
```
Línea 1: 13/08/1971       SOLTERO         17/05/2023       13/08/2031
Línea 2: F. NACIMIENTO    EDO. CIVIL      F. EXPEDICION    F. VENCIMIENTO
```

**Estrategia de parsing para manejar ambos formatos:**
1. Detectar si la etiqueta está en la línea superior o inferior respecto al bloque de fechas
2. Usar `bounding box` vertical: si en la celda superior hay una fecha (`\d{2}/\d{2}/\d{4}`) → es Formato B; si hay texto (`F. NACIMIENTO`) → es Formato A
3. El parser no debe asumir coordenada fija; debe resolver el par etiqueta-valor dinámicamente

---

#### 2.14.5 Reto: Huella Dactilar en Lugar de Firma

En los documentos `cc_venezuela_2.png` y `cc_venezuela_3.jpeg` el campo `FIRMA TITULAR` contiene una **huella dactilar** en lugar de firma manuscrita. Las líneas papilares de la huella generan texto "basura" cuando el OCR las procesa (el motor interpreta los surcos como caracteres).

**Solución recomendada:**
- Entrenar un clasificador binario simple (firma manuscrita vs. huella dactilar) para la región del campo `FIRMA TITULAR`
- Si se detecta huella: enmascarar (mask) esa región con un rectángulo blanco **antes** de pasar al motor de texto
- La región de firma ocupa aprox. el cuadrante inferior-izquierdo del área de datos

---

#### 2.14.6 Reto: Escudo Nacional como Fondo (Color Dropping)

El escudo venezolano impreso en amarillo/dorado en la zona central-inferior interfiere directamente con las fechas y el estado civil. Preprocesamiento recomendado:

1. **Conversión a espacio HSV:** aislar y neutralizar el rango de color amarillo-dorado (H: 35°–55°, S: >50%, V: >60%)
2. **Binarización adaptativa** (umbral local, no global) sobre la imagen resultante
3. **Resultado:** texto negro sobre fondo casi blanco, ready para Tesseract / Google ML Kit

---

#### 2.14.7 Regex Finales Sugeridos para `CedulaParser`

```dart
// Número de cédula (con o sin puntos, V o E)
static final _cedula = RegExp(
  r'(?<type>[VEve])\s*[-.]?\s*(?<num>\d{1,2}[.,]?\d{3}[.,]?\d{3})',
  caseSensitive: false,
);

// Fechas (DD/MM/YYYY o DD-MM-YYYY)
static final _date = RegExp(
  r'\b(?:0[1-9]|[12]\d|3[01])[\/\-\.](?:0[1-9]|1[012])[\/\-\.](?:19|20)\d{2}\b',
);

// Estado civil
static final _estadoCivil = RegExp(
  r'\b(SOLTERO|SOLTERA|CASADO|CASADA|VIUDO|VIUDA|DIVORCIADO|DIVORCIADA)\b',
  caseSensitive: false,
);

// Apellidos y Nombres: texto en mayúsculas de 2-4 palabras tras la etiqueta
static final _apellidos = RegExp(r'APELLIDOS?\s*:?\s*([A-ZÁÉÍÓÚÜÑ\s]{3,40})', caseSensitive: false);
static final _nombres   = RegExp(r'NOMBRES?\s*:?\s*([A-ZÁÉÍÓÚÜÑ\s]{3,40})', caseSensitive: false);
```

---

#### 2.14.8 Impacto en `CedulaParser` Existente

El `CedulaParser` actual ya maneja V/E y extrae nombre, cédula y DOB. Las mejoras requeridas son:

| Mejora | Descripción |
|--------|-------------|
| Detección de orientación | Antes de parsear, verificar si el texto de cabecera indica rotación |
| Normalización del número | Eliminar puntos/guiones del número extraído → entero limpio |
| Parsing de fechas — 2 formatos | Resolver ambos layouts (etiqueta arriba / etiqueta abajo) |
| Extracción de fecha de expedición | Campo nuevo — actualmente no se extrae pero es requerido por la aseguradora |
| Máscara de huella dactilar | Pre-filtro antes de reconocimiento de texto en zona de firma |
| Filtro de color amarillo | Preprocesamiento para neutralizar el escudo nacional |
| Estado civil | Campo nuevo deseable — agregar a `OnboardingData` si la aseguradora lo requiere |

---

#### 2.14.9 Campos Nuevos en `OnboardingData` desde la Cédula

```dart
// NUEVOS campos a considerar desde la cédula:
DateTime? idExpiryDate;   // F. VENCIMIENTO — la cédula tiene fecha de vencimiento
DateTime? idIssuedDate;   // F. EXPEDICION — fecha de emisión del documento
String?   civilStatus;    // EDO. CIVIL: 'SOLTERO' | 'CASADO' | etc. (si aseguradora lo requiere)
```

> **Nota:** `dateOfBirth` ya existe en `OnboardingData` y se extrae de la cédula. Lo nuevo son los campos de fecha de expedición y vencimiento, que pueden ser requeridos por la aseguradora para validar que la cédula es vigente antes de emitir la póliza.

---

## 3. Implicaciones en la Aplicación Móvil

### 3.1 Cambios al Flujo de Onboarding (Impacto ALTO)

#### A. Reducción de 3 Escaneos a 2 — Rediseño del Flujo

**Flujo nuevo completo:**

```
[1] Pantalla de bienvenida al onboarding
        ↓
[2] Cédula Scan
        ↓
[3] Cédula Confirm (usuario revisa/corrige campos extraídos)
        ↓
[4] Certificado de Circulación Scan
    ← REEMPLAZA: "Licencia Scan" + "Licencia Confirm" + "Carnet Scan"
        ↓
[5] Certificado Confirm (usuario revisa: placa, marca, modelo, tipo)
    ← Cross-validation cédula ↔ certificado (nombre + número ID)
    ← Validación de tipo de vehículo (solo MOTO PARTICULAR permitida)
        ↓
[6] Pantalla de Dirección (con geolocalización automática)
        ↓
[7] Contacto(s) de Emergencia
        ↓
[8] Consent Screen (4 checkboxes, sin cambios)
```

**Archivos Flutter afectados:**
- Eliminar/archivar: `licencia_scan_screen.dart`, `licencia_confirm_screen.dart`
- Renombrar/refactorizar: `carnet_scan_screen.dart` → `certificado_scan_screen.dart`
- Actualizar: `router.dart` (eliminar rutas de licencia)
- Actualizar: `OnboardingNotifier` (eliminar campos de licencia)
- Actualizar: `OnboardingData` (ver sección 2.13.4)

#### B. Pantalla de Dirección → Geolocalización
**Archivo:** `mobile/lib/features/onboarding/presentation/screens/address_screen.dart` (o similar)

- Agregar botón prominente "Detectar mi ubicación"
- Al presionar: usar `geolocator` package para obtener coordenadas
- Reverse geocoding para obtener estado/municipio (paquete `geocoding` o API externa)
- Guardar `lat/lon` en `profiles` (nuevas columnas)
- Campos de texto permanecen como edición manual post-autodetección
- Agregar columnas `latitude DOUBLE PRECISION`, `longitude DOUBLE PRECISION` a `profiles`

#### C. Contacto de Emergencia → Obligatorio y Expandido
**Archivos:** pantallas de onboarding, `profiles` table, nueva tabla `emergency_contacts`

- Actualmente el formulario pide UNO solo; cambiar arquitectura a lista
- Durante onboarding: capturar al menos 1 contacto de emergencia (obligatorio)
- En la pantalla de perfil: gestión de lista completa (agregar/editar/eliminar)
- Mínimo 1, máximo recomendado ~5

#### D. Nueva Sección: "Conductor Frecuente"
**Posición en flujo:** al final del Certificado Confirm, antes de pasar a dirección

Pantalla nueva o sección en el flujo de emisión:
```
¿Quién conduce frecuentemente esta moto?
  [○] Yo mismo (el dueño registrado)
  [○] Otra persona
      ← si selecciona "Otra persona":
         Nombre completo: ___________
         Cédula: ___________
```

Si es otra persona, esos datos deben guardarse en la tabla `policies` o en una nueva tabla `policy_drivers`.

---

### 3.2 Cambios al Flujo de Emisión de Póliza (Impacto ALTO)

#### A. Agregar `date_of_birth` a `CarrierSubmissionPayload`
**Archivo:** `mobile/lib/features/policy/data/carrier_api_client.dart`

```dart
// Agregar a CarrierSubmissionPayload:
final DateTime dateOfBirth;     // Requerido para coberturas adicionales (AP/vida)
final String email;             // Para entrega del documento
final String? frequentDriverName;   // Si conductor ≠ titular
final String? frequentDriverId;     // Cédula del conductor frecuente
```

#### B. Generación del Carnet con QR
**Archivo nuevo:** `mobile/lib/features/policy/services/policy_card_service.dart`

- Generar documento "carnet" (tarjeta pequeña, formato ~85x55mm)
- Contenido: nombre, cédula, placa, vigencia, número de póliza
- QR que codifica: `policyNumber|plate|expiryDate` firmado con HMAC-SHA256
- Necesita endpoint público `/api/verify/{token}` para validación policial
- Integrar en el share sheet junto al PDF

#### C. Entrega Automática Post-Emisión
**Archivo:** `mobile/lib/features/policy/presentation/screens/emission_screen.dart`

Después de confirmar emisión:
1. WhatsApp share: abrir `whatsapp://send?text=Tu póliza RuedaSeguro...&phone={contactPhone}` con el PDF adjunto
2. Email: enviar PDF + carnet al email registrado (via Edge Function de Supabase o SendGrid)
3. Ambos deben ser opcionales/confirmables, no automáticos sin consentimiento

---

### 3.3 Cambios a la Pantalla de Perfil (Impacto MEDIO)

#### A. Gestión de Múltiples Contactos de Emergencia
**Archivo:** `mobile/lib/features/profile/presentation/screens/profile_screen.dart`

- Nueva sección "Contactos de Emergencia" con `ListView` de contactos
- Botón "Agregar contacto" con formulario (nombre, teléfono, relación)
- Swipe-to-delete o botón de eliminar por contacto
- Indicador visual si hay 0 contactos: advertencia amber "Agrega al menos un contacto de emergencia"

#### B. Gestión de Plan (Upgrade/Downgrade)
**Archivo:** `mobile/lib/features/profile/presentation/screens/profile_screen.dart` o nueva pantalla

- Botón "Cambiar de plan" en la vista de póliza activa
- F. Angles confirmó: el motorizado puede cambiar/mejorar su plan desde la app
- Lógica: crear nueva póliza con nuevo plan al expirar la actual, o mid-term upgrade con prorrateo

---

### 3.4 Cambios al Método de Pago (Impacto MEDIO)

**Archivo:** `mobile/lib/features/policy/presentation/screens/payment_method_screen.dart`

- Agregar tercer tab: **Débito Inmediato**
- Campos: banco, número de cuenta o cédula/RIF, confirmación del titular
- Integración con API del sistema externo (pendiente contacto con el desarrollador)
- El pago debe confirmar en tiempo real (webhook de notificación de cobro exitoso)

---

### 3.5 Botón de Pánico — Mejoras de Fase 1.5

**Archivo:** `mobile/lib/features/home/presentation/widgets/panic_button.dart` (o donde esté)

- Múltiples destinatarios (lista de emergency_contacts)
- Integración con Venemergencia (cuando se defina el canal)
- Detección automática de accidente por sensores:
  - Velocidad de impacto (acelerómetro)
  - Ausencia de respuesta del usuario tras X segundos
  - Si no se cancela el botón de pánico → auto-trigger

---

### 3.6 Ajustes a la Pantalla de Cotización / Selección de Plan

**Archivo:** `mobile/lib/features/policy/presentation/screens/product_selection_screen.dart`

- Los precios finales de los planes están pendientes de definición de negocio
- La cobertura de acompañante (titular solo vs. titular + acompañante) aún no está cerrada
- La pantalla debe ser flexible para mostrar textos de cobertura configurables desde DB (`policy_types.description` o campo nuevo)
- Agregar condiciones pre-cotización si la aseguradora lo requiere (preguntas sobre uso del vehículo)

---

### 3.7 Mejoras de UX en Entrada de Datos — Listas Predefinidas, Cámara vs. Archivo y Otras

Esta sección consolida mejoras de experiencia de usuario que reducen fricción, errores de tipeo y tiempo de onboarding. Son independientes entre sí y pueden implementarse de forma incremental.

---

#### 3.7.1 Listas Predefinidas (Dropdowns / Autocomplete)

En lugar de campos de texto libre, todos los campos con un conjunto cerrado o casi cerrado de valores deben ofrecer selección guiada. Esto elimina errores de tipeo, normaliza los datos en DB y acelera el llenado.

| Campo | Pantalla | Tipo de control | Fuente de datos |
|-------|----------|-----------------|-----------------|
| Marca del vehículo | Certificado Confirm | Searchable dropdown | Lista estática (`CarnetParser` ya tiene 20 marcas: Toyota, Honda, Yamaha, Kawasaki, Suzuki, Bajaj, Hero, KTM, Ducati, BMW, Harley, Royal Enfield, Vespa, Piaggio, Kymco, SYM, AKT, TVS, Lifan, Zongshen, + otras) |
| Modelo del vehículo | Certificado Confirm | Searchable dropdown filtrado por marca | Lista estática por marca (o campo libre si marca no está en lista) |
| Tipo de carrocería (moto) | Certificado Confirm | Chips seleccionables | `RACING`, `SPORT`, `SCOOTER`, `TOURING`, `ENDURO`, `NAKED`, `CRUISER`, `TRAIL`, `UTILITARIA` |
| Estado (estado venezolano) | Dirección | Dropdown | 23 estados + DTTO. CAPITAL (lista fija) |
| Municipio | Dirección | Dropdown filtrado por estado | Tabla `municipios` en Supabase (330 municipios venezolanos) |
| Urbanización | Dirección | Searchable autocomplete | Tabla `urbanizaciones` en Supabase filtrada por municipio, o libre si no aparece en lista |
| Banco (pagos) | Método de pago | Dropdown | Lista de bancos con **código de 4 dígitos** (requerido por IoT API de Thony). Ampliar de 8 a ~13 bancos (ver sección 4.4.8) |
| Relación de contacto de emergencia | Contacto emergencia | Dropdown | `Madre`, `Padre`, `Cónyuge/Pareja`, `Hijo/a`, `Hermano/a`, `Amigo/a`, `Otro` |
| Tipo de ID | Login / Onboarding | Chips | `V` (Venezolano), `E` (Extranjero), `CC` (Colombiano) |
| Prefijo telefónico | Login / Contacto | Dropdown de banderas | `+58` (VE), `+57` (CO) + posibles expansiones Latam |
| Año del vehículo | Certificado Confirm | Scrollable year picker | Rango: 1970–año_actual |

**Impacto técnico:**
- Crear tabla `reference_data` en Supabase (o archivo JSON en assets) para marcas, modelos, municipios, urbanizaciones
- Las listas de estados/municipios venezolanos son datos públicos fijos → mejor como assets JSON para evitar requests
- Las urbanizaciones son dinámicas y crecen → mejor en Supabase con `ilike` search
- Modelos por marca: tabla bidimensional `vehicle_models(brand TEXT, model TEXT)` con ~200 registros iniciales

---

#### 3.7.2 Captura de Documentos: Cámara vs. Subir Archivo

**Estado actual:** Solo se usa `ImagePicker` con `source: ImageSource.camera`.

**Cambio requerido:** Ofrecer ambas opciones en cada pantalla de escaneo de documento.

```
┌─────────────────────────────┐
│  ¿Cómo quieres agregar el   │
│  Certificado de Circulación?│
│                             │
│  [📷 Tomar foto]            │
│  [📁 Subir desde galería]   │
└─────────────────────────────┘
```

**Implementación:**
```dart
// Tomar foto:
_picker.pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 1600)

// Subir archivo (galería o explorador):
_picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1600)
// Para archivos PDF:
FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'])
```

**Consideraciones:**
- Si el usuario sube un PDF (algunos escanean los documentos a PDF): extraer primera página como imagen antes del OCR
- Agregar paquete `file_picker: ^6.x` al `pubspec.yaml`
- La guía de calidad (`ImageQualityValidator`) debe aplicarse igual para imágenes subidas que para fotos en vivo
- Para fotos de galería: mostrar advertencia si la imagen es una foto de pantalla (ya existe heurística de Moiré en el validador)

---

#### 3.7.3 Herramienta de Recorte y Rotación Post-Captura

Entre la captura de la imagen y el envío al OCR, ofrecer una pantalla intermedia de ajuste:

- **Recorte (crop):** Cuadro ajustable para que el usuario recorte exactamente el documento, descartando fondo innecesario
- **Rotación:** Botones de 90° horario/antihorario + detección automática de orientación
- **Contraste/brillo rápido:** Slider simple para mejorar legibilidad si la foto es oscura o tiene reflejos

**Paquete sugerido:** `image_cropper: ^7.x` — ya tiene UI nativa para Android e iOS con handles de recorte.

---

#### 3.7.4 Feedback Visual de Confianza del OCR

Después del escaneo y antes de la pantalla de confirmación, mostrar indicadores de confianza campo por campo:

- Campo con confianza ≥ 0.90 → borde verde, icono ✓
- Campo con confianza 0.75–0.89 → borde ámbar, icono ⚠, tooltip: "Verifica este dato"
- Campo con confianza < 0.75 → borde rojo, campo vacío o con texto sugerido, usuario debe escribir

**Comportamiento en confirm screen:**
- Si todos los campos clave (nombre, cédula, placa) tienen confianza ≥ 0.90 → el botón "Confirmar" está habilitado de inmediato
- Si algún campo crítico tiene baja confianza → ese campo se resalta y el usuario debe editarlo antes de continuar

Ya existe parcialmente en `CedulaParser` (confidence scoring). Extender el mismo sistema a `CertificadoCirculacionParser`.

---

#### 3.7.5 Reintento de Escaneo con Guía Contextual

Si el OCR tiene baja confianza general (< 0.60 en promedio de campos clave), en lugar de mostrar la pantalla de confirmación con muchos campos vacíos/rojos, ofrecer directamente la opción de reintentar con consejos:

```
┌─────────────────────────────────────┐
│  ⚠️ No pudimos leer bien el documento│
│                                     │
│  Consejos para una mejor foto:       │
│  • Coloca el documento sobre una    │
│    superficie plana y oscura        │
│  • Evita reflejos de luz            │
│  • Asegúrate de que el texto esté   │
│    completamente visible            │
│                                     │
│  [🔄 Reintentar]  [✏️ Ingresar manualmente] │
└─────────────────────────────────────┘
```

La opción "Ingresar manualmente" desactiva el OCR y muestra todos los campos como inputs de texto vacíos.

---

#### 3.7.6 Guardado Parcial del Onboarding (Resume Later)

Si el usuario cierra la app durante el onboarding (que tiene ~7 pantallas), al volver debería continuar desde donde lo dejó, no empezar de cero.

**Implementación:**
- `OnboardingNotifier` persiste el estado actual en `SharedPreferences` / `flutter_secure_storage` al navegar entre pantallas
- Al entrar a la app con sesión autenticada pero sin perfil completo → el router detecta `AuthStatus.authenticated` (sin profile) y reanuda el onboarding en la última pantalla alcanzada
- Al completar el onboarding → limpiar el estado guardado

**Ya existe** el `AuthStatus.authenticated` (sin profile) que diferencia al usuario sin perfil. Solo se necesita persistir el progreso de `OnboardingData`.

---

#### 3.7.7 Autocompletado de Datos del Perfil desde el OTP

Cuando el usuario se registra con su número de teléfono, el campo de teléfono en los formularios posteriores (contacto de emergencia, pago móvil) debería pre-llenarse automáticamente con ese número. Evita que el usuario lo escriba de nuevo.

**Fuente:** `Supabase.instance.client.auth.currentUser?.phone`

---

#### 3.7.8 Contacto de Emergencia — Importar desde Agenda del Teléfono

En lugar de escribir nombre y teléfono, permitir seleccionar un contacto directamente desde la agenda del dispositivo.

```dart
// Paquete: contacts_service o flutter_contacts
final contact = await FlutterContacts.openExternalPick();
// → pre-llena nombre + teléfono del contacto seleccionado
```

El usuario confirma/edita antes de guardar. Esto reduce el onboarding en varios pasos de escritura.

**Consideración:** Requiere permiso `READ_CONTACTS`. Mostrar explicación clara del por qué se pide el permiso. La selección es siempre manual (el usuario elige quién).

---

#### 3.7.9 Validación en Tiempo Real de la Placa

El campo de placa (si el usuario edita el valor del OCR) debe validar el formato mientras el usuario escribe:

- Formato nuevo VE: `XXX-00X` o `XX-000-XX` → regex `[A-Z]{2,3}-\d{2,3}-[A-Z]{1,2}`
- Formato antiguo VE: `ABC-123` → regex `[A-Z]{3}-\d{3}`
- Formato CO: `ABC-123` (igual al antiguo VE)

Mostrar checkmark verde cuando el formato es válido, borde rojo mientras no lo es. No bloquear el avance si el usuario confirma explícitamente un formato no estándar (puede haber placas especiales o diplomáticas).

---

#### 3.7.11 Resumen de Mejoras UX — Priorización

| Mejora | Impacto en conversión | Complejidad | Sprint sugerido |
|--------|----------------------|-------------|-----------------|
| Listas predefinidas (marca, modelo, tipo carrocería, estado, municipio) | 🔴 Alto | Media | Sprint 4 |
| Cámara vs. subir archivo | 🔴 Alto | Baja | Sprint 4 |
| Feedback de confianza OCR (campo a campo) | 🟠 Medio-Alto | Media | Sprint 4 |
| Validación en tiempo real de placa | 🟠 Medio | Baja | Sprint 4 |
| Reintento con guía contextual | 🟠 Medio | Baja | Sprint 4 |
| Importar contacto desde agenda | 🟠 Medio | Baja | Sprint 4 |
| Auto-fill teléfono desde OTP | 🟡 Bajo-Medio | Baja | Sprint 4 |
| Herramienta de recorte/rotación | 🟡 Bajo-Medio | Media | Sprint 5 |
| Guardado parcial del onboarding | 🟡 Bajo | Media | Sprint 5 |

---

## 4. Implicaciones en la Arquitectura del Sistema

### 4.1 Separación Definitiva de Sistemas

```
┌─────────────────────────────────────────────────────────────────┐
│                    ECOSISTEMA RUEDASEGURO                        │
│                                                                   │
│  [App Móvil Flutter]    [Portal Web Broker]    [Portal POS]      │
│   Cliente final          Brokers/Vendedores     Biopago/Cajeros   │
│   (implementado)         (A CONSTRUIR)          (A CONSTRUIR)     │
│        │                      │                      │            │
│        └──────────────────────┴──────────────────────┘            │
│                               │                                   │
│                    [API RuedaSeguro / Supabase]                   │
│                               │                                   │
│           ┌───────────────────┼──────────────────────┐            │
│           │                   │                      │            │
│  [Carrier APIs]   [Plataforma IoT Thony]    [Venemergencia]       │
│  Seguros Pirámide   Dashboard multi-rol      API emergencias       │
│  Seguros Caracas    Telemetría en tiempo                          │
│  Seguros Mercantil  real                                          │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2 Endpoint de Verificación de QR (Nuevo)

Se necesita un endpoint público (no autenticado) para que la policía de tránsito pueda verificar la validez de una póliza escaneando el QR del carnet:

```
GET /verify/{policyToken}
```

- `policyToken` = HMAC-SHA256 de `policyNumber|plate|expiryDate` con clave secreta interna
- Respuesta pública: `{ valid: bool, policyNumber, holderName, plate, expiryDate, planName }`
- Puede implementarse como Supabase Edge Function con resultado HTML (para scanner de cámara simple)
- **No debe exponer datos sensibles** (cédula, dirección, teléfono)

### 4.3 Sistema de Invitaciones / Pre-provisión de Pólizas

Para el flujo "broker emite → cliente descarga app y ya tiene póliza":

```
Nueva tabla: policy_invitations
  - id: UUID
  - phone_number: TEXT (E.164 del futuro cliente)
  - policy_id: FK → policies
  - invitation_token: TEXT UNIQUE
  - expires_at: TIMESTAMPTZ
  - claimed_at: TIMESTAMPTZ (NULL si no activado)
  - created_by_broker_id: FK → brokers
```

Flujo de activación:
1. Broker emite póliza en portal web → se crea `policy_invitation` con token único
2. Cliente recibe link con token: `https://app.ruedaseguro.com/activate/{token}`
3. App detecta el token (deep link), solicita OTP con el número registrado
4. Al autenticar, `policy_invitation` se asocia al nuevo `profile_id` y marca `claimed_at`

### 4.4 Integración con la Plataforma IoT de Thony — Análisis de Payloads (30/03)

Thony proporcionó los contratos de API entre la app y su plataforma (Quasar Infotech). Esta sección analiza los payloads, evalúa su completitud respecto al `MQTT_INTEGRATION_GUIDE.md` e identifica implicaciones técnicas nuevas.

---

#### 4.4.1 Naturaleza de la Comunicación: REST, no MQTT

**Hallazgo crítico:** El payload de `issue_policy` tiene estructura de llamada **HTTP REST** (verbo + `action` + `request_id`), no de mensaje MQTT. Esto implica que existen **dos canales de comunicación separados** con la plataforma de Thony:

| Canal | Protocolo | Propósito | Estado |
|-------|-----------|-----------|--------|
| **API REST** (`api.quasarinfotech.com`) | HTTPS | Emisión de pólizas, respuesta con documentos | ✅ Payload definido |
| **MQTT broker** | MQTT/TLS o WebSocket | Telemetría en tiempo real, emergencias, presencia | ⏳ Pendiente — faltan broker URL, credenciales, topics |

El `MQTT_INTEGRATION_GUIDE.md` cubre el canal MQTT. El nuevo payload cubre el canal REST. **Ambos son necesarios y son independientes.**

---

#### 4.4.2 Payload App → IoT: `issue_policy`

```json
{
  "request_id": "req_892374982374",
  "timestamp": "2026-03-30T18:47:29Z",
  "action": "issue_policy",
  "rider_data": { ... },
  "asset_data": { ... },
  "selected_coverage": { ... },
  "payment_data": { ... }
}
```

**Análisis campo por campo:**

| Campo | Lo que envían | Lo que tenemos en app | Gap / Acción |
|-------|--------------|----------------------|-------------|
| `request_id` | String único por request | No existe | Generar UUID antes de cada llamada |
| `timestamp` | ISO 8601 UTC | Usar `DateTime.now().toUtc().toIso8601String()` | Ninguno |
| `action` | `"issue_policy"` | Literal fijo | Ninguno |
| `rider_data.first_name` | `"Carlos"` | `profiles.full_name` (nombre completo) | Separar en first_name / last_name al construir el payload |
| `rider_data.last_name` | `"Mendoza"` | `profiles.full_name` | Ídem — necesita split o campos separados en DB |
| `rider_data.national_id` | `"V-12345678"` | `profiles.id_type + profiles.id_number` | Concatenar: `"${idType}-${idNumber}"` |
| `rider_data.dob` | `"1990-05-14"` (YYYY-MM-DD) | `profiles.date_of_birth` | Formatear a `YYYY-MM-DD` |
| `rider_data.email` | `"carlos@..."` | `profiles.email` (campo no confirmado en DB) | Verificar que email se guarda en `profiles` |
| `rider_data.phone` | `"+584141234567"` (E.164) | Phone del OTP de Supabase Auth | Obtener de `auth.users.phone` |
| `rider_data.kyc_document_id` | `"doc_55f8a9b2"` | **NO EXISTE** | ⚠️ Campo desconocido — ver sección 4.4.4 |
| `asset_data.vehicle_type` | `"motorbike"` | `vehicles.vehicle_type` = `"MOTO PARTICULAR"` | Mapear: `"MOTO PARTICULAR"` → `"motorbike"` |
| `asset_data.make` | `"Empire Keeway"` | `vehicles.brand` | Directamente (formato puede diferir) |
| `asset_data.model` | `"Horse II"` | `vehicles.model` | Directamente |
| `asset_data.year` | `2024` (int) | `vehicles.year` (String en parser) | Parsear a int |
| `asset_data.vin` | `"LBP1234567890ABCD"` | `vehicles.serial_niv` | Directamente (es el Serial NIV) |
| `asset_data.license_plate` | `"AB123CD"` (**sin guiones**) | `vehicles.plate` = `"AB-123-CD"` | ⚠️ Normalizar: eliminar guiones antes de enviar |
| `selected_coverage.plan_tier` | `"comprehensive_plus"` | `policy_types.tier` = `"plus"` / `"basica"` / `"ampliada"` | ⚠️ Mapear tiers — ver sección 4.4.5 |
| `selected_coverage.premium_amount` | `45.00` (float) | `policy_types.price_usd` | Directamente |
| `selected_coverage.currency` | `"USD"` | Literal fijo | Ninguno |
| `payment_data.method` | `"pago_movil"` | `payments.method` = `"pago_movil_p2p"` | Mapear: eliminar `_p2p` |
| `payment_data.bank_code` | `"0102"` | Nombre del banco en texto (ej. `"Banco de Venezuela"`) | ⚠️ Agregar código SWIFT/BID venezolano a la lista de bancos |
| `payment_data.source_phone` | `"+584141234567"` | `payments.pago_movil_phone` | Directamente |
| `payment_data.payment_reference` | `"987654321"` | `payments.reference` | Directamente |
| `payment_data.payment_date` | `"2026-03-30"` (YYYY-MM-DD) | `payments.created_at` | Formatear fecha |

---

#### 4.4.3 Payload IoT → App: Respuesta de Política

```json
{
  "status": "success",
  "policy_data": { "policy_number": "QIT-MB-2026-001928", ... },
  "financial_receipt": { "transaction_id": "txn_pm_...", "receipt_url": "..." },
  "policy_documents": {
    "digital_id_card_url": "...",
    "full_policy_pdf_url": "...",
    "dynamic_content": { "coverage_summary": [...], "terms_and_conditions_url": "..." }
  },
  "telemetry_setup": { "device_pairing_status": "pending", "pairing_code": "8842-AX" }
}
```

**Implicaciones por campo:**

| Campo | Implicación |
|-------|------------|
| `policy_data.policy_number` | Guardar como `carrier_policy_number` en tabla `policies` — reemplaza el número stub `STUB-xxx` |
| `policy_data.status` | `"active"` → actualizar `policies.status = 'active'` e `issuance_status = 'confirmed'` |
| `policy_data.effective_date` / `expiration_date` | Actualizar `policies.start_date` y `policies.end_date` con los valores que retorna Thony (pueden diferir de los nuestros) |
| `financial_receipt.transaction_id` | Guardar en `payments.external_transaction_id` (nueva columna) |
| `financial_receipt.receipt_url` | URL de recibo externo — mostrar en la app en la sección de póliza/pagos |
| `policy_documents.digital_id_card_url` | ⚠️ **Thony genera el carnet digital** — la URL apunta a `api.quasarinfotech.com`. Esto **puede reemplazar** nuestro `PolicyCardService` propuesto. Requiere aclaración: ¿su carnet tiene QR de verificación? |
| `policy_documents.full_policy_pdf_url` | ⚠️ **Thony genera el PDF completo** — esto podría reemplazar nuestro `PolicyPdfService`. Mismo interrogante sobre el QR. |
| `dynamic_content.coverage_summary` | Array de strings con cobertura. Usar para mostrar resumen en la app sin hardcodear. Guardar o cachear por `plan_tier`. |
| `dynamic_content.terms_and_conditions_url` | URL a JSON de T&C. Considerar mostrar en pantalla de consentimiento |
| `telemetry_setup.device_pairing_status` | ⚠️ **NUEVO** — Implica un dispositivo físico IoT a emparejar. ¿Qué es? Ver sección 4.4.6 |
| `telemetry_setup.pairing_code` | Código de emparejamiento (`"8842-AX"`). La app debería mostrarlo al usuario para que lo introduzca en el dispositivo |

---

#### 4.4.4 Campo Desconocido: `kyc_document_id`

El payload de emisión incluye `"kyc_document_id": "doc_55f8a9b2"` en `rider_data`. Este campo no fue discutido y su origen es desconocido.

**Hipótesis:** Thony's platform tiene un módulo de KYC (Know Your Customer) donde se suben los documentos de identidad escaneados (cédula, certificado de circulación). El `kyc_document_id` es el ID que devuelve ese módulo al confirmar la verificación.

**Implicación de flujo si la hipótesis es correcta:**

```
FLUJO ACTUAL (Sprint 3):
  Escaneo OCR → Supabase Storage → Perfil creado → Póliza emitida (CarrierApi)

FLUJO NUEVO PROBABLE:
  Escaneo OCR → Supabase Storage (archivado)
              → Upload a Thony KYC API → kyc_document_id
              → issue_policy con kyc_document_id
```

**Preguntas que deben responderse con Thony antes de implementar:**
1. ¿Cómo se obtiene el `kyc_document_id`? ¿Hay un endpoint `POST /kyc/documents` previo?
2. ¿Qué documentos se deben subir? ¿Cédula, certificado, o ambos?
3. ¿El KYC lo validan ellos o es solo almacenamiento?
4. ¿Qué pasa si se omite el campo? ¿La emisión falla?

**Acción:** Agregar como pregunta bloqueante para la reunión con Thony del miércoles.

---

#### 4.4.5 Mapeo de Plan Tiers

La plataforma de Thony usa nombres de plan distintos a los nuestros. Necesitamos una tabla de mapeo:

| RuedaSeguro (`policy_types.tier`) | IoT Thony (`plan_tier`) |
|-----------------------------------|------------------------|
| `basica` | `"basic"` (inferido) |
| `plus` | `"comprehensive_plus"` (ejemplo del payload) |
| `ampliada` | `"premium"` o `"comprehensive_full"` (por confirmar) |

**Implementación:** Agregar columna `iot_plan_tier_code TEXT` a la tabla `policy_types`, o mantener el mapeo como constante en `CarrierSubmissionPayload` / nuevo `IotApiClient`.

---

#### 4.4.6 Campo Desconocido: `telemetry_setup.pairing_code`

La respuesta incluye `{ "device_pairing_status": "pending", "pairing_code": "8842-AX" }`. Esto sugiere un **dispositivo físico IoT** a instalar en la moto, separado del teléfono del motorizado.

**Preguntas que deben responderse con Thony:**
1. ¿Qué es el dispositivo? ¿Un GPS tracker físico? ¿Un OBD-II dongle?
2. ¿Todos los planes incluyen el dispositivo, o solo los premium?
3. ¿Cómo se instala? ¿El usuario lo hace solo o requiere técnico?
4. ¿La app necesita mostrar el `pairing_code` al usuario y guiarle en la instalación?
5. ¿Qué pasa si el dispositivo nunca se empareja? ¿La póliza sigue activa?

**Implicación en la app:** Si el emparejamiento es obligatorio, necesitamos una pantalla post-emisión de "Configura tu dispositivo" que muestre el código y el estado del emparejamiento.

---

#### 4.4.7 Documentos de Póliza: ¿Thony o Nosotros?

La respuesta de Thony incluye URLs a dos documentos ya generados por su plataforma:
- `digital_id_card_url` → el carnet digital (lo que íbamos a construir con `PolicyCardService`)
- `full_policy_pdf_url` → el PDF completo (lo que ya existe en `PolicyPdfService`)

**Escenarios posibles:**

| Escenario | Descripción | Decisión requerida |
|-----------|-------------|-------------------|
| A | Usar solo documentos de Thony | Simplifica desarrollo — pero perdemos control sobre el formato, el QR y el branding |
| B | Usar documentos de Thony como primarios, los nuestros como fallback | Mayor resiliencia, el usuario siempre tiene acceso al documento aunque la API de Thony esté caída |
| C | Mantener documentos propios, ignorar los de Thony | Control total — más desarrollo, potencial inconsistencia |

**Recomendación provisional:** Escenario B. Guardar las URLs de Thony en la tabla `policies` (`iot_card_url`, `iot_pdf_url`) y mostrarlas prioritariamente. Mantener el `PolicyPdfService` como fallback offline.

**Verificar con Thony:**
- ¿Sus documentos incluyen QR de verificación policial?
- ¿Las URLs tienen TTL o son permanentes?
- ¿Están bajo HTTPS con certificado válido?

---

#### 4.4.8 Códigos de Banco Venezolanos

El campo `payment_data.bank_code` usa el código de 4 dígitos del sistema bancario venezolano (BID/SWIFT local). Actualmente la app almacena nombres de banco en texto. Necesitamos agregar los códigos:

| Banco | Código | Ya en la app |
|-------|--------|-------------|
| Banco de Venezuela (BDV) | `0102` | ✅ |
| Banesco | `0134` | ✅ |
| Mercantil | `0105` | ✅ |
| BBVA Provincial | `0108` | ✅ |
| BNC | `0191` | ✅ |
| Bicentenario | `0175` | ✅ |
| BanPlus | `0174` | ✅ |
| BanFondeso | `0177` | ✅ |
| Banco Activo | `0171` | ❌ |
| Banco Exterior | `0115` | ❌ |
| Bancaribe | `0128` | ❌ |
| Del Sur | `0157` | ❌ |
| Sofitasa | `0137` | ❌ |

Agregar columna `bank_code TEXT` al modelo de selección de banco en `PaymentMethodScreen` y en `payments` table.

---

#### 4.4.9 Preguntas Pendientes para Thony (Completando el MQTT Guide)

El `MQTT_INTEGRATION_GUIDE.md` (secciones 1.1 y 1.2) lista preguntas que siguen sin respuesta para el canal MQTT de telemetría:

| Pregunta | Sección MQTT Guide | Estado |
|----------|-------------------|--------|
| Broker URL + puerto | 1.1-A | ⏳ Pendiente |
| Protocolo (MQTT/S vs WSS) | 1.1-B | ⏳ Pendiente |
| Método de autenticación | 1.1-C | ⏳ Pendiente |
| Credenciales reales | 1.1-D | ⏳ Pendiente |
| TLS requerido | 1.1-E | ⏳ Pendiente |
| Estructura de topics | 1.2-F | ⏳ Pendiente |
| Topic separado para emergencias | 1.2-G | ⏳ Pendiente |
| QoS level | 1.2-H | ⏳ Pendiente |
| Retained messages | 1.2-I | ⏳ Pendiente |
| ¿GCP escribe telemetría a Supabase o lo hace la app? | 6 (deferred) | ⏳ Pendiente |
| ¿Existe broker de staging separado? | 6 (deferred) | ⏳ Pendiente |
| **¿Cómo se obtiene `kyc_document_id`?** | **NUEVO** | ⏳ Bloqueante |
| **¿Qué es el dispositivo físico del `pairing_code`?** | **NUEVO** | ⏳ Bloqueante |
| **¿Los documentos de Thony tienen QR policial?** | **NUEVO** | ⏳ Decisión de diseño |
| **Mapeo completo de `plan_tier`** | **NUEVO** | ⏳ Pendiente |

---

#### 4.4.10 Nuevo Componente: `IotApiClient`

El canal REST de Thony requiere un cliente análogo al `CarrierApiClient` existente. Diseño propuesto:

```dart
// Nuevo archivo: mobile/lib/features/policy/data/iot_api_client.dart

class IotPolicyRequest {
  final String requestId;          // UUID generado en el momento
  final String action;             // siempre "issue_policy"
  final IotRiderData riderData;
  final IotAssetData assetData;
  final IotCoverageData selectedCoverage;
  final IotPaymentData paymentData;
}

class IotPolicyResponse {
  final bool isSuccess;
  final String? policyNumber;      // carrier_policy_number en nuestra DB
  final String? digitalCardUrl;    // guardar en policies.iot_card_url
  final String? fullPdfUrl;        // guardar en policies.iot_pdf_url
  final String? receiptUrl;
  final String? transactionId;
  final String? pairingCode;       // mostrar al usuario post-emisión
  final List<String>? coverageSummary;
  final String? errorMessage;
}

abstract class IotApiClient {
  Future<IotPolicyResponse> issuePolicy(IotPolicyRequest request);
}

// Implementación stub para desarrollo:
class StubIotClient implements IotApiClient { ... }

// Implementación real:
class QuasarInfotechClient implements IotApiClient { ... }
```

Este `IotApiClient` **reemplaza o convive con** `CarrierApiClient` dependiendo de si Thony's platform también valida con la aseguradora o si la aseguradora sigue siendo un paso separado. Pendiente de aclarar.

---

### 4.5 Email Transaccional

No existe todavía ningún mecanismo de envío de correo. Se necesita:
- Integración con un proveedor de email (Resend, SendGrid, Amazon SES)
- Templates para: bienvenida, entrega de póliza PDF+carnet, renovación, siniestro recibido
- Edge Function `send-policy-email` que se active post-emisión

---

## 5. Implicaciones en el Modelo de Datos

### 5.1 Modificaciones a `profiles`

```sql
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS latitude  DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS address_from_gps BOOLEAN DEFAULT false;
  -- Indica si la dirección se capturó por GPS (true) o manual (false)
```

### 5.2 Nueva Tabla `emergency_contacts`

Reemplaza los tres campos planos actuales:

```sql
CREATE TABLE emergency_contacts (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  full_name    TEXT NOT NULL,
  phone        TEXT NOT NULL,       -- E.164
  relation     TEXT,                -- 'madre', 'padre', 'pareja', 'amigo', etc.
  is_primary   BOOLEAN DEFAULT false,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_emergency_contacts_profile ON emergency_contacts(profile_id);
-- RLS: el rider solo puede gestionar sus propios contactos
```

> **Nota de migración:** Los datos actuales en `profiles.emergency_contact_*` deben migrarse a `emergency_contacts` y los campos originales deprecarse (no eliminar de inmediato para compatibilidad).

### 5.3 Modificaciones a `policies`

```sql
ALTER TABLE policies
  ADD COLUMN IF NOT EXISTS frequent_driver_name TEXT,
  ADD COLUMN IF NOT EXISTS frequent_driver_id   TEXT,
  ADD COLUMN IF NOT EXISTS frequent_driver_id_type TEXT CHECK (frequent_driver_id_type IN ('V','E','CC'));
```

### 5.4 Modificaciones a `carrier_api_config`

Verificar que la tabla soporte los tres carriers. Agregar filas cuando lleguen los contratos:
- `seguros_caracas` (API disponible — pendiente docs)
- `seguros_mercantil` (API disponible — pendiente docs)

Posiblemente agregar columna `api_type TEXT` para distinguir tipo de integración (`rest`, `soap`, `batch_file`).

### 5.5 Nueva Tabla `policy_invitations`

Ver sección 4.3.

### 5.6 Modificaciones al ENUM `payment_method`

```sql
-- Verificar si 'debito_inmediato' necesita agregarse
ALTER TYPE payment_method ADD VALUE IF NOT EXISTS 'debito_inmediato';
```

### 5.7 `CarrierSubmissionPayload` — Campos Adicionales

El payload Dart que se envía a la aseguradora necesita:

```dart
class CarrierSubmissionPayload {
  // Campos existentes...
  final String riderCedula;
  final String riderIdType;
  final String riderFullName;
  final String riderPhone;
  // ...

  // CAMPOS A AGREGAR:
  final DateTime riderDateOfBirth;        // ← NUEVO — requerido para AP/vida
  final String riderEmail;                // ← NUEVO — para entrega de documentos
  final String? frequentDriverName;       // ← NUEVO — si conductor ≠ titular
  final String? frequentDriverIdNumber;   // ← NUEVO
  final String? frequentDriverIdType;     // ← NUEVO ('V'|'E'|'CC')
  final String vehicleUse;               // ← VERIFICAR — ¿ya se pasa?
  final String vehicleSerialMotor;       // ← VERIFICAR — ¿ya se pasa?
}
```

---

## 6. Implicaciones en el Flujo de Emisión de Pólizas

### 6.1 Secuencia Actualizada

El flujo completo de emisión debe quedar así:

```
[Selección de Plan]
        ↓
[Resumen de Cotización]
        ↓
[Método de Pago]  ← agregar Débito Inmediato
        ↓
[Confirmación del Tomador]  ← NUEVO
    ¿Quién conduce frecuentemente?
    → [Yo mismo]  → continúa
    → [Otra persona]  → captura datos del conductor
        ↓
[Pantalla de Emisión — 4 pasos de carga]
    1. Verificando datos del vehículo
    2. Registrando póliza provisional
    3. Guardando referencia de pago
    4. Contactando a la aseguradora...
        ↓
[Resultado: Confirmada / Provisional]
    → Generación PDF + Carnet con QR  ← NUEVO
    → Envío por WhatsApp / Email  ← NUEVO
```

### 6.2 Compatibilidad con Flujo de Broker

Cuando el flujo viene por invitación (broker emitió la póliza previamente):

```
[Deep Link de activación]
        ↓
[Pantalla: "Tu póliza ya fue creada por {brokerName}"]
    → Ver póliza
    → Configurar contactos de emergencia  ← obligatorio
    → Configurar botón de pánico
```

En este caso NO se pasa por selección de plan ni pago (ya fue procesado por el broker).

---

## 7. Nuevos Componentes a Desarrollar

### 7.1 `PolicyCardService` (Dart)
**Prioridad:** Alta
Generación del carnet de póliza (tarjeta pequeña con QR) como PDF/imagen compartible.

### 7.2 Edge Function `send-policy-email`
**Prioridad:** Alta
Envío automático del PDF + carnet al email del rider post-emisión.

### 7.3 Edge Function `verify-policy`
**Prioridad:** Alta
Endpoint público para verificación de QR por policía de tránsito. Devuelve HTML/JSON con validez de la póliza.

### 7.4 Portal Web Broker (Proyecto Separado)
**Prioridad:** Alta (inicio en Sprint 5+)
Aplicación web independiente. Stack sugerido: Next.js (App Router) + Supabase + mismo diseño de marca.

Funcionalidades mínimas:
- Login con código SUDEASEG + OTP
- Gestión de vendedores (multinivel)
- Emisión de pólizas con OCR web (cámara o upload)
- Generación de link de activación para cliente
- Dashboard de pólizas emitidas y comisiones

### 7.5 Módulo de Débito Inmediato (Dart + Edge Function)
**Prioridad:** Media-Alta
Integración con el sistema externo del desarrollador de pagos.

### 7.6 Integración Venemergencia
**Prioridad:** Media
Pendiente definición de protocolo. Se diseñará tras reunión con ellos.

### 7.7 `EmergencyContactsScreen` (Dart)
**Prioridad:** Alta
Pantalla de gestión de múltiples contactos de emergencia (CRUD completo).

---

## 8. Decisiones de Negocio Pendientes

Las siguientes decisiones de negocio **bloquean o condicionan** trabajo de desarrollo:

| # | Decisión | Quién decide | Impacto en App |
|---|----------|-------------|----------------|
| 1 | Cobertura del acompañante: ¿solo titular o titular + acompañante con monto fijo? | F. Angles + Alex | Estructura del `CarrierSubmissionPayload`, copy del plan |
| 2 | Frecuencia de reporte de telemetría al IoT | Thony + Alex | `TelemetryBufferService`, formato de payload |
| 3 | Canal de integración con Venemergencia (API/SMS/Email) | Alex + Venemergencia | Diseño de la Edge Function de notificación |
| 4 | Preguntas pre-cotización para la aseguradora (uso del vehículo, etc.) | F. Angles | Nueva pantalla en flujo de onboarding/emisión |
| 5 | Precio final de los tres planes | F. Angles + Alex | `policy_types` en DB, copy de `ProductSelectionScreen` |
| 6 | Modelo de comisiones para brokers | F. Angles + Alex | Tabla `commissions`, dashboard de broker |
| 7 | Protocolo de verificación QR: ¿app web pública o solo datos raw en QR? | F. Angles + Alex | Diseño del endpoint de verificación |

---

## 9. Plan de Sprints e Issues

> **Leyenda de bloqueos**
> - 🟢 Sin bloqueo — se puede empezar ya
> - 🟡 Bloqueado por decisión de negocio interna
> - 🔴 Bloqueado por respuesta externa (Thony, William, F. Angles, etc.)
>
> **Numeración:** Los sprints 1–3 usaron tickets RS-001 a RS-073. Sprint 4 comienza en RS-074.

---

### Sprint 4 — Núcleo de Venta y Onboarding Simplificado

**Objetivo:** Flujo de venta funcional de punta a punta en la app móvil con los 2 escaneos, listo para prueba con usuarios reales.
**Duración estimada:** 2 semanas

---

#### Bloque 4A — Onboarding (arrancar inmediatamente)

| Ticket | Descripción | Archivos principales | Complejidad | Bloqueo |
|--------|-------------|----------------------|-------------|---------|
| **RS-074** | Rediseño flujo onboarding: eliminar pantallas de Licencia, adaptar router a 2 escaneos (Cédula → Certificado → Dirección → Contactos → Consentimiento) | `router.dart`, `onboarding/` screens | Alta | 🟢 |
| **RS-075** | `CedulaParser` mejorado: detección de orientación, dual-layout fechas (etiqueta arriba/abajo), máscara de región de huella dactilar, filtro de color amarillo (escudo) | `cedula_parser.dart`, `image_preprocessor.dart` (nuevo) | Media | 🟢 |
| **RS-076** | `CarnetParser` → `CertificadoCirculacionParser`: soporte 2 formatos INTT (reciente y antiguo), extraer `vehicleType`, `vehicleBodyType`, `serialNiv`, `seats`; ignorar color, peso, ejes, ID trámite largo | `certificado_circulacion_parser.dart` (nuevo/renombrado) | Alta | 🟢 |
| **RS-077** | Validación cruzada: nombre + cédula coinciden entre los dos documentos; bloquear si `vehicleType ≠ MOTO PARTICULAR` | `cross_validator.dart` (ampliar), confirm screens | Media | 🟢 |
| **RS-078** | Actualizar `OnboardingData`: eliminar `licenciaNumber`, `bloodType`, `drivingCategories`, `licenciaExpiry`; agregar `vehicleType`, `vehicleBodyType`, `serialNiv`, `seats`, `idExpiryDate`, `idIssuedDate` | `onboarding_data.dart`, `onboarding_notifier.dart` | Baja | 🟢 |
| **RS-079** | SQL: `vehicles` table — agregar `vehicle_type`, `vehicle_body_type`, `serial_niv`, `seats`; deprecar `color` como opcional | `RS-079_vehicles_certificado_fields.sql` | Baja | 🟢 |
| **RS-080** | Captura de documentos: agregar opción "Subir archivo" (galería + PDF) junto a "Tomar foto" en todas las pantallas de escaneo | `cedula_scan_screen.dart`, `certificado_scan_screen.dart`, `pubspec.yaml` (`file_picker`) | Baja | 🟢 |
| **RS-081** | Semáforo de confianza OCR: indicador visual por campo (verde ≥ 0.90 / ámbar 0.75–0.89 / rojo < 0.75) en confirm screens | `cedula_confirm_screen.dart`, `certificado_confirm_screen.dart` | Media | 🟢 |
| **RS-082** | Pantalla de reintento con guía contextual (tips de foto) cuando confianza global < 0.60; opción de ingreso manual | Ambas scan screens | Baja | 🟢 |
| **RS-083** | Listas predefinidas en `CertificadoConfirmScreen`: dropdown de marca (20+ marcas), dropdown de modelo filtrado por marca, chips de tipo carrocería, year picker | `certificado_confirm_screen.dart`, `assets/data/vehicle_brands.json` (nuevo) | Media | 🟢 |
| **RS-084** | Assets JSON de estados y municipios venezolanos (datos fijos, sin request); dropdown en cascada en `AddressScreen` | `assets/data/estados_municipios.json` (nuevo), `address_screen.dart` | Media | 🟢 |
| **RS-085** | Geolocalización en `AddressScreen`: botón "Detectar ubicación", reverse geocoding → pre-llena estado/municipio; guardar lat/lon; SQL `profiles` — agregar `latitude`, `longitude`, `address_from_gps` | `address_screen.dart`, `RS-085_profiles_geo.sql` | Media | 🟢 |
| **RS-086** | Autocompletado de urbanización: `ilike` search en Supabase filtrado por municipio seleccionado | `address_screen.dart`, tabla `urbanizaciones` (nueva o en `reference_data`) | Baja | 🟢 |
| **RS-087** | Campo "conductor frecuente": pregunta post-CertificadoConfirm, captura de nombre + cédula si ≠ titular; SQL `policies` — agregar `frequent_driver_name`, `frequent_driver_id`, `frequent_driver_id_type` | nueva pantalla `frequent_driver_screen.dart`, `RS-087_policies_conductor_frecuente.sql` | Media | 🟡 Decisión #1 |

---

#### Bloque 4B — Datos del Rider y Contactos

| Ticket | Descripción | Archivos principales | Complejidad | Bloqueo |
|--------|-------------|----------------------|-------------|---------|
| **RS-088** | SQL + migración: nueva tabla `emergency_contacts` (N por perfil), deprecar campos planos `emergency_contact_*` en `profiles`; RLS | `RS-088_emergency_contacts.sql` | Baja | 🟢 |
| **RS-089** | `EmergencyContactsScreen`: lista con add/edit/delete, al menos 1 obligatorio, badge de alerta si vacío | `emergency_contacts_screen.dart` (nuevo), `profile_screen.dart` | Media | 🟢 |
| **RS-090** | Importar contacto desde agenda del teléfono (`flutter_contacts`) en formulario de contacto de emergencia | `emergency_contacts_screen.dart`, `pubspec.yaml` | Baja | 🟢 |
| **RS-091** | Separar `full_name` en `first_name` + `last_name` en DB y UI; SQL ALTER + migración de datos existentes | `RS-091_profiles_name_split.sql`, `OnboardingData`, `ProfileRepository` | Media | 🟢 |
| **RS-092** | Auto-fill de teléfono desde sesión OTP (`auth.currentUser.phone`) en formularios de pago y contacto | `payment_method_screen.dart`, `emergency_contacts_screen.dart` | Baja | 🟢 |

---

#### Bloque 4C — Integración IoT REST (Quasar Infotech)

| Ticket | Descripción | Archivos principales | Complejidad | Bloqueo |
|--------|-------------|----------------------|-------------|---------|
| **RS-093** | `IotApiClient` (abstract) + `StubIotClient` (confirma siempre, simula `policyNumber`, `iot_card_url`, `pairing_code`) | `iot_api_client.dart` (nuevo) | Media | 🟢 |
| **RS-094** | Capa de normalización/mapeo: placa sin guiones, `plan_tier` a código Thony, `bank_code` 4 dígitos, `first_name`/`last_name` split | `iot_payload_mapper.dart` (nuevo) | Baja | 🟢 |
| **RS-095** | Agregar `bank_code` (4 dígitos) a lista de bancos en `PaymentMethodScreen`; SQL `payments` — agregar columna `bank_code` | `payment_method_screen.dart`, `RS-095_payments_bank_code.sql` | Baja | 🟢 |
| **RS-096** | SQL: `policies` — agregar `iot_card_url`, `iot_pdf_url`, `iot_transaction_id`, `iot_pairing_code`; actualizar `PolicyDetailModel` | `RS-096_policies_iot_fields.sql`, `policy_detail_model.dart` | Baja | 🟢 |
| **RS-097** | Mostrar docs de Thony en app: si `iot_card_url` disponible, usar como carnet; si `iot_pdf_url`, usar como PDF primario; local como fallback | `policy_detail_screen.dart` | Baja | 🟢 |
| **RS-098** | `QuasarInfotechClient` — implementación real: POST `issue_policy`, parsear respuesta, manejar errores | `quasar_infotech_client.dart` (nuevo) | Alta | 🔴 Thony: `kyc_document_id` flow |
| **RS-099** | Flujo de subida de documentos al KYC de Thony → obtener `kyc_document_id` antes de llamar `issue_policy` | nuevo step en `emission_screen.dart` o nuevo service | Alta | 🔴 Thony: endpoint KYC |
| **RS-100** | Pantalla de emparejamiento de dispositivo post-emisión: mostrar `pairing_code`, estado `pending`/`paired` | `device_pairing_screen.dart` (nuevo) | Media | 🔴 Thony: ¿qué dispositivo? |
| **RS-101** | `PolicyCardService` — generar carnet propio con QR de verificación (solo si Thony no provee QR) | `policy_card_service.dart` (nuevo) | Alta | 🔴 ¿Carnet Thony tiene QR? |
| **RS-102** | Edge Function `verify-policy` — endpoint público para escaneo QR policial | `supabase/functions/verify-policy/index.ts` (nuevo) | Media | 🔴 Ídem RS-101 |

---

#### Bloque 4D — Pagos y Entrega

| Ticket | Descripción | Archivos principales | Complejidad | Bloqueo |
|--------|-------------|----------------------|-------------|---------|
| **RS-103** | Agregar `date_of_birth` + `email` a `IotPolicyRequest` / `CarrierSubmissionPayload` | `iot_api_client.dart`, `carrier_api_client.dart` | Baja | 🟢 |
| **RS-104** | Validación en tiempo real del formato de placa (regex) mientras el usuario edita en confirm screen | `certificado_confirm_screen.dart` | Baja | 🟢 |
| **RS-105** | Entrega post-emisión: botón "Compartir por WhatsApp" abre share sheet con PDF adjunto | `emission_screen.dart` | Baja | 🟢 |
| **RS-106** | Débito Inmediato — tercer tab en `PaymentMethodScreen`; integración con API del dev externo | `payment_method_screen.dart`, nuevo service | Alta | 🔴 Dev externo (F. Angles) |

---

### Sprint 5 — Portal Broker (MVP)

**Objetivo:** Vareca puede emitir pólizas desde la web y enviar link de activación al cliente final.
**Prerequisito:** RS-098 completado (cliente real IoT).
**Duración estimada:** 2 semanas

| Ticket | Descripción | Complejidad | Bloqueo |
|--------|-------------|-------------|---------|
| **RS-107** | Scaffold Next.js portal broker (App Router, Supabase Auth, diseño RuedaSeguro) | Baja | 🟢 |
| **RS-108** | Auth con código SUDEASEG + OTP (validación de código ante registro interno) | Media | 🟢 |
| **RS-109** | OCR web: upload cédula + certificado → extracción de campos usando Google Cloud Vision o Tesseract.js | Alta | 🟢 |
| **RS-110** | Flujo de emisión web con `IotApiClient` (real) — mismo payload que app móvil | Alta | 🔴 RS-098 |
| **RS-111** | SQL + Edge Function: tabla `policy_invitations` (token único, phone, policy_id, claimed_at) | Media | 🟢 |
| **RS-112** | Generación y envío de link de activación por WhatsApp + SMS tras emisión | Media | 🟢 |
| **RS-113** | Deep link en app móvil: detectar token en URL → asociar `policy_invitation` al perfil del rider post-OTP | Media | 🟢 |
| **RS-114** | Dashboard broker básico: lista de pólizas emitidas, estados, fechas de vencimiento | Media | 🟡 |
| **RS-115** | Comisiones: registro por póliza emitida, resumen por broker/vendedor | Alta | 🟡 Modelo de negocio pendiente |
| **RS-116** | Gestión multinivel: broker crea vendedores, vendedores emiten pólizas bajo el broker | Alta | 🟡 Modelo de negocio pendiente |

---

### Sprint 6 — Telemetría, Servicios y Notificaciones

**Objetivo:** Plan Plus/Ampliada completamente funcional: sensores, MQTT, Venemergencia, push notifications.
**Prerequisito:** Respuestas de Thony sobre MQTT (reunión 01/04).
**Duración estimada:** 2 semanas

| Ticket | Descripción | Complejidad | Bloqueo |
|--------|-------------|-------------|---------|
| **RS-117** | `MqttService`: connect, reconexión exponencial, `publishTelemetry()`, `publishEmergency()`, `publishPresence()` | Alta | 🔴 Thony: broker URL + credenciales + topics |
| **RS-118** | Activar `sensors_plus`: acelerómetro + giroscopio + GPS; loop de muestreo según frecuencia acordada con Thony | Media | 🔴 RS-117 + frecuencia acordada |
| **RS-119** | `TelemetryBufferService` → upload MQTT en background; apagado graceful al cerrar app | Media | 🔴 RS-117 |
| **RS-120** | Botón de pánico → notifica a todos los `emergency_contacts` (SMS/WhatsApp) + dispara integración Venemergencia | Media | 🔴 RS-088 + RS-121 |
| **RS-121** | Integración Venemergencia: canal TBD (API/SMS/webhook según reunión con Alex) | Alta | 🔴 Reunión con Venemergencia |
| **RS-122** | Email transaccional: Edge Function `send-policy-email` con PDF + carnet post-emisión (Resend o SendGrid) | Media | 🟡 Elección de proveedor |
| **RS-123** | Push notifications post-confirmación de póliza y recordatorio de renovación (Firebase) | Media | 🔴 `google-services.json` + `GoogleService-Info.plist` |
| **RS-124** | `AcselSirwayClient` — implementación real del carrier Seguros Pirámide | Alta | 🔴 William: sandbox + docs |
| **RS-125** | `SegurosCaracasClient` + `SeguroseMercantilClient` | Alta | 🔴 Docs de API externos |

---

## 10. Dependencias Externas Identificadas

| Dependencia | Proveedor | Estado | Urgencia | Acción requerida |
|-------------|-----------|--------|----------|------------------|
| **`kyc_document_id` — endpoint de KYC** | Thony (Quasar Infotech) | ❓ Desconocido | 🔴 Bloqueante Sprint 4C | Responder mensaje enviado |
| **Dispositivo físico (`pairing_code`)** | Thony | ❓ Desconocido | 🔴 Bloqueante Sprint 4C | Responder mensaje enviado |
| **QR en carnet de Thony** | Thony | ❓ Desconocido | 🔴 Bloqueante `PolicyCardService` | Responder mensaje enviado |
| **Mapeo completo de `plan_tier`** | Thony | ❓ Desconocido | 🔴 Sprint 4C | Responder mensaje enviado |
| **MQTT broker URL + credenciales + topics** | Thony | ⏳ Pendiente reunión miércoles | 🟠 Sprint 6 | Reunión del 01/04 |
| Débito Inmediato — API docs | Dev externo (vía F. Angles) | No iniciado | 🟠 Sprint 4D | F. Angles pone en contacto |
| Flujo de ventas documentado punta a punta | F. Angles + Alex | Prometido para miércoles 01/04 | 🟠 Sprint 4 | Esperar entrega |
| Acceso al sistema Vareca (demo F. Angles) | F. Angles | ✅ Prometido | 🟡 Referencia | F. Angles crea usuario |
| API Acsel/Sirway (Seguros Pirámide real) | William | En progreso desde Sprint 3 | 🟡 Sprint 6 | Seguimiento a William |
| API Seguros Caracas | Seguros Caracas | Disponible, sin docs | 🟡 Sprint 6 | Solicitar documentación |
| API Seguros Mercantil | Seguros Mercantil | Disponible, sin docs | 🟡 Sprint 6 | Solicitar documentación |
| Venemergencia — canal de integración | Operador (vía Alex) | No contactado | 🟡 Sprint 6 | Alex gestiona reunión |
| Firebase (Push Notifications) | Google | Pendiente desde RS-065 | 🟡 Sprint 6 | Configurar `google-services.json` + `GoogleService-Info.plist` |

---

## Apéndice: Comparativa Estado Actual vs. Estado Requerido

| Componente | Estado Actual (post-Sprint 3) | Estado Requerido (post-reunión) | Gap |
|------------|------------------------------|--------------------------------|-----|
| **Flujo de onboarding** | **3 escaneos: Cédula + Licencia + Carnet** | **2 escaneos: Cédula + Certificado de Circulación** | **Rediseño de screens y parsers** |
| `CarnetParser` | Parsea Carnet de Circulación básico | Parsea Certificado INTT (2 formatos: reciente y antiguo) | Extender parser, renombrar |
| Validación tipo vehículo | No existe | Bloquear si no es `MOTO PARTICULAR` | Nueva validación en confirm screen |
| Licencia de Conducir | Escaneo activo, datos en `OnboardingData` | **ELIMINADO** del flujo | Eliminar screens + campos |
| `OnboardingData` — campos licencia | `licenciaNumber`, `bloodType`, `drivingCategories`, `licenciaExpiry` | Eliminados | Limpiar modelo |
| Campos del Certificado nuevos | `plate`, `brand`, `model`, `year`, `color` | + `vehicleType`, `vehicleBodyType`, `serialNiv`, `seats` | Ampliar modelo + tabla vehicles |
| Dirección en onboarding | Campos de texto manual | Geolocalización + edición manual | Nuevo feature |
| Contactos de emergencia | 1 contacto, campos planos en `profiles` | N contactos, tabla `emergency_contacts` | Migración + UI |
| DOB en payload carrier | No incluido | Incluido obligatoriamente | Modificar `CarrierSubmissionPayload` |
| Conductor frecuente | No contemplado | Pregunta + captura de datos si ≠ titular | Nueva pantalla |
| Carnet con QR | No existe | Generación + entrega automática | Nuevo servicio |
| Entrega de documentos | Solo descarga local en app | WhatsApp + Email | Nuevos canales |
| Canal de pago | Pago Móvil + Transferencia | + Débito Inmediato | Nuevo método |
| Multi-carrier | Stub Pirámide | Pirámide + Caracas + Mercantil | 2 nuevos clientes |
| Canal broker | No existe | Portal web separado | Nuevo proyecto |
| Canal POS | No existe | Integración Biopago (separado) | Nuevo proyecto |
| Venemergencia | Mencionado en planes, sin integración | Integración funcional en Plus/Ampliada | Nueva integración |
| Pánico multi-contacto | No implementado | Envío a todos los contactos | Depends en emergency_contacts |
| Telemetría | Buffer local 15min | Upload MQTT al IoT de Thony | Sprint 6 — pendiente broker MQTT |
| **IoT REST API (Thony)** | **No existe** | **`IotApiClient` + `QuasarInfotechClient`** | **Sprint 4C — bloqueado en partes** |
| **`kyc_document_id`** | **No existe** | **Subida de documentos a KYC API de Thony** | **Bloqueante — respuesta pendiente** |
| **Dispositivo físico (`pairing_code`)** | **No contemplado** | **Pantalla de emparejamiento post-emisión** | **Bloqueante — respuesta pendiente** |
| **Documentos de Thony (card + PDF)** | **Generados localmente** | **URLs de Thony como primario, local como fallback** | **Sprint 4C** |
| **Códigos de banco (4 dígitos)** | **Solo nombres en texto** | **`bank_code` en dropdown y tabla `payments`** | **Sprint 4C — desbloqueado** |
| **`first_name` / `last_name` separados** | **`full_name` unificado en `profiles`** | **Dos campos separados (requerido por IoT payload)** | **Sprint 4B — desbloqueado** |
| **Mapeo de `plan_tier`** | **`basica`/`plus`/`ampliada`** | **+ equivalente Thony (`comprehensive_plus`, etc.)** | **Pendiente respuesta Thony** |
