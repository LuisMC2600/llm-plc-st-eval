1. **Tabla de entradas y salidas:**

   | Nombre       | Tipo de dato | Descripción                                           |
   |--------------|--------------|-------------------------------------------------------|
   | tankEmpty    | BOOL         | Indica si el tanque de arriba está vacío              |
   | wellEmpty    | BOOL         | Indica si el pozo está sin agua                       |
   | btnOff       | BOOL         | Botón para apagar manualmente la bomba                |
   | pump         | BOOL         | Salida para controlar el estado de la bomba del pozo  |
   | alarmLight   | BOOL         | Luz de alarma para indicar problemas                  |

2. **Tipo de POU recomendado:**

   Recomendaría usar un **FUNCTION_BLOCK**. La razón es que un FUNCTION_BLOCK es adecuado para encapsular la lógica de control de la bomba, ya que puede mantener estados internos y gestionar múltiples entradas y salidas. Además, permite reutilizar el bloque en diferentes partes del programa o en otros proyectos si es necesario.

3. **Lista de ambigüedades o información faltante:**

   - ¿Qué condiciones específicas deben activar la luz de alarma? ¿Solo cuando el pozo está vacío y el tanque también, o hay otras condiciones?
   - ¿Qué debe suceder si el tanque está vacío pero el pozo tiene agua y el botón está presionado? ¿Debe la bomba apagarse inmediatamente o continuar hasta que el botón se suelte?
   - ¿Existe un tiempo de retardo deseado para el encendido o apagado de la bomba?
   - ¿Qué sucede si el tanque se llena mientras la bomba está funcionando? ¿Debe apagarse automáticamente?
   - ¿Hay alguna condición en la que la bomba deba encenderse manualmente, independientemente del estado del tanque o del pozo?
   - ¿Qué acciones deben tomarse si la luz de alarma se activa? ¿Debe la bomba detenerse automáticamente?