FUNCTION_BLOCK FB_Com
VAR
    // Entradas
    txReq: BOOL;
    rxOk: BOOL;
    rxData: INT;

    // Salidas
    txData: INT;
    ocupado: BOOL;
    ok: BOOL;
    error: BOOL;
    nIntentos: INT;

    // Variables internas
    intentoActual: INT := 0;
    tiempoInicio: TIME;
    tiempoTranscurrido: TIME;
    txReqPrev: BOOL := FALSE;
    intentoExitoso: BOOL := FALSE;
END_VAR

VAR CONSTANT
    VALOR_PRUEBA: INT := 100;
    TIEMPO_MAXIMO: TIME := T#500MS;
    MAX_INTENTOS: INT := 3;
END_VAR

// Lógica del bloque de funciones
IF NOT ocupado THEN
    // Detectar flanco ascendente de txReq
    IF txReq AND NOT txReqPrev THEN
        // Iniciar un nuevo intercambio
        txData := VALOR_PRUEBA;
        ocupado := TRUE;
        ok := FALSE;
        error := FALSE;
        intentoActual := 1;
        nIntentos := intentoActual;
        tiempoInicio := TIME(); // Guardar el tiempo de inicio
    END_IF;
ELSE
    // Intercambio en curso
    tiempoTranscurrido := TIME() - tiempoInicio;

    IF rxOk AND (rxData = VALOR_PRUEBA) THEN
        // Intento exitoso
        intentoExitoso := TRUE;
        ok := TRUE;
        ocupado := FALSE;
    ELSIF tiempoTranscurrido >= TIEMPO_MAXIMO THEN
        // Intento fallido, verificar si hay más intentos
        intentoActual := intentoActual + 1;
        IF intentoActual > MAX_INTENTOS THEN
            // Todos los intentos fallaron
            error := TRUE;
            ocupado := FALSE;
        ELSE
            // Iniciar un nuevo intento
            nIntentos := intentoActual;
            tiempoInicio := TIME(); // Reiniciar el tiempo de inicio
        END_IF;
    END_IF;
END_IF;

// Actualizar txReqPrev para detectar flancos
txReqPrev := txReq;