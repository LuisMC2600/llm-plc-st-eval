(* DOBLE DE PRUEBA A3/SinEco - NO ES CORPUS. Esperado: veredicto 2, falla en el paso 7 *)
FUNCTION_BLOCK FB_Com
VAR_INPUT
    txReq : BOOL;
    rxOk : BOOL;
    rxData : INT;
END_VAR
VAR_OUTPUT
    txData : INT;
    ocupado : BOOL;
    ok : BOOL;
    error : BOOL;
    nIntentos : INT;
END_VAR
VAR
    tPlazo : TON;
    prev : BOOL;
    flanco : BOOL;
END_VAR
flanco := txReq AND NOT prev;
prev := txReq;
IF flanco AND NOT ocupado THEN
    txData := 100;
    ocupado := TRUE;
    ok := FALSE;
    error := FALSE;
    nIntentos := 1;
    tPlazo(IN := FALSE, PT := T#500MS);
ELSIF ocupado THEN
    tPlazo(IN := TRUE, PT := T#500MS);
    IF rxOk THEN
        ok := TRUE;
        ocupado := FALSE;
    ELSIF rxOk OR tPlazo.Q THEN
        IF nIntentos < 3 THEN
            nIntentos := nIntentos + 1;
            tPlazo(IN := FALSE, PT := T#500MS);
        ELSE
            error := TRUE;
            ocupado := FALSE;
        END_IF
    END_IF
END_IF
END_FUNCTION_BLOCK
