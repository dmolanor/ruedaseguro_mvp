Aquí está el análisis completo del proceso de compra de póliza RCV en **portal.bareca.com** (versión 1.0.6 — 29/04/2026):

---

## 🏢 Plataforma General

**Bareca** es un portal de venta digital de pólizas RCV (Responsabilidad Civil Vial) para Venezuela. La aplicación es una SPA desarrollada en **Angular 20**, con **4 pasos lineales** obligatorios (wizard), estado persistido en `localStorage` con la clave `policyAppFormState`, y una barra lateral de **Resumen de Solicitud** siempre visible que muestra: Plan seleccionado, precio, vehículo, Tasa BCV y Total a pagar en Bs.

El soporte al cliente está disponible por **WhatsApp** (`+58 424 347 3119`). El sitio maneja **transacción encriptada** y muestra el sello de "Compra Segura".

---

## 🗺️ UJM — User Journey Map (4 Pasos)

```
[Paso 1: Cotización]  →  [Paso 2: Datos del Cliente y Vehículo]  →  [Paso 3: Conductor]  →  [Paso 4: Pago]
     ✓ completado           actual → requiere verificación OTP             frequentDriverType             método de pago
```

El usuario solo puede avanzar al siguiente paso cuando completa correctamente el actual. Existe un botón **"Reiniciar"** con confirmación modal que borra todo el estado. Al completar el proceso se ofrecen dos salidas: "Finalizar y volver al inicio" o "Finalizar y Volver al Dashboard" (para clientes registrados), y se entregan: **Carnet de RCV**, **Póliza** y **Contrato de Servicio**.

---

## 📋 PASO 1 — Cotización ("Cotiza y Elige tu Plan")

### Campos de clasificación del vehículo

**Clase de Vehículo** (dropdown obligatorio — 9 opciones):

- Autobuses
- Carga (A)
- Minibuses
- Moto Carros
- Otras Máquinas
- Otros Vehículos
- **Particulares** ← la más común
- Tracción Sangre
- Vehículos Rústicos de doble tracción
- Vehículos Rutas Foráneas

**Grupo de Vehículo** (dropdown dependiente de la clase — ejemplo para "Particulares"):

- Alquiler sin chofer, Taxi o Por puesto
- Alquiler sin chofer
- Más de 800 Kg de peso
- **Hasta 800 Kg de peso**
- Auto Escuela

**Tipo de Placa** (dropdown):

- Nacional
- Internacional (Extranjera)

### Información Adicional de Riesgo (3 toggles — ajustan el precio)

Estos toggles vienen de la API como preguntas dinámicas (`question_[UUID]`), con los siguientes textos completos:

1. Para vehículos destinados al transporte de materiales **inflamables, corrosivos, tóxicos o explosivos**
2. Para vehículos pertenecientes a **cuerpos policiales, bomberos, servicios de ambulancia, empresas de seguridad o de transporte de fondos**
3. Para vehículos de cualquier grupo que **remolquen, de manera ocasional o habitual embarcaciones, motocicletas, casas rodantes, equipos deportivos, vehículos de competición y otros remolques**

### Cobertura Adicional Opcional

**Cobertura a Ocupantes (APOV):** checkbox que activa protección adicional para pasajeros (gastos médicos, invalidez y rescate). El precio se calcula automáticamente en base a la **Cantidad de Puestos** del vehículo.

### Resultado: Los Planes

Tras hacer clic en **"Cotizar Planes"** aparecen tarjetas de plan. En el ejemplo de "Particulares / Hasta 800 Kg de peso" se ofrecieron **2 planes** (ambos de **Seguros Caroní**):

| Concepto                    | Plan EUR          | Plan USD       |
| --------------------------- | ----------------- | -------------- |
| Aseguradora                 | Seguros Caroní    | Seguros Caroní |
| Moneda                      | EUR (TCR)         | USD            |
| Suma Asegurada Cosas        | 2.000,00 EUR      | 2.320,34 USD   |
| Suma Asegurada Personas     | 2.505,00 EUR      | 2.906,23 USD   |
| Prima Anual                 | **TCR 33,00 EUR** | **103,62 USD** |
| Equivalente en Bs.          | Bs. 18.802,08     | Bs. 50.475,37  |
| Tasa BCV aplicada           | 569,76            | 487,12 (USD)   |
| Servicio adicional incluido | —                 | **Grúa** ✅    |

Las aseguradoras disponibles en el sistema son **Seguros Caroní** (`CARONI`) y **Estar Seguros** (`ESTARSEGUROS`), dependiendo del tipo de vehículo y grupo seleccionado. Los precios se expresan en la moneda original del plan y siempre se muestran convertidos a Bolívares a la tasa BCV actualizada en tiempo real, con fecha y hora de la última actualización.

Una vez cotizado, el botón cambia a **"Actualizar Cotización"** para modificar parámetros.

---

## 👤 PASO 2 — Datos del Cliente y Vehículo

El paso tiene dos modos de entrada:

- **Cliente Nuevo** (formulario completo)
- **Cliente Registrado** (búsqueda por cédula para pre-llenar datos)

El formulario se organiza en **dos secciones colapsables**:

