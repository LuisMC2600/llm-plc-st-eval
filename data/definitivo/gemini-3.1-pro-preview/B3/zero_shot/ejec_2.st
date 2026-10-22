```iecst
FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; // Sensor fotoeléctrico (TRUE al detectar pieza)
    btnReset    : BOOL; // Botón para reiniciar el contador
END_VAR

VAR_OUTPUT
    loteListo   : BOOL; // Se activa al llegar a 12 piezas
    cuenta      : INT;  // Número de piezas contadas
END_VAR

VAR
    flancoSensor : R_TRIG; // Bloque estándar para detectar flanco de subida
END_VAR

// Detectar transición de FALSE a TRUE en el sensor
flancoSensor(CLK := sensorPieza);

// Lógica de reinicio y conteo
IF btnReset THEN
    cuenta := 0; // Reiniciar cuenta
ELSIF flancoSensor.Q THEN
    cuenta := cuenta + 1; // Incrementar cuenta con cada nueva pieza
END_IF;

// Evaluar si el lote está completo (12 piezas)
// Al reiniciar la cuenta a 0, esta condición automáticamente desactiva loteListo
loteListo := (cuenta >= 12);

END_FUNCTION_BLOCK
```