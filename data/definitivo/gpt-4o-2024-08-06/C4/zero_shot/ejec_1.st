El FUNCTION_BLOCK denominado `FB_D` está diseñado para gestionar el control de dos bombas en un sistema que requiere redundancia y alternancia en su operación. Este bloque es útil en aplicaciones donde se necesita asegurar que al menos una bomba esté operativa en caso de falla de la otra, y donde se desea alternar el uso de las bombas para equilibrar el desgaste. El bloque recibe señales de demanda y de fallas individuales para cada bomba, y determina cuál de las bombas debe estar activa en función de la demanda y el estado de las fallas. Además, genera una alarma si se detecta una falla en la bomba que debería estar operativa.

```pascal
FUNCTION_BLOCK FB_D
VAR_INPUT
    demanda : BOOL;  // Entrada que indica si hay demanda para activar las bombas.
    falla1 : BOOL;   // Entrada que indica si la bomba1 tiene una falla.
    falla2 : BOOL;   // Entrada que indica si la bomba2 tiene una falla.
END_VAR
VAR_OUTPUT
    bomba1 : BOOL;   // Salida que controla el estado de la bomba1 (activa/inactiva).
    bomba2 : BOOL;   // Salida que controla el estado de la bomba2 (activa/inactiva).
    almFalla : BOOL; // Salida que indica si hay una alarma de falla en la bomba activa.
END_VAR
VAR
    turno : BOOL;    // Variable interna que determina cuál bomba debe activarse.
    fDem : R_TRIG;   // Detector de flanco ascendente para la señal de demanda.
END_VAR

// Detecta el flanco ascendente de la señal de demanda.
fDem(CLK := demanda);

// Si se detecta un flanco ascendente en la demanda, alterna el turno.
IF fDem.Q THEN
    turno := NOT turno;
END_IF

// Si hay demanda, decide qué bomba activar según el turno y el estado de fallas.
IF demanda THEN
    IF turno THEN
        // Si es el turno de la bomba1, actívala si no hay falla.
        bomba1 := NOT falla1;
        // Activa la bomba2 solo si la bomba1 falla y la bomba2 no tiene falla.
        bomba2 := falla1 AND NOT falla2;
        // Genera alarma si la bomba1 tiene falla.
        almFalla := falla1;
    ELSE
        // Si es el turno de la bomba2, actívala si no hay falla.
        bomba2 := NOT falla2;
        // Activa la bomba1 solo si la bomba2 falla y la bomba1 no tiene falla.
        bomba1 := falla2 AND NOT falla1;
        // Genera alarma si la bomba2 tiene falla.
        almFalla := falla2;
    END_IF
ELSE
    // Si no hay demanda, ambas bombas están inactivas y no hay alarma.
    bomba1 := FALSE;
    bomba2 := FALSE;
    almFalla := FALSE;
END_IF
END_FUNCTION_BLOCK
```