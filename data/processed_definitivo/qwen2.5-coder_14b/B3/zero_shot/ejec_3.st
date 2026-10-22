FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; // Sensor fotoeléctrico que detecta la pieza
    btnReset : BOOL;    // Botón de reset para reiniciar el contador
END_VAR

VAR_OUTPUT
    loteListo : BOOL;  // Salida que indica que se ha completado un lote
    cuenta : INT;       // Contador de piezas
END_VAR

VAR
    sensorAnterior : BOOL; // Variable para almacenar el estado anterior del sensor
END_VAR

// Inicialización de variables
IF sensorAnterior = FALSE AND sensorPieza = TRUE THEN
    cuenta := cuenta + 1; // Incrementar el contador al detectar una pieza
END_IF;

// Control del botón de reset
IF btnReset THEN
    cuenta := 0; // Reiniciar el contador
    loteListo := FALSE; // Desactivar la salida de lote completo
END_IF;

// Control de la salida de lote completo
IF cuenta >= 12 THEN
    loteListo := TRUE; // Activar la salida de lote completo
ELSE
    loteListo := FALSE; // Desactivar la salida de lote completo si no se han completado 12 piezas
END_IF;

// Actualizar el estado anterior del sensor
sensorAnterior := sensorPieza;
END_FUNCTION_BLOCK