```pascal
FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL;   // Entrada del sensor fotoeléctrico
    btnReset : BOOL;      // Botón de reset
END_VAR

VAR_OUTPUT
    loteListo : BOOL;     // Indica si el lote está completo
    cuenta : INT;         // Cuenta de piezas detectadas
END_VAR

VAR
    prevSensorPieza : BOOL; // Estado previo del sensor
END_VAR

// Inicialización de variables
IF btnReset THEN
    cuenta := 0;          // Reinicia la cuenta si se presiona el botón de reset
    loteListo := FALSE;   // Desactiva la salida de lote completo
END_IF

// Detección de flanco ascendente del sensor
IF (NOT prevSensorPieza) AND sensorPieza THEN
    cuenta := cuenta + 1; // Incrementa la cuenta al detectar una pieza
END_IF

// Comprobación de lote completo
IF cuenta >= 12 THEN
    loteListo := TRUE;    // Activa la salida de lote completo si se alcanzan 12 piezas
ELSE
    loteListo := FALSE;   // Asegura que la salida esté desactivada si no se alcanza el lote
END_IF

// Actualización del estado previo del sensor
prevSensorPieza := sensorPieza;

END_FUNCTION_BLOCK
```

Este código implementa un bloque de función en Structured Text (ST) que cuenta piezas en una línea de producción. Utiliza un sensor fotoeléctrico para detectar piezas y un botón de reset para reiniciar la cuenta. La salida `loteListo` se activa cuando se detectan 12 piezas.