FUNCTION_BLOCK FB_Com
VAR_INPUT
    txReq : BOOL; (* Peticion de transmision *)
    rxOk : BOOL; (* Confirmacion de recepcion *)
    rxData : INT; (* Dato recibido (eco) *)
END_VAR
VAR_OUTPUT
    txData : INT; (* Dato a transmitir *)
    ocupado : BOOL; (* Intercambio en curso *)
    ok : BOOL; (* Intercambio finalizado con exito *)
    error : BOOL; (* Intercambio fallido tras 3 intentos *)
    nIntentos : INT; (* Numero de intento en curso *)
END_VAR
VAR
    reqTrig : R_TRIG; (* Flanco de subida de la peticion *)
    rxTrig : R_TRIG; (* Flanco de subida de la recepcion *)
    tTimeout : TON; (* Temporizador de plazo de espera *)
    resetTimer : BOOL; (* Pulso para reiniciar el temporizador *)
END_VAR

(* Deteccion de flancos *)
reqTrig(CLK := txReq);
rxTrig(CLK := rxOk);

(* Inicio de un nuevo intercambio (se ignora si ya esta ocupado) *)
IF reqTrig.Q AND NOT ocupado THEN
    txData := 100;
    ocupado := TRUE;
    ok := FALSE;
    error := FALSE;
    nIntentos := 1;
    resetTimer := TRUE;
END_IF;

(* Evaluacion del intento en curso *)
IF ocupado THEN
    IF rxTrig.Q AND (rxData = txData) THEN
        (* Confirmacion recibida correctamente *)
        ok := TRUE;
        ocupado := FALSE;
    ELSIF rxTrig.Q OR tTimeout.Q THEN
        (* Falla por dato incorrecto o por agotarse el tiempo (timeout) *)
        IF nIntentos < 3 THEN
            nIntentos := nIntentos + 1;
            resetTimer := TRUE; (* Reinicia el temporizador para el siguiente intento *)
        ELSE
            (* Se agotaron los 3 intentos *)
            error := TRUE;
            ocupado := FALSE;
        END_IF;
    END_IF;
END_IF;

(* Control del temporizador: se detiene si no esta ocupado o si se requiere reinicio *)
tTimeout(IN := ocupado AND NOT resetTimer, PT := T#500MS);
resetTimer := FALSE;

END_FUNCTION_BLOCK