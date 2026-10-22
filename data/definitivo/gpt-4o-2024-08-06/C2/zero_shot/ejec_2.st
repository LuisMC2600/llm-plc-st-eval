1. **Tabla de entradas y salidas:**

   | Nombre          | Tipo de dato IEC 61131-3 | Descripción                                           |
   |-----------------|--------------------------|-------------------------------------------------------|
   | `StartPump`     | `BOOL`                   | Señal para arrancar la bomba automáticamente cuando el tanque está vacío. |
   | `WellEmpty`     | `BOOL`                   | Sensor que indica si el pozo está sin agua.           |
   | `ManualStop`    | `BOOL`                   | Botón para apagar la bomba manualmente.               |
   | `FaultIndicator`| `BOOL`                   | Luz indicadora de fallo en el sistema.                |
   | `PumpStatus`    | `BOOL`                   | Estado de la bomba (encendida/apagada).               |

2. **Tipo de POU recomendado:**

   Recomendaría usar un `FUNCTION_BLOCK`. La razón es que un FUNCTION_BLOCK permite encapsular tanto el estado como el comportamiento de la bomba, lo que es útil para manejar las condiciones de arranque y parada, así como para gestionar el estado de la luz indicadora de fallos. Además, un FUNCTION_BLOCK puede ser instanciado múltiples veces si se desea controlar más de una bomba en el futuro.

3. **Lista de ambigüedades o información faltante:**

   - ¿Cuál es el criterio exacto para considerar que el tanque de arriba está "vacío"? ¿Se requiere un sensor específico para esto?
   - ¿Qué condiciones específicas deben activar la luz indicadora de fallo? ¿Solo cuando el pozo está vacío y se intenta arrancar la bomba, o hay otras condiciones de fallo?
   - ¿Cómo se debe comportar el sistema si el pozo se queda sin agua mientras la bomba está funcionando?
   - ¿Existe un tiempo de retardo deseado entre el intento de arranque de la bomba y la verificación de las condiciones de seguridad?
   - ¿Qué sucede si el botón de parada manual se activa mientras la bomba está funcionando? ¿Debe reiniciarse automáticamente cuando el botón se desactiva, o debe esperar a que el tanque esté vacío nuevamente?
   - ¿Hay alguna consideración adicional de seguridad o mantenimiento que deba tenerse en cuenta en el diseño del sistema?