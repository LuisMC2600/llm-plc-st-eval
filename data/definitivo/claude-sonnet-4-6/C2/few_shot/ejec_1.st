# Análisis de requisitos: Control de bomba de pozo

---

## 1. Tabla de entradas y salidas

| # | Nombre propuesto | Dirección | Tipo IEC 61131-3 | Descripción |
|---|-----------------|-----------|------------------|-------------|
| **ENTRADAS** |
| 1 | `sensorTanqueVacio` | `%IX0.0` | `BOOL` | Sensor de nivel bajo del tanque superior (TRUE = tanque vacío) |
| 2 | `sensorPozoSinAgua` | `%IX0.1` | `BOOL` | Sensor de nivel mínimo del pozo (TRUE = pozo sin agua) |
| 3 | `btnParo` | `%IX0.2` | `BOOL` | Botón de paro manual de la bomba (TRUE = paro solicitado) |
| **SALIDAS** |
| 4 | `bombaPozo` | `%QX0.0` | `BOOL` | Activación del contactor de la bomba (TRUE = bomba en marcha) |
| 5 | `luzAlarma` | `%QX0.1` | `BOOL` | Luz de aviso de condición anormal (TRUE = alarma activa) |

---

## 2. Tipo de POU recomendado

**FUNCTION_BLOCK**

**Justificación:** El control de la bomba requiere conservar estado entre ciclos de scan (por ejemplo, el enclavamiento del paro manual, el historial de alarma o futuros temporizadores de arranque/parada). Un `FUNCTION_BLOCK` tiene memoria interna propia, lo que permite instanciarlo con sus variables retenidas. Un `FUNCTION` no conserva estado y un `PROGRAM` es adecuado solo para la capa de coordinación global; la lógica de un equipo específico se encapsula mejor en un `FUNCTION_BLOCK` reutilizable e instanciable.

---

## 3. Ambigüedades e información faltante

1. **Lógica de los sensores:** ¿Los sensores de nivel son normalmente abiertos o normalmente cerrados? ¿TRUE significa "hay agua" o "no hay agua"? Esto es crítico para la seguridad ante fallo de sensor.

2. **Condición de rearranque tras paro manual:** Después de pulsar el botón de paro, ¿la bomba debe permanecer detenida hasta que el operador realice alguna acción de rearranque explícita (enclavamiento), o puede volver a arrancar sola en cuanto el tanque vuelva a estar vacío?

3. **Condición exacta de alarma:** ¿Qué situaciones deben activar la luz de aviso? ¿Solo "pozo sin agua con tanque vacío"? ¿También el paro manual activo? ¿Fallo del contactor o discrepancia entre mando y retroalimentación?

4. **Retroalimentación de la bomba:** ¿Existe un contacto auxiliar del contactor o un sensor de flujo para confirmar que la bomba realmente arrancó? Sin ello no se puede detectar fallo de arranque.

5. **Temporización:** ¿Se requiere retardo al arranque (anti-golpe de ariete), tiempo mínimo de marcha o tiempo mínimo de parada para proteger el motor?

6. **Rearranque automático tras recuperación del pozo:** Si el pozo recupera nivel mientras el tanque sigue vacío, ¿la bomba debe arrancar automáticamente o esperar confirmación del operador?

7. **Nivel del tanque superior:** ¿Existe también un sensor de tanque lleno para detener la bomba cuando el tanque se llene, o solo hay sensor de vacío?

8. **Prioridades de seguridad:** ¿Qué tiene mayor prioridad: el paro manual o la protección por pozo seco? (Se asume pozo seco, pero debe confirmarse.)

9. **Tipo de botón de paro:** ¿Es un pulsador momentáneo (normalmente abierto/cerrado) o un selector con enclavamiento físico?

10. **Requisitos eléctricos y de seguridad:** ¿Se requiere categoría de parada SIL/PLd, o es una aplicación estándar sin requisitos de seguridad funcional formales?