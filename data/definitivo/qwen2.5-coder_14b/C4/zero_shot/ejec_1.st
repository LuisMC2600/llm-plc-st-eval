### Descripción del Bloque de Función

El bloque de función `FB_D` es un controlador de bombas diseñado para gestionar la operación de dos bombas (`bomba1` y `bomba2`) en respuesta a una demanda (`demanda`) y considerando posibles fallas (`falla1` y `falla2`). El bloque opera de acuerdo con un sistema de turnos, alternando la activación de las bombas para evitar sobrecargas y asegurar un funcionamiento eficiente. Además, mantiene un registro de la falla que ha ocurrido (`almFalla`). Este bloque es útil en aplicaciones industriales donde se requiere un control preciso y redundante de dispositivos como bombas, asegurando que en caso de una falla, el otro dispositivo pueda tomar el control.

### Código con Comentarios Técnicos

```structured-text
FUNCTION_BLOCK FB_D
VAR_INPUT
    demanda : BOOL;  // Indica si hay una demanda de activación de bombas
    falla1 : BOOL;   // Indica si la bomba1 ha fallado
    falla2 : BOOL;   // Indica si la bomba2 ha fallado
END_VAR
VAR_OUTPUT
    bomba1 : BOOL;   // Controla la activación de la bomba1
    bomba2 : BOOL;   // Controla la activación de la bomba2
    almFalla : BOOL; // Almacena la falla detectada
END_VAR
VAR
    turno : BOOL;    // Variable de estado para alternar el turno entre bomba1 y bomba2
    fDem : R_TRIG;   // Detector de flanco de subida en la demanda
END_VAR

// Detecta el flanco de subida en la demanda
fDem(CLK := demanda);

// Si se detecta un flanco de subida en la demanda, se alterna el turno
IF fDem.Q THEN
    turno := NOT turno;
END_IF

// Si hay una demanda de activación de bombas
IF demanda THEN
    // Si es el turno de la bomba1
    IF turno THEN
        bomba1 := NOT falla1;  // Activa bomba1 si no ha fallado
        bomba2 := falla1 AND NOT falla2;  // Activa bomba2 si bomba1 ha fallado y bomba2 no ha fallado
        almFalla := falla1;  // Almacena la falla de bomba1 si ha ocurrido
    // Si es el turno de la bomba2
    ELSE
        bomba2 := NOT falla2;  // Activa bomba2 si no ha fallado
        bomba1 := falla2 AND NOT falla1;  // Activa bomba1 si bomba2 ha fallado y bomba1 no ha fallado
        almFalla := falla2;  // Almacena la falla de bomba2 si ha ocurrido
    END_IF
// Si no hay demanda de activación de bombas
ELSE
    bomba1 := FALSE;  // Desactiva bomba1
    bomba2 := FALSE;  // Desactiva bomba2
    almFalla := FALSE;  // Limpia el registro de falla
END_IF
END_FUNCTION_BLOCK
```