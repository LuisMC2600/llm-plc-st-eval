**1. Tabla de Entradas y Salidas**

| Nombre Propuesto | Tipo de Dato IEC 61131-3 | Descripción |
| :--- | :--- | :--- |
| `xSensorTanqueVacio` | BOOL | **Entrada:** Detecta si el tanque superior está vacío (TRUE = vacío). |
| `xSensorTanqueLleno` | BOOL | **Entrada:** Detecta si el tanque superior está lleno (Añadida por deducción lógica para saber cuándo detener la bomba). |
| `xSensorPozoVacio` | BOOL | **Entrada:** Detecta si el pozo se ha quedado sin agua (TRUE = sin agua). |
| `xBotonParo` | BOOL | **Entrada:** Botón o interruptor manual para detener la bomba a voluntad del usuario. |
| `xFalloTermicoBomba` | BOOL | **Entrada:** Señal del guardamotor o relé térmico (Asumida para la condición "algo ande mal"). |
| `xBotonRearme` | BOOL | **Entrada:** Botón para apagar la luz de alarma y reiniciar el sistema tras un fallo (Añadida por deducción lógica). |
| `qMandoBomba` | BOOL | **Salida:** Señal de control que acciona el contactor o variador para arrancar la bomba. |
| `qLuzAlarma` | BOOL | **Salida:** Señal que enciende la luz indicadora de advertencia/fallo. |

*Nota: El prefijo 'x' denota una variable booleana de entrada/memoria y 'q' una salida física, siguiendo convenciones habituales de programación.*

**2. Tipo de POU recomendado**

Se recomienda utilizar un **FUNCTION_BLOCK (Bloque de Función)**. 

**Justificación:** El control de una bomba requiere retener estados en memoria (por ejemplo, recordar que la bomba arrancó cuando el tanque se vació y mantenerla encendida hasta que se llene, o mantener encendida la luz de alarma hasta que un operador la reconozca). A diferencia de una FUNCTION (que no tiene memoria interna y siempre devuelve el mismo resultado para las mismas entradas), el FUNCTION_BLOCK permite el uso de variables estáticas y biestables (como flip-flops SR/RS). Además, si en el futuro el cliente añade más pozos o bombas, el FUNCTION_BLOCK se puede instanciar múltiples veces reutilizando la misma lógica.

**3. Lista de ambigüedades e información faltante a aclarar con el cliente**

1. **Condición de parada por llenado:** El cliente indica que la bomba arranca cuando el tanque está vacío, pero no especifica en qué momento debe detenerse. ¿Existe un sensor de "tanque lleno" o se debe apagar por tiempo?
2. **Recuperación del pozo:** Si la bomba se detiene porque el pozo se quedó sin agua, ¿cuándo es seguro volver a arrancar? ¿Existe un sensor de "nivel normal" en el pozo o se debe esperar un tiempo específico antes de intentar de nuevo?
3. **Comportamiento del botón de apagado:** ¿Es un interruptor fijo (modo Automático / modo Apagado) o es un pulsador momentáneo? Si es un pulsador, ¿cómo se vuelve a poner el sistema en modo automático?
4. **Definición de "algo ande mal":** ¿La luz de alarma solo debe encenderse cuando el pozo se queda sin agua, o también si hay un fallo eléctrico/térmico en el motor de la bomba? 
5. **Apagado de la alarma:** Una vez que la luz de aviso se enciende, ¿cómo se apaga? ¿Se apaga sola cuando vuelve el agua al pozo, o requiere que un operador presione un botón de "rearme/reconocimiento"?
6. **Seguridad de los sensores (Fail-Safe):** ¿Los sensores de nivel y el botón de paro son Normalmente Abiertos (NO) o Normalmente Cerrados (NC)? (Por seguridad, se recomienda que el botón de paro y las señales de fallo sean NC para que la bomba se detenga si se corta un cable).