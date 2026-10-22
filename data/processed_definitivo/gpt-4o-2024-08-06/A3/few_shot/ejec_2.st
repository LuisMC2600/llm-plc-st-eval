FUNCTION_BLOCK FB_Com
VAR_INPUT
    txReq : BOOL; (* Solicitud de transmisión *)
    rxOk : BOOL; (* Confirmación de recepción *)
    rxData : INT; (* Datos recibidos *)
END_VAR
VAR_OUTPUT
    txData : INT; (* Datos a transmitir *)
    ocupado : BOOL; (* Indica si el intercambio está en curso *)
    ok : BOOL; (* Indica si el intercambio fue exitoso *)
    error : BOOL; (* Indica si el intercambio falló *)
    nIntentos : INT; (* Número de intento actual *)
END_VAR
VAR
    intentoActual : INT := 0; (* Contador de intentos *)
    valorPrueba : INT := 100; (* Valor de prueba a transmitir *)
    tLimite : TON; (* Temporizador de límite de tiempo *)
    txReqAnt : BOOL := FALSE; (* Estado anterior de txReq *)
    intercambioEnCurso : BOOL := FALSE; (* Estado del intercambio *)
END_VAR

(* Detectar flanco ascendente de txReq *)
IF txReq AND NOT txReqAnt THEN
    IF NOT intercambioEnCurso THEN
        (* Iniciar nuevo intercambio *)
        txData := valorPrueba;
        ocupado := TRUE;
        ok := FALSE;
        error := FALSE;
        intentoActual := 1;
        intercambioEnCurso := TRUE;
        tLimite(IN := TRUE, PT := T#500MS);
    END_IF;
END_IF;

(* Control de intentos y recepción *)
IF intercambioEnCurso THEN
    IF tLimite.Q THEN
        (* Tiempo límite alcanzado, intento fallido *)
        intentoActual := intentoActual + 1;
        IF intentoActual > 3 THEN
            (* Todos los intentos fallaron *)
            error := TRUE;
            ocupado := FALSE;
            intercambioEnCurso := FALSE;
        ELSE
            (* Iniciar nuevo intento *)
            tLimite(IN := TRUE, PT := T#500MS);
        END_IF;
    ELSIF rxOk AND (rxData = valorPrueba) THEN
        (* Intento exitoso *)
        ok := TRUE;
        ocupado := FALSE;
        intercambioEnCurso := FALSE;
    END_IF;
END_IF;

(* Actualizar salidas *)
nIntentos := intentoActual;

(* Almacenar estado anterior de txReq *)
txReqAnt := txReq;
END_FUNCTION_BLOCK