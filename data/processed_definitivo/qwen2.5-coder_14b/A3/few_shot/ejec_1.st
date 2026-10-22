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
    error : BOOL; (* Error en la transmisión *)
    nIntentos : INT; (* Número de intentos *)
END_VAR
VAR
    tEspera : TP; (* Temporizador de espera *)
    estado : INT := 0; (* Estado del intercambio *)
    intentos : INT := 0; (* Contador de intentos *)
    valorTx : INT := 0; (* Valor a transmitir *)
END_VAR

(* Estado 0: Esperando petición *)
IF txReq AND NOT ocupado THEN
    estado := 1;
    intentos := 1;
    valorTx := 100;
    txData := valorTx;
    ocupado := TRUE;
    tEspera(IN := TRUE, PT := T#500MS);
END_IF

(* Estado 1: Esperando respuesta *)
IF estado = 1 THEN
    IF tEspera.Q THEN
        IF rxOk AND rxData = valorTx THEN
            estado := 2;
            ok := TRUE;
        ELSE
            estado := 0;
            intentos := intentos + 1;
            IF intentos <= 3 THEN
                estado := 1;
                tEspera(IN := TRUE, PT := T#500MS);
            ELSE
                estado := 3;
                error := TRUE;
            END_IF
        END_IF
    END_IF
END_IF

(* Estado 2: Transmisión exitosa *)
IF estado = 2 THEN
    ocupado := FALSE;
END_IF

(* Estado 3: Transmisión fallida *)
IF estado = 3 THEN
    ocupado := FALSE;
END_IF

(* Actualizar nIntentos *)
nIntentos := intentos;

END_FUNCTION_BLOCK