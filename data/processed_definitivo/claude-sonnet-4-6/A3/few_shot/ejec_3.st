FUNCTION_BLOCK FB_Com
VAR_INPUT
    txReq  : BOOL; (* Solicitud de inicio de intercambio *)
    rxOk   : BOOL; (* Confirmacion recibida del dispositivo externo *)
    rxData : INT;  (* Dato recibido (eco esperado) *)
END_VAR
VAR_OUTPUT
    txData   : INT;  (* Dato transmitido al dispositivo externo *)
    ocupado  : BOOL; (* Intercambio en curso *)
    ok       : BOOL; (* Ultimo intercambio exitoso *)
    error    : BOOL; (* Fallaron los 3 intentos *)
    nIntentos: INT;  (* Numero del intento en curso *)
END_VAR
VAR
    tTimeout  : TON;          (* Temporizador de plazo por intento *)
    txReqPrev : BOOL;         (* Valor anterior de txReq para detectar flanco *)
    activo    : BOOL;         (* Intercambio en curso (interno) *)
    txValor   : INT := 100;   (* Valor de prueba fijo *)
END_VAR

(* --- Deteccion de flanco ascendente en txReq --- *)
IF txReq AND NOT txReqPrev AND NOT activo THEN
    (* Inicio de nuevo intercambio *)
    activo    := TRUE;
    ocupado   := TRUE;
    ok        := FALSE;
    error     := FALSE;
    nIntentos := 1;
    txData    := txValor;
    tTimeout(IN := FALSE, PT := T#500MS); (* Reset del temporizador *)
END_IF;
txReqPrev := txReq;

(* --- Logica principal del intercambio --- *)
IF activo THEN
    (* Ejecutar temporizador del intento actual *)
    tTimeout(IN := TRUE, PT := T#500MS);

    (* Verificar respuesta correcta: rxOk activo y eco correcto *)
    IF rxOk AND (rxData = txValor) THEN
        (* Intento exitoso *)
        ok       := TRUE;
        ocupado  := FALSE;
        activo   := FALSE;
        tTimeout(IN := FALSE, PT := T#500MS); (* Detener temporizador *)

    (* Verificar fallo: plazo vencido o eco incorrecto *)
    ELSIF tTimeout.Q OR (rxOk AND (rxData <> txValor)) THEN
        tTimeout(IN := FALSE, PT := T#500MS); (* Reset del temporizador *)

        IF nIntentos < 3 THEN
            (* Iniciar siguiente intento *)
            nIntentos := nIntentos + 1;
            (* El temporizador arrancara en el proximo ciclo con IN=TRUE *)
        ELSE
            (* Agotados los 3 intentos: error *)
            error   := TRUE;
            ocupado := FALSE;
            activo  := FALSE;
        END_IF;
    END_IF;
END_IF;

END_FUNCTION_BLOCK