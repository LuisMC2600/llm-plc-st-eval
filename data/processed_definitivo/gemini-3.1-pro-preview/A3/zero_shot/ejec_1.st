FUNCTION_BLOCK FB_Com
VAR_INPUT
    txReq : BOOL;   // Petición de transmisión
    rxOk : BOOL;    // Confirmación de recepción
    rxData : INT;   // Dato recibido
END_VAR

VAR_OUTPUT
    txData : INT;   // Dato a transmitir
    ocupado : BOOL; // Intercambio en curso
    ok : BOOL;      // Intercambio exitoso
    error : BOOL;   // Intercambio fallido tras 3 intentos
    nIntentos : INT;// Número de intento actual (1, 2 o 3)
END_VAR

VAR
    rtTxReq : R_TRIG; // Detector de flanco para txReq
    rtRxOk : R_TRIG;  // Detector de flanco para rxOk
    timer : TON;      // Temporizador de 500ms
    timerIn : BOOL;   // Control de inicio/reinicio del temporizador
END_VAR

// Detección de flancos ascendentes
rtTxReq(CLK := txReq);
rtRxOk(CLK := rxOk);

// Inicio de un nuevo intercambio (se ignora si ya está ocupado)
IF rtTxReq.Q AND NOT ocupado THEN
    txData := 100;
    ocupado := TRUE;
    ok := FALSE;
    error := FALSE;
    nIntentos := 1;
    timerIn := FALSE; // Fuerza un ciclo en FALSE para reiniciar el temporizador
END_IF;

// Actualización del temporizador
timer(IN := timerIn, PT := T#500MS);

// Máquina de estados durante el intercambio
IF ocupado THEN
    IF timerIn THEN
        // El temporizador está corriendo, evaluar condiciones de respuesta o timeout
        IF rtRxOk.Q AND (rxData = txData) THEN
            // Éxito: se recibió confirmación con el eco correcto
            ok := TRUE;
            ocupado := FALSE;
            timerIn := FALSE;
            
        ELSIF timer.Q OR (rtRxOk.Q AND (rxData <> txData)) THEN
            // Falla: por tiempo agotado o por dato incorrecto
            IF nIntentos < 3 THEN
                nIntentos := nIntentos + 1;
                timerIn := FALSE; // Reinicia el temporizador en el próximo ciclo
            ELSE
                // Fallaron los 3 intentos permitidos
                error := TRUE;
                ocupado := FALSE;
                timerIn := FALSE;
            END_IF;
        END_IF;
    ELSE
        // Activar el temporizador para iniciar el conteo del intento actual
        timerIn := TRUE;
    END_IF;
ELSE
    // Asegurar que el temporizador se mantenga apagado si no hay intercambio activo
    timerIn := FALSE;
END_IF;
END_FUNCTION_BLOCK