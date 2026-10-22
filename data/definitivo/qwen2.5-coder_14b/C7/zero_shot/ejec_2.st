```pascal
FUNCTION_BLOCK FB_Contador
VAR_INPUT
    sensorPieza : BOOL; // Contacto normalmente abierto del sensor de pieza
    btnReset : BOOL;    // Contacto normalmente abierto del botón de reset
END_VAR

VAR_OUTPUT
    loteListo : BOOL;  // Bobina que indica que el lote está listo
    cuenta : INT;      // Variable que almacena el valor actual del contador
END_VAR

VAR
    C1 : CTU;          // Contador ascendente
END_VAR

// Configuración del contador ascendente
C1.PV := 12;          // Valor preestablecido del contador

// Rama 1: Conteo de piezas
C1(CU := sensorPieza, RESET := btnReset);

// Rama 2: Indicación de lote listo
loteListo := C1.Q;

// Rama 3: Transferencia del valor actual del contador a la variable cuenta
cuenta := C1.CV;
END_FUNCTION_BLOCK
```