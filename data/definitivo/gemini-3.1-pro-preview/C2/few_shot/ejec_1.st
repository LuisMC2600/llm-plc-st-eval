1. Tabla de entradas y salidas

| Nombre | Tipo de dato | Descripción |
| :--- | :--- | :--- |
| **Entradas (VAR_INPUT)** | | |
| `senTanqueVacio` | BOOL | Sensor de nivel del tanque superior (Activo = tanque vacío). |
| `senPozoVacio` | BOOL | Sensor de nivel del pozo (Activo = pozo sin agua). |
| `btnParo` | BOOL | Botón para apagar la bomba manualmente. |
| **Salidas (VAR_OUTPUT)** | | |
| `cmdBomba` | BOOL | Comando de encendido para el motor/contactor de la bomba. |
| `luzAlarma` | BOOL | Luz indicadora de advertencia/falla. |

2. Tipo de POU recomendado

**FUNCTION_BLOCK**
*Justificación:* El control de esta bomba requiere memoria interna (estado). Por ejemplo, si la bomba arranca al vaciarse el tanque, debe mantenerse encendida (enclavamiento) hasta que se llene, lo cual implica recordar su estado anterior. Además, el manejo de alarmas suele requerir retención de estados. Una `FUNCTION` no puede retener valores entre ciclos de escaneo, y un `PROGRAM` limitaría la reutilización del código si en el futuro el cliente añade más pozos o bombas al sistema.

3. Lista de ambigüedades o información faltante a aclarar con el cliente

* **Condición de paro automático:** El cliente indica que la bomba arranca cuando el tanque está vacío, pero no especifica cuándo debe detenerse automáticamente (por ejemplo, ¿existe un sensor de "tanque lleno"?).
* **Reinicio tras el paro manual:** Si se presiona el botón para apagarla, ¿cómo vuelve el sistema a modo automático? ¿Se necesita un botón adicional de "Arranque/Auto" o un selector manual/automático?
* **Definición de "algo ande mal" (Alarma):** ¿La luz de aviso solo debe encenderse cuando el pozo se queda sin agua, o existen otras señales de falla a considerar (como un relé térmico de sobrecarga de la bomba)?
* **Reinicio de la alarma:** Una vez que se enciende la luz de aviso, ¿se apaga sola cuando el problema se resuelve (ej. el pozo vuelve a tener agua) o requiere que un operador presione un botón de "Reset" o "Acuse de recibo"?
* **Naturaleza física de los sensores y botones:** Es necesario definir si los sensores y el botón de paro son Normalmente Abiertos (NO) o Normalmente Cerrados (NC) para programar la lógica de seguridad (fail-safe) correctamente.