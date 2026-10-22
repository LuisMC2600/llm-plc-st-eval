FUNCTION_BLOCK FB_Com
VAR_INPUT
    txReq  : BOOL; (* Solicitud de inicio de intercambio *)
    rxOk   : BOOL; (* Confirmacion recibida del dispositivo externo *)
    rxData : INT;  (* Dato recibido (eco esperado) *)
END_VAR
VAR_OUTPUT
    txData   : INT;  (* Dato transmitido al dispositivo externo *)
    ocupado  : BOOL; (* TRUE mientras hay un intercambio en curso *)
    ok       : BOOL; (* TRUE si el intercambio termino correctamente *)
    error    : BOOL; (* TRUE si fallaron los 3 intentos *)
    nIntentos: INT;  (* Numero del intento en curso o ultimo realizado *)
END_VAR
VAR
    tIntento  : TON;       (* Temporizador de plazo por intento (500 ms) *)
    txReqPrev : BOOL;      (* Valor anterior de txReq para detectar flanco *)
    enCurso   : BOOL;      (* Intercambio activo internamente *)
    VAL_PRUEBA: INT := 100;(* Valor fijo de prueba transmitido *)
END_VAR

(* --- Deteccion de flanco ascendente en txReq --- *)
IF txReq AND NOT txReqPrev THEN
    IF NOT enCurso THEN
        (* Iniciar nuevo intercambio *)
        enCurso   := TRUE;
        ocupado   := TRUE;
        ok        := FALSE;
        error     := FALSE;
        nIntentos := 1;
        txData    := VAL_PRUEBA;
        (* Arrancar temporizador del primer intento *)
        tIntento(IN := FALSE, PT := T#500MS); (* Reset previo *)
    END_IF;
END_IF;
txReqPrev := txReq;

(* --- Logica principal del intercambio --- *)
IF enCurso THEN
    (* Mantener temporizador activo *)
    tIntento(IN := TRUE, PT := T#500MS);

    (* Comprobar respuesta correcta: rxOk activo y eco coincide *)
    IF rxOk AND (rxData = txData) THEN
        (* Intento exitoso *)
        ok        := TRUE;
        ocupado   := FALSE;
        enCurso   := FALSE;
        tIntento(IN := FALSE, PT := T#500MS); (* Detener temporizador *)

    (* Comprobar fallo: plazo vencido O rxOk con dato incorrecto *)
    ELSIF tIntento.Q OR (rxOk AND (rxData <> txData)) THEN
        (* Detener temporizador antes de evaluar siguiente paso *)
        tIntento(IN := FALSE, PT := T#500MS);

        IF nIntentos >= 3 THEN
            (* Agotados los 3 intentos *)
            error   := TRUE;
            ocupado := FALSE;
            enCurso := FALSE;
        ELSE
            (* Iniciar siguiente intento *)
            nIntentos := nIntentos + 1;
            (* El temporizador se reanudara en el proximo ciclo con IN=TRUE *)
        END_IF;
    END_IF;
END_IF;

END_FUNCTION_BLOCK