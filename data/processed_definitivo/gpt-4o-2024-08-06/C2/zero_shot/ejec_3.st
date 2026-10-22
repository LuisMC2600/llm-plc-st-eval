1. **Tabla de entradas y salidas:**

   | Nombre         | Tipo de dato IEC 61131-3 | Descripción                                           |
   |----------------|--------------------------|-------------------------------------------------------|
   | `StartButton`  | `BOOL`                   | Botón para iniciar manualmente la bomba.              |
   | `StopButton`   | `BOOL`                   | Botón para detener manualmente la bomba.              |
   | `TankEmpty`    | `BOOL`                   | Sensor que indica si el tanque de arriba está vacío.  |
   | `WellEmpty`    | `BOOL`                   | Sensor que indica si el pozo está sin agua.           |
   | `PumpRunning`  | `BOOL`                   | Salida que controla el estado de la bomba.            |
   | `FaultLight`   | `BOOL`                   | Salida que enciende una luz cuando hay un fallo.      |

2. **Tipo de POU recomendado:**

   Recomendaría usar un `FUNCTION_BLOCK`. La razón es que un FUNCTION_BLOCK es adecuado para encapsular la lógica de control que puede incluir estados internos y puede ser reutilizado fácilmente si se necesita aplicar la misma lógica a múltiples bombas o sistemas similares en el futuro. Además, permite mantener el estado entre ejecuciones, lo cual es útil para manejar el estado de la bomba y las condiciones de fallo.

3. **Lista de ambigüedades o información faltante:**

   - ¿Cuál es el comportamiento esperado si el tanque de arriba se llena mientras la bomba está funcionando? ¿Debe detenerse automáticamente?
   - ¿Qué condiciones específicas deben activar la luz de fallo? ¿Solo cuando el pozo está vacío y la bomba intenta arrancar, o hay otras condiciones?
   - ¿Debe haber algún tipo de retardo o temporización al arrancar o detener la bomba para evitar ciclos de encendido/apagado rápidos?
   - ¿Qué prioridad tienen los botones manuales en comparación con las condiciones automáticas? Por ejemplo, si el botón de parada se presiona, ¿debe detenerse la bomba inmediatamente incluso si el tanque está vacío?
   - ¿Existen condiciones de seguridad adicionales que deban considerarse, como sobrecalentamiento de la bomba o mantenimiento programado?