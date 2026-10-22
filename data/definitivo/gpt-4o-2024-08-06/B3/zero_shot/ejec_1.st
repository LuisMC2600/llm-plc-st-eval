```pascal
FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL;   // Entrada del sensor fotoeléctrico
    btnReset : BOOL;      // Botón de reset
END_VAR

VAR_OUTPUT
    loteListo : BOOL;     // Salida que indica si el lote está completo
    cuenta : INT;         // Contador de piezas
END_VAR

VAR
    sensorPiezaAnt : BOOL; // Estado anterior del sensor
END_VAR

// Inicialización de variables
sensorPiezaAnt := FALSE;
cuenta := 0;
loteListo := FALSE;

// Cuerpo del bloque de función
IF btnReset THEN
    // Si se presiona el botón de reset, reiniciar el contador y la salida de lote
    cuenta := 0;
    loteListo := FALSE;
ELSE
    // Detectar flanco ascendente del sensor
    IF (sensorPieza AND NOT sensorPiezaAnt) THEN
        // Incrementar el contador al detectar una pieza
        cuenta := cuenta + 1;
    END_IF;
    
    // Verificar si se ha completado el lote
    IF cuenta >= 12 THEN
        loteListo := TRUE;
    ELSE
        loteListo := FALSE;
    END_IF;
END_IF;

// Actualizar el estado anterior del sensor
sensorPiezaAnt := sensorPieza;

END_FUNCTION_BLOCK
```

Este bloque de función `FB_Contador` implementa el conteo de piezas y la lógica para determinar cuándo un lote está completo, además de permitir el reinicio del contador mediante un botón de reset.