```pascal
FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; // Sensor fotoeléctrico que detecta la pieza
    btnReset : BOOL;    // Botón de reset para reiniciar el contador
END_VAR

VAR_OUTPUT
    loteListo : BOOL; // Salida que indica que se ha completado un lote
    cuenta : INT;      // Contador de piezas
END_VAR

VAR
    sensorAnterior : BOOL; // Variable para almacenar el estado anterior del sensor
END_VAR

// Inicialización del sensorAnterior con el valor actual del sensorPieza
IF sensorPieza THEN
    sensorAnterior := TRUE;
ELSE
    sensorAnterior := FALSE;
END_IF

// Lógica de conteo
IF sensorPieza AND NOT sensorAnterior THEN
    cuenta := cuenta + 1;
END_IF

// Actualización del sensorAnterior
sensorAnterior := sensorPieza;

// Lógica para detectar el lote completo
IF cuenta >= 12 THEN
    loteListo := TRUE;
ELSE
    loteListo := FALSE;
END_IF

// Lógica de reset
IF btnReset THEN
    cuenta := 0;
    loteListo := FALSE;
END_IF
END_FUNCTION_BLOCK
```