FUNCTION_BLOCK FB_Com
VAR_INPUT
    txReq : BOOL;   (* Peticion de transmision *)
    rxOk : BOOL;    (* Confirmacion de recepcion *)
    rxData : INT;   (* Dato recibido (eco) *)
END_VAR
VAR_OUTPUT
    txData : INT;   (* Dato a transmitir *)
    ocupado : BOOL; (* Intercambio en curso *)
    ok : BOOL;      (* Intercambio correcto *)
    error : BOOL;   (* Intercambio fallido tras 3 intentos *)
    nIntentos : INT;(* Numero de intento actual *)
END_VAR
VAR
    rTrigReq : R_TRIG; (* Detector de flanco para txReq *)
    rTrigRx : R_TRIG;  (* Detector de flanco para rxOk *)
    tTimeout : TON;    (* Temporizador de 500 ms *)
END_VAR

(* Deteccion de flancos *)
rTrigReq(CLK := txReq);
rTrigRx(CLK := rxOk);

(* Inicio de un nuevo intercambio si no hay uno en curso *)
IF rTrigReq.Q AND NOT ocupado THEN
    txData := 100;
    ocupado := TRUE;
    ok := FALSE;
    error := FALSE;
    nIntentos := 1;
    tTimeout(IN := FALSE, PT := T#500MS); (* Asegura el reinicio del temporizador *)
END_IF;

(* Control del intercambio en curso *)
IF ocupado THEN
    (* Actualiza el temporizador del intento actual *)
    tTimeout(IN := TRUE, PT := T#500MS);
    
    (* Evaluacion de la respuesta *)
    IF rTrigRx.Q AND (rxData = txData) THEN
        (* Intento correcto *)
        ok := TRUE;
        ocupado := FALSE;
        tTimeout(IN := FALSE, PT := T#500MS);
        
    ELSIF tTimeout.Q OR (rTrigRx.Q AND (rxData <> txData)) THEN
        (* Intento fallido por timeout o dato incorrecto *)
        IF nIntentos < 3 THEN
            (* Pasa al siguiente intento *)
            nIntentos := nIntentos + 1;
            tTimeout(IN := FALSE, PT := T#500MS); (* Reinicia el tiempo para el nuevo intento *)
        ELSE
            (* Fallaron los 3 intentos *)
            error := TRUE;
            ocupado := FALSE;
            tTimeout(IN := FALSE, PT := T#500MS);
        END_IF;
    END_IF;
END_IF;
END_FUNCTION_BLOCK