```pascal
FUNCTION_BLOCK FB_Com
VAR
    // Entradas
    txReq : BOOL;
    rxOk : BOOL;
    rxData : INT;
    
    // Salidas
    txData : INT := 0;
    ocupado : BOOL := FALSE;
    ok : BOOL := FALSE;
    error : BOOL := FALSE;
    nIntentos : INT := 0;
    
    // Variables internas
    intentoActual : INT := 0;
    tiempoInicio : TIME;
    tiempoActual : TIME;
    esperandoRespuesta : BOOL := FALSE;
    valorPrueba : INT := 100;
END_VAR

// Código del bloque de función
IF NOT ocupado AND txReq THEN
    // Iniciar nuevo intercambio
    txData := valorPrueba;
    ocupado := TRUE;
    ok := FALSE;
    error := FALSE;
    intentoActual := 1;
    nIntentos := intentoActual;
    tiempoInicio := TIME(); // Captura el tiempo actual
    esperandoRespuesta := TRUE;
ELSIF ocupado THEN
    // Si estamos ocupados, verificar el estado del intento actual
    tiempoActual := TIME();
    
    IF esperandoRespuesta THEN
        // Verificar si se recibió respuesta correcta
        IF rxOk AND rxData = valorPrueba THEN
            // Respuesta correcta
            ok := TRUE;
            ocupado := FALSE;
            esperandoRespuesta := FALSE;
        ELSIF (tiempoActual - tiempoInicio) >= T#500MS THEN
            // Tiempo de espera agotado, intentar de nuevo
            intentoActual := intentoActual + 1;
            IF intentoActual > 3 THEN
                // Todos los intentos fallaron
                error := TRUE;
                ocupado := FALSE;
                esperandoRespuesta := FALSE;
            ELSE
                // Iniciar nuevo intento
                nIntentos := intentoActual;
                tiempoInicio := tiempoActual; // Reiniciar tiempo de inicio
            END_IF
        END_IF
    END_IF
END_IF
```

Este código implementa un intercambio de petición/respuesta con un dispositivo externo, manejando hasta 3 intentos y verificando la respuesta dentro de un plazo de 500 ms.