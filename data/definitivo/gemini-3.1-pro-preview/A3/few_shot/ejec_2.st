FUNCTION_BLOCK FB_Com
VAR_INPUT
    txReq : BOOL;  (* Peticion de transmision *)
    rxOk : BOOL;   (* Confirmacion de recepcion *)
    rxData : INT;  (* Datos recibidos (eco) *)
END_VAR
VAR_OUTPUT
    txData : INT;  (* Datos a transmitir *)
    ocupado : BOOL;(* Intercambio en curso *)
    ok : BOOL;     (* Intercambio correcto *)
    error : BOOL;  (* Intercambio fallido tras 3 intentos *)
    nIntentos : INT; (* Numero de intento actual *)
END_VAR
VAR
    flancoReq : R_TRIG; (* Detector de flanco para txReq *)
    flancoRx : R_TRIG;  (* Detector de flanco para rxOk *)
    temporizador : TON; (* Temporizador de 500 ms *)
    resetTemp : BOOL;   (* Señal para reiniciar el temporizador *)
END_VAR

(* Deteccion de flancos *)
flancoReq(CLK := txReq);
flancoRx(CLK := rxOk);

(* Inicio de un nuevo intercambio si no esta ocupado *)
IF flancoReq.Q AND NOT ocupado THEN
    ocupado := TRUE;
    ok := FALSE;
    error := FALSE;
    nIntentos := 1;
    txData := 100;
    resetTemp := TRUE;
ELSE
    resetTemp := FALSE;
END_IF;

(* Temporizador del intento en curso (se reinicia con resetTemp) *)
temporizador(IN := ocupado AND NOT resetTemp, PT := T#500MS);

(* Logica durante el intercambio *)
IF ocupado THEN
    (* Evaluacion de la respuesta *)
    IF flancoRx.Q THEN
        IF rxData = txData THEN
            (* Respuesta correcta (eco valido) *)
            ok := TRUE;
            ocupado := FALSE;
        ELSE
            (* Respuesta incorrecta: falla el intento *)
            IF nIntentos < 3 THEN
                nIntentos := nIntentos + 1;
                resetTemp := TRUE;
            ELSE
                error := TRUE;
                ocupado := FALSE;
            END_IF;
        END_IF;
    (* Evaluacion del timeout *)
    ELSIF temporizador.Q THEN
        IF nIntentos < 3 THEN
            nIntentos := nIntentos + 1;
            resetTemp := TRUE;
        ELSE
            error := TRUE;
            ocupado := FALSE;
        END_IF;
    END_IF;
END_IF;
END_FUNCTION_BLOCK