```pascal
FUNCTION_BLOCK FB_Com

VAR_INPUT
    txReq  : BOOL; (* Solicitud de transmisión *)
    rxOk   : BOOL; (* Confirmación de recepción del dispositivo externo *)
    rxData : INT;  (* Dato recibido (eco) *)
END_VAR

VAR_OUTPUT
    txData   : INT;  (* Dato transmitido *)
    ocupado  : BOOL; (* Intercambio en curso *)
    ok       : BOOL; (* Último intercambio correcto *)
    error    : BOOL; (* Fallaron los 3 intentos *)
    nIntentos: INT;  (* Número de intento en curso / último *)
END_VAR

VAR
    txReq_prev : BOOL;        (* Valor anterior de txReq para detectar flanco *)
    timer      : TON;         (* Temporizador de 500 ms por intento *)
    timerStart : BOOL;        (* Señal de arranque del temporizador *)
    TEST_VALUE : INT := 100;  (* Valor de prueba fijo *)
    MAX_INTENTOS : INT := 3;  (* Máximo de intentos permitidos *)
END_VAR

(* ─────────────────────────────────────────────────────────────
   Detección de flanco ascendente en txReq
   ───────────────────────────────────────────────────────────── *)
IF txReq AND NOT txReq_prev THEN
    (* Flanco detectado: iniciar intercambio solo si no hay uno en curso *)
    IF NOT ocupado THEN
        ocupado   := TRUE;
        ok        := FALSE;
        error     := FALSE;
        nIntentos := 1;
        txData    := TEST_VALUE;
        timerStart := FALSE; (* Forzar reinicio del TON en el siguiente ciclo *)
    END_IF;
END_IF;
txReq_prev := txReq;

(* ─────────────────────────────────────────────────────────────
   Lógica principal: solo activa cuando hay intercambio en curso
   ───────────────────────────────────────────────────────────── *)
IF ocupado THEN

    (* Arrancar / mantener el temporizador del intento actual *)
    timerStart := TRUE;
    timer(IN := timerStart, PT := T#500MS);

    (* Comprobar respuesta correcta: rxOk activo y eco coincide *)
    IF rxOk AND (rxData = txData) THEN
        (* Intento exitoso *)
        ok        := TRUE;
        ocupado   := FALSE;
        timerStart := FALSE;
        timer(IN := FALSE, PT := T#500MS); (* Detener temporizador *)

    (* Comprobar fallo: tiempo agotado O rxOk con dato incorrecto *)
    ELSIF timer.Q OR (rxOk AND (rxData <> txData)) THEN
        (* Intento fallido *)
        IF nIntentos < MAX_INTENTOS THEN
            (* Iniciar siguiente intento *)
            nIntentos  := nIntentos + 1;
            timerStart := FALSE;             (* Bajar IN para reiniciar TON *)
            timer(IN := FALSE, PT := T#500MS);
            (* timerStart se volverá TRUE en el próximo ciclo *)
        ELSE
            (* Se agotaron los 3 intentos *)
            error      := TRUE;
            ocupado    := FALSE;
            timerStart := FALSE;
            timer(IN := FALSE, PT := T#500MS); (* Detener temporizador *)
        END_IF;
    END_IF;

END_IF;

(* Llamada final al temporizador para actualizar su salida Q *)
timer(IN := timerStart, PT := T#500MS);
```