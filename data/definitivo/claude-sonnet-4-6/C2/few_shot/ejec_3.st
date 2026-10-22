# Análisis de requisitos: Control de bomba de pozo

---

## 1. Tabla de entradas y salidas

| # | Nombre propuesto | Dirección E/S | Tipo IEC 61131-3 | Descripción |
|---|-----------------|---------------|------------------|-------------|
| 1 | `sensorTanqueVacio` | Entrada | `BOOL` | Sensor de nivel bajo del tanque superior (TRUE = tanque vacío) |
| 2 | `sensorPozoSinAgua` | Entrada | `BOOL` | Sensor de nivel mínimo del pozo (TRUE = pozo sin agua) |
| 3 | `btnParo` | Entrada | `BOOL` | Botón de paro manual de la bomba |
| 4 | `bomba` | Salida | `BOOL` | Activación del contactor/arrancador de la bomba |
| 5 | `luzFalla` | Salida | `BOOL` | Luz de aviso de condición anormal |

---

## 2. Tipo de POU recomendado

**FUNCTION_BLOCK**

**Justificación:** El control requiere conservar estado entre ciclos de scan (por ejemplo, el enclavamiento de paro manual o el historial de falla), lo cual exige memoria interna persistente. Un `FUNCTION_BLOCK` permite instanciar ese estado de forma encapsulada y reutilizable, a diferencia de una `FUNCTION` (sin estado) o un `PROGRAM` (único, global y menos reutilizable si hubiera más de un pozo).

---

## 3. Ambigüedades e información faltante

1. **Lógica de los sensores:** ¿Los sensores de nivel son normalmente abiertos o normalmente cerrados? ¿TRUE significa nivel presente o nivel ausente? Esto afecta directamente la lógica de activación.

2. **Condición de "tanque lleno":** ¿Existe un sensor de nivel alto del tanque para detener la bomba cuando el tanque se llene, o solo se detiene con el botón de paro manual?

3. **Enclavamiento por pozo seco:** Si la bomba no arrancó por falta de agua en el pozo y luego el pozo se recupera, ¿debe arrancar automáticamente o requiere un reset manual?

4. **Comportamiento del botón de paro:** ¿Es un paro momentáneo (el sistema puede volver a arrancar automáticamente en el siguiente ciclo) o un paro con enclavamiento que requiere acción manual para reanudar?

5. **Definición de "algo ande mal":** ¿Qué condiciones activan la luz de falla? ¿Solo pozo seco, o también incluye falla eléctrica de la bomba, sobrecarga térmica, ausencia de flujo, u otras alarmas externas?

6. **Señal de falla de la bomba:** ¿El arrancador o guardamotor dispone de un contacto de falla (térmico, sobrecarga) que deba conectarse como entrada al PLC?

7. **Prioridades entre condiciones:** Si simultáneamente el tanque está vacío y el pozo está seco, ¿cuál condición tiene prioridad en la lógica y en la indicación visual?

8. **Temporización de arranque:** ¿Se requiere algún retardo antes de arrancar (anti-rebote de sensores, tiempo de espera tras un paro) para proteger la bomba?

9. **Tipo de arranque:** ¿La bomba arranca directo a línea o mediante variador/arrancador suave? Esto puede requerir señales adicionales de habilitación o retroalimentación.

10. **Rearme de la luz de falla:** ¿La luz de falla se apaga sola al desaparecer la condición, o requiere un botón de reconocimiento/reset explícito?