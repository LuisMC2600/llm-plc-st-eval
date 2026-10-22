1. Tabla de entradas y salidas

| Nombre | Tipo de dato | E/S | Descripción |
| :--- | :--- | :--- | :--- |
| `snsTanqueVacio` | BOOL | Entrada | Sensor que indica que el tanque superior está vacío. |
| `snsPozoVacio` | BOOL | Entrada | Sensor que indica que el pozo no tiene agua (protección de trabajo en seco). |
| `btnParo` | BOOL | Entrada | Botón para apagar manualmente la bomba. |
| `cmdBomba` | BOOL | Salida | Señal de mando para activar el contactor/motor de la bomba. |
| `luzAlarma` | BOOL | Salida | Luz piloto para avisar de un fallo o condición anormal. |

2. Tipo de POU recomendado

**FUNCTION_BLOCK**
*Justificación:* El sistema requiere memoria para almacenar estados internos. Por ejemplo, si se presiona el botón de apagado, el sistema debe "recordar" mantenerse apagado y no arrancar automáticamente aunque el tanque esté vacío. Además, la gestión de alarmas suele requerir enclavamientos (latches). Una FUNCTION no conserva estados entre ciclos de scan, por lo que un FUNCTION_BLOCK es la estructura ideal y reutilizable para este propósito.

3. Ambigüedades o información faltante a aclarar con el cliente

*   **Condición de parada por nivel:** El cliente indica que la bomba arranca cuando el tanque está vacío, pero no especifica cuándo debe detenerse. ¿Existe un sensor de "tanque lleno" o se detiene tras un tiempo determinado?
*   **Reinicio tras apagado manual:** Si se usa el botón para apagar la bomba, ¿cómo se vuelve a habilitar el modo automático? ¿Se necesita un botón adicional de "Arranque/Auto" o un interruptor selector de modos (Manual/Auto)?
*   **Definición de "algo ande mal":** ¿La luz de alarma solo debe encenderse cuando el pozo se queda sin agua, o el sistema contará con otras protecciones físicas (como un relé térmico de sobrecarga del motor) que deban conectarse al PLC para disparar la alarma?
*   **Reinicio de la alarma:** Cuando la luz de alarma se enciende, ¿debe apagarse automáticamente en cuanto el pozo vuelva a tener agua, o el operador debe presionar un botón de "Reset/Acuse de recibo" para apagarla?
*   **Tipo de contactos (Hardware):** Es necesario definir si los sensores y el botón de paro serán Normalmente Abiertos (NO) o Normalmente Cerrados (NC) para programar la lógica de seguridad (fail-safe) correctamente.