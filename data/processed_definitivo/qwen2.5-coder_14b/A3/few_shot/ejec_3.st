FUNCTION_BLOCK FB_Com
VAR_INPUT
    txReq : BOOL; (* Petición de transmisión *)
    rxOk : BOOL; (* Confirmación de recepción *)
    rxData : INT; (* Datos recibidos *)
END_VAR
VAR_OUTPUT
    txData : INT; (* Datos a transmitir *)
    ocupado : BOOL; (* Estado ocupado *)
    ok : BOOL; (* Confirmación de éxito *)
    error : BOOL; (* Confirmación de error *)
    nIntentos : INT; (* Número de intentos *)
END_VAR
VAR
    tEspera : TP; (* Temporizador de espera *)
    estado : INT; (* Estado actual del intercambio *)
    intentos : INT; (* Contador de intentos *)
END_VAR

(* Estados: 0 - Inactivo, 1 - En espera de respuesta, 2 - Éxito, 3 - Error *)
IF txReq AND NOT ocupado THEN
    estado := 1;
    intentos := 1;
    txData := 100;
    ocupado := TRUE;
    tEspera(IN := TRUE, PT := T#500MS);
END_IF

IF estado = 1 THEN
    IF tEspera.Q THEN
        IF rxOk AND rxData = txData THEN
            estado := 2;
            ok := TRUE;
        ELSE
            estado := 3;
            error := TRUE;
        END_IF
        ocupado := FALSE;
    END_IF
END_IF

IF estado = 3 AND intentos < 3 THEN
    estado := 1;
    intentos := intentos + 1;
    tEspera(IN := TRUE, PT := T#500MS);
END_IF

nIntentos := intentos;

IF estado = 2 THEN
    ocupado := FALSE;
    ok := TRUE;
END_IF

IF estado = 3 AND intentos = 3 THEN
    ocupado := FALSE;
    error := TRUE;
END_IF

END_FUNCTION_BLOCK