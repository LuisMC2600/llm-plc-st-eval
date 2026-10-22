FUNCTION_BLOCK FB_Com
VAR_INPUT
    txReq : BOOL;  // Petición de transmisión
    rxOk  : BOOL;  // Confirmación de recepción
    rxData: INT;   // Datos recibidos
END_VAR

VAR_OUTPUT
    txData  : INT;  // Datos a transmitir
    ocupado : BOOL; // Indica si se está ocupado en un intercambio
    ok      : BOOL; // Indica si el intercambio fue exitoso
    error   : BOOL; // Indica si el intercambio falló
    nIntentos: INT;  // Número de intentos realizados
END_VAR

VAR
    estado    : INT := 0; // Estado del intercambio (0: Idle, 1: Enviando, 2: Esperando respuesta)
    intentos  : INT := 0; // Contador de intentos
    timer     : TON;     // Temporizador para esperar la respuesta
    valorTx   : INT := 0; // Valor a transmitir
    inicioIntercambio : BOOL := FALSE; // Indica si se ha iniciado un intercambio
END_VAR

// Inicialización del temporizador
timer(IN := FALSE, PT := T#500MS);

// Máquina de estados
CASE estado OF
    0: // Estado Idle
        IF txReq AND NOT inicioIntercambio THEN
            inicioIntercambio := TRUE;
            estado := 1;
            intentos := 1;
            nIntentos := intentos;
            valorTx := 100;
            txData := valorTx;
            ocupado := TRUE;
            timer(IN := TRUE);
        END_IF

    1: // Estado Enviando
        IF rxOk AND (rxData = valorTx) THEN
            estado := 0;
            ok := TRUE;
            ocupado := FALSE;
            inicioIntercambio := FALSE;
        ELSIF timer.Q THEN
            IF intentos < 3 THEN
                intentos := intentos + 1;
                nIntentos := intentos;
                timer(IN := TRUE);
            ELSE
                estado := 0;
                error := TRUE;
                ocupado := FALSE;
                inicioIntercambio := FALSE;
            END_IF
        END_IF

    2: // Estado Esperando respuesta
        // Este estado no se utiliza en este código, pero se mantiene por claridad.
        // El estado de espera se maneja en el estado 1.
END_CASE

// Mantener ok y error activos hasta el siguiente intercambio
IF estado = 0 THEN
    IF ok THEN
        ok := FALSE;
    END_IF
    IF error THEN
        error := FALSE;
    END_IF
END_IF