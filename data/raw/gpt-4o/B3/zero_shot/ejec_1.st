```pascal
FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL;  // Entrada del sensor fotoeléctrico
    btnReset : BOOL;     // Botón de reset
END_VAR

VAR_OUTPUT
    loteListo : BOOL;    // Indica si el lote está completo
    cuenta : INT;        // Contador de piezas
END_VAR

VAR
    prevSensorPieza : BOOL;  // Estado anterior del sensor
END_VAR

// Inicialización de variables
IF btnReset THEN
    cuenta := 0;         // Reinicia el contador
    loteListo := FALSE;  // Desactiva la salida de lote completo
ELSE
    // Detecta el flanco ascendente del sensor
    IF (sensorPieza AND NOT prevSensorPieza) THEN
        cuenta := cuenta + 1;  // Incrementa el contador
    END_IF

    // Verifica si el lote está completo
    IF cuenta >= 12 THEN
        loteListo := TRUE;  // Activa la salida de lote completo
    ELSE
        loteListo := FALSE; // Asegura que la salida esté desactivada si no está completo
    END_IF
END_IF

// Actualiza el estado anterior del sensor
prevSensorPieza := sensorPieza;

END_FUNCTION_BLOCK
```

Este código implementa un bloque de función `FB_Contador` que cuenta piezas detectadas por un sensor fotoeléctrico. La cuenta se incrementa en cada transición de FALSE a TRUE del sensor. Cuando se detectan 12 piezas, se activa la salida `loteListo`. Un botón de reset permite reiniciar el contador y desactivar la salida de lote completo.