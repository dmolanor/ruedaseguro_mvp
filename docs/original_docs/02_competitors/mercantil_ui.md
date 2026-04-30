## Seguros Mercantil

### Flujo de Solicitud de Atención Médica

**1. Acceso a la sección de emergencias:**

- El flujo comienza al abrir la aplicación, donde se muestra la pantalla de inicio.
- Para iniciar una solicitud, el usuario debe hacer clic en el botón de emergencias situado en la parte inferior de la pantalla.

**2. Selección del tipo de asistencia:**

- Se despliega un menú donde el usuario debe deslizar el botón desde la opción "Atención al cliente" para activar la "Asistencia Médica".
- La aplicación presenta dos opciones: "Llamar a un médico" o "Ir a una clínica".
- En este caso, se selecciona la opción "Ir a una clínica".

**3. Evaluación de la urgencia y geolocalización:**

- La aplicación pide clasificar el "Nivel de urgencia" de la emergencia médica, ofreciendo opciones que van desde "Máxima urgencia" hasta "Muy leve".
- El sistema requiere que se active la geolocalización.
- Esto permite a la app mostrar una lista de las clínicas disponibles de su "Red Segura" que están más cercanas a la ubicación del usuario.

**4. Selección y confirmación de la clínica:**

- El usuario debe seleccionar la clínica específica a la que desea asistir de la lista proporcionada.
- Aparece una pantalla de confirmación con un mapa de la ubicación de la clínica seleccionada y un botón para "Confirmar asistencia".

**5. Identificación del paciente y motivo de ingreso:**

- En la pantalla "Asegurado afectado", la aplicación permite seleccionar si el servicio es para el titular de la póliza o para un beneficiario.
- Luego, se le da al usuario la opción de notificar el motivo del ingreso a la clínica marcando la casilla "Deseo indicar el motivo de la atención médica".
- Al marcarla, se habilita un cuadro de texto para describir los síntomas de la emergencia, como por ejemplo: "Presión en el pecho y sudoración fría.".

**6. Confirmación final:**

- Una vez ingresados los datos, el usuario debe presionar el botón "Confirmo que voy".
- El flujo termina con una pantalla de "Aviso realizado" que confirma el proceso.
- Esta pantalla final muestra la información de la clínica (dirección y teléfono), un mapa, la instrucción de llevar el documento de identidad, y le asegura al usuario que Mercantil Seguros ya sabe que va en camino.
- Finalmente, se indica que la clínica estará esperando para atender al paciente.

## Especificación técnica de las pantallas

### 1. Pantalla de Inicio (Dashboard)

El punto de entrada debe ser accesible y estar siempre visible para el usuario en estado de pánico.

- **Componentes UI:** Barra de navegación inferior (Bottom Navigation Bar) con un botón central de **Emergencias** altamente destacado (suele comportarse como un Floating Action Button o FAB). Tarjetas de resumen de pólizas activas.
- **Estado de la App:** El usuario está autenticado (`is_authenticated: true`). La aplicación ya cargó en caché el perfil del usuario, pólizas activas y beneficiarios.
- **Lógica:** Al presionar el botón central, no se cambia de ruta inmediatamente, sino que se invoca un componente sobrepuesto (Modal o Bottom Sheet) para evitar toques accidentales.

### 2. Modal de Confirmación de Intención (Asistencia Médica)

Diseñado para fricción positiva; asegura que el usuario realmente necesita la asistencia y define el canal.

- **Componentes UI:** Un control deslizante (_Slider_ o _Swipe to confirm_) para desbloquear la acción. Dos botones de enrutamiento principal: "Llamar a un médico" (Telemedicina) e "Ir a una clínica" (Atención presencial).
- **Estado/Datos:** Captura el tipo de canal de atención: `service_channel = 'in_person'`.
- **Lógica:** Al deslizar y seleccionar "Ir a una clínica", se inicializa el objeto de la solicitud de emergencia (`EmergencyClaim`) en el frontend y se navega a la siguiente ruta.

