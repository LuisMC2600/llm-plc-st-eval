FUNCTION_BLOCK FB_D
VAR_INPUT
    demanda : BOOL; // Entrada que indica si hay demanda de bombeo
    falla1 : BOOL;  // Entrada que indica si la bomba 1 ha fallado
    falla2 : BOOL;  // Entrada que indica si la bomba 2 ha fallado
END_VAR
VAR_OUTPUT
    bomba1 : BOOL;  // Salida que controla el estado de la bomba 1
    bomba2 : BOOL;  // Salida que controla el estado de la bomba 2
    almFalla : BOOL; // Salida que indica si hay una alarma de falla
END_VAR
VAR
    turno : BOOL;   // Variable interna para alternar el uso de las bombas
    fDem : R_TRIG;  // Detector de flanco ascendente para la señal de demanda
END_VAR

// Detecta un flanco ascendente en la señal de demanda
fDem(CLK := demanda);

// Si se detecta un flanco ascendente en la demanda, alterna el turno
IF fDem.Q THEN
    turno := NOT turno;
END_IF

// Si hay demanda de bombeo
IF demanda THEN
    // Si es el turno de la bomba 1
    IF turno THEN
        bomba1 := NOT falla1; // Activa la bomba 1 si no hay falla
        bomba2 := falla1 AND NOT falla2; // Activa la bomba 2 si la bomba 1 falla y la bomba 2 no
        almFalla := falla1; // Activa la alarma si la bomba 1 falla
    ELSE
        // Si es el turno de la bomba 2
        bomba2 := NOT falla2; // Activa la bomba 2 si no hay falla
        bomba1 := falla2 AND NOT falla1; // Activa la bomba 1 si la bomba 2 falla y la bomba 1 no
        almFalla := falla2; // Activa la alarma si la bomba 2 falla
    END_IF
ELSE
    // Si no hay demanda, apaga ambas bombas y resetea la alarma
    bomba1 := FALSE;
    bomba2 := FALSE;
    almFalla := FALSE;
END_IF
END_FUNCTION_BLOCK