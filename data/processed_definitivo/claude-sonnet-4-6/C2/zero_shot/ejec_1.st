# Análisis de Requisitos – Control de Bomba de Pozo

---

## 1. Tabla de Entradas y Salidas

### Entradas (Inputs)

| Nombre | Tipo IEC 61131-3 | Descripción |
|---|---|---|
| `LS_TANK_EMPTY` | `BOOL` | Sensor de nivel bajo del tanque superior (TRUE = tanque vacío, solicita arranque) |
| `LS_TANK_FULL` | `BOOL` | Sensor de nivel alto del tanque superior (TRUE = tanque lleno, solicita paro) |
| `LS_WELL_DRY` | `BOOL` | Sensor de nivel mínimo del pozo (TRUE = sin agua, bloquea arranque) |
| `PB_STOP` | `BOOL` | Pulsador de paro manual (NC recomendado, TRUE = paro solicitado) |
| `CB_FAULT` | `BOOL` | Contacto auxiliar del guardamotor / disyuntor (TRUE = falla eléctrica/térmica) |

### Salidas (Outputs)

| Nombre | Tipo IEC 61131-3 | Descripción |
|---|---|---|
| `Q_PUMP` | `BOOL` | Activación del contactor de la bomba (TRUE = bomba en marcha) |
| `Q_ALARM_LIGHT` | `BOOL` | Lámpara de alarma (TRUE = condición anormal presente) |

### Variables Internas sugeridas

| Nombre | Tipo IEC 61131-3 | Descripción |
|---|---|---|
| `PUMP_ENABLED` | `BOOL` | Condición lógica interna que habilita el arranque |
| `FAULT_ACTIVE` | `BOOL` | Bandera interna de falla activa |

---

## 2. Tipo de POU Recomendado

**→ `FUNCTION_BLOCK`**

**Justificación:**
El control de esta bomba requiere **estado interno persistente entre ciclos de scan** (memoria de marcha/paro, retención de fallas, enclavamientos). Un `FUNCTION` no retiene estado. Un `PROGRAM` sería válido, pero un `FUNCTION_BLOCK` es preferible porque:
- Permite **instanciar el mismo bloque** si en el futuro el cliente agrega más pozos o bombas.
- Encapsula la lógica y el estado de forma cohesionada y reutilizable.
- Facilita las pruebas unitarias del bloque de forma aislada.

El `FUNCTION_BLOCK` se instanciaría y llamaría desde un `PROGRAM` principal.

---

## 3. Ambigüedades e Información Faltante

1. **Condición exacta de "tanque vacío":** ¿Se usa un sensor de nivel discreto (flotador/electrodo) o un transmisor analógico con umbral configurable? ¿Hay histéresis entre el punto de arranque y el punto de paro?

2. **Confirmación de arranque vs. señal de marcha:** ¿Se requiere retroalimentación del contactor (contacto auxiliar) para confirmar que la bomba realmente arrancó, o basta con energizar la salida?

3. **Comportamiento ante falla del guardamotor:** ¿La falla debe bloquearse hasta un reset manual del operador, o se permite un rearranque automático una vez que desaparece la falla?

4. **Lógica del pulsador de paro:** ¿El paro manual debe ser momentáneo (el sistema rearranque solo cuando el tanque vuelva a estar vacío) o debe requerir un reset/rearranque manual explícito?

5. **Condición de "pozo sin agua" durante marcha:** Si el pozo se queda sin agua *mientras la bomba ya está corriendo*, ¿debe parar inmediatamente o hay un retardo para evitar disparos por falsas lecturas (p. ej., turbulencia del agua)?

6. **Temporización de arranque:** ¿Se requiere un retardo mínimo entre paros y rearranques (tiempo de espera) para proteger el motor?

7. **Criterio de la luz de alarma:** ¿Qué condiciones exactas la activan? (¿solo pozo seco?, ¿también falla eléctrica?, ¿tanque lleno por demasiado tiempo?) ¿Debe parpadear o encenderse fija? ¿Hay bocina asociada?

8. **Tipo y tensión del motor:** Dato necesario para dimensionar el guardamotor y definir si se requiere arranque suave o estrella-triángulo, lo que afectaría las salidas del PLC.

9. **Acceso remoto o HMI:** ¿Se necesita visualización, registro de eventos o control desde algún panel o sistema SCADA?

10. **Normativa de seguridad aplicable:** ¿Existe algún requisito de nivel de integridad de seguridad (SIL) o categoría de parada que deba cumplirse?