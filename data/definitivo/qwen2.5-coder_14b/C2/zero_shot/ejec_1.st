1. **Tabla de Entradas y Salidas**

| Nombre Propuesto | Tipo de Dato IEC 61131-3 | Descripción |
|------------------|------------------------|-------------|
| `TankEmpty`      | BOOL                   | Indica si el tanque de arriba está vacío |
| `PumpRunning`    | BOOL                   | Indica si la bomba está en funcionamiento |
| `PumpFault`      | BOOL                   | Indica si hay un fallo en la bomba |
| `StopButton`     | BOOL                   | Botón para detener manualmente la bomba |
| `PumpStart`      | BOOL                   | Salida para iniciar la bomba |
| `FaultLight`     | BOOL                   | Salida para encender la luz de advertencia de fallo |

2. **Tipo de POU Recomendado**

Recomendaría utilizar un **PROGRAM** para esta tarea. Un programa es adecuado porque maneja un proceso completo y puede coordinar múltiples entradas y salidas. Además, un programa puede mantener un estado persistente y realizar una secuencia de operaciones que se ajustan bien a los requisitos de control de la bomba.

3. **Lista de Ambigüedades o Información Faltante**

- **Definición de "se queme":** ¿Qué exactamente significa que la bomba "se queme"? ¿Es un fallo eléctrico, una sobrecarga, o algún otro tipo de daño?
- **Tiempo de espera después de que el tanque esté vacío:** ¿Cuánto tiempo debe esperar la bomba antes de intentar arrancar nuevamente si el tanque se vacía?
- **Condición de "sin agua" en el pozo:** ¿Cómo se detecta que el pozo está sin agua? ¿Es un sensor de nivel de agua o algún otro método?
- **Tiempo de encendido de la luz de advertencia:** ¿Cuánto tiempo debe permanecer encendida la luz de advertencia una vez que se detecta un fallo?
- **Acciones en caso de fallo:** ¿Qué acciones adicionales se deben tomar si se detecta un fallo en la bomba, además de encender la luz de advertencia?