# Análisis de Requisitos – Control de Bomba de Pozo

---

## 1. Tabla de Entradas y Salidas

### Entradas (Inputs)

| Nombre | Tipo IEC 61131-3 | Descripción |
|---|---|---|
| `LS_TANK_EMPTY` | `BOOL` | Sensor de nivel bajo del tanque superior (TRUE = tanque vacío, solicita arranque) |
| `LS_TANK_FULL` | `BOOL` | Sensor de nivel alto del tanque superior (TRUE = tanque lleno, solicita paro) |
| `LS_WELL_DRY` | `BOOL` | Sensor de nivel mínimo del pozo (TRUE = sin agua, inhibe arranque) |
| `PB_STOP` | `BOOL` | Pulsador de paro manual (TRUE = operador solicita detener la bomba) |
| `FB_PUMP_FAULT` | `BOOL` | Señal de falla del arrancador/guardamotor de la bomba (TRUE = falla activa) |

### Salidas (Outputs)

| Nombre | Tipo IEC 61131-3 | Descripción |
|---|---|---|
| `Q_PUMP` | `BOOL` | Comando de arranque de la bomba (TRUE = bomba en marcha) |
| `Q_ALARM_LIGHT` | `BOOL` | Luz de alarma/aviso de condición anormal (TRUE = luz encendida) |

---

## 2. Tipo de POU Recomendado

**Recomendación: `FUNCTION_BLOCK`**

**Justificación:**
- El control de la bomba requiere **retención de estado** (la bomba debe permanecer encendida o apagada entre ciclos de scan), lo cual es la característica definitoria de un Function Block frente a una FUNCTION.
- Permite instanciar el mismo bloque si en el futuro el cliente agrega más bombas o pozos, reutilizando la lógica sin duplicar código.
- A diferencia de un `PROGRAM`, el `FUNCTION_BLOCK` es encapsulable, testeable de forma aislada y puede ser llamado desde un `PROGRAM` principal que gestione otras partes de la instalación.

---

## 3. Ambigüedades e Información Faltante

1. **Lógica de los sensores de nivel:** ¿Los sensores son normalmente abiertos (NA) o normalmente cerrados (NC)? ¿El TRUE indica presencia de agua o ausencia? Esto es crítico para no invertir la lógica de seguridad.

2. **Condición de paro por tanque lleno:** El cliente solo mencionó arranque cuando el tanque está vacío, pero no especificó cuándo debe *apagarse* la bomba. ¿Se detiene al detectar nivel alto, por tiempo, o manualmente?

3. **Tipo de pulsador de paro:** ¿El botón de paro es de acción momentánea o de enclavamiento (tipo hongo con retención)? ¿Debe requerir rearme manual para volver a arrancar?

4. **Naturaleza de la "luz de aviso":** ¿Qué condiciones específicas deben activarla? ¿Solo pozo seco, también falla eléctrica, también paro manual? ¿Debe parpadear o permanecer fija?

5. **Protección eléctrica de la bomba:** ¿Existe un guardamotor o arrancador con señal de falla disponible? ¿Debe el PLC leer esa falla y bloquear el rearme automático?

6. **Rearme tras condición de falla:** Cuando el pozo recupera nivel o se corrige una falla, ¿la bomba debe arrancar automáticamente o esperar confirmación manual del operador?

7. **Retardo en el arranque:** ¿Se requiere un tiempo de espera antes de arrancar (para proteger la bomba de arranques frecuentes) o antes de declarar el pozo como seco?

8. **Fuente de alimentación y modo de falla:** Si el PLC pierde energía o comunicación, ¿la bomba debe quedar encendida o apagada por seguridad (fail-safe state)?