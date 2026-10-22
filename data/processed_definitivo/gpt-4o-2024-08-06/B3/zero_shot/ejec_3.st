FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL;   // Entrada del sensor fotoeléctrico
    btnReset : BOOL;      // Botón de reset
END_VAR

VAR_OUTPUT
    loteListo : BOOL;     // Indica si el lote está completo
    cuenta : INT;         // Cuenta de piezas
END_VAR

VAR
    lastSensorState : BOOL; // Estado anterior del sensor
END_VAR

// Inicialización de variables
IF btnReset THEN
    cuenta := 0;
    loteListo := FALSE;
END_IF

// Detección de flanco ascendente del sensor
IF (sensorPieza AND NOT lastSensorState) THEN
    cuenta := cuenta + 1;
END_IF

// Comprobación si el lote está completo
IF cuenta >= 12 THEN
    loteListo := TRUE;
ELSE
    loteListo := FALSE;
END_IF

// Actualización del estado anterior del sensor
lastSensorState := sensorPieza;

END_FUNCTION_BLOCK