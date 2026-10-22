FUNCTION_BLOCK FB_Com
VAR_INPUT
    txReq  : BOOL; (* Solicitud de transmisión *)
    rxOk   : BOOL; (* Confirmación de recepción del dispositivo externo *)
    rxData : INT;  (* Dato recibido (eco) *)
END_VAR

VAR_OUTPUT
    txData   : INT;  (* Dato transmitido *)
    ocupado  : BOOL; (* Intercambio en curso *)
    ok       : BOOL; (* Último intercambio exitoso *)
    error    : BOOL; (* Fallaron los 3 intentos *)
    nIntentos: INT;  (* Número de intento en curso / último intento realizado *)
END_VAR

VAR
    txReq_prev : BOOL;       (* Valor anterior de txReq para detectar flanco ascendente *)
    timer      : TON;        (* Temporizador de plazo por intento *)
    activo     : BOOL;       (* Intercambio en curso internamente *)
    valorTx    : INT := 100; (* Valor de prueba fijo *)
END_VAR

(* ── Detección de flanco ascendente de txReq ── *)
IF txReq AND NOT txReq_prev THEN
    IF NOT activo THEN
        (* Iniciar nuevo intercambio *)
        activo    := TRUE;
        ocupado   := TRUE;
        ok        := FALSE;
        error     := FALSE;
        nIntentos := 1;
        txData    := valorTx;
        (* Arrancar temporizador del primer intento *)
        timer(IN := FALSE, PT := T#500MS);
        timer(IN := TRUE,  PT := T#500MS);
    END_IF;
    (* Si activo = TRUE, el flanco se ignora *)
END_IF;

(* ── Lógica principal del intercambio ── *)
IF activo THEN
    (* Actualizar temporizador *)
    timer(IN := TRUE, PT := T#500MS);

    (* Comprobar respuesta correcta: rxOk activo y eco coincide *)
    IF rxOk AND (rxData = txData) THEN
        (* Intento exitoso *)
        ok      := TRUE;
        error   := FALSE;
        ocupado := FALSE;
        activo  := FALSE;
        timer(IN := FALSE, PT := T#500MS); (* Detener temporizador *)

    (* Comprobar fallo: plazo vencido O rxOk con dato incorrecto *)
    ELSIF timer.Q OR (rxOk AND (rxData <> txData)) THEN
        (* Intento fallido *)
        timer(IN := FALSE, PT := T#500MS); (* Resetear temporizador *)

        IF nIntentos < 3 THEN
            (* Iniciar siguiente intento *)
            nIntentos := nIntentos + 1;
            txData    := valorTx;
            timer(IN := TRUE, PT := T#500MS); (* Arrancar nuevo plazo *)
        ELSE
            (* Agotados los 3 intentos *)
            error   := TRUE;
            ok      := FALSE;
            ocupado := FALSE;
            activo  := FALSE;
        END_IF;
    END_IF;
END_IF;

(* ── Guardar estado anterior de txReq ── *)
txReq_prev := txReq;