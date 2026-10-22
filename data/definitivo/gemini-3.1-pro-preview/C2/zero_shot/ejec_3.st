**1. Tabla de Entradas y Salidas**

| Nombre propuesto | Tipo IEC 61131-3 | E/S | Descripción |
| :--- | :--- | :--- | :--- |
| `di_TanqueVacio` | BOOL | Entrada | Sensor de nivel bajo del tanque superior (Activo cuando el tanque está vacío). |
| `di_PozoVacio` | BOOL | Entrada | Sensor de nivel bajo del pozo (Activo cuando el pozo se queda sin agua). |
| `di_BotonParada` | BOOL | Entrada | Botón o interruptor para apagar la bomba a voluntad del usuario. |
| `di_FallaTermica` | BOOL | Entrada | Señal de protección del motor (guardamotor/relé térmico) para detectar si la bomba sufre una falla eléctrica. |
| `do_ComandoBomba` | BOOL | Salida | Señal de control hacia el contactor o variador para arrancar la bomba. |
| `do_LuzAlarma` | BOOL | Salida | Luz piloto que avisa cuando hay una condición de falla (pozo vacío o falla térmica). |

**2. Tipo de POU recomendado y justificación**

*   **Tipo recomendado:** `FUNCTION_BLOCK` (Bloque de Función).
*   **Justificación:** El control de esta bomba requiere retención de estado (memoria interna). Aunque el cliente lo describe de forma sencilla, en la práctica se necesitará memorizar estados, como mantener la bomba encendida después de que el tanque deje de estar "vacío" (histéresis) o enclavar una señal de alarma hasta que un operador la reconozca. Un `FUNCTION_BLOCK` permite conservar estas variables de estado entre los ciclos de scan del PLC y, además, permite instanciar el código fácilmente si el cliente decide agregar más bombas o pozos en el futuro.

**3. Ambigüedades e información faltante a aclarar con el cliente**

1.  **Condición de parada automática:** El cliente indica que la bomba arranca cuando el tanque está vacío, pero no especifica cuándo se detiene. ¿Existe un sensor de "tanque lleno" para detenerla automáticamente y evitar que el agua se desborde, o espera apagarla siempre con el botón manual?
2.  **Definición de "algo ande mal":** ¿La luz de alarma debe encenderse únicamente cuando el pozo se queda sin agua, o el sistema eléctrico cuenta con protecciones (como un relé térmico) que también deban disparar esta luz si la bomba se atasca o sobrecalienta?
3.  **Rearme (Reset) del sistema:** Si la bomba se detiene por protección porque el pozo se quedó sin agua, ¿debe arrancar sola de nuevo en cuanto el pozo recupere su nivel de agua, o por seguridad requiere que una persona presione un botón de "reinicio/reset" tras la falla?
4.  **Comportamiento del botón de apagado:** ¿Es un interruptor de posición fija (selector Automático/Apagado) o un pulsador momentáneo? Si se apaga con el botón, ¿cómo se vuelve a habilitar el sistema para que arranque sola de nuevo?
5.  **Naturaleza de los contactos (Seguridad):** Es necesario definir si los sensores de nivel y el botón de parada serán Normalmente Abiertos (NO) o Normalmente Cerrados (NC). Por estándar de seguridad, los botones de parada y las señales de falla deben ser NC (lógica a prueba de fallos o rotura de cable).