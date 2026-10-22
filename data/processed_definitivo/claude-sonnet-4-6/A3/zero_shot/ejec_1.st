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
    nIntentos: INT;  (* Número de intento en curso / último *)
END_VAR

VAR
    txReq_prev : BOOL;        (* Valor anterior de txReq para detectar flanco *)
    timer      : TON;         (* Temporizador de plazo por intento *)
    timerRun   : BOOL;        (* Habilita el temporizador *)
    TEST_VALUE : INT := 100;  (* Valor de prueba fijo *)
    MAX_INT    : INT := 3;    (* Máximo número de intentos *)
END_VAR

(* ── Temporizador ── *)
timer(IN := timerRun, PT := T#500MS);

(* ── Detección de flanco ascendente en txReq ── *)
IF txReq AND NOT txReq_prev THEN
    IF NOT ocupado THEN
        (* Iniciar nuevo intercambio *)
        ok        := FALSE;
        error     := FALSE;
        ocupado   := TRUE;
        nIntentos := 1;
        txData    := TEST_VALUE;
        timerRun  := TRUE;   (* Arrancar temporizador del intento 1 *)
    END_IF;
    (* Si ocupado = TRUE, el flanco se ignora *)
END_IF;

(* ── Lógica principal durante un intercambio ── *)
IF ocupado THEN

    IF rxOk THEN
        (* Ha llegado respuesta del dispositivo *)
        IF rxData = txData THEN
            (* ── Intento correcto ── *)
            timerRun := FALSE;
            ocupado  := FALSE;
            ok       := TRUE;
        ELSE
            (* ── Respuesta incorrecta: tratar como fallo de intento ── *)
            timerRun := FALSE;          (* Detener y resetear temporizador *)
            IF nIntentos < MAX_INT THEN
                nIntentos := nIntentos + 1;
                timerRun  := TRUE;      (* Nuevo plazo para el siguiente intento *)
            ELSE
                (* Agotados los 3 intentos *)
                ocupado := FALSE;
                error   := TRUE;
            END_IF;
        END_IF;

    ELSIF timer.Q THEN
        (* ── Plazo vencido sin confirmación ── *)
        timerRun := FALSE;              (* Resetear temporizador *)
        IF nIntentos < MAX_INT THEN
            nIntentos := nIntentos + 1;
            timerRun  := TRUE;          (* Nuevo plazo para el siguiente intento *)
        ELSE
            (* Agotados los 3 intentos *)
            ocupado := FALSE;
            error   := TRUE;
        END_IF;
    END_IF;

END_IF;

(* ── Guardar estado anterior de txReq ── *)
txReq_prev := txReq;