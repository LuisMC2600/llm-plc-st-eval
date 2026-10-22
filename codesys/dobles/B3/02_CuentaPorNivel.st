(* DOBLE DE PRUEBA B3/CuentaPorNivel - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 2 *)
FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL;
    btnReset : BOOL;
END_VAR
VAR_OUTPUT
    loteListo : BOOL;
    cuenta : INT;
END_VAR
VAR
    prev : BOOL;
END_VAR
IF btnReset THEN
    cuenta := 0;
    loteListo := FALSE;
ELSIF sensorPieza THEN
    cuenta := cuenta + 1;
END_IF
IF cuenta >= 12 THEN
    loteListo := TRUE;
END_IF
prev := sensorPieza;
END_FUNCTION_BLOCK