### Sección 1: Datos del Tomador y Contacto

**Documentos a cargar (OCR):**

- Documento de Identidad (foto drag & drop o clic para buscar — la app procesa con IA: "Datos recuperados mediante IA")
- Carnet de Circulación (foto drag & drop)

**Información de Identidad:**

- Nombres
- Apellidos
- Cédula / RIF (formato validado: `V12345678`, `E-`, `J-` — con validaciones `invalidVenezuelanId`)
- Estado (dropdown con los 24 estados + Dependencias Federales + Distrito Capital)
- Ciudad (dropdown dependiente del estado seleccionado)

**Verificación de Contacto** (ambos campos requieren validación OTP antes de avanzar):

- Correo Electrónico → botón "Validar" → envía código → se confirma con PIN
- Teléfono Celular → botón "Validar" → validación de formato venezolano (`invalidVenezuelanPhone`)

### Sección 2: Datos del Vehículo

**Información Técnica:**

- Placa (ej: `ABC123D`)
- Año (ej: `2024`)
- Marca (ej: `TOYOTA`)
- Modelo (ej: `COROLLA`)
- Tipo (ej: `PARTICULAR`)
- Uso (ej: `PASEO`)
- Color
- Serial NIV (con botón "Copiar NIV" al motor)
- Serial Motor
- Peso (Kg)
- Ejes
- Puestos

**Propietario del Vehículo** (si difiere del tomador):

- Nombres (Titular)
- Apellidos (Titular)
- Cédula / RIF (Titular)

El sistema valida incompatibilidades entre el tipo de vehículo registrado y el plan seleccionado (ej: si el peso excede el límite del grupo, si es moto y el plan no aplica, etc.).

---

## 🚗 PASO 3 — Conductor Frecuente

El usuario elige **quién es el conductor frecuente** del vehículo mediante un selector de tipo (`frequentDriverType`):

- **Tomador de la Póliza** (el mismo que contrató)
- **Titular del Vehículo** (el dueño registrado)
- **Otra Persona** → activa el formulario de "Datos del Conductor Adicional":
  - Cédula / RIF del Conductor (con búsqueda automática en el sistema)
  - Nombres del conductor
  - Apellidos del conductor

Si el conductor es "Otra Persona", el sistema busca la cédula en su base de datos para pre-llenar. El nombre del paso es oficialmente **"Paso 3: Conductor Frecuente"**.

---

## 💳 PASO 4 — Pago

El sistema ofrece múltiples métodos de pago, identificados en el código como:

| Código interno                          | Nombre mostrado  | Descripción                                                                                                         |
| --------------------------------------- | ---------------- | ------------------------------------------------------------------------------------------------------------------- |
| `C2P` / `PAGO_MOVIL`                    | **Pago C2P**     | Pago Móvil Interbancario C2P — desde la app bancaria del usuario, con selección de Banco Emisor y datos del titular |
| `DEBITO` / `PLAZA`                      | **Débito Plaza** | Pago con tarjeta de débito a través de Banco Plaza                                                                  |
| `PAGOLISTO`                             | **Pago Listo**   | Pasarela PagoListo                                                                                                  |
| `EXTERNAL_WALLET` / `AVILACASH/NEVACOM` | **Avila Cash**   | Billetera digital Avila Cash (NEVACOM)                                                                              |
| `AUTOGESTION`                           | **Autogestión**  | Aparece en el código como método alternativo (posiblemente para distribuidores/kioscos)                             |

Para el método **Pago C2P** se recopilan: banco emisor (selector de bancos), datos del titular de la cuenta, número de teléfono celular bancario. El sistema luego redirige a la app bancaria, pollea el estado de la transacción en tiempo real por WebSocket, y maneja múltiples estados: `EN_PROCESO`, `PENDIENTE`, `APROBADA`, `PAGADA`, `PAGO_MOVIL_RECHAZADO`, `POLLING_TIMEOUT`.

Los errores bancarios manejados incluyen: saldo insuficiente, monto excede límite diario, formato de monto incorrecto con decimales, sistema fuera de franja horaria, firma digital vencida, cobro no permitido para el tipo de cuenta, entre otros.

El pago siempre se muestra como **"Total a Debitar"** en Bs. calculado a tasa BCV en tiempo real.

---

## 🔑 Puntos Clave de Diseño

- **Tasa BCV en tiempo real:** todos los precios en moneda extranjera (EUR/USD) se convierten automáticamente a Bolívares.
- **OCR con IA:** los documentos de identidad y carnet de circulación se procesan automáticamente para pre-llenar datos.
- **Verificación OTP doble:** tanto correo como teléfono requieren validación por código antes de avanzar.
- **Estado en localStorage:** todo el progreso se guarda en `policyAppFormState` y `policyAppCurrentStep`, permitiendo al usuario retomar si cierra el navegador.
- **Validaciones en tiempo real:** cédula venezolana, teléfono venezolano, formato de placa, compatibilidad plan-vehículo.
- **WebSocket en el pago:** el estado de la transacción se monitorea en tiempo real con polling via socket (ODT).
- **Modo pruebas activo:** el código muestra el label "MODO PRUEBAS:" en el paso de pago, indicando que existe un entorno sandbox.
