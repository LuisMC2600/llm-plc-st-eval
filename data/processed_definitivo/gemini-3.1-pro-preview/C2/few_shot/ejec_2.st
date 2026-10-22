1. Tabla de entradas y salidas

**Entradas (VAR_INPUT)**
*   `snrTanqueVacio` | BOOL | Sensor de nivel del tanque superior (Activo cuando el tanque está vacío).
*   `snrPozoVacio` | BOOL | Sensor de nivel del pozo (Activo cuando el pozo se queda sin agua).
*   `btnApagar` | BOOL | Botón manual para detener o deshabilitar el funcionamiento de la bomba.
*   `snrFallaExterna` | BOOL | Señal de protección de la bomba (ej. relé térmico o guardamotor) para detectar si "algo anda mal".

**Salidas (VAR_OUTPUT)**
*   `cmdBomba` | BOOL | Señal de mando para accionar el contactor o relé de la bomba del pozo.
*   `indAlarma` | BOOL | Señal para encender la luz de aviso de falla o pozo vacío.

2. Tipo de POU recomendado

**FUNCTION_BLOCK**
*Justificación:* El control de esta bomba requiere memoria (retención de estado). Por ejemplo, si la bomba arranca al vaciarse el tanque, debe mantenerse encendida hasta que se llene, lo que implica recordar su estado. Además, el manejo de alarmas y botones de parada suele requerir enclavamientos o detección de flancos. Un `FUNCTION_BLOCK` permite almacenar estos estados internos entre ciclos de scan, a diferencia de una `FUNCTION`, y ofrece mayor modularidad y reutilización que un `PROGRAM` en caso de que en el futuro se añadan más pozos.

3. Lista de ambigüedades o información faltante a aclarar con el cliente

*   **Condición de parada automática:** El cliente indicó que la bomba arranca cuando el tanque está vacío, pero no especificó cuándo debe detenerse. ¿Existe un sensor de "tanque lleno" para apagarla automáticamente?
*   **Definición de "algo ande mal":** ¿La luz de aviso debe encenderse solo cuando el pozo se queda sin agua, o existe alguna otra señal de falla eléctrica/mecánica (como un relé térmico) que deba disparar esta alarma?
*   **Comportamiento del botón de apagado:** ¿Es un interruptor fijo (tipo Auto/Apagado) o un pulsador momentáneo? Si se apaga con el botón, ¿cómo y cuándo se vuelve a habilitar el modo automático?
*   **Reinicio tras falta de agua:** Si la bomba se detiene para protegerse porque el pozo se quedó sin agua, ¿debe arrancar sola de nuevo en cuanto el pozo recupere su nivel, o requiere que un operador presione un botón de reinicio (reset) por seguridad?
*   **Lógica de los contactos (Hardware):** Es necesario definir si los sensores de nivel y el botón de apagado serán Normalmente Abiertos (NO) o Normalmente Cerrados (NC) para programar la lógica de seguridad adecuada (fail-safe).