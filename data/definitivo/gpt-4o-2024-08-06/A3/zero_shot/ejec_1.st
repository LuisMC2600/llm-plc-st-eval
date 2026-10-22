```pascal
FUNCTION_BLOCK FB_Com
VAR
    // Entradas
    txReq : BOOL;
    rxOk : BOOL;
    rxData : INT;
    
    // Salidas
    txData : INT;
    ocupado : BOOL;
    ok : BOOL;
    error : BOOL;
    nIntentos : INT;
    
    // Variables internas
    txReqPrev : BOOL; // Para detectar flancos
    intentoActual : INT; // Contador de intentos
    timer : TON; // Temporizador para los 500 ms
    intentoExitoso : BOOL; // Indica si el intento fue exitoso
END_VAR

// Inicialización de variables
IF NOT ocupado THEN
    txData := 100; // Valor de prueba
    intentoActual := 0;
    intentoExitoso := FALSE;
    ok := FALSE;
    error := FALSE;
END_IF

// Detección de flanco ascendente en txReq
IF txReq AND NOT txReqPrev THEN
    IF NOT ocupado THEN
        // Iniciar nuevo intercambio
        ocupado := TRUE;
        intentoActual := 1;
        nIntentos := intentoActual;
        timer(IN := TRUE, PT := T#500MS);
    END_IF
END_IF

// Guardar estado anterior de txReq
txReqPrev := txReq;

// Lógica de intercambio
IF ocupado THEN
    // Verificar si el temporizador ha expirado
    timer(IN := TRUE);
    IF timer.Q THEN
        // Intento fallido, incrementar contador de intentos
        intentoActual := intentoActual + 1;
        IF intentoActual > 3 THEN
            // Todos los intentos fallaron
            error := TRUE;
            ocupado := FALSE;
        ELSE
            // Iniciar nuevo intento
            nIntentos := intentoActual;
            timer(IN := TRUE, PT := T#500MS);
        END_IF
    ELSE
        // Verificar si el intento es exitoso
        IF rxOk AND (rxData = txData) THEN
            intentoExitoso := TRUE;
            ok := TRUE;
            ocupado := FALSE;
        END_IF
    END_IF
END_IF
```

Este código implementa un intercambio de petición/respuesta con un dispositivo externo, manejando hasta 3 intentos y verificando el éxito de cada intento dentro de un plazo de 500 milisegundos.