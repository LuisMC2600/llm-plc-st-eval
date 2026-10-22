```pascal
FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL;  // Sensor que detecta la pieza
    btnReset : BOOL;     // Botón para resetear el contador
END_VAR

VAR_OUTPUT
    loteListo : BOOL;    // Indica si el lote está completo
    cuenta : INT;        // Contador de piezas
END_VAR

VAR
    prevSensorPieza : BOOL;  // Estado previo del sensor
END_VAR

// Inicialización de variables
INIT
    cuenta := 0;
    loteListo := FALSE;
    prevSensorPieza := FALSE;
END_INIT

// Cuerpo del bloque de función
IF btnReset THEN
    // Si el botón de reset está presionado, reiniciar el contador y la salida de lote
    cuenta := 0;
    loteListo := FALSE;
ELSIF NOT prevSensorPieza AND sensorPieza THEN
    // Detectar flanco ascendente del sensor
    cuenta := cuenta + 1;
    IF cuenta >= 12 THEN
        // Si se han contado 12 piezas, activar la salida de lote completo
        loteListo := TRUE;
    END_IF
END_IF

// Actualizar el estado previo del sensor
prevSensorPieza := sensorPieza;

END_FUNCTION_BLOCK
```

Este código implementa un contador de piezas en un bloque de función `FB_Contador` utilizando el lenguaje Structured Text (ST) conforme al estándar IEC 61131-3. El contador incrementa cada vez que se detecta una transición de FALSE a TRUE en el sensor, y se reinicia cuando se presiona el botón de reset. La salida `loteListo` se activa al contar 12 piezas.