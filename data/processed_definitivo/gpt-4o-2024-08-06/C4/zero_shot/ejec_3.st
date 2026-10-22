FUNCTION_BLOCK FB_D
VAR_INPUT
    demanda : BOOL;  // Entrada que indica si hay demanda de bombeo.
    falla1 : BOOL;   // Entrada que indica si la bomba1 está en estado de falla.
    falla2 : BOOL;   // Entrada que indica si la bomba2 está en estado de falla.
END_VAR
VAR_OUTPUT
    bomba1 : BOOL;   // Salida que controla el estado de la bomba1.
    bomba2 : BOOL;   // Salida que controla el estado de la bomba2.
    almFalla : BOOL; // Salida que indica si hay una alarma de falla.
END_VAR
VAR
    turno : BOOL;    // Variable interna que determina el turno de operación de las bombas.
    fDem : R_TRIG;   // Detector de flanco ascendente para la señal de demanda.
END_VAR

// Detecta el flanco ascendente de la señal de demanda.
fDem(CLK := demanda);

// Si se detecta un flanco ascendente en la demanda, se alterna el turno.
IF fDem.Q THEN
    turno := NOT turno;
END_IF

// Si hay demanda de bombeo, se evalúa el turno y el estado de falla de las bombas.
IF demanda THEN
    IF turno THEN
        // Si es el turno de bomba1, se activa si no está en falla.
        bomba1 := NOT falla1;
        // Si bomba1 está en falla, se activa bomba2 si no está en falla.
        bomba2 := falla1 AND NOT falla2;
        // Se genera una alarma si bomba1 está en falla.
        almFalla := falla1;
    ELSE
        // Si es el turno de bomba2, se activa si no está en falla.
        bomba2 := NOT falla2;
        // Si bomba2 está en falla, se activa bomba1 si no está en falla.
        bomba1 := falla2 AND NOT falla1;
        // Se genera una alarma si bomba2 está en falla.
        almFalla := falla2;
    END_IF
ELSE
    // Si no hay demanda, ambas bombas están desactivadas y no hay alarma.
    bomba1 := FALSE;
    bomba2 := FALSE;
    almFalla := FALSE;
END_IF
END_FUNCTION_BLOCK