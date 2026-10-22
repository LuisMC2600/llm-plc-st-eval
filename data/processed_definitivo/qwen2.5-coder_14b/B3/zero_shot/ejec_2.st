FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; // Entrada del sensor fotoeléctrico
    btnReset : BOOL; // Botón de reset
END_VAR

VAR_OUTPUT
    loteListo : BOOL; // Salida de lote completo
    cuenta : INT; // Contador de piezas
END_VAR

VAR
    sensorAnterior : BOOL; // Estado anterior del sensor
END_VAR

// Inicialización
IF sensorAnterior = FALSE AND sensorPieza = TRUE THEN
    cuenta := cuenta + 1; // Incrementar el contador
END_IF;

// Reset
IF btnReset THEN
    cuenta := 0; // Poner el contador en cero
    loteListo := FALSE; // Desactivar la salida de lote
END_IF;

// Control de lote completo
IF cuenta >= 12 THEN
    loteListo := TRUE; // Activar la salida de lote completo
ELSE
    loteListo := FALSE; // Desactivar la salida de lote completo
END_IF;

// Actualizar el estado anterior del sensor
sensorAnterior := sensorPieza;