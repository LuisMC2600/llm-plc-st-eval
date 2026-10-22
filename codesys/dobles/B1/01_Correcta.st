(* DOBLE DE PRUEBA B1/Correcta - NO ES CORPUS. Esperado: veredicto 1 *)
FUNCTION_BLOCK FB_Motor
VAR_INPUT
    btnMarcha : BOOL;
    btnParo : BOOL;
    btnEmerg : BOOL;
END_VAR
VAR_OUTPUT
    motorOn : BOOL;
END_VAR
VAR
    bloqueo : BOOL;
END_VAR
IF btnEmerg THEN
    motorOn := FALSE;
    bloqueo := TRUE;
ELSE
    IF bloqueo AND NOT btnMarcha THEN
        bloqueo := FALSE;
    END_IF
    IF btnParo THEN
        motorOn := FALSE;
    ELSIF btnMarcha AND NOT bloqueo THEN
        motorOn := TRUE;
    END_IF
END_IF
END_FUNCTION_BLOCK
