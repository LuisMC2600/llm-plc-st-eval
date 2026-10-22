FUNCTION_BLOCK FB_Contador

VAR_INPUT
    sensorPieza : BOOL; // Entrada del sensor fotoeléctrico
    btnReset : BOOL;    // Botón para reiniciar el conteo y el lote
END_VAR

VAR_OUTPUT
    loteListo : BOOL;   // Se activa al llegar a 12 piezas
    cuenta : INT;       // Cantidad actual de piezas contadas
END_VAR

VAR
    flancoSensor : R_TRIG; // Instancia para detectar el flanco de subida
END_VAR

// Evaluar la transición de FALSE a TRUE del sensor
flancoSensor(CLK := sensorPieza);

// Lógica de reinicio y conteo
IF btnReset THEN
    cuenta := 0;
    loteListo := FALSE;
ELSIF flancoSensor.Q THEN
    cuenta := cuenta + 1;
END_IF;

// Lógica para activar la salida de lote completo
IF cuenta >= 12 THEN
    loteListo := TRUE;
END_IF;

END_FUNCTION_BLOCK