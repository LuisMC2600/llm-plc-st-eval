```iecst
FUNCTION_BLOCK FB_Com
VAR_INPUT
    txReq : BOOL;
    rxOk : BOOL;
    rxData : INT;
END_VAR
VAR_OUTPUT
    txData : INT;
    ocupado : BOOL;
    ok : BOOL;
    error : BOOL;
    nIntentos : INT;
END_VAR
VAR
    reqTrig : R_TRIG;
    rxTrig : R_TRIG;
    timer : TON;
END_VAR

// Detectar flancos de subida en las señales de control
reqTrig(CLK := txReq);
rxTrig(CLK := rxOk);

// Iniciar un nuevo intercambio (se ignora si ya está en curso)
IF reqTrig.Q AND NOT ocupado THEN
    txData := 100;
    ocupado := TRUE;
    ok := FALSE;
    error := FALSE;
    nIntentos := 1;
    timer(IN := FALSE, PT := T#500MS); // Reset inicial del temporizador
END_IF;

// Lógica de control durante el intercambio activo
IF ocupado THEN
    // Ejecutar temporizador para el intento actual
    timer(IN := TRUE, PT := T#500MS);

    // Evaluar si se recibe confirmación con el dato correcto (eco)
    IF rxTrig.Q AND (rxData = txData) THEN
        ok := TRUE;
        ocupado := FALSE;
        timer(IN := FALSE, PT := T#500MS); // Detener temporizador
        
    // Evaluar si el intento falla (por timeout o por dato incorrecto)
    ELSIF timer.Q OR (rxTrig.Q AND (rxData <> txData)) THEN
        IF nIntentos < 3 THEN
            nIntentos := nIntentos + 1;        // Incrementar contador de intentos
            timer(IN := FALSE, PT := T#500MS); // Reiniciar temporizador para el nuevo intento
        ELSE
            error := TRUE;                     // Activar error tras agotar los 3 intentos
            ocupado := FALSE;
            timer(IN := FALSE, PT := T#500MS); // Detener temporizador
        END_IF;
    END_IF;
ELSE
    // Mantener el temporizador inactivo cuando no hay intercambio
    timer(IN := FALSE, PT := T#500MS);
END_IF;
END_FUNCTION_BLOCK
```