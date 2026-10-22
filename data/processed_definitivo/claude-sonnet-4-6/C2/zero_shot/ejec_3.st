# Análisis de Requisitos – Control de Bomba de Pozo

---

## 1. Tabla de Entradas y Salidas

### Entradas (Inputs)

| Nombre | Tipo IEC 61131-3 | Descripción |
|---|---|---|
| `LS_TANK_EMPTY` | `BOOL` | Sensor de nivel bajo del tanque superior (TRUE = tanque vacío → solicita arranque) |
| `LS_WELL_DRY` | `BOOL` | Sensor de nivel bajo del pozo (TRUE = pozo sin agua → bloquea arranque) |
| `PB_STOP` | `BOOL` | Pulsador de paro manual (TRUE = operador solicita detener la bomba) |
| `LS_TANK_FULL` | `BOOL` | Sensor de nivel alto del tanque superior (TRUE = tanque lleno → detiene la bomba) |
| `CB_FAULT` | `BOOL` | Contacto auxiliar del guardamotor / disyuntor (TRUE = falla eléctrica detectada) |

### Salidas (Outputs)

| Nombre | Tipo IEC 61131-3 | Descripción |
|---|---|---|
| `M_PUMP` | `BOOL` | Bobina del contactor de la bomba (TRUE = bomba en marcha) |
| `AL_FAULT_LAMP` | `BOOL` | Lámpara / piloto de alarma (TRUE = condición anormal activa) |

---

## 2. Tipo de POU Recomendado

**`FUNCTION_BLOCK`**

**Justificación:**
El control requiere **memoria de estado** (la bomba debe mantenerse encendida o apagada entre ciclos de scan, y la alarma debe retenerse aunque la falla sea transitoria), lo cual es la característica definitoria de un Function Block frente a una FUNCTION. Se recomienda sobre un PROGRAM porque encapsular la lógica en un FB permite **reutilizarlo** si el cliente tiene más de un pozo, facilita las pruebas unitarias y mantiene el PROGRAM principal limpio como orquestador. El PROGRAM principal simplemente instanciará el FB y conectará las variables físicas de E/S.

---

## 3. Ambigüedades e Información Faltante

1. **Condición de llenado del tanque:** ¿Cuándo debe *detenerse* la bomba? El cliente solo menciona cuándo arrancar (tanque vacío), pero no define el nivel de parada. ¿Existe un sensor de tanque lleno o se para solo con el botón manual?

2. **Naturaleza del sensor de pozo seco:** ¿El sensor indica nivel bajo de forma continua o es un interlock de protección que requiere reconocimiento (reset) manual antes de permitir un nuevo arranque?

3. **Comportamiento del pulsador de paro:** ¿El paro manual es temporal (la bomba puede volver a arrancar sola en el siguiente ciclo si el tanque sigue vacío) o debe bloquearse hasta que el operador lo rearme explícitamente?

4. **Condiciones que activan la lámpara de alarma:** ¿La alarma enciende solo por pozo seco, o también por falla eléctrica del motor (sobrecarga, disyuntor disparado)? ¿Debe incluir una alarma sonora además de la visual?

5. **Reconocimiento (ACK) de alarma:** ¿La lámpara se apaga sola cuando desaparece la causa, o requiere que el operador la reconozca con un botón?

6. **Protección eléctrica del motor:** ¿Existe guardamotor o relé térmico cuya señal deba integrarse al PLC como entrada de falla?

7. **Retardos de tiempo:** ¿Se requiere un retardo al arranque (anti-golpe de ariete), un tiempo mínimo de funcionamiento o un tiempo mínimo de parada entre arranques consecutivos?

8. **Modo de operación:** ¿Se contempla un selector Manual/Automático, o la operación es siempre automática con solo el paro de emergencia?

9. **Tipo de señal de los sensores:** ¿Los sensores de nivel son digitales (flotador, electrodo) o analógicos (presión, ultrasonido con umbral configurable)?

10. **Requisitos de registro o HMI:** ¿Se necesita llevar conteo de horas de funcionamiento, historial de alarmas o visualización en pantalla?