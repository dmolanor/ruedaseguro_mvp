## RS-XXX: [Título de la Tarea]

### 🎯 Goal-Driven Execution

- **Problema:** [Breve descripción de qué se está resolviendo]
- **Criterio de Éxito:** [Cómo sabemos que funciona - ej: "El test de OCR ahora lee cédulas con fondo oscuro"]

### 🛠️ Cambios Realizados

- [ ] Implementación de...
- [ ] Cleanup de orphans (imports/variables no usados creados en esta PR)
- [ ] Actualización de documentación (si aplica)

### ✅ Checklist de Calidad (Reset Plan)

- [ ] **Surgicality:** ¿Los cambios tocan solo lo necesario?
- [ ] **Simplicity:** ¿Es esta la solución más simple posible?
- [ ] **Verification:** `flutter analyze` y `flutter test` pasan localmente.
- [ ] **Reproduce First:** (Para bugfixes) Se incluyó un test que fallaba antes del fix.
- [ ] **Gstack Skills:**
  - [ ] Se ejecutó `/review` en el diff.
  - [ ] Se ejecutó `/cso` (si toca Auth/Payments/RLS/Secrets).
  - [ ] Se ejecutó `/plan-eng-review` (si hay cambios de arquitectura o DB).

### 🔒 Seguridad y Privacidad

- [ ] No se incluyen secretos ni API keys.
- [ ] No se loguea PII (Cédulas, nombres, teléfonos).
- [ ] Se verificaron las políticas RLS de Supabase.

---

_Powered by Karpathy Protocol & RuedaSeguro Reset Plan_
