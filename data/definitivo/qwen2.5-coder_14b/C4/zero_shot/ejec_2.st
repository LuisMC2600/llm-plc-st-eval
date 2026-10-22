### Descripción del Bloque de Función

El bloque de función `FB_D` es un controlador de bombas diseñado para gestionar la operación de dos bombas (`bomba1` y `bomba2`) en respuesta a una demanda (`demanda`) y a posibles fallos (`falla1` y `falla2`). El bloque opera según un sistema de turnos, alternando la bomba que se activa en cada ciclo de demanda. Si se detecta una falla en una de las bombas, la otra bomba se activa automáticamente, y un alarma (`almFalla`) se activa para indicar el fallo. Este bloque de función es útil en aplicaciones industriales donde se requiere un sistema de redundancia y control de fallos para asegurar el funcionamiento continuo de los equipos.

### Código comentado

```structured-text
FUNCTION_BLOCK FB_D
VAR_INPUT
    demanda : BOOL;  // Entrada que indica si hay una demanda de activación de bombas
    falla1 : BOOL;   // Entrada que indica si hay una falla en la bomba 1
    falla2 : BOOL;   // Entrada que indica si hay una falla en la bomba 2
END_VAR
VAR_OUTPUT
    bomba1 : BOOL;   // Salida que controla la activación de la bomba 1
    bomba2 : BOOL;   // Salida que controla la activación de la bomba 2
    almFalla : BOOL; // Salida que indica si hay una falla detectada
END_VAR
VAR
    turno : BOOL;    // Variable interna que controla el turno entre bomba1 y bomba2
    fDem : R_TRIG;   // Objeto de retardo que detecta el flanco de subida de la demanda
END_VAR

// Configuración del objeto de retardo R_TRIG para detectar el flanco de subida de la demanda
fDem(CLK := demanda);

// Si se detecta un flanco de subida en la demanda
IF fDem.Q THEN
    // Cambiar el turno entre bomba1 y bomba2
    turno := NOT turno;
END_IF

// Si hay una demanda de activación de bombas
IF demanda THEN
    // Si el turno está asignado a bomba1
    IF turno THEN
        // Activar bomba1 si no hay falla en bomba1
        bomba1 := NOT falla1;
        // Activar bomba2 si hay falla en bomba1 y no hay falla en bomba2
        bomba2 := falla1 AND NOT falla2;
        // Activar la alarma de falla si hay falla en bomba1
        almFalla := falla1;
    // Si el turno está asignado a bomba2
    ELSE
        // Activar bomba2 si no hay falla en bomba2
        bomba2 := NOT falla2;
        // Activar bomba1 si hay falla en bomba2 y no hay falla en bomba1
        bomba1 := falla2 AND NOT falla1;
        // Activar la alarma de falla si hay falla en bomba2
        almFalla := falla2;
    END_IF
// Si no hay demanda de activación de bombas
ELSE
    // Desactivar bomba1
    bomba1 := FALSE;
    // Desactivar bomba2
    bomba2 := FALSE;
    // Desactivar la alarma de falla
    almFalla := FALSE;
END_IF
END_FUNCTION_BLOCK
```