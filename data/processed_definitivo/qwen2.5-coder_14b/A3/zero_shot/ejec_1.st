FUNCTION_BLOCK FB_Com
VAR_INPUT
    txReq : BOOL;  // Petición de transmisión
    rxOk  : BOOL;  // Confirmación de recepción correcta
    rxData: INT;   // Datos recibidos
END_VAR

VAR_OUTPUT
    txData : INT;  // Datos a transmitir
    ocupado: BOOL;  // Indica si el sistema está ocupado
    ok     : BOOL;  // Indica si el intercambio fue exitoso
    error  : BOOL;  // Indica si el intercambio falló
    nIntentos: INT; // Número de intentos realizados
END_VAR

VAR
    estado    : INT := 0; // Estado actual del intercambio
    intentos  : INT := 0; // Contador de intentos
    timer     : TON;      // Temporizador para el plazo de 500 ms
    valorTx   : INT := 0; // Valor a transmitir
    inicioInt : BOOL := FALSE; // Indica si se ha iniciado un intento
END_VAR

// Estado 0: Esperando petición de transmisión
IF txReq AND NOT inicioInt THEN
    estado := 1;
    intentos := 1;
    nIntentos := intentos;
    valorTx := 100;
    txData := valorTx;
    ocupado := TRUE;
    ok := FALSE;
    error := FALSE;
    timer(IN := TRUE, PT := T#500MS);
    inicioInt := TRUE;
END_IF

// Estado 1: Esperando respuesta
IF estado = 1 THEN
    IF rxOk AND rxData = valorTx THEN
        estado := 2;
        ok := TRUE;
        ocupado := FALSE;
    ELSIF timer.Q THEN
        IF intentos < 3 THEN
            intentos := intentos + 1;
            nIntentos := intentos;
            timer(IN := TRUE, PT := T#500MS);
        ELSE
            estado := 3;
            error := TRUE;
            ocupado := FALSE;
        END_IF
    END_IF
END_IF

// Estado 2: Intercambio exitoso
IF estado = 2 THEN
    // Mantener ok activo hasta la siguiente petición
END_IF

// Estado 3: Intercambio fallido
IF estado = 3 THEN
    // Mantener error activo hasta la siguiente petición
END_IF

// Reiniciar el estado si se recibe una nueva petición mientras se está ocupado
IF txReq AND inicioInt THEN
    // Ignorar la nueva petición
END_IF

// Reiniciar el estado al finalizar el intercambio
IF estado = 2 OR estado = 3 THEN
    inicioInt := FALSE;
END_IF
END_FUNCTION_BLOCK