FUNCTION_BLOCK FB_Duplex
VAR_INPUT
    demanda : BOOL;   // Entrada de demanda
    falla1 : BOOL;    // Falla de la bomba 1
    falla2 : BOOL;    // Falla de la bomba 2
END_VAR

VAR_OUTPUT
    bomba1 : BOOL;    // Salida para controlar la bomba 1
    bomba2 : BOOL;    // Salida para controlar la bomba 2
    almFalla : BOOL;  // Alarma de falla
END_VAR

VAR
    principal : BOOL; // Indica cuál es la bomba principal (TRUE para bomba1, FALSE para bomba2)
    lastDemanda : BOOL; // Estado anterior de la demanda
END_VAR

// Inicialización
IF NOT demanda AND NOT lastDemanda THEN
    principal := TRUE; // Inicialmente, bomba1 es la principal
END_IF

// Alternancia de bombas
IF demanda AND NOT lastDemanda THEN
    principal := NOT principal; // Alternar la bomba principal en cada nueva demanda
END_IF

// Lógica de control de bombas
IF demanda THEN
    IF principal THEN
        IF NOT falla1 THEN
            bomba1 := TRUE;
            bomba2 := FALSE;
            almFalla := FALSE;
        ELSIF NOT falla2 THEN
            bomba1 := FALSE;
            bomba2 := TRUE;
            almFalla := TRUE;
        ELSE
            bomba1 := FALSE;
            bomba2 := FALSE;
            almFalla := TRUE;
        END_IF
    ELSE
        IF NOT falla2 THEN
            bomba1 := FALSE;
            bomba2 := TRUE;
            almFalla := FALSE;
        ELSIF NOT falla1 THEN
            bomba1 := TRUE;
            bomba2 := FALSE;
            almFalla := TRUE;
        ELSE
            bomba1 := FALSE;
            bomba2 := FALSE;
            almFalla := TRUE;
        END_IF
    END_IF
ELSE
    bomba1 := FALSE;
    bomba2 := FALSE;
    almFalla := FALSE;
END_IF

// Actualizar el estado anterior de la demanda
lastDemanda := demanda;

END_FUNCTION_BLOCK