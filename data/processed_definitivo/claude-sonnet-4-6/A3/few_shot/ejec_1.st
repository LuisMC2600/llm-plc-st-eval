FUNCTION_BLOCK FB_Com
VAR_INPUT
    txReq  : BOOL; (* Solicitud de inicio de intercambio *)
    rxOk   : BOOL; (* Confirmacion de recepcion del dispositivo externo *)
    rxData : INT;  (* Dato recibido del dispositivo externo *)
END_VAR
VAR_OUTPUT
    txData   : INT;  (* Dato transmitido al dispositivo externo *)
    ocupado  : BOOL; (* Intercambio en curso *)
    ok       : BOOL; (* Intercambio completado con exito *)
    error    : BOOL; (* Fallaron los 3 intentos *)
    nIntentos: INT;  (* Numero del intento en curso o ultimo realizado *)
END_VAR
VAR
    tIntento   : TON;        (* Temporizador de plazo por intento: 500 ms *)
    txReq_prev : BOOL;       (* Valor anterior de txReq para detectar flanco *)
    flanco     : BOOL;       (* Flanco ascendente de txReq *)
    rxOk_prev  : BOOL;       (* Valor anterior de rxOk para detectar flanco *)
    flancoRx   : BOOL;       (* Flanco ascendente de rxOk *)
    TX_VALUE   : INT := 100; (* Valor de prueba fijo a transmitir *)
    MAX_INT    : INT := 3;   (* Numero maximo de intentos *)
END_VAR

(* --- Deteccion de flancos ascendentes --- *)
flanco   := txReq  AND NOT txReq_prev;
flancoRx := rxOk   AND NOT rxOk_prev;

(* --- Inicio de un nuevo intercambio (solo si no hay uno en curso) --- *)
IF flanco AND NOT ocupado THEN
    ocupado   := TRUE;
    ok        := FALSE;
    error     := FALSE;
    nIntentos := 1;
    txData    := TX_VALUE;
    tIntento(IN := FALSE, PT := T#500MS); (* Reset del temporizador *)
END_IF;

(* --- Logica principal durante un intercambio en curso --- *)
IF ocupado THEN
    (* Arrancar/mantener el temporizador del intento actual *)
    tIntento(IN := TRUE, PT := T#500MS);

    (* Caso 1: respuesta correcta dentro del plazo *)
    IF flancoRx AND (rxData = TX_VALUE) AND NOT tIntento.Q THEN
        ocupado  := FALSE;
        ok       := TRUE;
        tIntento(IN := FALSE, PT := T#500MS); (* Detener temporizador *)

    (* Caso 2: plazo vencido sin confirmacion, o respuesta con dato incorrecto *)
    ELSIF tIntento.Q OR (flancoRx AND (rxData <> TX_VALUE)) THEN
        IF nIntentos < MAX_INT THEN
            (* Iniciar siguiente intento *)
            nIntentos := nIntentos + 1;
            tIntento(IN := FALSE, PT := T#500MS); (* Reset para nuevo plazo *)
        ELSE
            (* Se agotaron los 3 intentos *)
            ocupado := FALSE;
            error   := TRUE;
            tIntento(IN := FALSE, PT := T#500MS); (* Detener temporizador *)
        END_IF;
    END_IF;
END_IF;

(* --- Guardar estados anteriores para proxima ejecucion --- *)
txReq_prev := txReq;
rxOk_prev  := rxOk;

END_FUNCTION_BLOCK