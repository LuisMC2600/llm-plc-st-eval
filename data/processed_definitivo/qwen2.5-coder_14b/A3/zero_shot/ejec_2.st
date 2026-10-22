FUNCTION_BLOCK FB_Com
VAR_INPUT
    txReq : BOOL;  // Petición de transmisión
    rxOk  : BOOL;  // Confirmación de recepción
    rxData: INT;   // Datos recibidos
END_VAR

VAR_OUTPUT
    txData  : INT;  // Datos a transmitir
    ocupado : BOOL; // Estado de ocupado
    ok      : BOOL; // Estado de éxito
    error   : BOOL; // Estado de error
    nIntentos: INT; // Número de intentos
END_VAR

VAR
    estado    : INT := 0; // Estado actual del intercambio
    intentos  : INT := 0; // Contador de intentos
    tiempoEspera: TON; // Temporizador para el plazo de espera
    valorTx   : INT := 0; // Valor a transmitir
END_VAR

// Inicialización del temporizador
tiempoEspera(IN := FALSE, PT := T#500MS);

// Máquina de estados
CASE estado OF
    0: // Estado inicial
        IF txReq THEN
            valorTx := 100; // Valor de prueba
            txData := valorTx;
            ocupado := TRUE;
            intentos := 1;
            nIntentos := intentos;
            tiempoEspera(IN := TRUE); // Iniciar temporizador
            estado := 1; // Pasar al estado de espera de respuesta
        END_IF

    1: // Estado de espera de respuesta
        IF rxOk AND (rxData = valorTx) THEN
            ok := TRUE;
            ocupado := FALSE;
            estado := 0; // Terminar intercambio
        ELSIF tiempoEspera.Q THEN
            IF intentos < 3 THEN
                intentos := intentos + 1;
                nIntentos := intentos;
                tiempoEspera(IN := TRUE); // Reiniciar temporizador
            ELSE
                error := TRUE;
                ocupado := FALSE;
                estado := 0; // Terminar intercambio
            END_IF
        END_IF

    ELSE
        estado := 0; // Restablecer estado en caso de error
END_CASE

// Mantener ok y error activos hasta el siguiente intercambio
IF estado = 0 THEN
    ok := FALSE;
    error := FALSE;
END_IF