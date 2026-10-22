FUNCTION_BLOCK FB_Duplex
VAR_INPUT
    demanda : BOOL; (* Demanda de arranque *)
    falla1 : BOOL; (* Falla de la bomba 1 *)
    falla2 : BOOL; (* Falla de la bomba 2 *)
END_VAR
VAR_OUTPUT
    bomba1 : BOOL; (* Bomba principal *)
    bomba2 : BOOL; (* Bomba secundaria *)
    almFalla : BOOL; (* Alarma de falla de la bomba principal *)
END_VAR
VAR
    estado : INT := 0; (* Estado del sistema *)
    cambio : BOOL := FALSE; (* Bandera de cambio de estado *)
END_VAR

(* Estado 0: Espera inicial *)
IF demanda THEN
    estado := 1;
    cambio := TRUE;
END_IF

(* Estado 1: Bomba 1 principal *)
IF estado = 1 THEN
    IF NOT falla1 THEN
        bomba1 := TRUE;
        bomba2 := FALSE;
        almFalla := FALSE;
    ELSE
        IF NOT falla2 THEN
            bomba1 := FALSE;
            bomba2 := TRUE;
            almFalla := TRUE;
        ELSE
            bomba1 := FALSE;
            bomba2 := FALSE;
            almFalla := TRUE;
        END_IF
    END_IF
END_IF

(* Estado 2: Bomba 2 principal *)
IF estado = 2 THEN
    IF NOT falla2 THEN
        bomba1 := FALSE;
        bomba2 := TRUE;
        almFalla := FALSE;
    ELSE
        IF NOT falla1 THEN
            bomba1 := TRUE;
            bomba2 := FALSE;
            almFalla := TRUE;
        ELSE
            bomba1 := FALSE;
            bomba2 := FALSE;
            almFalla := TRUE;
        END_IF
    END_IF
END_IF

(* Cambio de estado en nueva demanda *)
IF demanda AND cambio THEN
    IF estado = 1 THEN
        estado := 2;
    ELSE
        estado := 1;
    END_IF
    cambio := FALSE;
END_IF

(* Detener bombas al quitar demanda *)
IF NOT demanda THEN
    bomba1 := FALSE;
    bomba2 := FALSE;
    cambio := TRUE;
END_IF

END_FUNCTION_BLOCK