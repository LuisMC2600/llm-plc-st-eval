```pascal
FUNCTION_BLOCK FB_Com
VAR_INPUT
    txReq : BOOL; (* Solicitud de transmision *)
    rxOk : BOOL; (* Confirmacion de recepcion *)
    rxData : INT; (* Datos recibidos *)
END_VAR
VAR_OUTPUT
    txData : INT; (* Datos a transmitir *)
    ocupado : BOOL; (* Indicador de intercambio en curso *)
    ok : BOOL; (* Indicador de intercambio exitoso *)
    error : BOOL; (* Indicador de error en el intercambio *)
    nIntentos : INT; (* Numero de intento actual *)
END_VAR
VAR
    txReqPrev : BOOL; (* Estado previo de txReq *)
    intentoActual : INT; (* Contador de intentos *)
    tTimeout : TON; (* Temporizador de timeout *)
    intercambioActivo : BOOL; (* Indicador de intercambio activo *)
END_VAR

(* Inicializacion de variables *)
IF NOT intercambioActivo THEN
    IF txReq AND NOT txReqPrev THEN
        (* Inicio de un nuevo intercambio *)
        txData := 100;
        ocupado := TRUE;
        ok := FALSE;
        error := FALSE;
        intentoActual := 1;
        nIntentos := intentoActual;
        intercambioActivo := TRUE;
        tTimeout(IN := TRUE, PT := T#500MS);
    END_IF;
ELSE
    (* Proceso de intercambio en curso *)
    IF tTimeout.Q THEN
        (* Timeout del intento actual *)
        intentoActual := intentoActual + 1;
        IF intentoActual > 3 THEN
            (* Todos los intentos fallaron *)
            error := TRUE;
            ocupado := FALSE;
            intercambioActivo := FALSE;
        ELSE
            (* Iniciar siguiente intento *)
            nIntentos := intentoActual;
            tTimeout(IN := TRUE, PT := T#500MS);
        END_IF;
    ELSIF rxOk AND (rxData = txData) THEN
        (* Intento exitoso *)
        ok := TRUE;
        ocupado := FALSE;
        intercambioActivo := FALSE;
    END_IF;
END_IF;

(* Actualizar estado previo de txReq *)
txReqPrev := txReq;
END_FUNCTION_BLOCK
```