FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; // Sensor fotoeléctrico (TRUE al detectar pieza)
    btnReset    : BOOL; // Botón para reiniciar la cuenta a cero
END_VAR

VAR_OUTPUT
    loteListo   : BOOL; // Se activa al llegar a 12 piezas
    cuenta      : INT;  // Número de piezas contadas
END_VAR

VAR
    flancoSensor : R_TRIG; // Detector de flanco de subida estándar IEC
END_VAR

// Detección del flanco de subida (transición de FALSE a TRUE) del sensor
flancoSensor(CLK := sensorPieza);

// Lógica de reinicio y conteo
IF btnReset THEN
    cuenta := 0; // Reinicia el contador
ELSIF flancoSensor.Q THEN
    cuenta := cuenta + 1; // Incrementa la cuenta por cada nueva pieza
END_IF;

// Evaluación del estado del lote (se desactiva automáticamente si cuenta < 12)
loteListo := (cuenta >= 12);

END_FUNCTION_BLOCK