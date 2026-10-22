```pascal
FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; // Contacto normalmente abierto para el sensor de pieza
    btnReset : BOOL;    // Contacto normalmente abierto para el botón de reset
END_VAR

VAR_OUTPUT
    loteListo : BOOL;   // Bobina que indica si el lote está listo
    cuenta : INT;       // Valor actual del contador
END_VAR

VAR
    C1 : CTU;           // Contador ascendente
END_VAR

// Configuración del contador ascendente
C1(CU := sensorPieza, RESET := btnReset, PV := 12);

// Asignación de la salida del contador a la bobina loteListo
loteListo := C1.Q;

// Transferencia del valor actual del contador a la variable cuenta
cuenta := C1.CV;
END_FUNCTION_BLOCK
```

Este código en Structured Text (ST) implementa el comportamiento descrito en el Ladder Diagram, utilizando un bloque de función que maneja un contador ascendente y las condiciones especificadas.