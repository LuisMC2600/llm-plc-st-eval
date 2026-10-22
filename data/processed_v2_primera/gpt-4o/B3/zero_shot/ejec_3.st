FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL;  // Entrada del sensor fotoeléctrico
    btnReset : BOOL;     // Botón de reset
END_VAR

VAR_OUTPUT
    loteListo : BOOL;    // Salida que indica si el lote está completo
    cuenta : INT;        // Contador de piezas
END_VAR

VAR
    prevSensorPieza : BOOL;  // Estado anterior del sensor
END_VAR

// Inicialización de variables
IF btnReset THEN
    cuenta := 0;         // Reinicia el contador
    loteListo := FALSE;  // Desactiva la salida de lote completo
END_IF

// Detección de flanco ascendente del sensor
IF (sensorPieza AND NOT prevSensorPieza) THEN
    cuenta := cuenta + 1;  // Incrementa el contador
END_IF

// Verificación de lote completo
IF cuenta >= 12 THEN
    loteListo := TRUE;  // Activa la salida de lote completo
ELSE
    loteListo := FALSE; // Asegura que la salida esté desactivada si no se completa el lote
END_IF

// Actualización del estado anterior del sensor
prevSensorPieza := sensorPieza;

END_FUNCTION_BLOCK