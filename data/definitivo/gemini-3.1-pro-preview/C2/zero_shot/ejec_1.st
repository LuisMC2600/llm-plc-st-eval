**1. Tabla de entradas y salidas**

| Nombre Propuesto | Tipo de Dato | Descripción |
| :--- | :--- | :--- |
| `di_TanqueVacio` | BOOL | Entrada digital. Sensor de nivel bajo en el tanque superior; indica que el tanque está vacío y requiere llenado. |
| `di_PozoSinAgua` | BOOL | Entrada digital. Sensor de nivel en el pozo; indica que no hay agua suficiente para bombear (protección contra trabajo en seco). |
| `di_BotonParo` | BOOL | Entrada digital. Botón o interruptor manual para apagar o deshabilitar el funcionamiento de la bomba. |
| `do_BombaArranque` | BOOL | Salida digital. Señal de mando hacia el contactor o relé que enciende el motor de la bomba. |
| `do_LuzAlarma` | BOOL | Salida digital. Señal que enciende la luz piloto para notificar una anomalía en el sistema. |

*(Nota: Se asume el prefijo `di_` para Digital Input y `do_` para Digital Output).*

**2. Tipo de POU recomendado**

Recomiendo utilizar un **FUNCTION_BLOCK** (Bloque de Función). 

*Justificación:* El control de esta bomba requiere retener estados en la memoria entre los ciclos de escaneo (scans) del PLC. Por ejemplo, el sistema necesitará "recordar" que la bomba está en ciclo de llenado, o mantener enclavada una alarma. Una *FUNCTION* no posee memoria interna para retener estos estados. Aunque se podría usar un *PROGRAM*, encapsular esta lógica en un *FUNCTION_BLOCK* es la mejor práctica de programación estructurada, ya que permite reutilizar el código fácilmente si el cliente decide agregar más bombas o pozos en el futuro, instanciando el bloque varias veces.

**3. Ambigüedades e información faltante a aclarar con el cliente**

1. **Condición de paro por tanque lleno:** El cliente indica que la bomba arranca cuando el tanque está vacío, pero no menciona cuándo debe detenerse. ¿Existe un sensor de "tanque lleno" (nivel alto) o el llenado se controla mediante un temporizador?
2. **Comportamiento del botón de apagado:** ¿Es un interruptor fijo (tipo selector manual/auto) o un botón pulsador momentáneo? Si es un pulsador que apaga la bomba, ¿cómo se vuelve a encender o a poner en modo automático? (No se menciona un botón de "Arranque").
3. **Definición de "algo ande mal" (Condiciones de alarma):** ¿La luz de alarma solo debe encenderse cuando el pozo se queda sin agua, o el sistema contará con otras protecciones físicas que deban monitorearse (por ejemplo, un relé térmico de sobrecarga del motor o un fallo eléctrico)?
4. **Reinicio (Reset) de la alarma:** Si la luz de alarma se enciende, ¿se apaga automáticamente cuando el problema desaparece (ej. el pozo vuelve a tener agua), o se requiere que un operador presione un botón de "Reset" para confirmar que vio la falla?
5. **Lógica de recuperación del pozo:** Si la bomba se detiene por falta de agua en el pozo, ¿debe arrancar sola en cuanto el sensor detecte un mínimo de agua? (Esto podría causar que la bomba arranque y pare continuamente, dañándola. Sería recomendable preguntar si el pozo tiene un sensor de nivel alto o si se debe agregar un tiempo de espera).
6. **Estado lógico de los sensores (Seguridad):** ¿Los sensores de nivel y el botón de paro son contactos Normalmente Abiertos (NO) o Normalmente Cerrados (NC)? Por seguridad (Fail-Safe), el botón de paro y el sensor de presencia de agua en el pozo deberían ser NC.