1. **Tabla de Entradas y Salidas:**

| Nombre Propuesto | Tipo de Dato IEC 61131-3 | Descripción |
|----------------|------------------------|-------------|
| `TankIsEmpty`  | BOOL                   | Indica si el tanque de arriba está vacío |
| `PumpOverheat`   | BOOL                   | Indica si la bomba está en riesgo de quemarse |
| `PumpEmpty`      | BOOL                   | Indica si el pozo está sin agua |
| `StopButton`     | BOOL                   | Botón para apagar manualmente la bomba |
| `PumpRun`        | BOOL                   | Salida para controlar el arranque de la bomba |
| `AlarmLight`     | BOOL                   | Salida para encender la luz de advertencia |

2. **Tipo de POU Recomendado:**
   - **PROGRAM**: Se recomienda utilizar un PROGRAM para este caso. Un PROGRAM es adecuado para manejar un proceso de control secuencial y coordinar las diferentes condiciones y acciones que se describen. Un PROGRAM puede manejar múltiples entradas y salidas, y puede ser fácilmente expandido si se necesitan más funcionalidades en el futuro.

3. **Lista de Ambigüedades o Información Faltante:**
   - **Tiempo de Retardo**: ¿Hay un tiempo de retardo antes de que la bomba se encienda después de que el tanque esté vacío?
   - **Niveles de Temperatura**: ¿Cuál es el umbral de temperatura que considera el cliente como "riesgo de quemarse"?
   - **Niveles de Agua**: ¿Cuál es el umbral de nivel de agua que considera el cliente como "sin agua"?
   - **Tiempo de Encendido**: ¿Hay un límite de tiempo después del cual la bomba debe apagarse automáticamente si no se detecta agua en el pozo?
   - **Comportamiento en Fallos**: ¿Qué debe hacer la bomba si se detecta un fallo en algún sensor (por ejemplo, si el sensor de temperatura falla)?