### 3. Pantalla de Triage (Nivel de Urgencia)

- **Componentes UI:** Una lista vertical de opciones tipo _Radio Button_ con títulos claros (Máxima urgencia, Alta, Moderada, Leve) y subtítulos descriptivos para ayudar al usuario a autodiagnosticarse rápidamente.
- **Estado/Datos:** Captura la variable `urgency_level` (ej. `level_1_max`).
- **Lógica (Backend/Frontend):** Este dato es crucial. En el backend, un nivel de "Máxima urgencia" podría omitir ciertos pasos de autorización del seguro o filtrar la lista de clínicas en el siguiente paso para mostrar únicamente aquellas con áreas de trauma de alta complejidad.

### 4. Pantalla de Geolocalización y Directorio (Clínicas)

- **Componentes UI:** Barra de búsqueda (`TextInput`), chips de filtrado por región ("Distrito Capital"), y una lista interactiva (`ListView/RecyclerView`) de clínicas.
- **Estado/Datos:** Requiere permisos de ubicación del SO (`lat`, `long`). Se selecciona el `provider_id` (la clínica).
- **Lógica:**
  - La app hace una petición `GET` al backend: `/api/providers/nearest?lat={x}&long={y}&urgency={urgency_level}&network={user_policy_network}`.
  - El backend cruza la ubicación, el nivel de urgencia y la red de cobertura del usuario para devolver un JSON con las clínicas aplicables ordenadas por proximidad.

### 5. Pantalla de Confirmación de Ruta (Mapa)

- **Componentes UI:** Un componente de mapa (ej. Google Maps SDK) con un marcador (Pin) en la ubicación de la clínica seleccionada. Detalles en texto de la dirección. Botón de "Confirmar asistencia".
- **Estado/Datos:** Validar visualmente la variable `provider_id`.
- **Lógica:** Sirve como punto de confirmación antes de despachar la alerta al proveedor médico.

### 6. Pantalla de Selección de Paciente (Asegurado Afectado)

- **Componentes UI:** Lista de _Radio Buttons_ separando al "Titular" de los "Beneficiarios" (esposa, hijos, etc.), jalando los nombres directamente de la base de datos de la póliza.
- **Estado/Datos:** Captura el `patient_id`.
- **Lógica:** Permite que el titular de la cuenta tramite la emergencia para un dependiente. Esto define contra quién se facturará el siniestro o deducible en el sistema core de la aseguradora.

### 7. Pantalla de Ingreso de Síntomas (Contexto)

- **Componentes UI:** Un _Checkbox_ optativo que, al marcarse, despliega un _TextArea_ para texto libre.
- **Estado/Datos:** Captura `symptoms_description` (String).
- **Lógica:** Este es un paso de valor agregado. Al escribir "Presión en el pecho y sudoración", el sistema empaqueta este string en el payload final.

### 8. Pantalla de Éxito (Aviso Realizado)

- **Componentes UI:** Mensaje de confirmación en verde/azul, resumen de los datos de la clínica (dirección, teléfono), mapa estático de referencia y un recordatorio vital ("Llega con tu documento"). Botón para regresar al inicio.
- **Lógica:**
  - **El momento crítico de la transacción:** Al presionar confirmar en el paso anterior, la app ejecuta un `POST /api/emergencies/dispatch` con el payload completo: `{ patient_id, provider_id, urgency_level, symptoms_description, timestamp }`.
  - El backend de la aseguradora recibe esto, crea un número de caso (`case_id`), y dispara un webhook o notificación al sistema de admisión de la clínica elegida.
  - El frontend recibe el `200 OK` y muestra esta pantalla final, destruyendo el flujo temporal y devolviendo al usuario al estado principal, posiblemente agregando una tarjeta de "Emergencia en curso" en la vista de "Casos".
