# Análisis de requisitos: Control de bomba de pozo

---

## 1. Tabla de entradas y salidas propuestas

| # | Nombre | Dirección sugerida | Tipo IEC 61131-3 | Descripción |
|---|--------|--------------------|------------------|-------------|
| **ENTRADAS** |
| 1 | `sensorTanqueVacio` | `%IX0.0` | `BOOL` | Sensor de nivel bajo del tanque superior (TRUE = tanque vacío) |
| 2 | `sensorPozoSinAgua` | `%IX0.1` | `BOOL` | Sensor de nivel mínimo del pozo (TRUE = pozo sin agua) |
| 3 | `btnParo` | `%IX0.2` | `BOOL` | Botón de paro manual de la bomba |
| **SALIDAS** |
| 4 | `bomba` | `%QX0.0` | `BOOL` | Activación del contactor/variador de la bomba del pozo |
| 5 | `luzFalla` | `%QX0.1` | `BOOL` | Piloto de aviso de condición anormal |

---

## 2. Tipo de POU recomendado

**FUNCTION_BLOCK**

**Justificación:** El control de la bomba requiere conservar estado interno entre ciclos de scan (por ejemplo, el enclavamiento de marcha, el historial de fallas o el tiempo de funcionamiento). Un `FUNCTION` no retiene estado y un `PROGRAM` es menos reutilizable; el `FUNCTION_BLOCK` permite instanciar el mismo bloque para varios pozos o tanques si la instalación crece, y encapsula correctamente la lógica con su memoria propia.

---

## 3. Ambigüedades e información faltante a aclarar con el cliente

1. **Lógica de los sensores:** ¿Los sensores de nivel son normalmente abiertos o normalmente cerrados? ¿El sensor activa la señal cuando *detecta* agua o cuando *no* la detecta? Esto es crítico para no invertir la lógica de protección.

2. **Condición de "tanque lleno":** ¿Existe un sensor de nivel alto del tanque superior para detener la bomba cuando el tanque se llene, o solo hay sensor de nivel bajo?

3. **Rearranque tras paro manual:** Después de pulsar el botón de paro, ¿la bomba debe volver a arrancar automáticamente cuando el tanque vuelva a estar vacío, o se requiere un botón de marcha manual para reanudar?

4. **Qué condiciones activan la luz de falla:** ¿Solo el pozo sin agua, o también otras situaciones como sobrecarga del motor, paro de emergencia o falla de sensor?

5. **Protección por sobrecarga:** ¿El PLC recibirá la señal de disparo del relé térmico o guardamotor? ¿Debe incluirse en la lógica de enclavamiento y de falla?

6. **Temporización de arranque:** ¿Se requiere un retardo antes de arrancar (para evitar arranques por falsas lecturas del sensor) o un tiempo mínimo de funcionamiento antes de permitir el paro automático?

7. **Reconocimiento de falla:** ¿La luz de falla debe apagarse sola cuando desaparece la causa, o requiere un botón de reconocimiento (reset) manual?

8. **Tipo de botón de paro:** ¿Es un pulsador momentáneo (normalmente abierto) o un selector con enclavamiento mecánico? ¿Debe funcionar como parada de emergencia certificada o es solo un paro operativo?